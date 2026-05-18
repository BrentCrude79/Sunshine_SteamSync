# --- 0. Load Image Conversion Library ---
Add-Type -AssemblyName System.Drawing

#                                 README --- Configuration ---
# Update the variables below if Steam or Sunshine are installed in a non-standard directory 
# update the following line with your personal https://www.steamgriddb.com/ API key

$steamPath = "C:\Program Files (x86)\Steam"
$sunshineConfigDir = "C:\Program Files\Sunshine\config"   
$sgdbApiKey = "REPLACE ME WITH YOUR STEAM GRID DB API KEY"


$logoDir = Join-Path $sunshineConfigDir "logos"
$targetPath = Join-Path $sunshineConfigDir "apps.json" 


if (-not (Test-Path $logoDir)) { New-Item -ItemType Directory -Path $logoDir -Force | Out-Null }

# --- 1. Identify Steam Libraries ---
$libraryVdf = Join-Path $steamPath "steamapps\libraryfolders.vdf"
$vdfContent = Get-Content $libraryVdf -Raw -Encoding UTF8
$libraryPaths = [regex]::Matches($vdfContent, '"path"\s+"([^"]+)"').Groups | Where-Object { $_.Name -eq 1 } | Select-Object -ExpandProperty Value
$libraryPaths = $libraryPaths.Replace("\\", "\")

# --- 2. Gather Game Data & Assets ---
$currentSteamGames = @()
$sgdbHeaders = @{ "Authorization" = "Bearer $sgdbApiKey" }

foreach ($lib in $libraryPaths) {
    $manifests = Get-ChildItem (Join-Path $lib "steamapps\appmanifest_*.acf") -ErrorAction SilentlyContinue
    foreach ($file in $manifests) {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        $name    = [regex]::Match($content, '"name"\s+"([^"]+)"').Groups[1].Value
        $appid   = [regex]::Match($content, '"appid"\s+"([^"]+)"').Groups[1].Value
        $folder  = [regex]::Match($content, '"installdir"\s+"([^"]+)"').Groups[1].Value

        if ($name -match "SteamVR|Redistributable|Tool|Dedicated Server") { continue }

        $finalPngPath = Join-Path $logoDir "${appid}_poster.png"
        $posterPathJson = $finalPngPath.Replace("\", "/")

        if (-not (Test-Path $finalPngPath)) {
            Write-Host "Processing: $name..." -ForegroundColor Cyan
            try {
                # 1. Get the Game ID from SGDB
                $sgdbUrl = "https://www.steamgriddb.com/api/v2/games/steam/$appid"
                $gameSearch = Invoke-RestMethod -Uri $sgdbUrl -Headers $sgdbHeaders -Method Get -UserAgent "Mozilla/5.0"

                if ($gameSearch.success) {
                    $sgdbId = $gameSearch.data.id
                    # 2. Get the first available Grid (JPG is fine here)
                    $gridsUrl = "https://www.steamgriddb.com/api/v2/grids/game/$sgdbId"
                    $grids = Invoke-RestMethod -Uri $gridsUrl -Headers $sgdbHeaders -Method Get -UserAgent "Mozilla/5.0"

                    if ($grids.success -and $grids.data.Count -gt 0) {
                        $tempJpg = Join-Path $logoDir "temp_$appid.jpg"
                        Invoke-WebRequest -Uri $grids.data[0].url -OutFile $tempJpg -UserAgent "Mozilla/5.0"

                        # 3. CONVERSION ENGINE: JPG -> PNG
                        $image = [System.Drawing.Image]::FromFile($tempJpg)
                        $image.Save($finalPngPath, [System.Drawing.Imaging.ImageFormat]::Png)
                        $image.Dispose()

                        Remove-Item $tempJpg # Clean up the temp JPG
                        Write-Host "   [+] Converted & Saved as PNG." -ForegroundColor Green
                    }
                }
            } catch {
                Write-Host "   [!] Skip $name : $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        $currentSteamGames += @{
            name       = $name
            cmd        = "steam://rungameid/$appid"
            workingDir = (Join-Path $lib "steamapps\common\$folder").Replace("\", "/")
            image      = if (Test-Path $finalPngPath) { $posterPathJson } else { "" }
        }
    }
}

# --- 3. Update Sunshine apps.json ---
$sunshineConfig = if (Test-Path $targetPath) { Get-Content $targetPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { [PSCustomObject]@{ apps = @() } }
$preservedApps = @($sunshineConfig.apps | Where-Object { $_.cmd -notlike "steam://*" })

$updatedSteamApps = @(foreach ($game in $currentSteamGames) {
    [PSCustomObject]@{
        "name"         = $game.name
        "cmd"          = $game.cmd
        "working-dir"  = $game.workingDir
        "image-path"   = $game.image
        "auto-detach"  = "true"
        "wait-all"     = "true"
        "exit-timeout" = 5
        "detached"     = @()
    }
})

$sunshineConfig.apps = $preservedApps + $updatedSteamApps
[System.IO.File]::WriteAllText($targetPath, ($sunshineConfig | ConvertTo-Json -Depth 10))

# --- 4. Service Restart ---
Write-Host "`nRestarting Sunshine Service..." -ForegroundColor Yellow
$targetService = Get-Service | Where-Object { $_.DisplayName -eq "Sunshine Service" }
if ($targetService) {
    Stop-Service -Name $targetService.Name -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Get-Process sunshine -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Service -Name $targetService.Name -ErrorAction Stop
    Write-Host "Done! Check your library now." -ForegroundColor Green
}

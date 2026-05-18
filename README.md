Do you have Sunshine Game Streaming Service and you hate manually updating your applications list? 
Sunshine_steamsync is a script to keep Sunshine Applications up to date with Steam and automatically populate installed games.

Features:
Discover new Steam installed applications
Filter out VR and non-game tools
Add to Sunshine
Download cover art from SteamGridDB and add to Sunshine


<img width="1852" height="1476" alt="image" src="https://github.com/user-attachments/assets/011848ce-a715-4a09-86e5-613c46cf2da8" /># Sunshine_SteamSync
3rd party Sunshine Game Streaming Service Script to automate Steam Library synchronization.

Installation
Copy Steamsync.ps1 just about anywhere (e.g. c:\users\<yourname>) and then edit the file in notepad. Change the Steam and Sunshine installation directories if needed and then lookup your API key on SteamgridDB.com. Paste the API key into the steamsync.ps1 configuration section. Save and then create a task in task scheduler. Pick a time (daily at 4:15am for me) to run the program with the following settings:

Task name: Sunshine Steam Sync
time: daily at your chosen time
General:
<img width="935" height="664" alt="image" src="https://github.com/user-attachments/assets/712c7f09-9a94-4541-9353-29a7d812d199" />
Triggers:
<img width="910" height="649" alt="image" src="https://github.com/user-attachments/assets/a431d492-17f7-4931-b777-1f27f0efad0a" />
Actions:
<img width="898" height="592" alt="image" src="https://github.com/user-attachments/assets/08c5acbb-63a2-4287-87e1-99f43dc29cbc" />
<img width="672" height="737" alt="image" src="https://github.com/user-attachments/assets/43e68e11-20a7-43f0-8426-794aa2a13a6a" />

    Exact text assuming ps1 script placed in sunshine folder: powershell.exe -ExecutionPolicy Bypass -File "c:\program files\sunshine\Steamsync.ps1"

Conditions:
<img width="928" height="559" alt="image" src="https://github.com/user-attachments/assets/7b7f17db-0625-4a33-b8ba-a8dc10379af0" />
Settings:
<img width="910" height="581" alt="image" src="https://github.com/user-attachments/assets/99d9b92f-433b-4ce5-905c-c6df2b848a8e" />


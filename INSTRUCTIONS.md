# Instructions

## General Setup
1) Download the latest release of [Bizhawk](https://tasvideos.org/Bizhawk) and its prereq installer. Install both of them, starting with the prereq installer.
2) Acquire a clean version of Mega Man Battle Chip Challenge's rom. You're on your own for this one.
3) Download this repository via the big green button and hit "Download Zip".
4) Extract the downloaded zip in its entirety to its own folder inside the Bizhawk/Lua folder.
5) Open the emulator and run the game.
6) Edit Controls and Hotkeys under Bizhawk's "Config" menu. Clear out all hotkeys so they don't interfere.
7) Open the "Lua Console", under Bizhawk's "Tools" menu.
8) Open the Game and get past the introductory sequence.
9) While highlighting "PET" in the in-game menu, hit A to access its submenus. This is so the PET screen doesn't repeatedly flash.
10) Hit Open Script, then navigate to where you extracted the repository's files. Open "main.lua" first, then either "BCClocalbot.lua" or "BCCtwitchbot.lua" to start one of the bots. Open "BCCFolderEditor.lua" if you want to edit your Program Decks for the bots. Don't run both setups at the same time.
optional) Download the latest release of [DB Browser for SQLite](https://github.com/sqlitebrowser/sqlitebrowser) to manage the sqlite database. I recommend it so you can save data in a more easy-to-access file format.


## Bot Settings
Inside "settings.txt", which is accessed by both "BCClocalbot.lua" and "BCCtwitchbot.lua" when they first open, you will find various settings you can adjust.
- "Channel" is the name of a Twitch Channel you want BCCtwitchbot to connect to. Make sure it's one you have permission to use.
- "Name" is your bot's username. It must be a valid Twitch account.
- "OAuth" is the bot account's oauth ticket, which gives the bot access Twitch's API as well as verifying the account as legitimate.
- "Channel", "Name", and "OAuth" are only used by "BCCtwitchbot.lua"
- Don't edit "ActiveBanList" in this file. It will be automatically updated between tournaments and can be changed on the fly by your bot account or the Channel's account.
- BanLists is a list of lists, with those lists further defined with a Ban List name for their first value and another list comprised of Battle Chips as their second value, which are seperated by commas. Each full Ban List table must be seperated by commas as well. (Example Ban List: {"No Cannons", {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,51,52,53,54,63,64,65,116}})

### BCClocalbot Controls
"BCClocalbot.lua" requires input from the user playing the game to perform its commands.
- Keyboard 0-9: Type in Numbers
- Shift: Load Ban List ID
- Enter: Load User from "db/navicodes.cvs" into Tournament

### BCCFolderEditor Controls
"BCClocalbot.lua" has two modes; Name Entry and Program Deck Entry. To type in a username, go to "PET", then "NetNavi" in-game. To edit your Program Deck, go to "PET", then "Program Deck" in-game.
- Name Entry Controls
  - D-PAD Up/Right/Down/Left: Select Letter (Up = 1, Right = 2, Down = 3, Left = 4)
  - Keyboard A-Z: Change Selected Letter to Typed Letter
  - Button Select: Output Program Deck
- Program Deck Entry Controls
  - Button A: Select Chip
  - Button A (Hold): Cycle Chips by 10 instead of 1
  - Button L/R (Chip Selected): Cycle Chip (-1, +1)
  - Button L/R (No Chip Selected): Cycle NetOp (-1, +1)
  - Button Select: Output Program Deck
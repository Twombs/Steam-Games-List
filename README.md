# Steam-Games-List
Downloads and or Displays a list of games owned at Steam.

![Steam Games List](https://github.com/Twombs/Steam-Games-List/blob/main/Main_GUI_less.png?raw=true)

An inputbox is displayed when the executable is run, asking for the Steam User ID.

That ID is stored for repeated use, in the 'Settings.ini' file.

If OK is clicked, then basic game data is downloaded from Steam, then shown in a GUI, where it can be interacted with.

Or if CANCEL is clicked and data was downloaded previously, then it is shown in a GUI, where it can be interacted with.

Each input field has a button to copy text (Title or ID) or load an online link into your browser (URL or ICON). The URL can be either the Community game page or the Store game page, toggled by the 'Store' checkbox setting. Or input fields can be manually copied.

An XML file called 'Gameslist.xml' was downloaded to, containing the shown data and more.

The second to top button at right, is the Settings (Program Options) button. When clicked it shows or hides an extended lower section of the GUI.

![Steam Games List](https://github.com/Twombs/Steam-Games-List/blob/main/Main_GUI_more.png?raw=true)

A DRM-Free list can be downloaded from the PC Gaming Wiki, and then parsed for use when selecting a game entry or via a search. Steam Fandom page added as another option.

An existing (installed) game folder can be copied or moved to a different location as a backup. This can aternatively be done using the TeraCopy program, or you can use 7-Zip to create a zipped file at the backup destination, or instead create a self-extracting execute file there with a basic install menu.

NOT YET IMPLEMENTED - Interaction with SteamCMD to download and install your Steam games.

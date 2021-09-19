#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         Timboli

 Script Function:  Retrieve a list of games owned at Steam
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; FUNCTIONS
; MainGUI(), CharacterReplacements($text), ParseTheDRMFreeList(), SetStateOfControls($state)

#include <Constants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Misc.au3>
#include <File.au3>
#include <Inet.au3>
#include <InetConstants.au3>
#include <ListBoxConstants.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <ButtonConstants.au3>
#include <Array.au3>
#include <Crypt.au3>
#include <GuiListBox.au3>

_Singleton("steam-games-list-timboli")

Global $Button_backup, $Button_down, $Button_exit, $Button_find, $Button_fold, $Button_id, $Button_image, $Button_info
Global $Button_install, $Button_link, $Button_list, $Button_log, $Button_opts, $Button_pass, $Button_path, $Button_title
Global $Button_user, $Checkbox_find, $Checkbox_link, $Checkbox_ontop, $Checkbox_pass, $Checkbox_user, $Combo_backup
Global $Input_find, $Input_id, $Input_image, $Input_index, $Input_link, $Input_list, $Input_pass, $Input_path, $Input_size
Global $Input_title, $Input_user, $List_games

Global $a, $array, $buttxt, $c, $chunk, $created, $display, $download, $e, $entries, $entry, $freefle, $freelist, $g, $game
Global $gameID, $games, $image, $inifle, $line, $lines, $link, $ListGUI, $logfle, $notes, $pass, $ping, $read, $result, $state
Global $SteamCMD, $text, $title, $URL, $user, $userID, $val, $version, $xmlfle

$created = "September 2021"
$freefle = @ScriptDir & "\DRMfree.ini"
$freelist = @ScriptDir & "\DRMfree.html"
$inifle = @ScriptDir & "\Settings.ini"
$logfle = @ScriptDir & "\Log.txt"
$xmlfle = @ScriptDir & "\Gameslist.xml"
$SteamCMD = @ScriptDir & "\steamcmd.exe"
$version = " (v1.0)"

$display = IniRead($inifle, "Array", "display", "")
If $display = "" Then
	$display = 4
	IniWrite($inifle, "Array", "display", $display)
EndIf

$userID = IniRead($inifle, "Steam User", "id", "")
$result = InputBox("Steam User ID", "Enter or Accept the current ID.", $userID, "", 200, 130, Default, Default, 0)
If @error = 0 And $result <> "" Then
	SplashTextOn("", "Please Wait!", 180, 80, -1, -1, 33)
    If $result <> $userID Then
	   $userID = $result
	   IniWrite($inifle, "Steam User", "id", $userID)
   EndIf
    $URL = "https://steamcommunity.com/profiles/" & $userID & "/games/?xml=1"
	$ping = Ping("gog.com", 5000)
	If $ping > 0 Then
		_FileWriteLog($logfle, "Downloading owned Steam games list.")
		$download = InetGet($URL, $xmlfle, 0, 0)
		InetClose($download)
	Else
		MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 0, $GOGcliGUI)
	EndIf
	SplashOff()
EndIf
If FileExists($xmlfle) Then
    $lines = _FileCountLines($xmlfle)
    If $lines > 10 Then
		$read = FileRead($xmlfle)
		If $read <> "" Then
			$array = ""
			$games = StringSplit($read, "<appID>", 1)
			For $g = 2 To $games[0]
				$entry = $games[$g]
				$gameID = StringSplit($entry, "</appID>", 1)
				$gameID = $gameID[1]
				$title = StringSplit($entry, "<name><![CDATA[", 1)
				$title = $title[2]
				$title = StringSplit($title, "]]></name>", 1)
				$title = $title[1]
				$image = StringSplit($entry, "<logo><![CDATA[", 1)
				$image = $image[2]
				$image = StringSplit($image, "]]></logo>", 1)
				$image = $image[1]
				$link = StringSplit($entry, "<storeLink><![CDATA[", 1)
				$link = $link[2]
				$link = StringSplit($link, "]]></storeLink>", 1)
				$link = $link[1]
				$game = $title & " --- " & $gameID & " --- " & $link & " --- " & $image
				If $array = "" Then
					$array = $game
				Else
					$array = $array & "|" & $game
				EndIf
			Next
			$games = $games[0] - 1
			;MsgBox(262144, "Games", $games & " found.")
			$array = StringSplit($array, "|", 1)
			_ArraySort($array, 0, 1)
			If $display = 1 Then
				_ArrayDisplay($array, "Steam Games Owned", "", 0, "|", "Title --- ID --- Link --- Icon")
			EndIf
			_FileWriteLog($logfle, "Extracted game details from XML file.")
		EndIf
    EndIf
EndIf
If Not FileExists($freefle) Then
	If FileExists($freelist) Then
		$lines = _FileCountLines($freelist)
		If $lines > 0 Then
			SplashTextOn("", "Please Wait!", 180, 80, -1, -1, 33)
			ParseTheDRMFreeList()
			SplashOff()
		EndIf
    EndIf
EndIf
MainGUI()

Exit

Func MainGUI()
	Local $Edit_notes, $Group_backup, $Group_list, $Label_free, $Label_index, $Label_notes, $Label_size
	;
	Local $decrypt, $decrypted, $encrypted, $exStyle, $find, $gamesfld, $height, $icoD, $icoI, $icoM, $icoS
	Local $icoT, $icoX, $idx, $ind, $left, $listurl, $musicfld, $num, $ontop, $parent, $password, $size
	Local $steamfold, $store, $style, $tabs, $top, $type, $username, $vdffile, $width, $winsize
	;
	$exStyle = $WS_EX_TOPMOST
	$height = 510
	$left = -1
	$parent = 0
	$style = $WS_OVERLAPPED + $WS_CAPTION + $WS_SYSMENU + $WS_VISIBLE + $WS_CLIPSIBLINGS + $WS_MINIMIZEBOX
	$top = -1
	$width = 470
	$ListGUI = GUICreate("Games Owned At Steam", $width, $height, $left, $top, $style, $exStyle, $parent)
	GUISetBkColor($COLOR_YELLOW, $ListGUI)
	;
	; CONTROLS
	$Group_list = GUICtrlCreateGroup("Games", 10, 5, 390, 335)
	GUICtrlSetResizing($Group_list, $GUI_DOCKALL)
	$List_games = GUICtrlCreateList("", 15, 21, 380, 235, $GUI_SS_DEFAULT_LIST + $LBS_USETABSTOPS)
	GUICtrlSetResizing($List_games, $GUI_DOCKALL)
	GUICtrlSetBkColor($List_games, 0xFFFFCE)
	GUICtrlSetTip($List_games, "Select a game!")
	$Label_free = GUICtrlCreateLabel("DRM-Free", 20, 255, 60, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetFont($Label_free, 7, 400, 0, "Small Fonts")
	GUICtrlSetResizing($Label_free, $GUI_DOCKALL)
	GUICtrlSetBkColor($Label_free, 0xFFFFCE)
	$Label_notes = GUICtrlCreateLabel("NOTES", 20, 275, 60, 25, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetFont($Label_notes, 8, 600)
	GUICtrlSetResizing($Label_notes, $GUI_DOCKALL)
	GUICtrlSetBkColor($Label_notes, $COLOR_LIME)
	$Edit_notes = GUICtrlCreateEdit("", 80, 255, 310, 45, $ES_WANTRETURN + $WS_VSCROLL + $ES_AUTOVSCROLL)
	GUICtrlSetResizing($Edit_notes, $GUI_DOCKALL)
	GUICtrlSetTip($Edit_notes, "DRM-Free Notes!")
	$Label_index = GUICtrlCreateLabel("Index", 20, 310, 37, 20, $SS_CENTER + $SS_CENTERIMAGE)
	GUICtrlSetResizing($Label_index, $GUI_DOCKALL)
	GUICtrlSetBkColor($Label_index, $COLOR_BLUE)
	GUICtrlSetColor($Label_index, $COLOR_WHITE)
	$Input_index = GUICtrlCreateInput("", 57, 310, 35, 20, $ES_CENTER + $ES_READONLY)
	GUICtrlSetResizing($Input_index, $GUI_DOCKALL)
	GUICtrlSetTip($Input_index, "Selected entry number!")
	$Label_size = GUICtrlCreateLabel("Size", 102, 310, 32, 20, $SS_CENTER + $SS_CENTERIMAGE)
	GUICtrlSetResizing($Label_size, $GUI_DOCKALL)
	GUICtrlSetBkColor($Label_size, $COLOR_BLACK)
	GUICtrlSetColor($Label_size, $COLOR_WHITE)
	$Input_size = GUICtrlCreateInput("", 134, 310, 70, 20, $ES_CENTER + $ES_READONLY)
	GUICtrlSetResizing($Input_size, $GUI_DOCKALL)
	GUICtrlSetTip($Input_size, "Size of selected game folder!")
	$Input_find = GUICtrlCreateInput("", 212, 310, 130, 20, $ES_CENTER)
	GUICtrlSetResizing($Input_find, $GUI_DOCKALL)
	GUICtrlSetTip($Input_find, "Search text!")
	$Checkbox_find = GUICtrlCreateCheckbox("", 346, 310, 20, 20)
	GUICtrlSetResizing($Checkbox_find, $GUI_DOCKALL)
	GUICtrlSetTip($Checkbox_find, "Search for DRM-Free from selected!")
	$Button_find = GUICtrlCreateButton("F", 368, 308, 22, 23, $BS_ICON)
	GUICtrlSetResizing($Button_find, $GUI_DOCKALL)
	GUICtrlSetTip($Button_find, "Find the specified text in a title!")
	;
	$Checkbox_ontop = GUICtrlCreateCheckbox("On Top", 410, 10, 50, 25, $BS_PUSHLIKE)
	GUICtrlSetFont($Checkbox_ontop, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Checkbox_ontop, $GUI_DOCKALL)
	GUICtrlSetTip($Checkbox_ontop, "Toggle the Window On Top state!")
	;
	$Button_opts = GUICtrlCreateButton("Less", 410, 45, 50, 51, $BS_ICON)
	GUICtrlSetResizing($Button_opts, $GUI_DOCKALL)
	GUICtrlSetTip($Button_opts, "Program Options!")
	;
	$Button_fold = GUICtrlCreateButton("FOLD", 410, 106, 50, 51, $BS_ICON)
	GUICtrlSetResizing($Button_fold, $GUI_DOCKALL)
	GUICtrlSetTip($Button_fold, "Open selected game folder!")
	;
	$Button_log = GUICtrlCreateButton("LOG", 410, 167, 50, 51, $BS_ICON)
	GUICtrlSetResizing($Button_log, $GUI_DOCKALL)
	GUICtrlSetTip($Button_log, "View the Log Record file!")
	;
	$Button_info = GUICtrlCreateButton("INFO", 410, 228, 50, 51, $BS_ICON)
	GUICtrlSetResizing($Button_info, $GUI_DOCKALL)
	GUICtrlSetTip($Button_info, "Program Information!")
	;
	$Button_exit = GUICtrlCreateButton("EXIT", 410, 289, 50, 51, $BS_ICON)
	GUICtrlSetResizing($Button_exit, $GUI_DOCKALL)
	GUICtrlSetTip($Button_exit, "Exit or Close the program!")
	;
	$Button_title = GUICtrlCreateButton("TITLE", 10, 350, 45, 20)
	GUICtrlSetFont($Button_title, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_title, $GUI_DOCKALL)
	GUICtrlSetTip($Button_title, "Click to copy title to clipboard!")
	$Input_title = GUICtrlCreateInput("", 55, 350, 405, 20)
	GUICtrlSetResizing($Input_title, $GUI_DOCKALL)
	;
	$Button_id = GUICtrlCreateButton("ID", 10, 375, 30, 20)
	GUICtrlSetFont($Button_id, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_id, $GUI_DOCKALL)
	GUICtrlSetTip($Button_id, "Click to copy ID to clipboard!")
	$Input_id = GUICtrlCreateInput("", 40, 375, 70, 20)
	GUICtrlSetResizing($Input_id, $GUI_DOCKALL)
	;
	$Button_link = GUICtrlCreateButton("URL", 120, 375, 40, 20)
	GUICtrlSetFont($Button_link, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_link, $GUI_DOCKALL)
	GUICtrlSetTip($Button_link, "Click to go to the game web page!")
	$Input_link = GUICtrlCreateInput("", 160, 375, 250, 20)
	GUICtrlSetResizing($Input_link, $GUI_DOCKALL)
	$Checkbox_link = GUICtrlCreateCheckbox("Store", 415, 375, 45, 20)
	GUICtrlSetResizing($Checkbox_link, $GUI_DOCKALL)
	GUICtrlSetTip($Checkbox_link, "Change the link type!")
	;
	$Button_image = GUICtrlCreateButton("ICON", 10, 400, 45, 20)
	GUICtrlSetFont($Button_image, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_image, $GUI_DOCKALL)
	GUICtrlSetTip($Button_image, "Click to show the online image in your browser!")
	$Input_image = GUICtrlCreateInput("", 55, 400, 405, 20)
	GUICtrlSetResizing($Input_image, $GUI_DOCKALL)
	;
	$Button_list = GUICtrlCreateButton("LIST", 10, 425, 40, 20)
	GUICtrlSetFont($Button_list, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_list, $GUI_DOCKALL)
	GUICtrlSetTip($Button_list, "Click to go to the online DRM-Free list in your browser!")
	$Input_list = GUICtrlCreateInput("", 50, 425, 410, 20)
	GUICtrlSetResizing($Input_list, $GUI_DOCKALL)
	;
	$Button_down = GUICtrlCreateButton("DOWNLOAD && PARSE" & @LF & "THE DRM-FREE LIST", 10, 455, 140, 45, $BS_MULTILINE)
	GUICtrlSetFont($Button_down, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_down, $GUI_DOCKALL)
	GUICtrlSetTip($Button_down, "Download the online DRM-Free list and parse for use!")
	;
	$Button_install = GUICtrlCreateButton("DOWNLOAD && INSTALL" & @LF & "THE SELECTED GAME", 160, 455, 150, 45, $BS_MULTILINE)
	GUICtrlSetFont($Button_install, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_install, $GUI_DOCKALL)
	GUICtrlSetTip($Button_install, "Download & Install the selected game!")
	;
	$Button_backup = GUICtrlCreateButton("BACKUP" & @LF & "TO FILE", 320, 455, 75, 45, $BS_MULTILINE)
	GUICtrlSetFont($Button_backup, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_backup, $GUI_DOCKALL)
	GUICtrlSetTip($Button_backup, "Backup the selected game folder to specified file type!")
	$Group_backup = GUICtrlCreateGroup("", 395, 450, 65, 50)
	GUICtrlSetResizing($Group_backup, $GUI_DOCKALL)
	$Combo_backup = GUICtrlCreateCombo("", 405, 468, 45, 21)
	GUICtrlSetResizing($Combo_backup, $GUI_DOCKALL)
	;
	; OS SETTINGS
	$user = "C:\WINDOWS\system32\user32.dll"
	$shell = @SystemDir & "\shell32.dll"
	$icoD = -4
	$icoI = -5
	$icoM = -23
	$icoS = -217
	$icoT = -71
	$icoX = -4
	GUICtrlSetImage($Button_find, $shell, $icoM, 0)
	GUICtrlSetImage($Button_opts, $shell, $icoS, 1)
	GUICtrlSetImage($Button_fold, $shell, $icoD, 1)
	GUICtrlSetImage($Button_log, $shell, $icoT, 1)
	GUICtrlSetImage($Button_info, $user, $icoI, 1)
	GUICtrlSetImage($Button_exit, $user, $icoX, 1)
	;
	; SETTINGS
	SetStateOfControls($GUI_DISABLE)
	$ontop = IniRead($inifle, "Program Window", "ontop", "")
	If $ontop = "" Then
		$ontop = 1
		IniWrite($inifle, "Program Window", "ontop", $ontop)
	EndIf
	If $ontop = 4 Then
		WinSetOnTop($ListGUI, "", 0)
	EndIf
	GUICtrlSetState($Checkbox_ontop, $ontop)
	;
	$type = IniRead($inifle, "Backup File", "type", "")
	If $type = "" Then
		$type = "ZIP"
		IniWrite($inifle, "Backup File", "type", $type)
	EndIf
	GUICtrlSetData($Combo_backup, "ZIP|EXE|DIR", $type)
	If $type = "ZIP" Then
		GUICtrlSetTip($Combo_backup, "Zip the game folder!")
	ElseIf $type = "EXE" Then
		GUICtrlSetTip($Combo_backup, "Zip the game folder and make Executable!")
	ElseIf $type = "DIR" Then
		GUICtrlSetTip($Combo_backup, "Copy or Move the game folder to backup location!")
		GUICtrlSetData($Button_backup, "FOLDER" & @LF & "BACKUP")
	EndIf
	;GUICtrlSetState($Combo_backup, $GUI_DISABLE)
	;
	$encrypted = IniRead($inifle, "Username", "string", "")
	If $encrypted <> "" Then
		_Crypt_Startup()
		$username = _Crypt_DecryptData($encrypted, "d@C3fkk7x_", $CALG_AES_256)
		_Crypt_Shutdown()
		$username = BinaryToString($username)
	Else
		$username = ""
	EndIf
	$user = IniRead($inifle, "Username", "query", "")
	If $user = "" Then
		$user = 4
		IniWrite($inifle, "Username", "query", $user)
	EndIf
	;
	$encrypted = IniRead($inifle, "Password", "string", "")
	If $encrypted <> "" Then
		_Crypt_Startup()
		$password = _Crypt_DecryptData($encrypted, "d@C3fkk7x_", $CALG_AES_256)
		_Crypt_Shutdown()
		$password = BinaryToString($password)
	Else
		$password = ""
	EndIf
	$pass = IniRead($inifle, "Password", "query", "")
	If $pass = "" Then
		$pass = 1
		IniWrite($inifle, "Password", "query", $pass)
	EndIf
	;
	$store = IniRead($inifle, "Link Type", "store", "")
	If $store = "" Then
		$store = 1
		IniWrite($inifle, "Link Type", "store", $store)
	EndIf
	GUICtrlSetState($Checkbox_link, $store)
	;
	$listurl = IniRead($inifle, "DRM-Free List", "url", "")
	If $listurl = "" Then
		$listurl = "https://www.pcgamingwiki.com/wiki/The_Big_List_of_DRM-Free_Games_on_Steam"
		IniWrite($inifle, "DRM-Free List", "url", $listurl)
	EndIf
	GUICtrlSetData($Input_list, $listurl)
	;
	$tabs = @TAB & @TAB & @TAB & @TAB & @TAB & @TAB & @TAB & @TAB
	If IsArray($array) Then
		$games = $array[0]
		For $a = 1 To $games
			$entry = $array[$a]
			$entry = StringReplace($entry, " --- ", @TAB)
			$entry = StringReplace($entry, @TAB, $tabs, 1)
			GUICtrlSetData($List_games, $entry)
		Next
		GUICtrlSetData($Group_list, "Games (" & $games & ")")
    EndIf
	;
	$decrypt = ""
	$decrypted = ""
	$buttxt = "Less"
	;
	$gamefold = ""
	$ontop = 1
	;
	$steamfold = @ProgramFilesDir & "\Steam\steamapps"
	$gamesfld = $steamfold & "\common"
	$musicfld = $steamfold & "\music"
	$vdffile = $steamfold & "\libraryfolders.vdf"
	If FileExists($vdffile) Then
		$read = FileRead($vdffile)
		$read = StringSplit($read, '}')
		$read = $read[1]
		$read = StringSplit($read, '"')
		$read = $read[$read[0] - 1]
		$read = StringReplace($read, "\\", "\")
		If StringMid($read, 2, 2) = ":\" Then
			$path = $read & "\steamapps\common"
			If FileExists($path) Then
				$gamesfld = $path
				$musicfld = $read & "\steamapps\music"
			EndIf
		EndIf
	EndIf
	;Sleep(5000)
	SetStateOfControls($GUI_ENABLE)
	;
	;GUICtrlSetState($Button_down, $GUI_DISABLE)
	;GUICtrlSetState($Button_install, $GUI_DISABLE)
	;GUICtrlSetState($Button_backup, $GUI_DISABLE)

	GUISetState(@SW_SHOW)
	While 1
		$msg = GUIGetMsg()
        Select
			Case $msg = $GUI_EVENT_CLOSE Or $msg = $Button_exit
				; Exit or Close the program
				$listurl = GUICtrlRead($Input_list)
				If StringLeft($listurl, 4) = "http" Then
					If $listurl <> IniRead($inifle, "DRM-Free List", "url", "") Then
						IniWrite($inifle, "DRM-Free List", "url", $listurl)
					EndIf
				EndIf
				GUIDelete($ListGUI)
				ExitLoop
			Case $msg = $Button_user And $buttxt = "More"
				; Save the Username
				$username = GUICtrlRead($Input_user)
				If _IsPressed("11") And $username <> "" Then
					GUICtrlDelete($Input_user)
					If $decrypt = "" Then
						$decrypt = 1
						$Input_user = GUICtrlCreateInput("", 80, 550, 95, 20)
					Else
						$decrypt = ""
						$Input_user = GUICtrlCreateInput("", 80, 550, 95, 20, $ES_PASSWORD)
					EndIf
					GUICtrlSetData($Input_user, $username)
				Else
					If $username <> "" Then
						_Crypt_Startup()
						$encrypted = _Crypt_EncryptData($username, "d@C3fkk7x_", $CALG_AES_256)
						_Crypt_Shutdown()
					EndIf
					IniWrite($inifle, "Username", "string", $encrypted)
					_FileWriteLog($logfle, "Saved a username.")
				EndIf
			Case $msg = $Button_title
				; Click to copy title to clipboard
				$title = GUICtrlRead($Input_title)
				ClipPut($title)
			Case $msg = $Button_pass And $buttxt = "More"
				; Save the Password
				$password = GUICtrlRead($Input_pass)
				If _IsPressed("11") And $password <> "" Then
					GUICtrlDelete($Input_pass)
					If $decrypted = "" Then
						$decrypted = 1
						$Input_pass = GUICtrlCreateInput("", 310, 550, 100, 20)
					Else
						$decrypted = ""
						$Input_pass = GUICtrlCreateInput("", 310, 550, 100, 20, $ES_PASSWORD)
					EndIf
				Else
					If $password <> "" Then
						_Crypt_Startup()
						$password = _Crypt_EncryptData($password, "d@C3fkk7x_", $CALG_AES_256)
						_Crypt_Shutdown()
					EndIf
					IniWrite($inifle, "Password", "string", $password)
					_FileWriteLog($logfle, "Saved a password.")
				EndIf
			Case $msg = $Button_path And $buttxt = "More"
				; Browse to set the Steam games folder path
				MsgBox(262192, "Status Report", "This feature is currently unavailable!", 0, $ListGUI)
			Case $msg = $Button_opts
				; Program Options
				$buttxt = GUICtrlRead($Button_opts)
				If $buttxt = "Less" Then
					$buttxt = "More"
					GUICtrlSetData($Button_opts, $buttxt)
					$winsize = WinGetClientSize($ListGUI, "")
					$width = $winsize[0]
					$height = $winsize[1]
					WinMove($ListGUI, "", Default, Default, 476, 648)
					$Button_user = GUICtrlCreateButton("USERNAME", 10, 510, 75, 20)
					GUICtrlSetFont($Button_user, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_user, "Save the Username!")
					$Input_user = GUICtrlCreateInput("", 85, 510, 100, 20, $ES_PASSWORD)
					$Checkbox_user = GUICtrlCreateCheckbox("Query", 190, 510, 45, 20)
					GUICtrlSetTip($Checkbox_user, "Query for Username each time!")
					GUICtrlSetData($Input_user, $username)
					GUICtrlSetState($Checkbox_user, $user)
					If $user = 1 Then
						GUICtrlSetState($Button_user, $GUI_DISABLE)
						GUICtrlSetState($Input_user, $GUI_DISABLE)
					EndIf
					;
					$Button_pass = GUICtrlCreateButton("PASSWORD", 245, 510, 75, 20)
					GUICtrlSetFont($Button_pass, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_pass, "Save the Password!")
					$Input_pass = GUICtrlCreateInput("", 320, 510, 90, 20, $ES_PASSWORD)
					$Checkbox_pass = GUICtrlCreateCheckbox("Query", 415, 510, 45, 20)
					GUICtrlSetTip($Checkbox_pass, "Query for Password each time!")
					GUICtrlSetData($Input_pass, $password)
					GUICtrlSetState($Checkbox_pass, $pass)
					If $pass = 1 Then
						GUICtrlSetState($Button_pass, $GUI_DISABLE)
						GUICtrlSetState($Input_pass, $GUI_DISABLE)
					EndIf
					;
					$Input_path = GUICtrlCreateInput("", 10, 540, 355, 20)
					GUICtrlSetTip($Input_path, "Path of the Steam games folder!")
					$Button_path = GUICtrlCreateButton("GAMES FOLDER", 365, 540, 95, 20)
					GUICtrlSetFont($Button_path, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_path, "Browse to set the Steam games folder path!")
					GUICtrlSetData($Input_path, $gamesfld)
					;
					$Input_dest = GUICtrlCreateInput("", 10, 565, 315, 20)
					GUICtrlSetTip($Input_dest, "Destination path of the backup!")
					$Button_dest = GUICtrlCreateButton("DESTINATION", 325, 565, 85, 20)
					GUICtrlSetFont($Button_dest, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_dest, "Browse to set the destination path!")
					;GUICtrlSetData($Input_dest, $destfld)
					$Checkbox_dest = GUICtrlCreateCheckbox("Query", 415, 565, 45, 20)
					GUICtrlSetTip($Checkbox_dest, "Query for Destination each time!")
					;GUICtrlSetState($Checkbox_dest, $dest)
					;
					$Input_tera = GUICtrlCreateInput("", 10, 590, 338, 20)
					GUICtrlSetTip($Input_tera, "Path of the TeraCopy program!")
					$Button_tera = GUICtrlCreateButton("TeraCopy", 348, 590, 70, 20)
					GUICtrlSetFont($Button_tera, 7, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_tera, "Browse to set the TeraCopy path!")
					;GUICtrlSetData($Input_tera, $teracopy)
					$Checkbox_tera = GUICtrlCreateCheckbox("Use", 423, 590, 40, 20)
					GUICtrlSetTip($Checkbox_tera, "Use the TeraCopy program!")
					;GUICtrlSetState($Checkbox_tera, $tera)
				ElseIf $buttxt = "More" Then
					$buttxt = "Less"
					GUICtrlSetData($Button_opts, $buttxt)
					GUICtrlDelete($Button_user)
					GUICtrlDelete($Input_user)
					GUICtrlDelete($Checkbox_user)
					GUICtrlDelete($Button_pass)
					GUICtrlDelete($Input_pass)
					GUICtrlDelete($Checkbox_pass)
					GUICtrlDelete($Input_path)
					GUICtrlDelete($Button_path)
					GUICtrlDelete($Input_dest)
					GUICtrlDelete($Button_dest)
					GUICtrlDelete($Checkbox_dest)
					GUICtrlDelete($Input_tera)
					GUICtrlDelete($Button_tera)
					GUICtrlDelete($Checkbox_tera)
					WinMove($ListGUI, "", Default, Default, $width + 6, $height + 28)
				EndIf
			Case $msg = $Button_log
				; View the Log Record file
				If FileExists($logfle) Then
					If $ontop = 1 Then
						$ontop = 4
						GUICtrlSetState($Checkbox_ontop, $ontop)
						WinSetOnTop($ListGUI, "", 0)
					EndIf
					ShellExecute($logfle)
				EndIf
			Case $msg = $Button_list
				; Click to go to the online DRM-Free list in your browser
				$listurl = GUICtrlRead($Input_list)
				If StringLeft($listurl, 4) = "http" Then ShellExecute($listurl)
			Case $msg = $Button_link
				; Click to go to the game web page
				$link = GUICtrlRead($Input_link)
				If StringLeft($link, 4) = "http" Then ShellExecute($link)
			Case $msg = $Button_install
				; Download & Install the selected game
				$title = GUICtrlRead($Input_title)
				If $title <> "" Then
					$title = CharacterReplacements($title)
					$gameID = GUICtrlRead($Input_id)
					If $gameID <> "" Then
						If FileExists($SteamCMD) Then
							MsgBox(262192, "Status Report", "This feature is currently unavailable!", 0, $ListGUI)
							;$ping = Ping("gog.com", 5000)
							;If $ping > 0 Then
							;Else
							;	MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 0, $GOGcliGUI)
							;EndIf
						EndIf
					EndIf
				Else
					MsgBox(262192, "Usage Error", "No title selected!", 3, $ListGUI)
				EndIf
			Case $msg = $Button_info
				; Program Information
				SetStateOfControls($GUI_DISABLE)
				MsgBox(262208, "Program Information", _
					"This program is for downloading your list of owned Steam games," & @LF & _
					"and then viewing that list, and or then interacting with it usefully." & @LF & @LF & _
					"Of particular use, is using SteamCMD to download and install any" & @LF & _
					"selected game on the list, then maybe backing the game folder up" & @LF & _
					"to a zip file or self-extracting executable file, to a specified location." & @LF & @LF & _
					"Username and Password can be saved (stored) within the program," & @LF & _
					"though perhaps for improved security reasons, make the password" & @LF & _
					"a query, even though both credentials are stored encrypted in a file." & @LF & @LF & _
					"Some games at Steam, are capable of being DRM-Free, though you" & @LF & _
					"cannot find that information on the store game page. However you" & @LF & _
					"can find online listings about which ones are DRM-Free, and one of" & @LF & _
					"them can be used by this program, to make determinations easier." & @LF & @LF & _
					"CTRL held down while clicking folder button opens program folder." & @LF & @LF & _
					"CTRL held down while clicking the password or username buttons" & @LF & _
					"will reveal (toggle) the hidden text state." & @LF & @LF & _
					"© Created by Timboli (aka TheSaint) in " & $created & $version, 0, $ListGUI)
				SetStateOfControls($GUI_ENABLE)
			Case $msg = $Button_image
				; Click to show the online image in your browser
				$image = GUICtrlRead($Input_image)
				If StringLeft($image, 4) = "http" Then ShellExecute($image)
			Case $msg = $Button_id
				; Click to copy ID to clipboard
				$gameID = GUICtrlRead($Input_id)
				ClipPut($gameID)
			Case $msg = $Button_fold
				; Open selected game folder
				If $ontop = 1 Then
					$ontop = 4
					GUICtrlSetState($Checkbox_ontop, $ontop)
					WinSetOnTop($ListGUI, "", 0)
				EndIf
				If _IsPressed("11") Then
					ShellExecute(@ScriptDir)
				ElseIf FileExists($gamefold) Then
					ShellExecute($gamefold)
				ElseIf FileExists($gamesfld) Then
					ShellExecute($gamesfld)
				EndIf
			Case $msg = $Button_find
				; Find the specified text in a title
				$find = GUICtrlRead($Input_find)
				If $find <> "" Then
					$ind = _GUICtrlListBox_GetCurSel($List_games)
					If $find = "DRM-Free" Then
						GUICtrlSetData($Input_find, "Searching...")
						$cnt = _GUICtrlListBox_GetCount($List_games)
						For $c = $ind To $cnt - 1
							$idx = $c + 1
							$entry = _GUICtrlListBox_GetText($List_games, $idx)
							If $entry <> "" Then
								$entry = StringReplace($entry, $tabs, "|", 1)
								$entry = StringReplace($entry, @TAB, "|")
								$entry = StringSplit($entry, "|", 1)
								$title = $entry[1]
								$val = IniRead($freefle, $title, "drm-free", "")
								If $val = 1 Then
									$ind = $idx
									_GUICtrlListBox_SetCurSel($List_games, $ind)
									_GUICtrlListBox_ClickItem($List_games, $ind, "left", False, 1, 0)
									ExitLoop
								EndIf
								If $c = $cnt - 2 Then
									_GUICtrlListBox_SetTopIndex($List_games, 0)
									$ind = -1
									_GUICtrlListBox_SetCurSel($List_games, $ind)
									$c = $ind
								EndIf
							EndIf
						Next
						GUICtrlSetData($Input_find, "DRM-Free")
					Else
						$ind = _GUICtrlListBox_FindInText($List_games, $find, $ind, True)
						If $ind > -1 Then
							_GUICtrlListBox_SetCurSel($List_games, $ind)
							_GUICtrlListBox_ClickItem($List_games, $ind, "left", False, 1, 0)
						EndIf
					EndIf
				EndIf
			Case $msg = $Button_down
				; Download the online DRM-Free list and parse for use
				$listurl = GUICtrlRead($Input_list)
				If $listurl <> "" Then
					If StringLeft($listurl, 4) = "http" Then
						SetStateOfControls($GUI_DISABLE)
						$find = GUICtrlRead($Input_find)
						GUICtrlSetBkColor($Input_find, $COLOR_RED)
						GUICtrlSetData($Input_find, "Please Wait!")
						$ping = Ping("gog.com", 5000)
						If $ping > 0 Then
							$download = InetGet($listurl, $freelist, 0, 0)
							InetClose($download)
							_FileWriteLog($logfle, "Downloaded the DRM-Free list.")
							If FileExists($freelist) Then
								$lines = _FileCountLines($freelist)
								If $lines > 0 Then
									ParseTheDRMFreeList()
								Else
									_FileWriteLog($logfle, "Content Error - File is empty.")
									MsgBox(262192, "Content Error", "File is empty!", 0, $ListGUI)
								EndIf
							Else
								_FileWriteLog($logfle, "Download Error - File not found.")
								MsgBox(262192, "Download Error", "File not found!", 0, $ListGUI)
							EndIf
						Else
							MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 0, $ListGUI)
						EndIf
						GUICtrlSetBkColor($Input_find, $CLR_DEFAULT)
						GUICtrlSetData($Input_find, $find)
						SetStateOfControls($GUI_ENABLE)
						;MsgBox(262192, "Status Report", "This feature is incomplete!", 0, $ListGUI)
					EndIf
				EndIf
			Case $msg = $Button_backup
				; Backup the selected game folder to specified file type
				$title = GUICtrlRead($Input_title)
				$title = CharacterReplacements($title)
				$gamefold = $gamesfld & "\" & $title
				If $title <> "" And FileExists($gamefold) Then
					_FileWriteLog($logfle, "Started the backup for - " & $title)
					MsgBox(262192, "Status Report", "This feature is currently unavailable!", 0, $ListGUI)
					_FileWriteLog($logfle, "Backup Complete.")
				Else
					MsgBox(262192, "Usage Error", "No title selected!", 3, $ListGUI)
				EndIf
			Case $msg = $Checkbox_user And $buttxt = "More"
				; Query for Username each time
				If GUICtrlRead($Checkbox_user) = $GUI_CHECKED Then
					$user = 1
					GUICtrlSetState($Button_user, $GUI_DISABLE)
					GUICtrlSetState($Input_user, $GUI_DISABLE)
				Else
					$user = 4
					GUICtrlSetState($Button_user, $GUI_ENABLE)
					GUICtrlSetState($Input_user, $GUI_ENABLE)
				EndIf
				IniWrite($inifle, "Username", "query", $user)
			Case $msg = $Checkbox_pass And $buttxt = "More"
				; Query for Password each time
				If GUICtrlRead($Checkbox_pass) = $GUI_CHECKED Then
					$pass = 1
					GUICtrlSetState($Button_pass, $GUI_DISABLE)
					GUICtrlSetState($Input_pass, $GUI_DISABLE)
				Else
					$pass = 4
					GUICtrlSetState($Button_pass, $GUI_ENABLE)
					GUICtrlSetState($Input_pass, $GUI_ENABLE)
				EndIf
				IniWrite($inifle, "Password", "query", $pass)
			Case $msg = $Checkbox_ontop
				; Toggle the Window On Top state
				If GUICtrlRead($Checkbox_ontop) = $GUI_CHECKED Then
					$ontop = 1
					WinSetOnTop($ListGUI, "", 1)
				Else
					$ontop = 4
					WinSetOnTop($ListGUI, "", 0)
				EndIf
				IniWrite($inifle, "Program Window", "ontop", $ontop)
			Case $msg = $Checkbox_link
				; Change the link type
				$link = GUICtrlRead($Input_link)
				If GUICtrlRead($Checkbox_link) = $GUI_CHECKED Then
					$store = 1
					$link = StringReplace($link, "https://steamcommunity.com", "https://store.steampowered.com")
				Else
					$store = 4
					$link = StringReplace($link, "https://store.steampowered.com", "https://steamcommunity.com")
				EndIf
				GUICtrlSetData($Input_link, $link)
				IniWrite($inifle, "Link Type", "store", $store)
			Case $msg = $Checkbox_find
				; Search for DRM-Free from selected
				$find = GUICtrlRead($Input_find)
				If GUICtrlRead($Checkbox_find) = $GUI_CHECKED Then
					$find = "DRM-Free"
				Else
					$find = StringReplace($find, "DRM-Free", "")
				EndIf
				GUICtrlSetData($Input_find, $find)
			Case $msg = $Combo_backup
				; Backup file type
				$type = GUICtrlRead($Combo_backup)
				IniWrite($inifle, "Backup File", "type", $type)
				If $type = "DIR" Then
					GUICtrlSetTip($Combo_backup, "Copy or Move the game folder to backup location!")
					GUICtrlSetData($Button_backup, "FOLDER" & @LF & "BACKUP")
				Else
					If $type = "ZIP" Then
						GUICtrlSetTip($Combo_backup, "Zip the game folder!")
					ElseIf $type = "EXE" Then
						GUICtrlSetTip($Combo_backup, "Zip the game folder and make Executable!")
					EndIf
					GUICtrlSetData($Button_backup, "BACKUP" & @LF & "TO FILE")
				EndIf
			Case $msg = $List_games
				$title = ""
				$gameID = ""
				$link = ""
				$image = ""
				$entry = GUICtrlRead($List_games)
				If $entry <> "" Then
					$entry = StringReplace($entry, $tabs, "|", 1)
					$entry = StringReplace($entry, @TAB, "|")
					$entry = StringSplit($entry, "|", 1)
					$title = $entry[1]
					If $entry[0] > 1 Then
						$gameID = $entry[2]
						If $entry[0] > 2 Then
							$link = $entry[3]
							If $entry[0] > 3 Then
								$image = $entry[4]
							EndIf
						EndIf
					EndIf
					;GUICtrlSetState($Button_down, $GUI_ENABLE)
					;GUICtrlSetState($Button_install, $GUI_ENABLE)
					;GUICtrlSetState($Button_backup, $GUI_ENABLE)
					$val = IniRead($freefle, $title, "drm-free", "")
					If $val = 1 Then
						GUICtrlSetBkColor($Label_free, $COLOR_RED)
						GUICtrlSetColor($Label_free, $COLOR_YELLOW)
						$notes = IniRead($freefle, $title, "notes", "")
					Else
						GUICtrlSetBkColor($Label_free, 0xFFFFCE)
						GUICtrlSetColor($Label_free, $COLOR_BLACK)
						$notes = ""
					EndIf
					GUICtrlSetData($Edit_notes, $notes)
					$ind = _GUICtrlListBox_GetCurSel($List_games)
					$num = $ind + 1
					GUICtrlSetData($Input_index, $num)
					;$title = GUICtrlRead($Input_title)
					$title = CharacterReplacements($title)
					$gamefold = $gamesfld & "\" & $title
					If $title <> "" And FileExists($gamefold) Then
						GUICtrlSetState($List_games, $GUI_DISABLE)
						GUICtrlSetData($Input_size, "wait")
						$size = DirGetSize($gamefold)
						GUICtrlSetState($List_games, $GUI_ENABLE)
					Else
						If StringRight($title, 11) = " Soundtrack" Then
							$gamefold = $musicfld & "\" & $title
						EndIf
						If FileExists($gamefold) Then
							GUICtrlSetState($List_games, $GUI_DISABLE)
							GUICtrlSetData($Input_size, "wait")
							$size = DirGetSize($gamefold)
							GUICtrlSetState($List_games, $GUI_ENABLE)
						Else
							$gamefold = ""
							$size = ""
						;ElseIf FileExists($gamesfld) Then
						;	$size = DirGetSize($gamesfld)
						EndIf
					EndIf
					If $size > 0 Then
						If $size < 1024 Then
							$size = $size & " bytes"
						ElseIf $size < 1048576 Then
							$size = Ceiling($size / 1024)
							$size = $size & " Kb"
						ElseIf $size < 1073741824 Then
							$size = Round($size / 1048576, 2)
							$size = $size & " Mb"
						ElseIf $size < 1099511627776 Then
							$size = Round($size / 1073741824, 3)
							$size = $size & " Gb"
						Else
							$size = Round($size / 1099511627776, 4)
							$size = $size & " Tb"
						EndIf
					Else
						$size = "missing"
					EndIf
					GUICtrlSetData($Input_size, $size)
					GUICtrlSetData($Input_title, $title)
					GUICtrlSetData($Input_id, $gameID)
					If $store = 1 And $link <> "" Then
						$link = StringReplace($link, "https://steamcommunity.com", "https://store.steampowered.com")
					EndIf
					GUICtrlSetData($Input_link, $link)
					GUICtrlSetData($Input_image, $image)
					GUICtrlSetState($Input_title, $GUI_FOCUS)
					Send("{HOME}")
					GUICtrlSetState($List_games, $GUI_FOCUS)
				EndIf
			Case Else
		EndSelect
	WEnd
EndFunc ;=> MainGUI


Func CharacterReplacements($text)
	$text = StringReplace($text, ":", "")
	Return $text
EndFunc ;=> CharacterReplacements

Func ParseTheDRMFreeList()
	$read = FileRead($freelist)
	If $read <> "" Then
		_FileCreate($freefle)
		$games = ""
		$entries = StringSplit($read, @LF & "<tr>" & @LF, 1)
		For $e = 2 To $entries[0]
			$chunk = $entries[$e]
			$entry = StringSplit($chunk, '</td></tr>', 1)
			$entry = $entry[1]
			$entry = StringSplit($entry, '</a>' & @LF & '</td>', 1)
			$game = $entry[1]
			If StringInStr($game, ' title="') < 1 Then $game = $entry[2]
			$game = StringSplit($game, ' title="', 1)
			If $game[0] = 2 Then
				$game = $game[2]
				$game = StringSplit($game, '">', 1)
				$game = $game[2]
				$game = StringSplit($game, '</a>', 1)
				$game = $game[1]
				If $games = "" Then
					$games = "[" & $game & "]" & @CRLF & "drm-free=1"
				Else
					$games = $games & @CRLF & "[" & $game & "]" & @CRLF & "drm-free=1"
				EndIf
			Else
				$entry = $game
				For $a = 2 To $entry[0]
					$game = $entry[$a]
					$game = StringSplit($game, '">', 1)
					$game = $game[2]
					$game = StringSplit($game, '</a>', 1)
					$game = $game[1]
					If $games = "" Then
						$games = "[" & $game & "]" & @CRLF & "drm-free=1"
					Else
						$games = $games & @CRLF & "[" & $game & "]" & @CRLF & "drm-free=1"
					EndIf
				Next
			EndIf
			$notes = ""
			$chunk = StringReplace($chunk, '<td style="text-align: center;">?' & @LF, '')
			$chunk = StringReplace($chunk, '<td style="text-align: center;">✔' & @LF, '')
			$chunk = StringReplace($chunk, '</td></tr>' & @LF, '')
			$chunk = StringReplace($chunk, '</td></tr>', '')
			$chunk = StringReplace($chunk, '</td>' & @LF, '')
			$chunk = StringReplace($chunk, '<td>', '')
			$chunk = StringReplace($chunk, '</p>', '')
			$chunk = StringReplace($chunk, "<code>", "'")
			$chunk = StringReplace($chunk, "</code>", "'")
			$chunk = StringReplace($chunk, '</tbody></table>', '')
			$chunk = StringReplace($chunk, '<table class="wikitable" style="width: 100%">', '')
			$chunk = StringReplace($chunk, '<tbody><tr>', '')
			$chunk = StringReplace($chunk, "<b>", "(")
			$chunk = StringReplace($chunk, "</b>", ")")
			$chunk = StringReplace($chunk, "[", "")
			$chunk = StringReplace($chunk, "]", "")
			$chunk = StringSplit($chunk, @LF, 1)
			For $c = 1 To $chunk[0]
				$line = $chunk[$c]
				If StringInStr($line, 'href="') < 1 And StringInStr($line, '<td style=') < 1 Then
					$notes = StringStripWS($line, 7)
					If $notes <> "" Then ExitLoop
				EndIf
			Next
			If $notes <> "" Then $games = $games & @CRLF & "notes=" & $notes
		Next
		$games = StringReplace($games, "&#39;", "'")
		$games = StringReplace($games, "&amp;", "&")
		FileWrite($freefle, $games)
		$entries = $entries[0]
		MsgBox(262144, "DRM-Free Games", $entries & " found.", 3, $ListGUI)
	EndIf
	_FileWriteLog($logfle, "Parsed the DRM-Free list.")
EndFunc ;=> ParseTheDRMFreeList

Func SetStateOfControls($state)
	GUICtrlSetState($ListGUI, $state)
	GUICtrlSetState($Input_index, $state)
	GUICtrlSetState($Input_size, $state)
	GUICtrlSetState($Checkbox_find, $state)
	GUICtrlSetState($Button_find, $state)
	;
	GUICtrlSetState($Checkbox_ontop, $state)
	GUICtrlSetState($Button_opts, $state)
	GUICtrlSetState($Button_fold, $state)
	GUICtrlSetState($Button_log, $state)
	GUICtrlSetState($Button_info, $state)
	GUICtrlSetState($Button_exit, $state)
	;
	GUICtrlSetState($Button_title, $state)
	GUICtrlSetState($Input_title, $state)
	GUICtrlSetState($Button_id, $state)
	GUICtrlSetState($Input_id, $state)
	GUICtrlSetState($Button_link, $state)
	GUICtrlSetState($Input_link, $state)
	GUICtrlSetState($Checkbox_link, $state)
	GUICtrlSetState($Button_image, $state)
	GUICtrlSetState($Input_image, $state)
	GUICtrlSetState($Button_list, $state)
	GUICtrlSetState($Input_list, $state)
	;
	GUICtrlSetState($Button_down, $state)
	GUICtrlSetState($Button_install, $state)
	GUICtrlSetState($Button_backup, $state)
	GUICtrlSetState($Combo_backup, $state)
	;
	If $buttxt = "More" Then
		If $user = 4 Then
			GUICtrlSetState($Button_user, $state)
			GUICtrlSetState($Input_user, $state)
		EndIf
		GUICtrlSetState($Checkbox_user, $state)
		If $pass = 4 Then
			GUICtrlSetState($Button_pass, $state)
			GUICtrlSetState($Input_pass, $state)
		EndIf
		GUICtrlSetState($Checkbox_pass, $state)
		GUICtrlSetState($Input_path, $state)
		GUICtrlSetState($Button_path, $state)
	EndIf
EndFunc ;=> SetStateOfControls

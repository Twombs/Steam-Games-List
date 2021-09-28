#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         Timboli

 Script Function:  Retrieve a list of games owned at Steam
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; FUNCTIONS
; MainGUI()
; AddTextToInput($text, $what), CharacterReplacements($text), GetLocalSteamGamesFolder(), ParseTheDRMFreeList(), SetStateOfControls($state)

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

Global $Button_backup, $Button_code, $Button_dest, $Button_destiny, $Button_down, $Button_exit, $Button_find, $Button_fold
Global $Button_id, $Button_image, $Button_info, $Button_install, $Button_link, $Button_list, $Button_log, $Button_notes
Global $Button_opts, $Button_pass, $Button_path, $Button_save, $Button_tera, $Button_title, $Button_user, $Button_zip
Global $Checkbox_dest, $Checkbox_find, $Checkbox_link, $Checkbox_ontop, $Checkbox_pass, $Checkbox_path, $Checkbox_tera
Global $Checkbox_user, $Combo_backup, $Combo_list, $Input_code, $Input_dest, $Input_find, $Input_id, $Input_image
Global $Input_index, $Input_link, $Input_list, $Input_pass, $Input_path, $Input_size, $Input_tera, $Input_title, $Input_user
Global $Input_zip, $List_games

Global $7zip, $a, $alternate, $array, $buttxt, $c, $chunk, $code, $created, $delete, $dest, $display, $download, $drmfree
Global $e, $end, $entries, $entry, $fext, $freefle, $freefle1, $freefle2, $freelist, $g, $game, $gameID, $games, $gamesfld
Global $image, $inifle, $line, $lines, $link, $ListGUI, $logfle, $musicfld, $notes, $pass, $path, $ping, $pos, $read, $result
Global $state, $SteamCMD, $steamfold, $tera, $text, $title, $URL, $user, $userID, $val, $vdffile, $version, $what, $xmlfle

$created = "September 2021"
$freefle1 = @ScriptDir & "\DRMfree.ini"
$freefle2 = @ScriptDir & "\DRMfree2.ini"
$freelist = @ScriptDir & "\DRMfree.html"
$inifle = @ScriptDir & "\Settings.ini"
$logfle = @ScriptDir & "\Log.txt"
$xmlfle = @ScriptDir & "\Gameslist.xml"
$SteamCMD = @ScriptDir & "\steamcmd.exe"
$version = " (v1.1)"

$display = IniRead($inifle, "Array", "display", "")
If $display = "" Then
	$display = 4
	IniWrite($inifle, "Array", "display", $display)
EndIf

$userID = IniRead($inifle, "Steam User", "id", "")
$result = InputBox("Steam User ID", "Enter ID or Accept the current ID." & @LF & "  (will use your web connection)" & @LF & @LF & "Cancel = Just open the program.", $userID, "", 200, 165, Default, Default, 0)
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
		MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 0, $ListGUI)
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
			If $ping > 0 Then _FileWriteLog($logfle, "Extracted game details from XML file.")
		EndIf
    EndIf
EndIf
;~ If Not FileExists($freefle) Then
;~ 	If FileExists($freelist) Then
;~ 		$lines = _FileCountLines($freelist)
;~ 		If $lines > 0 Then
;~ 			SplashTextOn("", "Please Wait!", 180, 80, -1, -1, 33)
;~ 			ParseTheDRMFreeList()
;~ 			SplashOff()
;~ 		EndIf
;~     EndIf
;~ EndIf
MainGUI()

Exit

Func MainGUI()
	Local $Edit_notes, $Group_backup, $Group_list, $Label_free, $Label_index, $Label_notes, $Label_size
	;
	Local $altpth, $ans, $bakfile, $cnt, $copy, $decrypt, $decrypted, $destfld, $downfold, $drv, $encrypted, $exefile
	Local $exStyle, $find, $gamefold, $height, $icoD, $icoI, $icoM, $icoS, $icoT, $icoX, $idx, $ind, $left, $listurl
	Local $mass, $method, $n, $num, $ontop, $params, $parent, $password, $pid, $pth, $savefile, $savefold, $shell
	Local $size, $space, $store, $style, $tabs, $teracopy, $top, $type, $user32, $username, $volfile, $width, $winsize
	Local $zipfile, $zipfld, $zipfold
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
	GUICtrlSetTip($Input_title, "Selected game title!")
	;
	$Button_id = GUICtrlCreateButton("ID", 10, 375, 30, 20)
	GUICtrlSetFont($Button_id, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_id, $GUI_DOCKALL)
	GUICtrlSetTip($Button_id, "Click to copy ID to clipboard!")
	$Input_id = GUICtrlCreateInput("", 40, 375, 70, 20)
	GUICtrlSetResizing($Input_id, $GUI_DOCKALL)
	GUICtrlSetTip($Input_id, "Steam game ID!")
	;
	$Button_link = GUICtrlCreateButton("URL", 120, 375, 40, 20)
	GUICtrlSetFont($Button_link, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_link, $GUI_DOCKALL)
	GUICtrlSetTip($Button_link, "Click to go to the game web page!")
	$Input_link = GUICtrlCreateInput("", 160, 375, 250, 20)
	GUICtrlSetResizing($Input_link, $GUI_DOCKALL)
	GUICtrlSetTip($Input_link, "URL for online game web page!")
	$Checkbox_link = GUICtrlCreateCheckbox("Store", 415, 375, 45, 20)
	GUICtrlSetResizing($Checkbox_link, $GUI_DOCKALL)
	GUICtrlSetTip($Checkbox_link, "Change the link type!")
	;
	$Button_image = GUICtrlCreateButton("ICON", 10, 400, 45, 20)
	GUICtrlSetFont($Button_image, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_image, $GUI_DOCKALL)
	GUICtrlSetTip($Button_image, "Click to show the online image in your browser!")
	$Input_image = GUICtrlCreateInput("", 55, 400, 355, 20)
	GUICtrlSetResizing($Input_image, $GUI_DOCKALL)
	GUICtrlSetTip($Input_image, "URL for online game icon!")
	$Button_save = GUICtrlCreateButton("SAVE", 415, 400, 45, 20)
	GUICtrlSetFont($Button_save, 6, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_save, $GUI_DOCKALL)
	GUICtrlSetTip($Button_save, "Save the image to game destination folder!")
	;
	$Button_list = GUICtrlCreateButton("LIST", 10, 425, 40, 21)
	GUICtrlSetFont($Button_list, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_list, $GUI_DOCKALL)
	GUICtrlSetTip($Button_list, "Click to go to the online DRM-Free list in your browser!")
	$Input_list = GUICtrlCreateInput("", 50, 425, 300, 21)
	GUICtrlSetResizing($Input_list, $GUI_DOCKALL)
	GUICtrlSetTip($Input_list, "URL for online DRM-Free page!")
	$Combo_list = GUICtrlCreateCombo("", 355, 425, 105, 21)
	GUICtrlSetResizing($Combo_list, $GUI_DOCKALL)
	GUICtrlSetBkColor($Combo_list, 0xBFFFBF)
	GUICtrlSetTip($Combo_list, "Select the Online DRM-Free page!")
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
	$user32 = "C:\WINDOWS\system32\user32.dll"
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
	GUICtrlSetImage($Button_info, $user32, $icoI, 1)
	GUICtrlSetImage($Button_exit, $user32, $icoX, 1)
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
	$store = IniRead($inifle, "Link Type", "store", "")
	If $store = "" Then
		$store = 1
		IniWrite($inifle, "Link Type", "store", $store)
	EndIf
	GUICtrlSetState($Checkbox_link, $store)
	;
	;$listurl = IniRead($inifle, "DRM-Free List", "url", "")
	$drmfree = IniRead($inifle, "DRM-Free", "page", "")
	If $drmfree = "" Then
		$drmfree = "PC Gaming Wiki"
		IniWrite($inifle, "DRM-Free", "page", $drmfree)
	EndIf
	GUICtrlSetData($Combo_list, "PC Gaming Wiki|Steam Fandom", $drmfree)
	$listurl = IniRead($inifle, "Steam Fandom", "url", "")
	If $listurl = "" Then
		$listurl = "https://steam.fandom.com/wiki/List_of_DRM-free_games"
		IniWrite($inifle, "Steam Fandom", "url", $listurl)
	EndIf
	$listurl = IniRead($inifle, "PC Gaming Wiki", "url", "")
	If $listurl = "" Then
		$listurl = "https://www.pcgamingwiki.com/wiki/The_Big_List_of_DRM-Free_Games_on_Steam"
		IniWrite($inifle, "PC Gaming Wiki", "url", $listurl)
	EndIf
	If $drmfree = "PC Gaming Wiki" Then
		$freefle = $freefle1
		$listurl = "https://www.pcgamingwiki.com/wiki/The_Big_List_of_DRM-Free_Games_on_Steam"
	ElseIf $drmfree = "Steam Fandom" Then
		$freefle = $freefle2
		$listurl = "https://steam.fandom.com/wiki/List_of_DRM-free_games"
	EndIf
	GUICtrlSetData($Input_list, $listurl)
	;
	$encrypted = IniRead($inifle, "Steam Guard", "code", "")
	If $encrypted <> "" Then
		_Crypt_Startup()
		$code = _Crypt_DecryptData($encrypted, "d@C3fkk7x_", $CALG_AES_256)
		_Crypt_Shutdown()
		$code = BinaryToString($code)
	Else
		$code = ""
	EndIf
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
	$altpth = IniRead($inifle, "Games Folder", "alt_path", "")
	If $altpth = "" Then
		$altpth = ""
		IniWrite($inifle, "Games Folder", "alt_path", $altpth)
	EndIf
	$alternate = IniRead($inifle, "Games Folder", "use_alt", "")
	If $alternate = "" Then
		$alternate = 4
		IniWrite($inifle, "Games Folder", "use_alt", $alternate)
	EndIf
	;
	$destfld = IniRead($inifle, "Destination", "path", "")
	If $destfld = "" Then
		$destfld = ""
		IniWrite($inifle, "Destination", "path", $destfld)
	EndIf
	$dest = IniRead($inifle, "Destination", "query", "")
	If $dest = "" Then
		$dest = 1
		IniWrite($inifle, "Destination", "query", $dest)
	EndIf
	;
	$teracopy = IniRead($inifle, "TeraCopy", "path", "")
	If $teracopy = "" Then
		$teracopy = ""
		IniWrite($inifle, "TeraCopy", "path", $teracopy)
	EndIf
	$tera = IniRead($inifle, "TeraCopy", "use", "")
	If $tera = "" Then
		$tera = 4
		IniWrite($inifle, "TeraCopy", "use", $tera)
	EndIf
	;
	$7zip = IniRead($inifle, "7-Zip", "path", "")
	If $7zip = "" Then
		$7zip = ""
		IniWrite($inifle, "7-Zip", "path", $7zip)
	EndIf
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
	If $alternate = 4 Then GetLocalSteamGamesFolder()
	;
	SetStateOfControls($GUI_ENABLE)

	GUISetState(@SW_SHOW)
	While 1
		$msg = GUIGetMsg()
        Select
			Case $msg = $GUI_EVENT_CLOSE Or $msg = $Button_exit
				; Exit or Close the program
				;$listurl = GUICtrlRead($Input_list)
				;If StringLeft($listurl, 4) = "http" Then
				;	If $listurl <> IniRead($inifle, "DRM-Free List", "url", "") Then
				;		IniWrite($inifle, "DRM-Free List", "url", $listurl)
				;	EndIf
				;EndIf
				GUIDelete($ListGUI)
				ExitLoop
			Case $msg = $Button_zip And $buttxt = "More"
				; Browse to set the 7-Zip path
				$7zip = "C:\Program Files\7-Zip\7z.exe"
				If FileExists($7zip) Then
					$pth = $7zip
				Else
					$7zip = ""
					$pth = "7z.exe"
				EndIf
				$pth = FileOpenDialog("Browse to set the 7-Zip path", @ProgramFilesDir, "Program file (*.exe)", 3, $pth, $ListGUI)
				If Not @error And StringMid($pth, 2, 2) = ":\" Then
					$7zip = $pth
					IniWrite($inifle, "7-Zip", "path", $7zip)
					GUICtrlSetData($Input_zip, $7zip)
				EndIf
			Case $msg = $Button_user And $buttxt = "More"
				; Save the Username
				$username = GUICtrlRead($Input_user)
				$username = AddTextToInput($username, "Username")
				GUICtrlSetData($Input_user, $username)
				If $username = "" Then
					$encrypted = $username
				Else
					_Crypt_Startup()
					$encrypted = _Crypt_EncryptData($username, "d@C3fkk7x_", $CALG_AES_256)
					_Crypt_Shutdown()
				EndIf
				IniWrite($inifle, "Username", "string", $encrypted)
				_FileWriteLog($logfle, "Saved a username.")
			Case $msg = $Button_title
				; Click to copy title to clipboard
				$title = GUICtrlRead($Input_title)
				ClipPut($title)
			Case $msg = $Button_tera And $buttxt = "More"
				; Browse to set the TeraCopy path
				$teracopy = "C:\Program Files\TeraCopy\TeraCopy.exe"
				If FileExists($teracopy) Then
					$pth = $teracopy
				Else
					$teracopy = ""
					$pth = "TereCopy.exe"
				EndIf
				$pth = FileOpenDialog("Browse to set the TeraCopy path", @ProgramFilesDir, "Program file (*.exe)", 3, $pth, $ListGUI)
				If Not @error And StringMid($pth, 2, 2) = ":\" Then
					$teracopy = $pth
					IniWrite($inifle, "TeraCopy", "path", $teracopy)
					GUICtrlSetData($Input_tera, $teracopy)
				EndIf
			Case $msg = $Button_save
				; Save the image to game destination folder
				$image = GUICtrlRead($Input_image)
				If $image <> "" And StringLeft($image, 4) = "http" Then
					$title = GUICtrlRead($Input_title)
					If $title <> "" Then
						$title = CharacterReplacements($title)
						If FileExists($destfld) Then
							$fext = StringSplit($image, ".", 1)
							$fext = $fext[$fext[0]]
							If $fext <> "" Then
								$savefile = "GameIcon." & $fext
								$savefold = $destfld & "\" & $title
								If FileExists($savefold) Then
									$savefile = $savefold & "\" & $savefile
									$ping = Ping("gog.com", 5000)
									If $ping > 0 Then
										$download = InetGet($image, $savefile, 0, 0)
										InetClose($download)
										If FileExists($savefile) Then
											_FileWriteLog($logfle, "Downloaded the '" & $title & "' game icon image file.")
										Else
											_FileWriteLog($logfle, "Download Error - File not found.")
											MsgBox(262192, "Download Error", "File not found!", 3, $ListGUI)
										EndIf
									Else
										MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 3, $ListGUI)
									EndIf
								Else
									MsgBox(262192, "Path Error", "Game destination folder doesn't exist!", 3, $ListGUI)
								EndIf
							Else
								MsgBox(262192, "Image Error", "Could not determine image file type!", 3, $ListGUI)
							EndIf
						Else
							MsgBox(262192, "Path Error", "Destination folder not set or doesn't exist!", 3, $ListGUI)
						EndIf
					Else
						MsgBox(262192, "Usage Error", "No title selected!", 3, $ListGUI)
					EndIf
				Else
					MsgBox(262192, "Icon Error", "No image file linke is listed, or incorrect format!", 6, $ListGUI)
				EndIf
			Case $msg = $Button_pass And $buttxt = "More"
				; Save the Password
				$password = GUICtrlRead($Input_pass)
				$password = AddTextToInput($password, "Password")
				GUICtrlSetData($Input_pass, $password)
				If $password = "" Then
					$encrypted = $password
				Else
					_Crypt_Startup()
					$encrypted = _Crypt_EncryptData($password, "d@C3fkk7x_", $CALG_AES_256)
					_Crypt_Shutdown()
				EndIf
				IniWrite($inifle, "Password", "string", $encrypted)
				_FileWriteLog($logfle, "Saved a password.")
			Case $msg = $Button_path And $buttxt = "More"
				; Browse to set the Steam games folder path
				;MsgBox(262192, "Status Report", "This feature is currently unavailable!", 0, $ListGUI)
				$pth = FileSelectFolder("Browse to set your Steam games folder path", "", 7, "", $ListGUI)
				If Not @error Then
					;If $alternate = 4 Then
					;	$gamesfld = $pth
					;	GUICtrlSetData($Input_path, $gamesfld)
					;Else
						$altpth = $pth
						GUICtrlSetData($Input_path, $altpth)
						IniWrite($inifle, "Games Folder", "alt_path", $altpth)
					;EndIf
				EndIf
			Case $msg = $Button_opts
				; Program Options
				$buttxt = GUICtrlRead($Button_opts)
				If $buttxt = "Less" Then
					$buttxt = "More"
					GUICtrlSetData($Button_opts, $buttxt)
					$winsize = WinGetClientSize($ListGUI, "")
					$width = $winsize[0]
					$height = $winsize[1]
					WinMove($ListGUI, "", Default, Default, 476, 673)
					;
					$Input_zip = GUICtrlCreateInput("", 10, 510, 220, 20)
					GUICtrlSetTip($Input_zip, "Path of the 7-Zip program!")
					$Button_zip = GUICtrlCreateButton("7-Zip", 230, 510, 50, 20)
					GUICtrlSetFont($Button_zip, 7, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_zip, "Browse to set the 7-Zip path!")
					GUICtrlSetData($Input_zip, $7zip)
					;
					$Button_code = GUICtrlCreateButton("STEAM GUARD CODE", 290, 510, 120, 20)
					GUICtrlSetFont($Button_code, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_code, "Set the Steam Guard code!")
					$Input_code = GUICtrlCreateInput("", 410, 510, 50, 20, $ES_PASSWORD)
					GUICtrlSetTip($Input_code, "Users Steam Guard code!")
					GUICtrlSetData($Input_code, $code)
					;
					$Button_user = GUICtrlCreateButton("USERNAME", 10, 540, 75, 20)
					GUICtrlSetFont($Button_user, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_user, "Save the Username!")
					$Input_user = GUICtrlCreateInput("", 85, 540, 90, 20, $ES_PASSWORD)
					GUICtrlSetTip($Input_user, "Username!")
					$Checkbox_user = GUICtrlCreateCheckbox("Query", 179, 540, 45, 20)
					GUICtrlSetTip($Checkbox_user, "Query for Username each time!")
					GUICtrlSetData($Input_user, $username)
					GUICtrlSetState($Checkbox_user, $user)
					If $user = 1 Then
						GUICtrlSetState($Button_user, $GUI_DISABLE)
						GUICtrlSetState($Input_user, $GUI_DISABLE)
					EndIf
					;
					$Button_pass = GUICtrlCreateButton("PASSWORD", 225, 540, 75, 20)
					GUICtrlSetFont($Button_pass, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_pass, "Save the Password!")
					$Input_pass = GUICtrlCreateInput("", 300, 540, 111, 20, $ES_PASSWORD)
					GUICtrlSetTip($Input_pass, "Password!")
					$Checkbox_pass = GUICtrlCreateCheckbox("Query", 415, 540, 45, 20)
					GUICtrlSetTip($Checkbox_pass, "Query for Password each time!")
					GUICtrlSetData($Input_pass, $password)
					GUICtrlSetState($Checkbox_pass, $pass)
					If $pass = 1 Then
						GUICtrlSetState($Button_pass, $GUI_DISABLE)
						GUICtrlSetState($Input_pass, $GUI_DISABLE)
					EndIf
					;
					$Input_path = GUICtrlCreateInput("", 10, 565, 290, 20)
					GUICtrlSetTip($Input_path, "Path of the Steam games folder!")
					$Button_path = GUICtrlCreateButton("GAMES FOLDER", 300, 565, 95, 20)
					GUICtrlSetFont($Button_path, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_path, "Browse to set the Steam games folder path!")
					If $alternate = 4 Then
						GUICtrlSetData($Input_path, $gamesfld)
						GUICtrlSetState($Input_path, $GUI_DISABLE)
						GUICtrlSetState($Button_path, $GUI_DISABLE)
					Else
						GUICtrlSetData($Input_path, $altpth)
					EndIf
					$Checkbox_path = GUICtrlCreateCheckbox("Alternate", 400, 565, 65, 20)
					GUICtrlSetTip($Checkbox_path, "Use an alternate games folder!")
					GUICtrlSetState($Checkbox_path, $alternate)
					;
					$Input_dest = GUICtrlCreateInput("", 10, 590, 230, 20)
					GUICtrlSetTip($Input_dest, "Destination path of the backup!")
					$Button_dest = GUICtrlCreateButton("DESTINATION", 240, 590, 85, 20)
					GUICtrlSetFont($Button_dest, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_dest, "Browse to set the destination path!")
					GUICtrlSetData($Input_dest, $destfld)
					$Checkbox_dest = GUICtrlCreateCheckbox("Query", 330, 590, 45, 20)
					GUICtrlSetTip($Checkbox_dest, "Query for Destination each time!")
					GUICtrlSetState($Checkbox_dest, $dest)
					$Button_notes = GUICtrlCreateButton("NOTES", 380, 590, 50, 20)
					GUICtrlSetFont($Button_notes, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_notes, "Save selected notes to destination game folder!")
					$Button_destiny = GUICtrlCreateButton("D", 435, 589, 25, 22, $BS_ICON)
					GUICtrlSetTip($Button_destiny, "Open the destination folder!")
					GUICtrlSetImage($Button_destiny, $shell, $icoD, 0)
					If $dest = 1 Then
						GUICtrlSetState($Input_dest, $GUI_DISABLE)
						GUICtrlSetState($Button_dest, $GUI_DISABLE)
						GUICtrlSetState($Button_destiny, $GUI_DISABLE)
					EndIf
					;
					$Input_tera = GUICtrlCreateInput("", 10, 615, 338, 20)
					GUICtrlSetTip($Input_tera, "Path of the TeraCopy program!")
					$Button_tera = GUICtrlCreateButton("TeraCopy", 348, 615, 70, 20)
					GUICtrlSetFont($Button_tera, 7, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_tera, "Browse to set the TeraCopy path!")
					GUICtrlSetData($Input_tera, $teracopy)
					$Checkbox_tera = GUICtrlCreateCheckbox("Use", 423, 615, 40, 20)
					GUICtrlSetTip($Checkbox_tera, "Use the TeraCopy program!")
					GUICtrlSetState($Checkbox_tera, $tera)
					If $tera = 4 Then
						GUICtrlSetState($Input_tera, $GUI_DISABLE)
						GUICtrlSetState($Button_tera, $GUI_DISABLE)
					EndIf
				ElseIf $buttxt = "More" Then
					$buttxt = "Less"
					GUICtrlSetData($Button_opts, $buttxt)
					GUICtrlDelete($Input_zip)
					GUICtrlDelete($Button_zip)
					GUICtrlDelete($Button_code)
					GUICtrlDelete($Input_code)
					GUICtrlDelete($Button_user)
					GUICtrlDelete($Input_user)
					GUICtrlDelete($Checkbox_user)
					GUICtrlDelete($Button_pass)
					GUICtrlDelete($Input_pass)
					GUICtrlDelete($Checkbox_pass)
					GUICtrlDelete($Input_path)
					GUICtrlDelete($Button_path)
					GUICtrlDelete($Checkbox_path)
					GUICtrlDelete($Input_dest)
					GUICtrlDelete($Button_dest)
					GUICtrlDelete($Checkbox_dest)
					GUICtrlDelete($Button_notes)
					GUICtrlDelete($Button_destiny)
					GUICtrlDelete($Input_tera)
					GUICtrlDelete($Button_tera)
					GUICtrlDelete($Checkbox_tera)
					WinMove($ListGUI, "", Default, Default, $width + 6, $height + 28)
				EndIf
			Case $msg = $Button_notes And $buttxt = "More"
				; Save selected notes to destination game folder
				If $notes <> "" Then
					$title = GUICtrlRead($Input_title)
					If $title <> "" Then
						$title = CharacterReplacements($title)
						If FileExists($destfld) Then
							$drmfree = GUICtrlRead($Combo_list)
							If $drmfree = "PC Gaming Wiki" Then
								$savefile = "PC Gaming Wiki.txt"
							ElseIf $drmfree = "Steam Fandom" Then
								$savefile = "Steam Fandom.txt"
							EndIf
							$savefold = $destfld & "\" & $title
							If FileExists($savefold) Then
								$savefile = $savefold & "\" & $savefile
								_FileCreate($savefile)
								Sleep(500)
								FileWrite($savefile, $notes)
								_FileWriteLog($logfle, "Saved a DRM-Free List notes file for '" & $title & "'.")
							Else
								MsgBox(262192, "Path Error", "Game destination folder doesn't exist!", 3, $ListGUI)
							EndIf
						Else
							MsgBox(262192, "Path Error", "Destination folder not set or doesn't exist!", 3, $ListGUI)
						EndIf
					Else
						MsgBox(262192, "Usage Error", "No title selected!", 3, $ListGUI)
					EndIf
				Else
					MsgBox(262192, "Notes Error", "Notes don't exist for the selected game," & @LF & "with the current 'DRM-Free List' option!", 6, $ListGUI)
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
						If $alternate = 4 Then
							$downfold = $gamesfld
						Else
							$downfold = $altpth
						EndIf
						If FileExists($downfold) Then
							$downfold = $downfold & "\" & $title
							If FileExists($downfold) Then
								$ans = MsgBox(262144 + 33, "Alert & Query", "WARNING - Game title folder already exists" _
									& @LF & "at the chosen destination path." _
									& @LF & "Do you want to continue?" & @LF _
									& @LF & "OK = Continue." _
									& @LF & "CANCEL = Abort downloading." & @LF _
									& @LF & "NOTE - This could be due to an incomplete" _
									& @LF & "prior download or maybe you are updating.", 0, $ListGUI)
								If $ans = 2 Then
									ContinueLoop
								EndIf
							EndIf
							If FileExists($SteamCMD) Then
								;MsgBox(262192, "Status Report", "This feature is currently unavailable!", 0, $ListGUI)
								SetStateOfControls($GUI_DISABLE)
								$find = GUICtrlRead($Input_find)
								GUICtrlSetBkColor($Input_find, $COLOR_RED)
								GUICtrlSetData($Input_find, "Please Wait!")
								_FileWriteLog($logfle, "Downloading - " & $title)
								$ping = Ping("gog.com", 5000)
								If $ping > 0 Then
									;steamcmd.exe +login username password +set_steam_guard_code CODE +force_install_dir "E:\GAMES\steamapps\common\10 Second Ninja X" +app_update 435790 +quit
									;RunWait($SteamCMD, @ScriptDir)
									$params = ' +login '
									If $username = "" Or $user = 1 Then
										$username = AddTextToInput($username, "Username")
									EndIf
									If $password = "" Or $pass = 1 Then
										$password = AddTextToInput($password, "Password")
									EndIf
									If $username <> "" And $password <> "" Then
										$params = $params & $username & " " & $password
										If $code <> "" Then $params = $params & ' +set_steam_guard_code ' & $code
									Else
										$params = $params & 'anonymous'
									EndIf
									$params = $params & ' +force_install_dir "' & $downfold & '" +app_update ' & $gameID & ' +quit'
									RunWait($SteamCMD & $params, @ScriptDir)
									_FileWriteLog($logfle, "Downloading Finished.")
								Else
									_FileWriteLog($logfle, "Downloading Failed - Ping error.")
									MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 0, $ListGUI)
								EndIf
								GUICtrlSetBkColor($Input_find, $CLR_DEFAULT)
								GUICtrlSetData($Input_find, $find)
								SetStateOfControls($GUI_ENABLE)
							Else
								MsgBox(262192, "Program Error", "The required 'steamcmd.exe' file could not be found!" & @LF _
									& "It should be in the same folder as this program.", 0, $ListGUI)
							EndIf
						Else
							MsgBox(262192, "Path Error", "Game folder not set or location doesn't exist!", 0, $ListGUI)
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
					"can find online listings about which ones are DRM-Free, and two of" & @LF & _
					"those can be used by this program, to make determinations easier." & @LF & @LF & _
					"CTRL held down while clicking folder button opens program folder." & @LF & @LF & _
					"Third Party programs which have no ties to myself are required for" & @LF & _
					"some processes to work (i.e. 7-Zip, SteamCMD and TeraCopy)." & @LF & @LF & _
					"DISCLAIMER - While I have tried to ensure that nothing untoward" & @LF & _
					"happens, you use this program at your own risk (no guarantees)." & @LF & @LF & _
					"BIG THANKS as always to Jon & AutoIt developer etc team." & @LF & _
					"BIG THANKS to the developers of 7-Zip." & @LF & _
					"BIG THANKS to the developers of TeraCopy." & @LF & _
					"BIG THANKS to the developers of SteamCMD." & @LF & _
					"BIG THANKS to those who provided & created (update) the online" & @LF & _
					"'Steam Fandom' page for 'DRM-Free' Steam games." & @LF & _
					"BIG THANKS to those who provided & created (update) the online" & @LF & _
					"'PC Gaming Wiki' page for 'DRM-Free' Steam games." & @LF & @LF & _
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
				Else
					If $alternate = 1 Then
						If FileExists($altpth) Then ShellExecute($altpth)
					Else
						If FileExists($gamesfld) Then ShellExecute($gamesfld)
					EndIf
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
									;$c = $ind - 1
									;MsgBox(262192, "Index", $c, 0, $ListGUI)
									GUICtrlSetBkColor($Label_free, 0xFFFFCE)
									GUICtrlSetColor($Label_free, $COLOR_BLACK)
									$notes = ""
									GUICtrlSetData($Edit_notes, $notes)
									GUICtrlSetData($Input_index, "")
									GUICtrlSetData($Input_size, "")
									GUICtrlSetData($Input_title, "")
									GUICtrlSetData($Input_id, "")
									GUICtrlSetData($Input_link, "")
									GUICtrlSetData($Input_image, "")
								EndIf
							EndIf
							;GUICtrlSetData($Input_find, $idx)
							;Sleep(100)
							;If GUICtrlRead($Checkbox_find) = $GUI_UNCHECKED Then ExitLoop
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
						_GUICtrlListBox_SetCurSel($List_games, -1)
						GUICtrlSetBkColor($Label_free, 0xFFFFCE)
						GUICtrlSetColor($Label_free, $COLOR_BLACK)
						$notes = ""
						GUICtrlSetData($Edit_notes, $notes)
						GUICtrlSetData($Input_index, "")
						GUICtrlSetData($Input_size, "")
						GUICtrlSetData($Input_title, "")
						GUICtrlSetData($Input_id, "")
						GUICtrlSetData($Input_link, "")
						GUICtrlSetData($Input_image, "")
						$ping = Ping("gog.com", 5000)
						If $ping > 0 Then
							$download = InetGet($listurl, $freelist, 0, 0)
							InetClose($download)
							_FileWriteLog($logfle, "Downloaded the " & $drmfree & " DRM-Free list.")
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
			Case $msg = $Button_destiny And $buttxt = "More"
				; Open the destination folder
				If FileExists($destfld) Then
					If $ontop = 1 Then
						$ontop = 4
						GUICtrlSetState($Checkbox_ontop, $ontop)
						WinSetOnTop($ListGUI, "", 0)
					EndIf
					ShellExecute($destfld)
				Else
					MsgBox(262192, "Path Error", "Destination folder not set or doesn't exist!", 3, $ListGUI)
				EndIf
			Case $msg = $Button_dest And $buttxt = "More"
				; Browse to set the destination path
				$pth = FileSelectFolder("Browse to set the destination path", "", 7, "", $ListGUI)
				If Not @error Then
					$destfld = $pth
					IniWrite($inifle, "Destination", "path", $destfld)
					GUICtrlSetData($Input_dest, $destfld)
				EndIf
			Case $msg = $Button_code And $buttxt = "More"
				; Set the Steam Guard code
				$code = GUICtrlRead($Input_code)
				$code = AddTextToInput($code, "Steam Guard Code")
				GUICtrlSetData($Input_code, $code)
				If $code = "" Then
					$encrypted = $code
				Else
					_Crypt_Startup()
					$encrypted = _Crypt_EncryptData($code, "d@C3fkk7x_", $CALG_AES_256)
					_Crypt_Shutdown()
				EndIf
				IniWrite($inifle, "Steam Guard", "code", $encrypted)
				_FileWriteLog($logfle, "Saved a Steam Guard code.")
			Case $msg = $Button_backup
				; Backup the selected game folder to specified file type or folder
				;MsgBox(262192, "Status Report", "This feature is currently incomplete!", 0, $ListGUI)
				$title = GUICtrlRead($Input_title)
				$title = CharacterReplacements($title)
				If $alternate = 1 Then
					$gamefold = $altpth & "\" & $title
				Else
					$gamefold = $gamesfld & "\" & $title
				EndIf
				If $title <> "" And FileExists($gamefold) Then
					If $ontop = 1 Then
						$ontop = 4
						GUICtrlSetState($Checkbox_ontop, $ontop)
						WinSetOnTop($ListGUI, "", 0)
					EndIf
					SetStateOfControls($GUI_DISABLE)
					$find = GUICtrlRead($Input_find)
					If $type = "ZIP" Or $type = "EXE" Then
						If Not FileExists($7zip) Then
							MsgBox(262192, "Process Error", "The 7-Zip program cannot be found!", 0, $ListGUI)
							SetStateOfControls($GUI_ENABLE)
							ContinueLoop
						EndIf
					EndIf
					If $dest = 1 Then
						$pth = FileSelectFolder("Browse to select a destination path", "", 7, "", $ListGUI)
						If Not @error And StringMid($pth, 2, 2) = ":\" Then
							$destfld = $pth
						Else
							SetStateOfControls($GUI_ENABLE)
							ContinueLoop
						EndIf
					Else
						If Not FileExists($destfld) Then
							MsgBox(262192, "Process Error", "A destination folder path has not been set or no longer exists!", 0, $ListGUI)
							SetStateOfControls($GUI_ENABLE)
							ContinueLoop
						EndIf
					EndIf
					; Megabytes vs bytes
					$drv = StringLeft($destfld, 3)
					$space = DriveSpaceFree($drv)
					If $space > (($size / 1048576) + 200) Then
						; Free drive space is greater than game size + 200 Mb.
						If $type = "DIR" Then
							$ans = MsgBox(262144 + 256 + 35, "Backup Query", "WARNING  -  This process could take quite a lot of" _
								& @LF & "time, depending on the game folder size and if via" _
								& @LF & "a USB connection to another drive, etc." & @LF _
								& @LF & "Move the source folder to destination?" & @LF _
								& @LF & "YES = MOVE the folder." _
								& @LF & "NO = Just COPY the folder." _
								& @LF & "CANCEL = Abort any backing up.", 0, $ListGUI)
							If $ans = 6 Then
								$copy = "Move"
							ElseIf $ans = 7 Then
								$copy = "Copy"
							Else
								SetStateOfControls($GUI_ENABLE)
								ContinueLoop
							EndIf
							If $tera = 1 Then
								If Not FileExists($teracopy) Then
									MsgBox(262192, "Process Error", "The TeraCopy program cannot be found!", 0, $ListGUI)
									SetStateOfControls($GUI_ENABLE)
									ContinueLoop
								EndIf
								GUICtrlSetBkColor($Input_find, $COLOR_RED)
								GUICtrlSetData($Input_find, "Backing Up to Folder!")
								_FileWriteLog($logfle, "Started the TeraCopy (" & $copy & ") backup for - " & $title)
								If $copy = "Move" Then
									$method = ' Move "'
								ElseIf $copy = "Copy" Then
									$method = ' Copy "'
								EndIf
								$pid = RunWait($teracopy & $method & $gamefold & '" "' & $destfld & '" /SkipAll /Close')
							Else
								GUICtrlSetBkColor($Input_find, $COLOR_RED)
								GUICtrlSetData($Input_find, "Backing Up to Folder!")
								_FileWriteLog($logfle, "Started the (" & $copy & ") backup for - " & $title)
								Local $winshell = ObjCreate("Shell.Application")
								If Not @error Then
									If $copy = "Move" Then
										$winshell.NameSpace($destfld).MoveHere($gamefold, 16)
									ElseIf $copy = "Copy" Then
										$winshell.NameSpace($destfld).CopyHere($gamefold, 16)
									EndIf
								Else
									_FileWriteLog($logfle, "Object Error.")
									MsgBox(262192, "Object Error", "Could not create a Shell Application object!", 0, $ListGUI)
								EndIf
							EndIf
						Else
							$ans = MsgBox(262144 + 33, "Backup Query", "WARNING  -  This process could take quite a lot of" _
								& @LF & "time, depending on the game folder size and if via" _
								& @LF & "a USB connection to another drive, etc." & @LF _
								& @LF & "Create zipped file(s) at destination?" & @LF _
								& @LF & "OK = CREATE the zip file(s)." _
								& @LF & "CANCEL = Abort any backing up." & @LF _
								& @LF & "NOTE - If result is over 2 Gb, then it will be split up" _
								& @LF & "into individual Volume files. In any case, 2 files are" _
								& @LF & "created at least, for a self-executing EXE.", 0, $ListGUI)
							If $ans = 1 Then
								$zipfold = $destfld & "\" & $title
								If Not FileExists($zipfold) Then
									DirCreate($zipfold)
									Sleep(500)
								EndIf
								If FileExists($zipfold) Then
									$pos = StringInStr($7zip, "\", 0, -1)
									$zipfld = StringLeft($7zip, $pos - 1)
									FileChangeDir($zipfld)
									If $type = "ZIP" Then
										$zipfile = $zipfold & "\" & $title & ".7z"
										If FileExists($zipfile) Then
											$ans = MsgBox(262144 + 33, "Overwrite Query", "A zip file with the same name already exists." & @LF _
												& @LF & "OK = Overwrite (replace)." _
												& @LF & "CANCEL = Rename existing.", 0, $ListGUI)
											If $ans = 1 Then
												FileDelete($zipfile)
											Else
												$bakfile = $zipfile
												$n = 1
												While FileExists($bakfile)
													$bakfile = $zipfile & $n
													$n = $n + 1
												WEnd
												FileMove($zipfile, $bakfile)
											EndIf
											;SetStateOfControls($GUI_ENABLE)
											;ContinueLoop
										EndIf
										GUICtrlSetBkColor($Input_find, $COLOR_RED)
										GUICtrlSetData($Input_find, "Backing Up to File!")
										_FileWriteLog($logfle, "Started the ZIP backup for - " & $title)
										RunWait(@ComSpec & " /c " & '7z.exe a "' & $zipfile & '" "' & $gamefold & '" -v2g', "")
										$volfile = $zipfile & ".001"
										If FileExists($volfile) Then
											If Not FileExists($zipfile & ".002") Then
												FileMove($volfile, $zipfile)
											EndIf
										EndIf
									ElseIf $type = "EXE" Then
										$exefile = $zipfold & "\" & $title & ".exe"
										If FileExists($exefile) Then
											$ans = MsgBox(262144 + 33, "Overwrite Query", "A exe file with the same name already exists." & @LF _
												& @LF & "OK = Overwrite (replace)." _
												& @LF & "CANCEL = Rename existing.", 0, $ListGUI)
											If $ans = 1 Then
												FileDelete($exefile)
											Else
												$bakfile = $exefile
												$n = 1
												While FileExists($bakfile)
													$bakfile = $exefile & $n
													$n = $n + 1
												WEnd
												FileMove($exefile, $bakfile)
											EndIf
											;SetStateOfControls($GUI_ENABLE)
											;ContinueLoop
										EndIf
										GUICtrlSetBkColor($Input_find, $COLOR_RED)
										GUICtrlSetData($Input_find, "Backing Up to File!")
										_FileWriteLog($logfle, "Started the EXE backup for - " & $title)
										RunWait(@ComSpec & " /c " & '7z.exe a -sfx7z.sfx "' & $exefile & '" "' & $gamefold & '" -v2g', "")
									EndIf
								Else
									MsgBox(262192, "Destination Error", "A folder for the zipped file could not be created!", 0, $ListGUI)
								EndIf
							Else
								SetStateOfControls($GUI_ENABLE)
								ContinueLoop
							EndIf
						EndIf
						_FileWriteLog($logfle, "Backup Complete.")
					Else
						MsgBox(262192, "Drive Space Error", "Not enough free space on the destination drive!" & @LF & "(Game folder size + 200 Mb minimum required)", 0, $ListGUI)
					EndIf
					GUICtrlSetBkColor($Input_find, $CLR_DEFAULT)
					GUICtrlSetData($Input_find, $find)
					SetStateOfControls($GUI_ENABLE)
				Else
					MsgBox(262192, "Usage Error", "No title selected or game folder path doesn't exist!", 0, $ListGUI)
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
			Case $msg = $Checkbox_tera And $buttxt = "More"
				; Use the TeraCopy program
				If GUICtrlRead($Checkbox_tera) = $GUI_CHECKED Then
					$tera = 1
					GUICtrlSetState($Input_tera, $GUI_ENABLE)
					GUICtrlSetState($Button_tera, $GUI_ENABLE)
				Else
					$tera = 4
					GUICtrlSetState($Input_tera, $GUI_DISABLE)
					GUICtrlSetState($Button_tera, $GUI_DISABLE)
				EndIf
				IniWrite($inifle, "TeraCopy", "use", $tera)
			Case $msg = $Checkbox_path And $buttxt = "More"
				; Use an alternate games folder
				If GUICtrlRead($Checkbox_path) = $GUI_CHECKED Then
					$alternate = 1
					GUICtrlSetState($Input_path, $GUI_ENABLE)
					GUICtrlSetState($Button_path, $GUI_ENABLE)
				Else
					$alternate = 4
					GUICtrlSetState($Input_path, $GUI_DISABLE)
					GUICtrlSetState($Button_path, $GUI_DISABLE)
				EndIf
				IniWrite($inifle, "Games Folder", "use_alt", $alternate)
				If $alternate = 1 Then
					;$altpth = IniRead($inifle, "Games Folder", "alt_path", "")
					GUICtrlSetData($Input_path, $altpth)
				Else
					GetLocalSteamGamesFolder()
					GUICtrlSetData($Input_path, $gamesfld)
				EndIf
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
			Case $msg = $Checkbox_dest And $buttxt = "More"
				; Query for Destination each time
				If GUICtrlRead($Checkbox_dest) = $GUI_CHECKED Then
					$dest = 1
					GUICtrlSetState($Input_dest, $GUI_DISABLE)
					GUICtrlSetState($Button_dest, $GUI_DISABLE)
					GUICtrlSetState($Button_destiny, $GUI_DISABLE)
				Else
					$dest = 4
					GUICtrlSetState($Input_dest, $GUI_ENABLE)
					GUICtrlSetState($Button_dest, $GUI_ENABLE)
					GUICtrlSetState($Button_destiny, $GUI_ENABLE)
				EndIf
				IniWrite($inifle, "Destination", "query", $dest)
			Case $msg = $Combo_list
				; Select the Online DRM-Free page
				$drmfree = GUICtrlRead($Combo_list)
				IniWrite($inifle, "DRM-Free", "page", $drmfree)
				If $drmfree = "PC Gaming Wiki" Then
					$listurl = IniRead($inifle, "PC Gaming Wiki", "url", "")
					$freefle = $freefle1
				ElseIf $drmfree = "Steam Fandom" Then
					$listurl = IniRead($inifle, "Steam Fandom", "url", "")
					$freefle = $freefle2
				EndIf
				GUICtrlSetData($Input_list, $listurl)
				_GUICtrlListBox_SetCurSel($List_games, -1)
				GUICtrlSetBkColor($Label_free, 0xFFFFCE)
				GUICtrlSetColor($Label_free, $COLOR_BLACK)
				$notes = ""
				GUICtrlSetData($Edit_notes, $notes)
				GUICtrlSetData($Input_index, "")
				GUICtrlSetData($Input_size, "")
				GUICtrlSetData($Input_title, "")
				GUICtrlSetData($Input_id, "")
				GUICtrlSetData($Input_link, "")
				GUICtrlSetData($Input_image, "")
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
					$title = CharacterReplacements($title)
					If $alternate = 1 Then
						$gamefold = $altpth & "\" & $title
					Else
						$gamefold = $gamesfld & "\" & $title
					EndIf
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
						EndIf
					EndIf
					If $size > 0 Then
						If $size < 1024 Then
							$mass = $size & " bytes"
						ElseIf $size < 1048576 Then
							$mass = Ceiling($size / 1024)
							$mass = $mass & " Kb"
						ElseIf $size < 1073741824 Then
							$mass = Round($size / 1048576, 2)
							$mass = $mass & " Mb"
						ElseIf $size < 1099511627776 Then
							$mass = Round($size / 1073741824, 3)
							$mass = $mass & " Gb"
						Else
							$mass = Round($size / 1099511627776, 4)
							$mass = $mass & " Tb"
						EndIf
					Else
						$mass = "missing"
					EndIf
					GUICtrlSetData($Input_size, $mass)
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


Func AddTextToInput($text, $what)
	$val = InputBox($what, "Enter or Edit the text.", $text, "", 200, 130, Default, Default, 0, $ListGUI)
	If @error = 0 Then
		$text = $val
	EndIf
	Return $text
EndFunc ;=> AddTextToInput

Func CharacterReplacements($text)
	$text = StringReplace($text, ":", "")
	$text = StringReplace($text, "\", "+")
	$text = StringReplace($text, "/", "+")
	$text = StringReplace($text, "<", "(")
	$text = StringReplace($text, ">", ")")
	$text = StringReplace($text, "*", "")
	$text = StringReplace($text, '"', "'")
	$text = StringReplace($text, '|', "+")
	$text = StringReplace($text, '?', "!")
	Return $text
EndFunc ;=> CharacterReplacements

Func GetLocalSteamGamesFolder()
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
EndFunc ;=> GetLocalSteamGamesFolder

Func ParseTheDRMFreeList()
	$read = FileRead($freelist)
	If $read <> "" Then
		$games = ""
		If $drmfree = "PC Gaming Wiki" Then
			_FileCreate($freefle1)
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
			FileWrite($freefle1, $games)
			$entries = $entries[0]
			MsgBox(262144, "DRM-Free Games", $entries & " found.", 3, $ListGUI)
		ElseIf $drmfree = "Steam Fandom" Then
			_FileCreate($freefle2)
			Local $skipped, $skipping
			$skipped = ""
			;$read = StringSplit($read, "List of DRM-free software on Steam</span></h2>", 1)
			$read = StringSplit($read, "DRM-free game codes</b></span></h3>", 1)
			$read = $read[1]
			$entries = StringSplit($read, @LF & "<tr>" & @LF, 1)
			For $e = 2 To $entries[0]
				$skipping = ""
				$chunk = $entries[$e]
				$entry = StringSplit($chunk, '</a>', 1)
				If $entry[0] > 1 Then
					$entry = $entry[1]
					$entry = StringSplit($entry, '">', 1)
					If $entry[0] = 2 Then
						$game = $entry[2]
						If $game = "" Then
							$skipping = 1
						Else
							If $games = "" Then
								$games = "[" & $game & "]" & @CRLF & "drm-free=1"
							Else
								If StringInStr($games, "[" & $game & "]") > 0 Then
									If $skipped = "" Then
										$skipped = $game
									Else
										$skipped = $skipped & @LF & $game
									EndIf
									$skipping = 1
								Else
									$games = $games & @CRLF & "[" & $game & "]" & @CRLF & "drm-free=1"
								EndIf
							EndIf
						EndIf
					Else
						$skipping = 1
					EndIf
				Else
					$skipping = 1
				EndIf
				If $skipping = "" Then
					$notes = ""
					$chunk = StringReplace($chunk, '<td style="text-align: center;">✔' & @LF, '')
					$chunk = StringReplace($chunk, '<td style="text-align: center;">n/a' & @LF, '')
					$chunk = StringReplace($chunk, '<td style="text-align: center;">?' & @LF, '')
					$chunk = StringReplace($chunk, '<td style="text-align: center;">âœ˜' & @LF, '')
					$chunk = StringReplace($chunk, '<td rowspan="2">' & @LF, '')
					$chunk = StringReplace($chunk, '<td rowspan="3">' & @LF, '')
					$chunk = StringReplace($chunk, '<td rowspan="4">' & @LF, '')
					$chunk = StringReplace($chunk, '<td rowspan="5">' & @LF, '')
					$chunk = StringReplace($chunk, '</td></tr></tbody></table>' & @LF, '')
					$chunk = StringReplace($chunk, '</td></tr>' & @LF, '')
					$chunk = StringReplace($chunk, '</td></tr>', '')
					$chunk = StringReplace($chunk, '</td>' & @LF, '')
					$chunk = StringReplace($chunk, '<td>', '')
					$chunk = StringReplace($chunk, '<i>', '')
					$chunk = StringReplace($chunk, '</i>', '')
					$chunk = StringReplace($chunk, "<b>", "(")
					$chunk = StringReplace($chunk, "</b>", ")")
					$chunk = StringReplace($chunk, '<p>', '')
					$chunk = StringReplace($chunk, '</p>', '')
					$chunk = StringReplace($chunk, "<u>", "(")
					$chunk = StringReplace($chunk, "</u>", ")")
					$chunk = StringReplace($chunk, '<br />', '')
					$chunk = StringReplace($chunk, '<hr />', '')
					$chunk = StringReplace($chunk, '<h2>', '')
					$chunk = StringReplace($chunk, '</h2>', '')
					$chunk = StringReplace($chunk, '<h3>', '')
					$chunk = StringReplace($chunk, '</h3>', '')
					$chunk = StringReplace($chunk, '</span>', '')
					$chunk = StringReplace($chunk, '<tbody><tr>', '')
					$chunk = StringReplace($chunk, '<th>', '')
					$chunk = StringReplace($chunk, '</th>', '')
					$chunk = StringReplace($chunk, '</tr>', '')
					$chunk = StringReplace($chunk, '<ul>', '')
					$chunk = StringReplace($chunk, '</ul>', '')
					$chunk = StringReplace($chunk, '<li>', '')
					$chunk = StringReplace($chunk, '</li>', '')
					$lines = StringSplit($chunk, @LF, 1)
					For $c = 1 To $lines[0]
						$line = $lines[$c]
						If StringInStr($line, 'href="') > 0 Then
							$chunk = StringReplace($chunk, $line, '')
						ElseIf StringInStr($line, '<td style="') > 0 Then
							$chunk = StringReplace($chunk, $line, '')
						Else
							$notes = $line
							$delete = ""
							While 1
								$pos = StringInStr($notes, '<span class="')
								If $pos > 0 Then
									$end = StringInStr($notes, '">')
									If $end > 0 Then
										$end = $end + 2
										$delete = StringMid($notes, $pos, $end - $pos)
										$notes = StringReplace($notes, $delete, '')
									Else
										ExitLoop
									EndIf
								Else
									ExitLoop
								EndIf
							WEnd
							While 1
								$pos = StringInStr($notes, '<table class="')
								If $pos > 0 Then
									$end = StringInStr($notes, '">')
									If $end > 0 Then
										$end = $end + 2
										$delete = StringMid($notes, $pos, $end - $pos)
										$notes = StringReplace($notes, $delete, '')
									Else
										ExitLoop
									EndIf
								Else
									ExitLoop
								EndIf
							WEnd
							While 1
								$pos = StringInStr($notes, '<th style="')
								If $pos > 0 Then
									$end = StringInStr($notes, '">')
									If $end > 0 Then
										$end = $end + 2
										$delete = StringMid($notes, $pos, $end - $pos)
										$notes = StringReplace($notes, $delete, '')
									Else
										ExitLoop
									EndIf
								Else
									ExitLoop
								EndIf
							WEnd
							If $delete <> "" Then
								$chunk = StringReplace($chunk, $line, $notes)
								$notes = ""
							EndIf
						EndIf
					Next
					$notes = StringReplace($chunk, @LF, ' ')
					$notes = StringStripWS($notes, 7)
					$notes = StringReplace($notes, 'Title Win Mac Lin Remark', '')
					$notes = StringReplace($notes, 'Title Win Mac Lin Note', '')
					$notes = StringStripWS($notes, 7)
					;$notes = StringReplace($notes, @LF, ' & ')
					If $notes <> "" Then $games = $games & @CRLF & "notes=" & $notes
				EndIf
			Next
			FileWrite($freefle2, $games)
			$entries = $entries[0]
			MsgBox(262144, "DRM-Free Games", $entries & " found." & @LF & @LF & "[Duplicates Skipped]" & @LF & $skipped, 0, $ListGUI)
		EndIf
	EndIf
	_FileWriteLog($logfle, "Parsed the DRM-Free list.")
EndFunc ;=> ParseTheDRMFreeList

Func SetStateOfControls($state)
	GUICtrlSetState($List_games, $state)
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
	GUICtrlSetState($Button_save, $state)
	GUICtrlSetState($Button_list, $state)
	GUICtrlSetState($Input_list, $state)
	GUICtrlSetState($Combo_list, $state)
	;
	GUICtrlSetState($Button_down, $state)
	GUICtrlSetState($Button_install, $state)
	GUICtrlSetState($Button_backup, $state)
	GUICtrlSetState($Combo_backup, $state)
	;
	If $buttxt = "More" Then
		GUICtrlSetState($Input_zip, $state)
		GUICtrlSetState($Button_zip, $state)
		GUICtrlSetState($Button_code, $state)
		GUICtrlSetState($Input_code, $state)
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
		If $alternate = 1 Then
			GUICtrlSetState($Input_path, $GUI_DISABLE)
			GUICtrlSetState($Button_path, $GUI_DISABLE)
		EndIf
		;GUICtrlSetState($Input_path, $state)
		;GUICtrlSetState($Button_path, $state)
		GUICtrlSetState($Checkbox_path, $state)
		If $dest = 4 Then
			GUICtrlSetState($Input_dest, $state)
			GUICtrlSetState($Button_dest, $state)
			GUICtrlSetState($Button_destiny, $state)
		EndIf
		;GUICtrlSetState($Input_dest, $state)
		;GUICtrlSetState($Button_dest, $state)
		GUICtrlSetState($Checkbox_dest, $state)
		If $tera = 1 Then
			GUICtrlSetState($Input_tera, $state)
			GUICtrlSetState($Button_tera, $state)
		EndIf
		;GUICtrlSetState($Input_tera, $state)
		;GUICtrlSetState($Button_tera, $state)
		GUICtrlSetState($Checkbox_tera, $state)
	EndIf
EndFunc ;=> SetStateOfControls

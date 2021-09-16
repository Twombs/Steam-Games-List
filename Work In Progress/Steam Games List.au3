#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         Timboli

 Script Function:  Retrieve a list of games owned at Steam
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

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

_Singleton("steam-games-list-timboli")

Global $array, $display, $download, $entry, $g, $game, $gameID, $games, $image, $inifle, $lines, $link, $read, $result, $title, $URL, $userID, $xmlfle

$inifle = @ScriptDir & "\Settings.ini"
$xmlfle = @ScriptDir & "\Gameslist.xml"

$display = IniRead($inifle, "Array", "display", "")
If $display = "" Then
	$display = 4
	IniWrite($inifle, "Array", "display", $display)
EndIf

$userID = IniRead($inifle, "Steam User", "id", "")
$result = InputBox("Steam User ID", "Enter or Accept the current ID.", $userID, "", 200, 130, Default, Default, 0)
If @error = 0 And $result <> "" Then
    If $result <> $userID Then
	   $userID = $result
	   IniWrite($inifle, "Steam User", "id", $userID)
    EndIf
    $URL = "https://steamcommunity.com/profiles/" & $userID & "/games/?xml=1"
    $download = InetGet($URL, $xmlfle, 0, 0)
    InetClose($download)
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
		EndIf
    EndIf
EndIf
MainGUI()

Exit

Func MainGUI()
	Local $Button_backup, $Button_down, $Button_exit, $Button_fold, $Button_id, $Button_image, $Button_info, $Button_install
	Local $Button_link, $Button_list, $Button_log, $Button_opts, $Button_pass, $Button_path, $Button_title, $Button_user
	Local $Checkbox_link, $Checkbox_pass, $Checkbox_user, $Combo_backup, $Group_backup, $Group_list, $Input_id, $Input_image
	Local $Input_link, $Input_list, $Input_pass, $Input_path, $Input_title, $Input_user, $List_games
	Local $a, $buttxt, $decrypt, $decrypted, $encrypted, $exStyle, $gamesfld, $height, $icoD, $icoI, $icoS, $icoT, $icoX
	Local $left, $list, $ListGUI, $parent, $pass, $password, $steamfold, $store, $style, $tabs, $top, $type, $user, $username
	Local $vdffile, $width, $winsize
	;
	$exStyle = $WS_EX_TOPMOST
	$height = 480
	$left = -1
	$parent = 0
	$style = $WS_OVERLAPPED + $WS_CAPTION + $WS_SYSMENU + $WS_VISIBLE + $WS_CLIPSIBLINGS + $WS_MINIMIZEBOX
	$top = -1
	$width = 470
	$ListGUI = GUICreate("Games Owned At Steam", $width, $height, $left, $top, $style, $exStyle, $parent)
	GUISetBkColor($COLOR_YELLOW, $ListGUI)
	;
	; CONTROLS
	$Group_list = GUICtrlCreateGroup("Games", 10, 5, 390, 305)
	GUICtrlSetResizing($Group_list, $GUI_DOCKALL)
	$List_games = GUICtrlCreateList("", 15, 20, 380, 280, $GUI_SS_DEFAULT_LIST + $LBS_USETABSTOPS)
	GUICtrlSetResizing($List_games, $GUI_DOCKALL)
	GUICtrlSetTip($List_games, "Select a game!")
	;
	$Button_opts = GUICtrlCreateButton("Less", 410, 10, 50, 52, $BS_ICON)
	GUICtrlSetResizing($Button_opts, $GUI_DOCKALL)
	GUICtrlSetTip($Button_opts, "Program Options!")
	;
	$Button_fold = GUICtrlCreateButton("FOLD", 410, 72, 50, 52, $BS_ICON)
	GUICtrlSetResizing($Button_fold, $GUI_DOCKALL)
	GUICtrlSetTip($Button_fold, "Open selected game folder!")
	;
	$Button_log = GUICtrlCreateButton("LOG", 410, 134, 50, 52, $BS_ICON)
	GUICtrlSetResizing($Button_log, $GUI_DOCKALL)
	GUICtrlSetTip($Button_log, "Logging Record!")
	;
	$Button_info = GUICtrlCreateButton("INFO", 410, 196, 50, 52, $BS_ICON)
	GUICtrlSetResizing($Button_info, $GUI_DOCKALL)
	GUICtrlSetTip($Button_info, "Program Information!")
	;
	$Button_exit = GUICtrlCreateButton("EXIT", 410, 258, 50, 52, $BS_ICON)
	GUICtrlSetResizing($Button_exit, $GUI_DOCKALL)
	GUICtrlSetTip($Button_exit, "Exit or Close the program!")
	;
	$Button_title = GUICtrlCreateButton("TITLE", 10, 320, 45, 20)
	GUICtrlSetFont($Button_title, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_title, $GUI_DOCKALL)
	GUICtrlSetTip($Button_title, "Click to copy title to clipboard!")
	$Input_title = GUICtrlCreateInput("", 55, 320, 405, 20)
	GUICtrlSetResizing($Input_title, $GUI_DOCKALL)
	;
	$Button_id = GUICtrlCreateButton("ID", 10, 345, 30, 20)
	GUICtrlSetFont($Button_id, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_id, $GUI_DOCKALL)
	GUICtrlSetTip($Button_id, "Click to copy ID to clipboard!")
	$Input_id = GUICtrlCreateInput("", 40, 345, 70, 20)
	GUICtrlSetResizing($Input_id, $GUI_DOCKALL)
	;
	$Button_link = GUICtrlCreateButton("URL", 120, 345, 40, 20)
	GUICtrlSetFont($Button_link, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_link, $GUI_DOCKALL)
	GUICtrlSetTip($Button_link, "Click to go to the game web page!")
	$Input_link = GUICtrlCreateInput("", 160, 345, 250, 20)
	GUICtrlSetResizing($Input_link, $GUI_DOCKALL)
	$Checkbox_link = GUICtrlCreateCheckbox("Store", 415, 345, 45, 20)
	GUICtrlSetResizing($Checkbox_link, $GUI_DOCKALL)
	GUICtrlSetTip($Checkbox_link, "Change the link type!")
	;
	$Button_image = GUICtrlCreateButton("ICON", 10, 370, 45, 20)
	GUICtrlSetFont($Button_image, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_image, $GUI_DOCKALL)
	GUICtrlSetTip($Button_image, "Click to show the online image in your browser!")
	$Input_image = GUICtrlCreateInput("", 55, 370, 405, 20)
	GUICtrlSetResizing($Input_image, $GUI_DOCKALL)
	;
	$Button_list = GUICtrlCreateButton("LIST", 10, 395, 40, 20)
	GUICtrlSetFont($Button_list, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_list, $GUI_DOCKALL)
	GUICtrlSetTip($Button_list, "Click to go to the online DRM-Free list in your browser!")
	$Input_list = GUICtrlCreateInput("", 50, 395, 410, 20)
	GUICtrlSetResizing($Input_list, $GUI_DOCKALL)
	;
	$Button_down = GUICtrlCreateButton("DOWNLOAD && PARSE" & @LF & "THE DRM-FREE LIST", 10, 425, 140, 45, $BS_MULTILINE)
	GUICtrlSetFont($Button_down, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_down, $GUI_DOCKALL)
	GUICtrlSetTip($Button_down, "Download the online DRM-Free list and parse for use!")
	;
	$Button_install = GUICtrlCreateButton("DOWNLOAD && INSTALL" & @LF & "THE SELECTED GAME", 160, 425, 150, 45, $BS_MULTILINE)
	GUICtrlSetFont($Button_install, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_install, $GUI_DOCKALL)
	GUICtrlSetTip($Button_install, "Download & Install the selected game!")
	;
	$Button_backup = GUICtrlCreateButton("BACKUP" & @LF & "TO FILE", 320, 425, 75, 45, $BS_MULTILINE)
	GUICtrlSetFont($Button_backup, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_backup, $GUI_DOCKALL)
	GUICtrlSetTip($Button_backup, "Backup the selected game folder to specified file type!")
	$Group_backup = GUICtrlCreateGroup("", 395, 420, 65, 50)
	GUICtrlSetResizing($Group_backup, $GUI_DOCKALL)
	$Combo_backup = GUICtrlCreateCombo("", 405, 438, 45, 21)
	GUICtrlSetResizing($Combo_backup, $GUI_DOCKALL)
	;
	; OS SETTINGS
	$user = "C:\WINDOWS\system32\user32.dll"
	$shell = @SystemDir & "\shell32.dll"
	$icoD = -4
	$icoI = -5
	$icoS = -217
	$icoT = -71
	$icoX = -4
	GUICtrlSetImage($Button_opts, $shell, $icoS, 1)
	GUICtrlSetImage($Button_fold, $shell, $icoD, 1)
	GUICtrlSetImage($Button_log, $shell, $icoT, 1)
	GUICtrlSetImage($Button_info, $user, $icoI, 1)
	GUICtrlSetImage($Button_exit, $user, $icoX, 1)
	;
	; SETTINGS
	GUICtrlSetState($Button_down, $GUI_DISABLE)
	GUICtrlSetState($Button_install, $GUI_DISABLE)
	;
	GUICtrlSetState($Button_backup, $GUI_DISABLE)
	$type = IniRead($inifle, "Backup File", "type", "")
	If $type = "" Then
		$type = "ZIP"
		IniWrite($inifle, "Backup File", "type", $type)
	EndIf
	GUICtrlSetData($Combo_backup, "ZIP|EXE", $type)
	If $type = "ZIP" Then
		GUICtrlSetTip($Combo_backup, "Zip the game folder!")
	ElseIf $type = "EXE" Then
		GUICtrlSetTip($Combo_backup, "Zip the game folder and make Executable!")
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
	$list = IniRead($inifle, "DRM-Free List", "url", "")
	If $list = "" Then
		$list = "https://www.pcgamingwiki.com/wiki/The_Big_List_of_DRM-Free_Games_on_Steam"
		IniWrite($inifle, "DRM-Free List", "url", $list)
	EndIf
	GUICtrlSetData($Input_list, $list)
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
	$steamfold = @ProgramFilesDir & "\Steam\steamapps"
	$gamesfld = $steamfold & "\common"
	$vdffile = $steamfold & "\libraryfolders.vdf"
	If FileExists($vdffile) Then
		$read = FileRead($vdffile)
		$read = StringSplit($read, '}')
		$read = $read[1]
		$read = StringSplit($read, '"')
		$read = $read[$read[0] - 1]
		$read = StringReplace($read, "\\", "\")
		If StringMid($read, 2, 2) = ":\" Then
			$read = $read & "\steamapps\common"
			If FileExists($read) Then
				$gamesfld = $read
			EndIf
		EndIf
	EndIf

	GUISetState(@SW_SHOW)
	While 1
		$msg = GUIGetMsg()
        Select
			Case $msg = $GUI_EVENT_CLOSE Or $msg = $Button_exit
				; Exit or Close the program
				$list = GUICtrlRead($Input_list)
				If StringLeft($list, 4) = "http" Then
					If $list <> IniRead($inifle, "DRM-Free List", "url", "") Then
						IniWrite($inifle, "DRM-Free List", "url", $list)
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
					WinMove($ListGUI, "", Default, Default, 476, 568)
					$Button_user = GUICtrlCreateButton("USERNAME", 10, 480, 75, 20)
					GUICtrlSetFont($Button_user, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_user, "Save the Username!")
					$Input_user = GUICtrlCreateInput("", 85, 480, 100, 20, $ES_PASSWORD)
					$Checkbox_user = GUICtrlCreateCheckbox("Query", 190, 480, 45, 20)
					GUICtrlSetTip($Checkbox_user, "Query for Username each time!")
					GUICtrlSetData($Input_user, $username)
					GUICtrlSetState($Checkbox_user, $user)
					If $user = 1 Then
						GUICtrlSetState($Button_user, $GUI_DISABLE)
						GUICtrlSetState($Input_user, $GUI_DISABLE)
					EndIf
					;
					$Button_pass = GUICtrlCreateButton("PASSWORD", 245, 480, 75, 20)
					GUICtrlSetFont($Button_pass, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_pass, "Save the Password!")
					$Input_pass = GUICtrlCreateInput("", 320, 480, 90, 20, $ES_PASSWORD)
					$Checkbox_pass = GUICtrlCreateCheckbox("Query", 415, 480, 45, 20)
					GUICtrlSetTip($Checkbox_pass, "Query for Password each time!")
					GUICtrlSetData($Input_pass, $password)
					GUICtrlSetState($Checkbox_pass, $pass)
					If $pass = 1 Then
						GUICtrlSetState($Button_pass, $GUI_DISABLE)
						GUICtrlSetState($Input_pass, $GUI_DISABLE)
					EndIf
					;
					$Input_path = GUICtrlCreateInput("", 10, 510, 355, 20)
					GUICtrlSetTip($Input_path, "Path of the Steam games folder!")
					$Button_path = GUICtrlCreateButton("GAMES FOLDER", 365, 510, 95, 20)
					GUICtrlSetFont($Button_path, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_path, "Browse to set the Steam games folder path!")
					GUICtrlSetData($Input_path, $gamesfld)
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
					WinMove($ListGUI, "", Default, Default, $width + 6, $height + 28)
				EndIf
			Case $msg = $Button_list
				; Click to go to the online DRM-Free list in your browser
				$list = GUICtrlRead($Input_list)
				If StringLeft($list, 4) = "http" Then ShellExecute($list)
			Case $msg = $Button_link
				; Click to go to the game web page
				$link = GUICtrlRead($Input_link)
				If StringLeft($link, 4) = "http" Then ShellExecute($link)
			Case $msg = $Button_image
				; Click to show the online image in your browser
				$image = GUICtrlRead($Input_image)
				If StringLeft($image, 4) = "http" Then ShellExecute($image)
			Case $msg = $Button_id
				; Click to copy ID to clipboard
				$gameID = GUICtrlRead($Input_id)
				ClipPut($gameID)
			Case $msg = $Button_backup
				; Backup the selected game folder to specified file type
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
			Case $msg = $Combo_backup
				; Backup file type
				$type = GUICtrlRead($Combo_backup)
				IniWrite($inifle, "Backup File", "type", $type)
				If $type = "ZIP" Then
					GUICtrlSetTip($Combo_backup, "Zip the game folder!")
				ElseIf $type = "EXE" Then
					GUICtrlSetTip($Combo_backup, "Zip the game folder and make Executable!")
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
					GUICtrlSetState($Button_down, $GUI_ENABLE)
					GUICtrlSetState($Button_install, $GUI_ENABLE)
					GUICtrlSetState($Button_backup, $GUI_ENABLE)
				EndIf
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
			Case Else
		EndSelect
	WEnd
EndFunc

#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         Timboli

 Script Function:  Retrieve a list of games owned at Steam
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; FUNCTIONS
; MainGUI(), InstallOptionsEtcGUI(), SetupGUI()
; AddTextToInput($text, $what), CharacterReplacements($text), CheckIfComplete(), GetLocalEpicGamesFolder(), GetLocalSteamGamesFolder()
; LinkReplacements(), ParseTheDRMFreeList(), ParseTheGamesList(), ParseTheHTMLGamesList(), ParseTheXMLGamesList(), PopulateTheList()
; SetStateOfControls($state)

#include <Constants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <String.au3>
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
#include <Process.au3>

_Singleton("epic-steam-cure-timboli")

Global $Button_backup, $Button_code, $Button_dest, $Button_destiny, $Button_down, $Button_exit, $Button_find, $Button_fix
Global $Button_fold, $Button_id, $Button_image, $Button_inf, $Button_info, $Button_link, $Button_list, $Button_log, $Button_more
Global $Button_notes, $Button_options, $Button_opts, $Button_pass, $Button_path, $Button_save, $Button_tera, $Button_title
Global $Button_updater, $Button_user, $Button_zip, $Checkbox_dest, $Checkbox_find, $Checkbox_link, $Checkbox_ontop, $Checkbox_pass
Global $Checkbox_path, $Checkbox_tera, $Checkbox_user, $Combo_backup, $Combo_list, $Group_list, $Input_code, $Input_dest
Global $Input_find, $Input_id, $Input_image, $Input_index, $Input_link, $Input_list, $Input_pass, $Input_path, $Input_size
Global $Input_tera, $Input_title, $Input_user, $Input_zip, $List_games
;$Button_setup,
Global $7zip, $a, $alldlc, $alternate, $appname, $array, $buttxt, $c, $chunk, $CMDfold, $code, $compress, $created, $delete, $dest
Global $display, $dlc, $done, $download, $drmfree, $e, $end, $entries, $entry, $epic, $epicfold, $fext, $freefle, $freefle1, $freefle2
Global $freefle3, $freelist, $g, $game, $gameID, $games, $gamesfld, $gamesini, $gameslist, $htmlfld, $icoI, $icoX, $image, $inifle
Global $Legendary, $LEGfold, $legskip, $line, $lines, $link, $ListGUI, $logfle, $manner, $mode, $musicfld, $notes, $other, $pass
Global $path, $ping, $pos, $process, $read, $resfile, $result, $savpth, $shell, $split, $state, $SteamCMD,  $steamfold, $store, $tabs
Global $tera, $text, $thread, $timefile, $titfle, $title, $updates, $URL, $user, $user32, $userID, $val, $vdffile, $version, $what
Global $xmlfle

$CMDfold = @ScriptDir & "\SteamCMD"
$created = "September 2021"
$freefle1 = @ScriptDir & "\DRMfree.ini"
$freefle2 = @ScriptDir & "\DRMfree2.ini"
$freefle3 = @ScriptDir & "\DRMfree3.ini"
$freelist = @ScriptDir & "\DRMfree.html"
$gamesini = @ScriptDir & "\Games.ini"
$gameslist = @ScriptDir & "\Gameslist.txt"
$htmlfld = @ScriptDir & "\HTML"
$inifle = @ScriptDir & "\Settings.ini"
;$Legendary = @ScriptDir & "\Legendary\legendary.exe"
$logfle = @ScriptDir & "\Log.txt"
$resfile = @ScriptDir & "\Zip Results.txt"
$savpth = $htmlfld & "\Purchase History.html"
$timefile = @ScriptDir & "\Endtime.ini"
$titfle = @ScriptDir & "\Titles.txt"
$xmlfle = @ScriptDir & "\Gameslist.xml"
$SteamCMD = @ScriptDir & "\SteamCMD\steamcmd.exe"
$version = " (v1.4)"

If Not FileExists($htmlfld) Then DirCreate($htmlfld)

$display = IniRead($inifle, "Array", "display", "")
If $display = "" Then
	$display = 4
	IniWrite($inifle, "Array", "display", $display)
EndIf

$mode = MsgBox(262144 + 33, "Program Mode Query", "OK = STEAM mode." & @LF & "CANCEL = EPIC mode.", 0, $ListGUI)
If $mode = 1 Then
	$mode = "Steam"
	$other = "Store"
	$userID = IniRead($inifle, "Steam User", "id", "")
	If $userID = "" Then
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
	EndIf
	ParseTheXMLGamesList()
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
Else
	$mode = "Epic"
	$other = "IGDB"
	;
	$LEGfold = ""
	$legskip = IniRead($inifle, "Legendary", "skip", "")
	If $legskip = 1 Then
		$ans = MsgBox(262144 + 33, "Legendary Query", _
			"Enable use of Legendary?" & @LF _
			& @LF & "(closes in 3 seconds)", 3, $ListGUI)
		If $ans = 1 Then
			$legskip = ""
			IniWrite($inifle, "Legendary", "skip", $legskip)
		EndIf
	EndIf
	If $legskip = "" Then
		$Legendary = IniRead($inifle, "Legendary", "path", "")
		If $Legendary = "" Then
			$Legendary = @ScriptDir & "\Legendary\legendary.exe"
			$LEGfold = @ScriptDir & "\Legendary"
			$epic = 1
		EndIf
		;MsgBox(262192, "$epic 1", $epic & $LEGfold, 0, $ListGUI)
		If FileExists($Legendary) Then
			If $LEGfold = "" Then
				$LEGfold = StringTrimRight($Legendary, 14)
				If StringRight($LEGfold, 10) = "\Legendary" Then
					$epic = 1
				ElseIf StringRight($LEGfold, 12) = "\Legendary32" Then
					$epic = 2
				EndIf
			EndIf
			IniWrite($inifle, "Legendary", "path", $Legendary)
		Else
			$Legendary = @ScriptDir & "\Legendary32\legendary.exe"
			If FileExists($Legendary) Then
				$epic = 2
				$LEGfold = @ScriptDir & "\Legendary32"
				IniWrite($inifle, "Legendary", "path", $Legendary)
			Else
				$pth = FileOpenDialog("Browse to set the Legendary path", @ProgramFilesDir, "Program file (*.exe)", 3, "legendary.exe", $ListGUI)
				If Not @error And StringMid($pth, 2, 2) = ":\" Then
					$Legendary = $pth
					IniWrite($inifle, "Legendary", "path", $Legendary)
					$LEGfold = StringTrimRight($Legendary, 14)
					If StringRight($LEGfold, 10) = "\Legendary" Then
						$epic = 1
					ElseIf StringRight($LEGfold, 12) = "\Legendary32" Then
						$epic = 2
					EndIf
				Else
					$epic = 3
					$Legendary = ""
					$LEGfold = ""
					$legskip = 1
					IniWrite($inifle, "Legendary", "skip", $legskip)
				EndIf
			EndIf
		EndIf
	Else
		$epic = 3
		$Legendary = ""
	EndIf
	;
	$fixed = IniRead($inifle, "Games.ini", "fixed", "")
	;
	;ParseTheHTMLGamesList()
	If FileExists($gameslist) Then
		ParseTheGamesList()
	ElseIf FileExists($titfle) Then
		_FileReadToArray($titfle, $array, 1)
	Else
		;$array = ""
		ParseTheHTMLGamesList()
	EndIf
	;
	If $fixed = "" Then
		$fixed = 1
		IniWrite($inifle, "Games.ini", "fixed", $fixed)
	EndIf
EndIf

MainGUI()

Exit

Func MainGUI()
	Local $Edit_notes, $Graphic_update, $Group_backup, $Label_free, $Label_index, $Label_notes, $Label_size
	;
	Local $alias, $altpth, $ans, $bakfile, $cmd, $cnt, $comp, $copy, $decrypt, $decrypted, $destfld, $downfold, $drv, $encrypted
	Local $exefile, $exStyle, $find, $gamefold, $height, $high, $icoD, $icoM, $icoS, $icoT, $idx, $ind, $left, $listurl, $mass
	Local $message, $meth, $method, $n, $notify, $num, $numb, $ontop, $params, $parent, $password, $pid, $pth, $savefile, $savefold
	Local $sid, $size, $space, $style, $t, $teracopy, $titles, $top, $type, $username, $vol, $volfile, $w, $wide, $width, $winpos
	Local $winsize, $words, $zipfile, $zipfld, $zipfold
	;
	$exStyle = $WS_EX_TOPMOST
	$style = $WS_OVERLAPPED + $WS_CAPTION + $WS_SYSMENU + $WS_VISIBLE + $WS_CLIPSIBLINGS + $WS_MINIMIZEBOX
	$parent = 0
	$width = 470
	$height = 510
	$left = IniRead($inifle, "Program Window", "left", @DesktopWidth - $width - 25)
	$top = IniRead($inifle, "Program Window", "top", @DesktopHeight - $height - 60)
	$ListGUI = GUICreate("Epic Steam Cure - Games Owned At " & $mode, $width, $height, $left, $top, $style, $exStyle, $parent)
	GUISetBkColor($COLOR_YELLOW, $ListGUI)
	;
	; CONTROLS
	$Group_list = GUICtrlCreateGroup("Games", 10, 5, 386, 335)
	GUICtrlSetResizing($Group_list, $GUI_DOCKALL)
	$List_games = GUICtrlCreateList("", 15, 21, 376, 235, $GUI_SS_DEFAULT_LIST + $LBS_USETABSTOPS)
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
	$Edit_notes = GUICtrlCreateEdit("", 80, 255, 306, 45, $ES_WANTRETURN + $WS_VSCROLL + $ES_AUTOVSCROLL)
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
	$Input_find = GUICtrlCreateInput("", 212, 310, 126, 20, $ES_CENTER)
	GUICtrlSetResizing($Input_find, $GUI_DOCKALL)
	GUICtrlSetTip($Input_find, "Search text!")
	$Checkbox_find = GUICtrlCreateCheckbox("", 342, 310, 20, 20, $BS_AUTO3STATE)
	GUICtrlSetResizing($Checkbox_find, $GUI_DOCKALL)
	GUICtrlSetTip($Checkbox_find, "Search for DRM-Free from selected!")
	$Button_find = GUICtrlCreateButton("F", 364, 308, 22, 23, $BS_ICON)
	GUICtrlSetResizing($Button_find, $GUI_DOCKALL)
	GUICtrlSetTip($Button_find, "Find the specified text in a title!")
	;
	$Checkbox_ontop = GUICtrlCreateCheckbox("On Top", 406, 10, 54, 20, $BS_PUSHLIKE)
	GUICtrlSetFont($Checkbox_ontop, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Checkbox_ontop, $GUI_DOCKALL)
	GUICtrlSetTip($Checkbox_ontop, "Toggle the Window On Top state!")
	;
	$Graphic_update = GUICtrlCreateGraphic(401, 32, 64, 38)
	GUICtrlSetGraphic($Graphic_update, $GUI_GR_RECT, 405, 36, 56, 30)
	GUICtrlSetBkColor($Graphic_update, $COLOR_YELLOW)
	GUICtrlSetState($Graphic_update, $GUI_DISABLE)
	$Button_updater = GUICtrlCreateButton("UPDATE", 406, 37, 54, 28)
	GUICtrlSetFont($Button_updater, 6, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_updater, $GUI_DOCKALL)
	GUICtrlSetTip($Button_updater, "Update the list of owned games!")
	;
	$Button_more = GUICtrlCreateButton("Less", 406, 72, 54, 48, $BS_ICON)
	GUICtrlSetResizing($Button_more, $GUI_DOCKALL)
	GUICtrlSetTip($Button_more, "More program options!")
	;
	$Button_fold = GUICtrlCreateButton("FOLD", 406, 127, 54, 48, $BS_ICON)
	GUICtrlSetResizing($Button_fold, $GUI_DOCKALL)
	GUICtrlSetTip($Button_fold, "Open selected game folder!")
	;
	$Button_log = GUICtrlCreateButton("LOG", 406, 182, 54, 48, $BS_ICON)
	GUICtrlSetResizing($Button_log, $GUI_DOCKALL)
	GUICtrlSetTip($Button_log, "View the Log Record file!")
	;
	$Button_info = GUICtrlCreateButton("INFO", 406, 237, 54, 48, $BS_ICON)
	GUICtrlSetResizing($Button_info, $GUI_DOCKALL)
	GUICtrlSetTip($Button_info, "Program Information!")
	;
	$Button_exit = GUICtrlCreateButton("EXIT", 406, 292, 54, 48, $BS_ICON)
	GUICtrlSetResizing($Button_exit, $GUI_DOCKALL)
	GUICtrlSetTip($Button_exit, "Exit or Close the program!")
	;
	$Button_title = GUICtrlCreateButton("TITLE", 10, 350, 45, 20)
	GUICtrlSetFont($Button_title, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_title, $GUI_DOCKALL)
	GUICtrlSetTip($Button_title, "Click to copy title to clipboard!")
	$Input_title = GUICtrlCreateInput("", 55, 350, 360, 20, $ES_READONLY)
	GUICtrlSetResizing($Input_title, $GUI_DOCKALL)
	GUICtrlSetTip($Input_title, "Selected game title!")
	$Button_inf = GUICtrlCreateButton("INFO", 415, 350, 45, 20)
	GUICtrlSetFont($Button_inf, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_inf, $GUI_DOCKALL)
	GUICtrlSetTip($Button_inf, "Save selected game information!")
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
	$Checkbox_link = GUICtrlCreateCheckbox($other, 415, 375, 45, 20)
	GUICtrlSetResizing($Checkbox_link, $GUI_DOCKALL)
	GUICtrlSetTip($Checkbox_link, "Change the link type!")
	;
	$Button_image = GUICtrlCreateButton("ICON", 10, 400, 45, 20)
	GUICtrlSetFont($Button_image, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_image, $GUI_DOCKALL)
	GUICtrlSetTip($Button_image, "Click to show the online image in your browser!")
	$Input_image = GUICtrlCreateInput("", 55, 400, 315, 20)
	GUICtrlSetResizing($Input_image, $GUI_DOCKALL)
	GUICtrlSetTip($Input_image, "URL for online game icon!")
	$Button_fix = GUICtrlCreateButton("FIX", 375, 400, 35, 20)
	GUICtrlSetFont($Button_fix, 6, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_fix, $GUI_DOCKALL)
	GUICtrlSetTip($Button_fix, "Fix the title or stored image link or game page URL!")
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
	$Button_options = GUICtrlCreateButton("DOWNLOAD && INSTALL" & @LF & "THE SELECTED GAME", 160, 455, 150, 45, $BS_MULTILINE)
	GUICtrlSetFont($Button_options, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_options, $GUI_DOCKALL)
	GUICtrlSetTip($Button_options, "Download & Install the selected game!")
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
	GUICtrlSetImage($Button_more, $shell, $icoS, 1)
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
	;
	If $mode = "Steam" Then
		GUICtrlSetState($Button_inf, $GUI_DISABLE)
		GUICtrlSetState($Button_fix, $GUI_DISABLE)
		;
		GUICtrlSetData($Button_options, "DOWNLOAD && INSTALL" & @LF & "THE SELECTED GAME")
		GUICtrlSetTip($Button_options, "Download & Install the selected game!")
		;
		$store = IniRead($inifle, "Link Type", "store", "")
		If $store = "" Then
			$store = 1
			IniWrite($inifle, "Link Type", "store", $store)
		EndIf
		GUICtrlSetState($Checkbox_link, $store)
		;
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
		$alldlc = IniRead($inifle, "Steam Install", "all_dlc", "")
		;If $alldlc = "" Then
		;	$alldlc = 1
		;	IniWrite($inifle, "Steam Install", "all_dlc", $alldlc)
		;EndIf
	ElseIf $mode = "Epic" Then
		GUICtrlSetData($Button_options, "INSTALL OPTIONS ETC" & @LF & "FOR SELECTED GAME")
		GUICtrlSetTip($Button_options, "Open the Install Options Etc window!")
		;GUICtrlSetState($Checkbox_link, $GUI_DISABLE)
		GUICtrlSetState($Combo_list, $GUI_DISABLE)
		If $epic = 3 Then
			GUICtrlSetState($Button_inf, $GUI_DISABLE)
			GUICtrlSetState($Button_id, $GUI_DISABLE)
			GUICtrlSetState($Input_id, $GUI_DISABLE)
		EndIf
		GUICtrlSetState($Button_image, $GUI_DISABLE)
		GUICtrlSetState($Input_image, $GUI_DISABLE)
		GUICtrlSetState($Button_save, $GUI_DISABLE)
		GUICtrlSetState($Button_fix, $GUI_DISABLE)
		If $epic <> 1 Then GUICtrlSetState($Button_options, $GUI_DISABLE)
		$drmfree = "Google Docs"
		GUICtrlSetData($Combo_list, "Google Docs", $drmfree)
		$freefle = $freefle3
		$listurl = IniRead($inifle, "Google Docs", "url", "")
		If $listurl = "" Then
			;https://docs.google.com/spreadsheets/d/16BjnaBO40vkt6kFVl0QWMWVh86UFnr-j_yWhQbASJ58/gviz/tq?tqx=out:html
			$listurl = "https://docs.google.com/spreadsheets/d/16BjnaBO40vkt6kFVl0QWMWVh86UFnr-j_yWhQbASJ58"
			IniWrite($inifle, "Google Docs", "url", $listurl)
		EndIf
		GUICtrlSetData($Input_list, $listurl)
		;
		$altpth = IniRead($inifle, "Epic Games Folder", "alt_path", "")
		If $altpth = "" Then
			$altpth = ""
			IniWrite($inifle, "Epic Games Folder", "alt_path", $altpth)
		EndIf
		$alternate = IniRead($inifle, "Epic Games Folder", "use_alt", "")
		If $alternate = "" Then
			$alternate = 4
			IniWrite($inifle, "Epic Games Folder", "use_alt", $alternate)
		EndIf
		;
		$destfld = IniRead($inifle, "Epic Destination", "path", "")
		If $destfld = "" Then
			$destfld = ""
			IniWrite($inifle, "Epic Destination", "path", $destfld)
		EndIf
		$dest = IniRead($inifle, "Epic Destination", "query", "")
		If $dest = "" Then
			$dest = 1
			IniWrite($inifle, "Epic Destination", "query", $dest)
		EndIf
		;
		$alldlc = IniRead($inifle, "Epic Install", "all_dlc", "")
		If $alldlc = "" Then
			$alldlc = 1
			IniWrite($inifle, "Epic Install", "all_dlc", $alldlc)
		EndIf
		;
		$updates = 4
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
	$split = IniRead($inifle, "7-Zip", "split", "")
	If $split = "" Then
		$split = "2 Gb"
		IniWrite($inifle, "7-Zip", "split", $split)
	EndIf
	$compress = IniRead($inifle, "7-Zip", "compression", "")
	If $compress = "" Then
		$compress = "Default"
		IniWrite($inifle, "7-Zip", "compression", $compress)
	EndIf
	$thread = IniRead($inifle, "7-Zip", "multithread", "")
	If $thread = "" Then
		$thread = "off"
		IniWrite($inifle, "7-Zip", "multithread", $thread)
	EndIf
	;
	$manner = IniRead($inifle, "Zip Logging", "method", "")
	If $manner = "" Then
		$manner = 1
		IniWrite($inifle, "Zip Logging", "method", $manner)
	EndIf
	;
	$tabs = @TAB & @TAB & @TAB & @TAB & @TAB & @TAB & @TAB & @TAB
	PopulateTheList()
	;
	$decrypt = ""
	$decrypted = ""
	$buttxt = "Less"
	$process = ""
	;
	$gamefold = ""
	$ontop = 1
	;
	If $mode = "Steam" Then
		;If $alternate = 4 Then GetLocalSteamGamesFolder()
		GetLocalSteamGamesFolder()
	ElseIf $mode = "Epic" Then
		;If $alternate = 4 Then GetLocalEpicGamesFolder()
		GetLocalEpicGamesFolder()
	EndIf
	;
	SetStateOfControls($GUI_ENABLE)
	;
	; TESTING ONLY
	;GUICtrlSetState($Button_options, $GUI_ENABLE)

	GUISetState(@SW_SHOW)
	While 1
		$msg = GUIGetMsg()
        Select
			Case $msg = $GUI_EVENT_CLOSE Or $msg = $Button_exit
				; Exit or Close the program
				$winpos = WinGetPos($ListGUI, "")
				$left = $winpos[0]
				If $left < 0 Then
					$left = 2
				ElseIf $left > @DesktopWidth - $width Then
					$left = @DesktopWidth - $width - 25
				EndIf
				IniWrite($inifle, "Program Window", "left", $left)
				$top = $winpos[1]
				If $top < 0 Then
					$top = 2
				ElseIf $top > @DesktopHeight - $height - 30 Then
					$top = @DesktopHeight - $height - 60
				EndIf
				IniWrite($inifle, "Program Window", "top", $top)
				;
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
			Case $msg = $Button_updater
				; Update the list of owned games
				SetStateOfControls($GUI_DISABLE)
				_FileWriteLog($logfle, "Updating Owned Games List.")
				$ping = Ping("gog.com", 5000)
				If $ping > 0 Then
					If $mode = "Steam" Then
						$find = GUICtrlRead($Input_find)
						GUICtrlSetBkColor($Input_find, $COLOR_RED)
						GUICtrlSetData($Input_find, "Please Wait - Updating")
						$userID = IniRead($inifle, "Steam User", "id", "")
						$result = InputBox("Steam User ID", "Enter ID or Accept the current ID." & @LF & "  (will use your web connection)", $userID, "", 200, 145, Default, Default, 0, $ListGUI)
						If @error = 0 And $result <> "" Then
							If $result <> $userID Then
							   $userID = $result
							   IniWrite($inifle, "Steam User", "id", $userID)
							EndIf
							$URL = "https://steamcommunity.com/profiles/" & $userID & "/games/?xml=1"
							_FileWriteLog($logfle, "Downloading owned Steam games list.")
							$download = InetGet($URL, $xmlfle, 0, 0)
							InetClose($download)
							_FileWriteLog($logfle, "Updating Finished.")
							ParseTheXMLGamesList()
							_FileWriteLog($logfle, "Parsing Finished.")
							GUICtrlSetData($List_games, "")
							PopulateTheList()
						EndIf
					ElseIf $mode = "Epic" Then
						If $epic = 3 Then
							; Semi-Automatic
							If GUICtrlRead($Button_updater) = "UPDATE" Then
								$find = GUICtrlRead($Input_find)
								GUICtrlSetBkColor($Input_find, $COLOR_RED)
								GUICtrlSetData($Input_find, "Please Wait - Updating")
								SplashTextOn("", "Please Wait until web" & @LF & "page has fully loaded" & @LF & "before clicking SAVE", 210, 120, -1, -1, 33)
								_FileWriteLog($logfle, "Downloading owned Epic games list.")
								ShellExecute("https://www.epicgames.com/account/transactions")
								Sleep(5000)
								; Maybe use a floating SAVE button or rename UPDATE button.
								WinWait("Purchase History", "", 15)
								Sleep(5000)
								SplashOff()
								GUICtrlSetData($Button_updater, "SAVE")
								GUICtrlSetFont($Button_updater, 7, 600, 0, "Small Fonts")
								GUICtrlSetState($Button_updater, $GUI_ENABLE)
								GUICtrlSetBkColor($Graphic_update, $COLOR_RED)
								ContinueLoop
							ElseIf GUICtrlRead($Button_updater) = "SAVE" Then
								GUICtrlSetState($Button_updater, $GUI_DISABLE)
								WinActivate("Purchase History", "")
								Send("^s")
								;$savpth = $htmlfld & "\Purchase History.html"
								;ClipPut($savpth)
								$wintit = "Save As"
								BlockInput(1)
								WinWaitActive($wintit, "", 9)
								If WinExists($wintit, "") Then
									WinActivate($wintit, "")
									Send($savpth)
								EndIf
								BlockInput(0)
								WinWaitClose($wintit, "", 0)
								_FileWriteLog($logfle, "Updating Finished.")
								GUICtrlSetBkColor($Graphic_update, $COLOR_BLUE)
								GUICtrlSetData($Button_updater, "LOAD")
								GUICtrlSetState($Button_updater, $GUI_ENABLE)
								;GUISetState(@SW_SHOWNORMAL, $ListGUI)
								WinActivate($ListGUI, "")
								ContinueLoop
							Else
								GUICtrlSetState($Button_updater, $GUI_DISABLE)
								ParseTheHTMLGamesList()
								_FileWriteLog($logfle, "Parsing Finished.")
								GUICtrlSetData($List_games, "")
								PopulateTheList()
								GUICtrlSetBkColor($Graphic_update, $COLOR_YELLOW)
								GUICtrlSetData($Button_updater, "UPDATE")
								GUICtrlSetFont($Button_updater, 6, 600, 0, "Small Fonts")
							EndIf
						Else
							; Automatic using Legendary
							$find = GUICtrlRead($Input_find)
							GUICtrlSetBkColor($Input_find, $COLOR_RED)
							GUICtrlSetData($Input_find, "Please Wait - Updating")
							_FileWriteLog($logfle, "Downloading owned Epic games list.")
							;$sid = IniRead($inifle, "Epic User", "sid", "")
							;If $sid = 1 Then
								$ans = MsgBox(262144 + 33, "Authenticate Query", _
									"Do you want to use any existing authentication?" & @LF _
									& @LF & "OK = Continue with existing SID." _
									& @LF & "CANCEL = Obtain a new SID." & @LF _
									& @LF & "NOTE - If you have never used Legendary, then" _
									& @LF & "select CANCEL to get an authentication code." & @LF _
									& @LF & "ADVICE - If existing authentication no longer" _
									& @LF & "works, then use CANCEL next time.", 0, $ListGUI)
								$sid = $ans
								;If $ans = 2 Then
								;	$sid = ""
								;EndIf
							;EndIf
							;If $sid = "" Then
							If $sid = 2 Then
								$params = " auth"
								;RunWait($Legendary & $params, $LEGfold)
								FileChangeDir($LEGfold)
								RunWait(@ComSpec & " /c legendary.exe auth --delete")
								Sleep(2000)
								$cmd = @SystemDir & "\cmd.exe"
								$pid = Run(@ComSpec & " /c legendary.exe" & $params, "", @SW_MINIMIZE)
								$result = InputBox('Epic Authentication', 'Enter the SID value from the web page that' & @LF & 'should eventually appear. Use the text from' _
									& @LF & 'between the quotes after "sid":.', '', '', 255, 160, Default, Default, 0, $ListGUI)
								If @error = 0 And $result <> "" Then
									;ProcessClose($pid)
									WinClose($cmd, "")
									$sid = $result
									IniWrite($inifle, "Epic User", "sid", "1")
									$params = " auth --sid " & $sid
									;RunWait($Legendary & $params, $LEGfold)
									FileChangeDir($LEGfold)
									RunWait(@ComSpec & " /c legendary.exe" & $params)
								Else
									;ProcessClose($cmd)
									WinClose($cmd, "")
									GUICtrlSetBkColor($Input_find, $CLR_DEFAULT)
									GUICtrlSetData($Input_find, $find)
									SetStateOfControls($GUI_ENABLE)
									ContinueLoop
								EndIf
							EndIf
							$params = ' list-games > "' & $gameslist & '"'
							;$params = ' list-games > Gameslist.txt'
							;$params = " list-games --json"
							;RunWait($Legendary & $params, $LEGfold)
							;$params = 'list-games > Gameslist.txt'
							;ShellExecuteWait($Legendary, $params, @ScriptDir)
							;_RunDos($Legendary & $params)
							FileChangeDir($LEGfold)
							RunWait(@ComSpec & " /c legendary.exe" & $params)
							_FileWriteLog($logfle, "Updating Finished.")
							If FileExists($gameslist) Then
								$lines = _FileCountLines($gameslist)
								If $lines > 0 Then
									ParseTheGamesList()
									_FileWriteLog($logfle, "Parsing Finished.")
									GUICtrlSetData($List_games, "")
									PopulateTheList()
								Else
									_FileWriteLog($logfle, "Content Error - Game list is empty.")
									MsgBox(262192, "Content Error", "Gamelist file is empty!", 0, $ListGUI)
								EndIf
							Else
								_FileWriteLog($logfle, "Download Error - File not found.")
								MsgBox(262192, "Download Error", "Gamelist file not found!", 0, $ListGUI)
							EndIf
						EndIf
					EndIf
				Else
					_FileWriteLog($logfle, "Updating Failed - Ping error.")
					MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 0, $ListGUI)
				EndIf
				GUICtrlSetBkColor($Input_find, $CLR_DEFAULT)
				GUICtrlSetData($Input_find, $find)
				SetStateOfControls($GUI_ENABLE)
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
			Case $msg = $Button_opts And $buttxt = "More"
				; Setup the 7-Zip options
				SetupGUI()
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
								While 1
									$savefold = $destfld & "\" & $title
									If FileExists($savefold) Then
										$savefile = $savefold & "\" & $savefile
										$ping = Ping("gog.com", 5000)
										If $ping > 0 Then
											$download = InetGet($image, $savefile, 0, 0)
											InetClose($download)
											If FileExists($savefile) Then
												_FileWriteLog($logfle, "Downloaded the '" & $title & "' game icon image file.")
												SplashTextOn("", "Image Saved!", 180, 80, -1, -1, 33)
												Sleep(1000)
												SplashOff()
											Else
												_FileWriteLog($logfle, "Download Error - File not found.")
												MsgBox(262192, "Download Error", "Image file not found!", 3, $ListGUI)
											EndIf
										Else
											MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 3, $ListGUI)
										EndIf
										ExitLoop
									Else
										$ans = MsgBox(262144 + 33, "Path Error", "Game destination (backup) folder doesn't exist!" _
											& @LF & @LF & "Do you wish to create?", 0, $ListGUI)
										If $ans = 1 Then
											DirCreate($savefold)
										Else
											ExitLoop
										EndIf
									EndIf
								WEnd
							Else
								MsgBox(262192, "Image Error", "Could not determine image file type!", 3, $ListGUI)
							EndIf
						Else
							MsgBox(262192, "Path Error", "Destination (backup) folder not set or doesn't exist!", 3, $ListGUI)
						EndIf
					Else
						MsgBox(262192, "Usage Error", "No title selected!", 3, $ListGUI)
					EndIf
				Else
					MsgBox(262192, "Icon Error", "No image file link is listed, or incorrect format!", 6, $ListGUI)
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
				; Browse to set the Steam or Epic games folder path
				;MsgBox(262192, "Status Report", "This feature is currently unavailable!", 0, $ListGUI)
				$pth = FileSelectFolder("Browse to set your " & $mode & " games folder path", $altpth, 7, "", $ListGUI)
				If Not @error Then
					;If $alternate = 4 Then
					;	$gamesfld = $pth
					;	GUICtrlSetData($Input_path, $gamesfld)
					;Else
						$altpth = $pth
						GUICtrlSetData($Input_path, $altpth)
						If $mode = "Steam" Then
							IniWrite($inifle, "Games Folder", "alt_path", $altpth)
						ElseIf $mode = "Epic" Then
							IniWrite($inifle, "Epic Games Folder", "alt_path", $altpth)
						EndIf
					;EndIf
				EndIf
			Case $msg = $Button_options
				; Download & Install the selected game
				$title = GUICtrlRead($Input_title)
				If $title <> "" Then
					$ind = _GUICtrlListBox_GetCurSel($List_games)
					If $mode = "Steam" Then
						$ans = MsgBox(262144 + 35, "Download Query", _
							"Do you want to install/update the selected game?" & @LF _
							& @LF & "YES = Install & Validate." _
							& @LF & "NO = Just Install (No Validate)." _
							& @LF & "CANCEL = Abort any downloading.", 0, $ListGUI)
						If $ans = 2 Then
							ContinueLoop
						ElseIf $ans = 6 Then
							$process = "install & validate"
						ElseIf $ans = 7 Then
							$process = "install"
						EndIf
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
								If FileExists($downfold) And $process = "install" Then
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
									;_FileWriteLog($logfle, "Downloading - " & $title)
									_FileWriteLog($logfle, _StringProper($process) & " - " & $title)
									$ping = Ping("gog.com", 5000)
									If $ping > 0 Then
										_FileCreate($timefile)
										$done = ""
										FileWriteLine($timefile, "[" & $process & "]")
										AdlibRegister("CheckIfComplete", 1000)
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
										$params = $params & ' +force_install_dir "' & $downfold & '" +app_update ' & $gameID
										If $process = "install & validate" Then
											$params = $params & ' +validate'
										EndIf
										$params = $params & ' +quit && echo done=1 >>"' & $timefile & '" && pause'
										;RunWait($SteamCMD & $params, @ScriptDir)
										;RunWait($SteamCMD & $params, $CMDfold)
										FileChangeDir($CMDfold)
										RunWait(@ComSpec & " /c steamcmd.exe" & $params)
										;_FileWriteLog($logfle, "Downloading Finished.")
										If $done = "" Then
											AdlibUnRegister("CheckIfComplete")
											$process = _StringProper($process)
											_FileWriteLog($logfle, $process & " Complete.")
											$process = ""
										EndIf
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
						Else
							MsgBox(262192, "ID Error", "Game ID not found (listed)!", 0, $ListGUI)
						EndIf
					ElseIf $mode = "Epic" Then
						InstallOptionsEtcGUI()
						; TESTING ONLY
						;ContinueLoop
						If $process <> "" Then
							; Replacements may not be needed if Legendary takes care of such things. UPDATE - Doing both.
							;$game = $title
							$title = CharacterReplacements($title)
							If $alternate = 4 Then
								$downfold = $gamesfld
							Else
								$downfold = $altpth
							EndIf
							If FileExists($downfold) Then
								; Need to consider further the option of using a specific game folder path, or change the following
								; to something like $checkfold. This path may not always be accurate, due to title issues.
								; UPDATE - Specifying specific and sticking with $downfold.
								$downfold = $downfold & "\" & $title
								If FileExists($downfold) Then
									If $process = "install" Or $process = "download" Then
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
								ElseIf $process = "update" Or $process = "verify" Then
									MsgBox(262192, "Path Error", "Game folder not found at specified location!", 0, $ListGUI)
									ContinueLoop
								EndIf
								If FileExists($Legendary) Then
									SetStateOfControls($GUI_DISABLE)
									$find = GUICtrlRead($Input_find)
									GUICtrlSetBkColor($Input_find, $COLOR_RED)
									GUICtrlSetData($Input_find, "Please Wait!")
									;_FileWriteLog($logfle, "Downloading - " & $title)
									If $process = "installed" Then
										_FileWriteLog($logfle, "Checking For Installed.")
									Else
										_FileWriteLog($logfle, _StringProper($process) & " - " & $title)
									EndIf
									$ping = Ping("gog.com", 5000)
									If $ping > 0 Then
										If $process <> "installed" Then
											_FileCreate($timefile)
											$done = ""
											FileWriteLine($timefile, "[" & $process & "]")
											AdlibRegister("CheckIfComplete", 1000)
										EndIf
										If $process = "install" Then
											;$params = ' -y install ' & $game & ' --base-path "' & $downfold & '" --force'
											;$params = ' -y install ' & $game & ' --game-folder "' & $downfold & '" --force'
											$params = ' -y install ' & $appname & ' --game-folder "' & $downfold & '" --force'
										ElseIf $process = "download" Then
											;$params = ' -y install ' & $game & ' --base-path "' & $downfold & '" --force --download-only'
											;$params = ' -y install ' & $game & ' --game-folder "' & $downfold & '" --force --download-only'
											$params = ' -y install ' & $appname & ' --game-folder "' & $downfold & '" --force --download-only'
										ElseIf $process = "update" Then
											$params = ' -y install ' & $appname & ' --game-folder "' & $downfold & '" --update-only'
										ElseIf $process = "verify" Then
											$params = ' verify-game ' & $appname
										;ElseIf $process = "import" Then
										ElseIf $process = "repair" Then
											$params = ' -y install ' & $appname & ' --game-folder "' & $downfold & '" --repair'
										ElseIf $process = "installed" Then
											$savefile = @ScriptDir & "\Installed.txt"
											$params = ' list-installed'
											If $updates = 1 Then
												$params = $params & ' --check-updates'
											EndIf
											$params = $params & ' > "' & $savefile & '"'
										EndIf
										If $process <> "verify" And $process <> "installed" Then
											If $alldlc = 1 Then
												$params = $params & ' --with-dlcs'
											EndIf
										EndIf
										If $process <> "installed" Then
											;$params = $params & ' && pause'
											$params = $params & ' && echo done=1 >>"' & $timefile & '" && pause'
										EndIf
										FileChangeDir($LEGfold)
										RunWait(@ComSpec & " /c legendary.exe" & $params)
										If $process = "installed" Then
											_FileWriteLog($logfle, "Check Installed Finished.")
											If FileExists($savefile) Then ShellExecute($savefile)
										Else
											If $done = "" Then
												AdlibUnRegister("CheckIfComplete")
												$process = _StringProper($process)
												_FileWriteLog($logfle, $process & " Complete.")
												$process = ""
											EndIf
										EndIf
									Else
										_FileWriteLog($logfle, "Install Option Failed - Ping error.")
										MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 0, $ListGUI)
									EndIf
									GUICtrlSetBkColor($Input_find, $CLR_DEFAULT)
									GUICtrlSetData($Input_find, $find)
									SetStateOfControls($GUI_ENABLE)
								Else
									MsgBox(262192, "Program Error", "The required 'legendary.exe' file could not be found!", 0, $ListGUI)
								EndIf
							Else
								MsgBox(262192, "Path Error", "Game folder not set or location doesn't exist!", 0, $ListGUI)
							EndIf
						EndIf
					EndIf
					_GUICtrlListBox_ClickItem($List_games, $ind, "left", False, 1, 0)
				Else
					MsgBox(262192, "Usage Error", "No title selected!", 3, $ListGUI)
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
							ElseIf $drmfree = "Google Docs" Then
								$savefile = "Epic DRM-Free Notes.txt"
							EndIf
							While 1
								$savefold = $destfld & "\" & $title
								If FileExists($savefold) Then
									$savefile = $savefold & "\" & $savefile
									_FileCreate($savefile)
									Sleep(500)
									FileWrite($savefile, $notes)
									_FileWriteLog($logfle, "Saved a DRM-Free List notes file for '" & $title & "'.")
									SplashTextOn("", "Notes Saved!", 180, 80, -1, -1, 33)
									Sleep(1000)
									SplashOff()
									ExitLoop
								Else
									$ans = MsgBox(262144 + 33, "Path Error", "Game destination (backup) folder doesn't exist!" _
										& @LF & @LF & "Do you wish to create?", 0, $ListGUI)
									If $ans = 1 Then
										DirCreate($savefold)
									Else
										ExitLoop
									EndIf
								EndIf
							WEnd
						Else
							MsgBox(262192, "Path Error", "Destination (backup) folder not set or doesn't exist!", 3, $ListGUI)
						EndIf
					Else
						MsgBox(262192, "Usage Error", "No title selected!", 3, $ListGUI)
					EndIf
				Else
					MsgBox(262192, "Notes Error", "Notes don't exist for the selected game," & @LF & "with the current 'DRM-Free List' option!", 6, $ListGUI)
				EndIf
			Case $msg = $Button_more
				; More program options
				$buttxt = GUICtrlRead($Button_more)
				If $buttxt = "Less" Then
					$buttxt = "More"
					GUICtrlSetData($Button_more, $buttxt)
					GUICtrlSetTip($Button_more, "Less program options!")
					$winsize = WinGetClientSize($ListGUI, "")
					$wide = $winsize[0]
					$high = $winsize[1]
					$winpos = WinGetPos($ListGUI)
					If $winpos[1] > (@DesktopHeight - $height - 190) Then
						WinMove($ListGUI, "", Default, (@DesktopHeight - $height - 190), 476, 673)
					Else
						WinMove($ListGUI, "", Default, Default, 476, 673)
					EndIf
					;
					$Button_opts = GUICtrlCreateButton("SETUP", 10, 510, 49, 20)
					GUICtrlSetFont($Button_opts, 6, 600, 0, "Small Fonts")
					GUICtrlSetTip($Button_opts, "Setup the 7-Zip options!")
					$Input_zip = GUICtrlCreateInput("", 60, 510, 170, 20)
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
					;
					If $mode = "Steam" Then
						If $user = 1 Then
							GUICtrlSetState($Button_user, $GUI_DISABLE)
							GUICtrlSetState($Input_user, $GUI_DISABLE)
						EndIf
						If $pass = 1 Then
							GUICtrlSetState($Button_pass, $GUI_DISABLE)
							GUICtrlSetState($Input_pass, $GUI_DISABLE)
						EndIf
					ElseIf $mode = "Epic" Then
						GUICtrlSetState($Button_code, $GUI_DISABLE)
						GUICtrlSetState($Input_code, $GUI_DISABLE)
						GUICtrlSetState($Button_user, $GUI_DISABLE)
						GUICtrlSetState($Input_user, $GUI_DISABLE)
						GUICtrlSetState($Checkbox_user, $GUI_DISABLE)
						GUICtrlSetState($Button_pass, $GUI_DISABLE)
						GUICtrlSetState($Input_pass, $GUI_DISABLE)
						GUICtrlSetState($Checkbox_pass, $GUI_DISABLE)
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
					GUICtrlSetData($Button_more, $buttxt)
					GUICtrlSetTip($Button_more, "More program options!")
					GUICtrlDelete($Button_opts)
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
					WinMove($ListGUI, "", Default, Default, $wide + 6, $high + 28)
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
				If StringLeft($listurl, 4) = "http" Then
					$ping = Ping("gog.com", 5000)
					If $ping > 0 Then
						If $drmfree = "Google Docs" Then
							ShellExecute($listurl & "/view#gid=0")
						Else
							ShellExecute($listurl)
						EndIf
					Else
						MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 0, $ListGUI)
					EndIf
				EndIf
			Case $msg = $Button_link
				; Click to go to the game web page
				$link = GUICtrlRead($Input_link)
				If StringLeft($link, 4) = "http" Then
					$ping = Ping("gog.com", 5000)
					If $ping > 0 Then
						If $mode = "Epic" Then
							If $appname = "" Then
								$val = $title
							Else
								$val = $appname
							EndIf
							If $link <> IniRead($gamesini, $val, "link", "") Then
								;https://www.epicgames.com/store/en-US/browse?q=3%20Out%20of%2010&sortBy=relevancy&sortDir=DESC&count=40
								LinkReplacements()
								If $store = 1 And $other = "IGDB" Then
									$link = StringReplace($link, "--", "-")
									$link = StringReplace($link, "-episode-", "-ep-")
								EndIf
							EndIf
						ElseIf _IsPressed("11") Then
							$link = StringReplace($link, "--", "-")
							$link = StringReplace($link, "-episode-", "-ep-")
						EndIf
						ShellExecute($link)
					Else
						MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 0, $ListGUI)
					EndIf
				EndIf
			Case $msg = $Button_info
				; Program Information
				SetStateOfControls($GUI_DISABLE)
				If $mode = "Steam" Then
					$message = "Of particular use, is using SteamCMD to download and install any" & @LF & _
						"selected game on the list, then maybe backing the game folder up" & @LF & _
						"to a zip file or self-extracting executable file, to a specified location." & @LF & @LF & _
						"Username and Password can be saved (stored) within the program," & @LF & _
						"though perhaps for improved security reasons, make the password" & @LF & _
						"a query, even though both credentials are stored encrypted in a file."
					$numb = "two"
				Else
					$message = "Of particular use, is backing up an installed game folder to a zip" & @LF & _
						"file or self-extracting executable file, to a specified location."
					$numb = "one"
				EndIf
				If $mode = "Steam" Then
					$notify = @LF
				Else
					$notify = "Enable IGDB checkbox to activate the ICON, FIX and SAVE buttons." & @LF & @LF
				EndIf
				MsgBox(262208, "Program Information", _
					"This program is for downloading your list of owned " & $mode & " games," & @LF & _
					"and then viewing that list, and or then interacting with it usefully." & @LF & @LF & _
					$message & @LF & @LF & _
					"Some games at " & $mode & ", are capable of being DRM-Free, though you" & @LF & _
					"cannot find that information on the store game page. However you" & @LF & _
					"can find online listings about which ones are DRM-Free, and " & $numb & " of" & @LF & _
					"those can be used by this program, to make determinations easier." & @LF & @LF & _
					"CTRL held down while clicking folder button opens program folder." & @LF & _
					$notify & _
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
					"'PC Gaming Wiki' page for 'DRM-Free' Steam games." & @LF & _
					"BIG THANKS to those who provided & created (update) the online" & @LF & _
					"'Google Docs' page for 'DRM-Free' Epic games." & @LF & @LF & _
					"© Created by Timboli (aka TheSaint) in " & $created & $version, 0, $ListGUI)
				SetStateOfControls($GUI_ENABLE)
			Case $msg = $Button_inf
				; Save selected game information
				$title = GUICtrlRead($Input_title)
				If $title <> "" Then
					If FileExists($Legendary) Then
						SetStateOfControls($GUI_DISABLE)
						$title = CharacterReplacements($title)
						$savefile = ""
						If FileExists($destfld) Then
							$savefold = $destfld & "\" & $title
						Else
							$savefold = @ScriptDir
							;MsgBox(262192, "Path Error", "Destination (backup) folder not set or doesn't exist!", 3, $ListGUI)
						EndIf
						While 1
							If FileExists($savefold) Then
								$savefile = $savefold & "\GameInfo.txt"
								$find = GUICtrlRead($Input_find)
								GUICtrlSetBkColor($Input_find, $COLOR_RED)
								GUICtrlSetData($Input_find, "Please Wait!")
								_FileWriteLog($logfle, "Information - " & $title)
								$ping = Ping("gog.com", 5000)
								If $ping > 0 Then
									$params = ' info ' & $appname & ' > "' & $savefile & '"'
									FileChangeDir($LEGfold)
									RunWait(@ComSpec & " /c legendary.exe" & $params)
									_FileWriteLog($logfle, "Information Finished.")
								Else
									_FileWriteLog($logfle, "Information Failed - Ping error.")
									MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 0, $ListGUI)
								EndIf
								GUICtrlSetBkColor($Input_find, $CLR_DEFAULT)
								GUICtrlSetData($Input_find, $find)
								ExitLoop
							Else
								$ans = MsgBox(262144 + 33, "Path Error", "Game destination (backup) folder doesn't exist!" & @LF _
									& @LF & "Do you wish to create?" & @LF _
									& @LF & "OK = Create a game folder for file." _
									& @LF & "CANCEL = Use a temporary file.", 0, $ListGUI)
								If $ans = 1 Then
									DirCreate($savefold)
								Else
									$savefold = @ScriptDir
									;ExitLoop
								EndIf
							EndIf
						WEnd
						SetStateOfControls($GUI_ENABLE)
						If FileExists($savefile) Then ShellExecute($savefile)
					Else
						MsgBox(262192, "Program Error", "The required 'legendary.exe' file could not be found!", 0, $ListGUI)
					EndIf
				Else
					MsgBox(262192, "Usage Error", "No title selected!", 3, $ListGUI)
				EndIf
			Case $msg = $Button_image
				; Click to show the online image in your browser
				$image = GUICtrlRead($Input_image)
				If StringLeft($image, 4) = "http" Or $other = "IGDB" Then
					$ping = Ping("gog.com", 5000)
					If $ping > 0 Then
						If $mode = "Steam" Or $image <> "" Then
							ShellExecute($image)
						ElseIf $mode = "Epic" Then
							SetStateOfControls($GUI_DISABLE)
							$find = GUICtrlRead($Input_find)
							GUICtrlSetBkColor($Input_find, $COLOR_RED)
							GUICtrlSetData($Input_find, "Please Wait!")
							;MsgBox(262192, "$link", $link, 0, $ListGUI)
							$link = GUICtrlRead($Input_link)
							If StringInStr($link, "www.epicgames.com") > 0 Then
								$link = StringReplace($link, "https://www.epicgames.com/store/en-US/p/", "https://www.igdb.com/games/")
								LinkReplacements()
								If _IsPressed("11") Then
									$link = StringReplace($link, "--", "-")
									$link = StringReplace($link, "-episode-", "-ep-")
								EndIf
								$link = StringReplace($link, "--", "-")
							EndIf
							$html = _INetGetSource($link, True)
							If $html <> "" Then
								;<meta content="https://images.igdb.com/igdb/image/upload/t_cover_big/co3hih.jpg"
								$image = StringSplit($html, "https://images.igdb.com/igdb/image/upload/t_cover_big/", 1)
								;If $image[0] = 2 Then
								If $image[0] > 1 Then
									$image = $image[2]
									$image = StringSplit($image, '"', 1)
									$image = $image[1]
									$image = "https://images.igdb.com/igdb/image/upload/t_cover_big/" & $image
									GUICtrlSetData($Input_image, $image)
									; Maybe write to an INI file so once off.
									If $appname = "" Then
										IniWrite($gamesini, $title, "image", $image)
									Else
										IniWrite($gamesini, $appname, "image", $image)
									EndIf
									$ans = MsgBox(262144 + 33, "Browser Query", "Show the image file in your browser?" & @LF _
										& @LF & "OK = Show in browser." _
										& @LF & "CANCEL = Just get the image link.", 0, $ListGUI)
									If $ans = 1 Then
										ShellExecute($image)
									EndIf
								Else
									$image = ""
									MsgBox(262192, "Image Error", "Link (URL) not found!", 0, $ListGUI)
								EndIf
							Else
								MsgBox(262192, "Image Error", "No web page data was returned!", 0, $ListGUI)
							EndIf
							GUICtrlSetBkColor($Input_find, $CLR_DEFAULT)
							GUICtrlSetData($Input_find, $find)
							SetStateOfControls($GUI_ENABLE)
						EndIf
					Else
						MsgBox(262192, "Web Error", "No connection detected or Ping took too long!", 0, $ListGUI)
					EndIf
				EndIf
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
			Case $msg = $Button_fix
				; Fix the title or stored image link or game page URL
				$title = GUICtrlRead($Input_title)
				If $title <> "" Then
					$title = CharacterReplacements($title)
					If $appname = "" Then
						$val = $title
					Else
						$val = $appname
					EndIf
					$ans = MsgBox(262179 + 256, "Game Title Query", "Do you want to fix the game title?" & @LF _
						& @LF & "YES = Fix the Game Title." _
						& @LF & "NO = Skip to Image Link query." _
						& @LF & "CANCEL = Abort all Fixes." & @LF _
						& @LF & "NOTE - A fix will only occur if the relevant" _
						& @LF & "input field contains the desired new entry.", 0, $ListGUI)
					If $ans = 6 Then
						$alias = IniRead($gamesini, $val, "title", "")
						If $alias = "" Then $alias = $title
						$alias = InputBox("Game Title Fix", "Enter a new title or Edit the listed one." & @LF _
							& @LF & "NOTE - The new title will only be used for DRM-Free detection.", $alias, "", 450, 155, Default, Default, 0, $ListGUI)
						If @error = 0 And $alias <> "" And $alias <> $title Then
							If $alias <> IniRead($gamesini, $val, "title", "") Then
								IniWrite($gamesini, $val, "title", $alias)
								SplashTextOn("", "Game Title Saved!", 220, 80, -1, -1, 33)
								Sleep(1000)
								SplashOff()
							EndIf
						EndIf
					ElseIf $ans = 2 Then
						ContinueLoop
					EndIf
					$ans = MsgBox(262179 + 256, "Image Link Query", "Do you want to fix the image link?" & @LF _
						& @LF & "YES = Fix the Image Link." _
						& @LF & "NO = Skip to Web Page query." _
						& @LF & "CANCEL = Abort all Fixes." & @LF _
						& @LF & "NOTE - A fix will only occur if the relevant" _
						& @LF & "input field contains the desired new entry.", 0, $ListGUI)
					If $ans = 6 Then
						$image = GUICtrlRead($Input_image)
						If $image <> "" Then
							If StringLeft($image, 4) = "http" Then
								If $image <> IniRead($gamesini, $val, "image", "") Then
									IniWrite($gamesini, $val, "image", $image)
									SplashTextOn("", "Image Link Saved!", 220, 80, -1, -1, 33)
									Sleep(1000)
									SplashOff()
								EndIf
							Else
								MsgBox(262192, "Icon Error", "Image file link is in an incorrect format!", 6, $ListGUI)
							EndIf
						Else
							MsgBox(262192, "Icon Error", "No image file link is listed!", 6, $ListGUI)
						EndIf
					ElseIf $ans = 2 Then
						ContinueLoop
					EndIf
					$ans = MsgBox(262177 + 256, "Web Page Link Query", "Do you want to fix the page link?" & @LF _
						& @LF & "OK = Fix the Web Page Link." _
						& @LF & "CANCEL = Abort the Fix.", 0, $ListGUI)
					If $ans = 1 Then
						$link = GUICtrlRead($Input_link)
						If $link <> "" And StringLeft($link, 4) <> "http" Then
							MsgBox(262192, "Page Link Error", "Game page URL is in an incorrect format!", 6, $ListGUI)
						Else
							If $link <> IniRead($gamesini, $val, "link", "") Then
								IniWrite($gamesini, $val, "link", $link)
								SplashTextOn("", "Game Page" & @LF & "Link Updated!", 200, 100, -1, -1, 33)
								Sleep(1000)
								SplashOff()
							EndIf
						EndIf
					EndIf
				Else
					MsgBox(262192, "Usage Error", "No title selected!", 3, $ListGUI)
				EndIf
			Case $msg = $Button_find
				; Find the specified text in a title
				$find = GUICtrlRead($Input_find)
				If $find = "" Then
					MsgBox(262192, "Search Error", "No text specified!", 0, $ListGUI)
				Else
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
								$title = StringStripWS($title, 4)
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
					ElseIf $find = "DRM-Free List" Then
						$title = GUICtrlRead($Input_title)
						$val = InputBox("DRM-Free Search", "Enter some title text to find.", $title, "", 300, 130, Default, Default, 0, $ListGUI)
						If $val <> "" Then
							GUICtrlSetBkColor($Input_find, $COLOR_RED)
							GUICtrlSetData($Input_find, "Searching...")
							$read = FileRead($freefle)
							If $read <> "" Then
								$titles = StringSplit($read, @CRLF & "[", 1)
								For $t = 1 To $titles[0]
									$text = $titles[$t]
									$text = StringSplit($text, "]", 1)
									$notes = $text[2]
									$notes = StringReplace($notes, "drm-free=1", "")
									$notes = StringReplace($notes, "notes=", "")
									$notes = StringStripWS($notes, 3)
									$text = $text[1]
									If $t = 1 Then $text = StringTrimLeft($text, 1)
									;MsgBox(262192, "Title", "'" & $text & "'" & @LF & "'" & $val & "'", 0, $ListGUI)
									;If $t = 4 Then ExitLoop
									If StringInStr($text, $val) > 0 Then
										$ans = MsgBox(262195 + 256, "Title Results", "Found = " & $text & @LF & @LF & "Notes = " & $notes & @LF _
											& @LF & "YES = Copy title to clipboard." _
											& @LF & "NO = Continue Search." _
											& @LF & "CANCEL = Abort Search.", 0, $ListGUI)
										If $ans = 6 Then
											ClipPut($text)
										ElseIf $ans = 2 Then
											ExitLoop
										EndIf
									EndIf
								Next
							EndIf
							GUICtrlSetBkColor($Input_find, $CLR_DEFAULT)
							GUICtrlSetData($Input_find, "DRM-Free List")
						EndIf
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
							If $mode = "Epic" Then
								$download = InetGet($listurl & "/gviz/tq?tqx=out:html", $freelist, 0, 0)
							Else
								$download = InetGet($listurl, $freelist, 0, 0)
							EndIf
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
				$pth = FileSelectFolder("Browse to set the destination path", $destfld, 7, "", $ListGUI)
				If Not @error Then
					$destfld = $pth
					If $mode = "Steam" Then
						IniWrite($inifle, "Destination", "path", $destfld)
					ElseIf $mode = "Epic" Then
						IniWrite($inifle, "Epic Destination", "path", $destfld)
					EndIf
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
						$pth = FileSelectFolder("Browse to select a destination path", $destfld, 7, "", $ListGUI)
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
							_FileWriteLog($logfle, "Backup Complete.")
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
								If $split = "none" Then
									$vol = ""
								Else
									$pos = StringInStr($mass, "bytes")
									If $pos = 0 Then
										$pos = StringInStr($mass, "Kb")
										If $pos = 0 Then
											$pos = StringInStr($mass, "Mb")
											If $pos = 0 Then
												$pos = StringInStr($mass, "Gb")
												$size = StringReplace($mass, " Gb", "")
												$size = Number($size)
												$vol = StringReplace($split, " Gb", "")
												$vol = Number($vol)
												If $size > $vol Then $pos = 0
											EndIf
										EndIf
									EndIf
									If $pos > 0 Then
										$vol = ""
									ElseIf $split = "1 Gb" Then
										$vol = " -v1g"
									ElseIf $split = "2 Gb" Then
										$vol = " -v2g"
									ElseIf $split = "3 Gb" Then
										$vol = " -v3g"
									ElseIf $split = "4 Gb" Then
										$vol = " -v4g"
									EndIf
								EndIf
								;$meth = " -m"
								If $compress = "Default" Then
									$comp = ""
								ElseIf $compress = "None" Then
									$comp = " -mx0"
								ElseIf $compress = "Fastest" Then
									$comp = " -mx=1"
								ElseIf $compress = "Fast" Then
									$comp = " -mx=3"
								ElseIf $compress = "Normal" Then
									$comp = " -mx=5"
								ElseIf $compress = "Maximum" Then
									$comp = " -mx=7"
								ElseIf $compress = "Ultra" Then
									$comp = " -mx=9"
								EndIf
								;$meth = $meth & $comp
								;$meth = $meth & "-mmt=" & $thread
								If FileExists($zipfold) Then
									If $manner = 1 Then
										_FileCreate($resfile)
									ElseIf $manner = 2 Then
										_FileCreate($timefile)
										$done = ""
										FileWriteLine($timefile, "[Zipping]")
										$process = "Zipping"
									EndIf
									$pos = StringInStr($7zip, "\", 0, -1)
									$zipfld = StringLeft($7zip, $pos - 1)
									FileChangeDir($zipfld)
									$exefile = $zipfold & "\" & $title & ".exe"
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
										;RunWait(@ComSpec & " /c " & '7z.exe a "' & $zipfile & '" "' & $gamefold & '" -mmt=' & $thread & $comp & $vol & ' && pause', "")
										If $manner = 1 Then
											RunWait(@ComSpec & " /c " & 'echo  7-Zip && 7z.exe a "' & $zipfile & '" "' & $gamefold & '" -mmt=' & $thread & $comp & $vol & ' -bsp2 >"' & $resfile & '"', "")
											_FileWriteLog($logfle, "Backup Complete.")
											If FileExists($resfile) Then ShellExecute($resfile)
										ElseIf $manner = 2 Then
											AdlibRegister("CheckIfComplete", 1000)
											RunWait(@ComSpec & " /c " & '7z.exe a "' & $zipfile & '" "' & $gamefold & '" -mmt=' & $thread & $comp & $vol & ' && echo done=1 >>"' & $timefile & '" && pause', "")
											If $done = "" Then
												AdlibUnRegister("CheckIfComplete")
												_FileWriteLog($logfle, "Backup Complete.")
											EndIf
										EndIf
										If Not FileExists($exefile) Then
											$volfile = $zipfile & ".001"
											If FileExists($volfile) Then
												If Not FileExists($zipfile & ".002") Then
													FileMove($volfile, $zipfile)
												EndIf
											EndIf
										EndIf
									ElseIf $type = "EXE" Then
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
										;RunWait(@ComSpec & " /c " & '7z.exe a -sfx7z.sfx "' & $exefile & '" "' & $gamefold & '" -mmt=' & $thread & $comp & $vol & ' && pause', "")
										If $manner = 1 Then
											RunWait(@ComSpec & " /c " & 'echo  7-Zip && 7z.exe a -sfx7z.sfx "' & $exefile & '" "' & $gamefold & '" -mmt=' & $thread & $comp & $vol & ' -bsp2 >"' & $resfile & '"', "")
											_FileWriteLog($logfle, "Backup Complete.")
											If FileExists($resfile) Then ShellExecute($resfile)
										ElseIf $manner = 2 Then
											AdlibRegister("CheckIfComplete", 1000)
											RunWait(@ComSpec & " /c " & '7z.exe a -sfx7z.sfx "' & $exefile & '" "' & $gamefold & '" -mmt=' & $thread & $comp & $vol & ' && echo done=1 >>"' & $timefile & '" && pause', "")
											If $done = "" Then
												AdlibUnRegister("CheckIfComplete")
												_FileWriteLog($logfle, "Backup Complete.")
											EndIf
										EndIf
									EndIf
								Else
									MsgBox(262192, "Destination Error", "A folder for the zipped file could not be created!", 0, $ListGUI)
								EndIf
							Else
								SetStateOfControls($GUI_ENABLE)
								ContinueLoop
							EndIf
						EndIf
						;_FileWriteLog($logfle, "Backup Complete.")
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
				If $mode = "Steam" Then
					IniWrite($inifle, "Games Folder", "use_alt", $alternate)
					If $alternate = 1 Then
						;$altpth = IniRead($inifle, "Games Folder", "alt_path", "")
						GUICtrlSetData($Input_path, $altpth)
					Else
						GetLocalSteamGamesFolder()
						GUICtrlSetData($Input_path, $gamesfld)
					EndIf
				Else
					IniWrite($inifle, "Epic Games Folder", "use_alt", $alternate)
					If $alternate = 1 Then
						GUICtrlSetData($Input_path, $altpth)
					Else
						GetLocalEpicGamesFolder()
						GUICtrlSetData($Input_path, $gamesfld)
					EndIf
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
					If $other = "Store" Then
						$link = StringReplace($link, "https://steamcommunity.com", "https://store.steampowered.com")
					Else
						If StringInStr($link, "www.epicgames.com") > 0 Then
							$link = StringReplace($link, "https://www.epicgames.com/store/en-US/p/", "https://www.igdb.com/games/")
							$link = StringReplace($link, "--", "-")
						EndIf
						GUICtrlSetState($Button_image, $GUI_ENABLE)
						GUICtrlSetState($Input_image, $GUI_ENABLE)
						GUICtrlSetState($Button_save, $GUI_ENABLE)
						GUICtrlSetState($Button_fix, $GUI_ENABLE)
					EndIf
				Else
					$store = 4
					If $other = "Store" Then
						$link = StringReplace($link, "https://store.steampowered.com", "https://steamcommunity.com")
					Else
						;$link = StringReplace($link, "https://www.igdb.com/games/", "https://www.epicgames.com/store/en-US/p/")
						$link = StringLower($title)
						LinkReplacements()
						$link = "https://www.epicgames.com/store/en-US/p/" & $link
						GUICtrlSetState($Button_image, $GUI_DISABLE)
						GUICtrlSetState($Input_image, $GUI_DISABLE)
						GUICtrlSetState($Button_save, $GUI_DISABLE)
						GUICtrlSetState($Button_fix, $GUI_DISABLE)
					EndIf
				EndIf
				GUICtrlSetData($Input_link, $link)
				IniWrite($inifle, "Link Type", "store", $store)
			Case $msg = $Checkbox_find
				; Search for DRM-Free from selected
				$find = GUICtrlRead($Input_find)
				If GUICtrlRead($Checkbox_find) = $GUI_CHECKED Then
					$find = "DRM-Free"
					GUICtrlSetTip($Checkbox_find, "Search for DRM-Free from selected!")
				ElseIf GUICtrlRead($Checkbox_find) = $GUI_UNCHECKED Then
					$find = StringReplace($find, "DRM-Free List", "")
					$find = StringReplace($find, "DRM-Free", "")
					GUICtrlSetTip($Checkbox_find, "Search for DRM-Free from selected!")
				Else
					$find = "DRM-Free List"
					GUICtrlSetTip($Checkbox_find, "Search for specified in the DRM-Free list!")
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
				If $mode = "Steam" Then
					IniWrite($inifle, "Destination", "query", $dest)
				Else
					IniWrite($inifle, "Epic Destination", "query", $dest)
				EndIf
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
				$appname = ""
				$gameID = ""
				$link = ""
				$image = ""
				$entry = GUICtrlRead($List_games)
				If $entry <> "" Then
					$entry = StringReplace($entry, $tabs, "|", 1)
					$entry = StringReplace($entry, @TAB, "|")
					$entry = StringSplit($entry, "|", 1)
					$title = $entry[1]
					$title = StringStripWS($title, 4)
					If StringInStr($title, " - DLC - ") > 0 Then
						$title = StringReplace($title, " - DLC - ", " - ")
					EndIf
					$val = IniRead($freefle, $title, "drm-free", "")
					If $val = "" Then
						; Check for possible title alternatives.
						$alias = CharacterReplacements($title)
						If $mode = "Epic" Then
							If $entry[0] > 2 Then
								$appname = $entry[2]
								$val = IniRead($gamesini, $appname, "title", "")
								$appname = ""
							Else
								$val = IniRead($gamesini, $alias, "title", "")
							EndIf
							If $val <> "" Then
								$alias = $val
								$val = IniRead($freefle, $alias, "drm-free", "")
							EndIf
						EndIf
						If $val = "" Then
							; An option that checks for the title when ':' added after each word in turn.
							$words = StringSplit($alias, " ", 1)
							If $words[0] > 1 Then
								$alias = $words[1] & ": " & $words[2]
								If $words[0] > 2 Then
									For $w = 3 To $words[0]
										$alias = $alias & " " & $words[$w]
									Next
								EndIf
								$val = IniRead($freefle, $alias, "drm-free", "")
								If $val = "" And $words[0] > 2 Then
									$alias = $words[1] & " " & $words[2] & ": " & $words[3]
									If $words[0] > 3 Then
										For $w = 4 To $words[0]
											$alias = $alias & " " & $words[$w]
										Next
									EndIf
									$val = IniRead($freefle, $alias, "drm-free", "")
									If $val = "" And $words[0] > 3 Then
										$alias = $words[1] & " " & $words[2] & " " & $words[3] & ": " & $words[4]
										If $words[0] > 4 Then
											For $w = 5 To $words[0]
												$alias = $alias & " " & $words[$w]
											Next
										EndIf
										$val = IniRead($freefle, $alias, "drm-free", "")
										If $val = "" And $words[0] > 4 Then
											$alias = $words[1] & " " & $words[2] & " " & $words[3] & " " & $words[4] & ": " & $words[5]
											If $words[0] > 5 Then
												For $w = 6 To $words[0]
													$alias = $alias & " " & $words[$w]
												Next
											EndIf
											$val = IniRead($freefle, $alias, "drm-free", "")
										EndIf
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
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
					$title = CharacterReplacements($title)
					If $entry[0] > 1 Then
						If $mode = "Steam" Then
							$gameID = $entry[2]
							If $entry[0] > 2 Then
								$link = $entry[3]
								If $entry[0] > 3 Then
									$image = $entry[4]
								EndIf
							EndIf
						ElseIf $mode = "Epic" Then
							If $entry[0] > 1 Then
								If $entry[0] > 2 Then
									$appname = $entry[2]
									If $appname <> "" Then
										$link = IniRead($gamesini, $appname, "link", "")
										If $link = "" Then $link = $entry[3]
										$image = IniRead($gamesini, $appname, "image", "")
									EndIf
								Else
									$appname = ""
									$link = IniRead($gamesini, $title, "link", "")
									If $link = "" Then $link = $entry[2]
									$image = IniRead($gamesini, $title, "image", "")
								EndIf
							EndIf
						EndIf
					EndIf
					$ind = _GUICtrlListBox_GetCurSel($List_games)
					$num = $ind + 1
					GUICtrlSetData($Input_index, $num)
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
						If $mode = "Steam" Then
							If StringRight($title, 11) = " Soundtrack" Then
								$gamefold = $musicfld & "\" & $title
							EndIf
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
					If $mode = "Steam" Then
						GUICtrlSetData($Input_id, $gameID)
						If $store = 1 And $link <> "" Then
							$link = StringReplace($link, "https://steamcommunity.com", "https://store.steampowered.com")
						EndIf
					ElseIf $mode = "Epic" Then
						GUICtrlSetData($Input_id, $appname)
						If $store = 1 And $link <> "" Then
							If StringInStr($link, "www.epicgames.com") > 0 Then
								$link = StringReplace($link, "https://www.epicgames.com/store/en-US/p/", "https://www.igdb.com/games/")
								$link = StringReplace($link, "--", "-")
							EndIf
						EndIf
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

Func InstallOptionsEtcGUI()
	Local $Button_close, $Button_download, $Button_inform, $Button_install, $Button_installed, $Button_uninstall, $Button_update
	Local $Button_verify, $Checkbox_dlc, $Checkbox_updates, $Group_install
	Local $Button_import, $Button_repair
	;
	Local $close, $exStyle, $height, $InstallOptionsGUI, $left, $style, $top, $width, $winpos
	;
	$exStyle = $WS_EX_TOPMOST
	$style = $WS_OVERLAPPED + $WS_CAPTION + $WS_SYSMENU + $WS_VISIBLE + $WS_CLIPSIBLINGS + $WS_MINIMIZEBOX
	$width = 370
	$height = 220
	$left = IniRead($inifle, "Install Options Window", "left", @DesktopWidth - $width - 25)
	$top = IniRead($inifle, "Install Options Window", "top", @DesktopHeight - $height - 60)
	$InstallOptionsGUI = GUICreate("Install Options Etc - " & $mode, $width, $height, $left, $top, $style, $exStyle, $ListGUI)
	GUISetBkColor($COLOR_SKYBLUE, $InstallOptionsGUI)
	;
	; CONTROLS
	$Group_install = GUICtrlCreateGroup("Install Related", 10, 5, 230, 202)
	$Button_install = GUICtrlCreateButton("DOWNLOAD" & @LF & "INSTALL", 20, 25, 100, 50, $BS_MULTILINE)
	GUICtrlSetFont($Button_install, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_install, "Download & Install the selected game!")
	$Button_verify = GUICtrlCreateButton("VERIFY" & @LF & "INSTALL", 130, 25, 100, 50, $BS_MULTILINE)
	GUICtrlSetFont($Button_verify, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_verify, "Verify the selected installed game!")
	$Button_update = GUICtrlCreateButton("UPDATE" & @LF & "INSTALL", 20, 85, 100, 50, $BS_MULTILINE)
	GUICtrlSetFont($Button_update, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_update, "Update the selected installed game!")
	$Button_uninstall = GUICtrlCreateButton("UNINSTALL", 130, 85, 100, 50)
	GUICtrlSetFont($Button_uninstall, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_uninstall, "Uninstall the selected installed game!")
	$Button_import = GUICtrlCreateButton("IMPORT" & @LF & "GAME", 20, 145, 100, 50, $BS_MULTILINE)
	GUICtrlSetFont($Button_import, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_import, "Import the selected installed game!")
	$Button_repair = GUICtrlCreateButton("REPAIR" & @LF & "INSTALL", 130, 145, 100, 50, $BS_MULTILINE)
	GUICtrlSetFont($Button_repair, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_repair, "Repair the selected installed game!")
	;
	$Button_download = GUICtrlCreateButton("DOWNLOAD" & @LF & "ONLY", 250, 10, 110, 43, $BS_MULTILINE)
	GUICtrlSetFont($Button_download, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_download, "Download the selected game (no Install)!")
	;
	$Checkbox_dlc = GUICtrlCreateCheckbox("Include all DLC", 260, 60, 100, 20)
	GUICtrlSetTip($Checkbox_dlc, "Also install all DLC for the game!")
	;
	$Button_installed = GUICtrlCreateButton("LIST ALL" & @LF & "INSTALLED", 250, 85, 110, 44, $BS_MULTILINE)
	GUICtrlSetFont($Button_installed, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_installed, "List all installed games)!")
	$Checkbox_updates = GUICtrlCreateCheckbox("Check for Updates", 252, 130, 110, 20)
	GUICtrlSetTip($Checkbox_updates, "Check for Updates for installed games!")
	;
	$Button_inform = GUICtrlCreateButton("INFO", 250, 158, 50, 50, $BS_ICON)
	GUICtrlSetTip($Button_inform, "Install Options Information!")
	;
	$Button_close = GUICtrlCreateButton("EXIT", 310, 158, 50, 50, $BS_ICON)
	GUICtrlSetTip($Button_close, "Exit or Close the window!")
	;
	;
	; SETTINGS
	GUICtrlSetImage($Button_inform, $user32, $icoI, 1)
	GUICtrlSetImage($Button_close, $user32, $icoX, 1)
	;
	GUICtrlSetState($Checkbox_dlc, $alldlc)
	GUICtrlSetState($Checkbox_updates, $updates)
	;
	GUICtrlSetState($Button_import, $GUI_DISABLE)
	;GUICtrlSetState($Button_repair, $GUI_DISABLE)
	;
	$close = ""
	$process = ""

	GUISetState(@SW_SHOW)
	While 1
		$msg = GUIGetMsg()
        Select
			Case $msg = $GUI_EVENT_CLOSE Or $msg = $Button_close Or $close = 1
				; Exit or Close the program
				$winpos = WinGetPos($InstallOptionsGUI, "")
				$left = $winpos[0]
				If $left < 0 Then
					$left = 2
				ElseIf $left > @DesktopWidth - $width Then
					$left = @DesktopWidth - $width - 25
				EndIf
				IniWrite($inifle, "Install Options Window", "left", $left)
				$top = $winpos[1]
				If $top < 0 Then
					$top = 2
				ElseIf $top > @DesktopHeight - $height - 30 Then
					$top = @DesktopHeight - $height - 60
				EndIf
				IniWrite($inifle, "Install Options Window", "top", $top)
				;
				GUIDelete($InstallOptionsGUI)
				ExitLoop
			Case $msg = $Button_verify
				; Validate the selected installed game
				$process = "verify"
				$close = 1
			Case $msg = $Button_update
				; Update the selected installed game
				$process = "update"
				$close = 1
			Case $msg = $Button_uninstall
				; Uninstall the selected installed game
				$close = 1
			Case $msg = $Button_repair
				; Repair the selected installed gam
				$process = "repair"
				$close = 1
			Case $msg = $Button_installed
				; Download & Install the selected game
				$process = "installed"
				$close = 1
			Case $msg = $Button_install
				; Download & Install the selected game
				$process = "install"
				$close = 1
			Case $msg = $Button_inform
				; Install Options Information
				MsgBox(262208, "Install Options Information", _
					"The DOWNLOAD ONLY button does not create an 'install' entry" & @LF & _
					"in the Epic manifest, so cannot be used with other 'Install" & @LF & _
					"Related' processes." & @LF & @LF & _
					"Most buttons will immediately close the 'Install Options'" & @LF & _
					"window and attempt that chosen process.", 0, $InstallOptionsGUI)
			Case $msg = $Button_download
				; Download the selected game (no Install)
				$process = "download"
				$close = 1
			Case $msg = $Checkbox_updates
				; Check for Updates for installed games
				If GUICtrlRead($Checkbox_updates) = $GUI_CHECKED Then
					$updates = 1
				Else
					$updates = 4
				EndIf
			Case $msg = $Checkbox_dlc
				; Also install all DLC for the game
				If GUICtrlRead($Checkbox_dlc) = $GUI_CHECKED Then
					$alldlc = 1
				Else
					$alldlc = 4
				EndIf
				IniWrite($inifle, "Epic Install", "all_dlc", $alldlc)
			Case Else
		EndSelect
	WEnd
EndFunc ;=> InstallOptionsEtcGUI

Func SetupGUI()
	Local $Combo_comp, $Combo_method, $Combo_split, $Combo_thread, $Label_comp, $Label_info, $Label_method, $Label_split, $Label_thread
	;
	Local $compact, $exStyle, $info, $methods, $SetupGUI, $splits, $style, $threads
	;
	$exStyle = $WS_EX_TOPMOST
	$style = $WS_OVERLAPPED + $WS_CAPTION + $WS_SYSMENU + $WS_VISIBLE + $WS_CLIPSIBLINGS
	$SetupGUI = GUICreate("7-Zip Options", 180, 195, Default, Default, $style, $exStyle, $ListGUI)
	;
	; CONTROLS
	$Label_split = GUICtrlCreateLabel("FILE SPLITTING", 10, 10, 90, 21, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetFont($Label_split, 7, 400, 0, "Small Fonts")
	GUICtrlSetBkColor($Label_split, $COLOR_BLUE)
	GUICtrlSetColor($Label_split, $COLOR_WHITE)
	$Combo_split = GUICtrlCreateCombo("", 100, 10, 50, 21)
	GUICtrlSetTip($Combo_split, "Select the size to split at!")
	$Label_comp = GUICtrlCreateLabel("COMPRESSION", 10, 40, 90, 21, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetFont($Label_comp, 7, 400, 0, "Small Fonts")
	GUICtrlSetBkColor($Label_comp, $COLOR_BLUE)
	GUICtrlSetColor($Label_comp, $COLOR_WHITE)
	$Combo_comp = GUICtrlCreateCombo("", 100, 40, 70, 21)
	GUICtrlSetTip($Combo_comp, "Select the level of compression!")
	$Label_thread = GUICtrlCreateLabel("MULTI-THREAD", 10, 70, 90, 21, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetFont($Label_thread, 7, 400, 0, "Small Fonts")
	GUICtrlSetBkColor($Label_thread, $COLOR_BLUE)
	GUICtrlSetColor($Label_thread, $COLOR_WHITE)
	$Combo_thread = GUICtrlCreateCombo("", 100, 70, 40, 21)
	GUICtrlSetTip($Combo_thread, "Set whether to use multi-threading!")
	$Label_info = GUICtrlCreateLabel("", 10, 100, 160, 55, $SS_CENTER)
	;
	$Label_method = GUICtrlCreateLabel("LOGGING METHOD", 10, 165, 105, 21, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetFont($Label_method, 7, 400, 0, "Small Fonts")
	GUICtrlSetBkColor($Label_method, $COLOR_GREEN)
	GUICtrlSetColor($Label_method, $COLOR_WHITE)
	$Combo_method = GUICtrlCreateCombo("", 115, 165, 35, 21)
	GUICtrlSetTip($Combo_method, "Method of reporting finished in Log file!")
	;
	; SETTINGS
	$splits = "1 Gb|2 Gb|3 Gb|4 Gb|none"
	GUICtrlSetData($Combo_split, $splits, $split)
	$compact = "Default|None|Fastest|Fast|Normal|Maximum|Ultra"
	GUICtrlSetData($Combo_comp, $compact, $compress)
	$threads = "off|on"
	GUICtrlSetData($Combo_thread, $threads, $thread)
	;
	$info = "Default = Normal Compression" & @LF _
		& @LF & "If source size is less than split" _
		& @LF & "size, only one file is created."
	GUICtrlSetData($Label_info, $info)
	;
	$methods = "1|2"
	GUICtrlSetData($Combo_method, $methods, $manner)

	GUISetState(@SW_SHOW)
	While 1
		$msg = GUIGetMsg()
        Select
			Case $msg = $GUI_EVENT_CLOSE
				; Exit or Close the window
				GUIDelete($SetupGUI)
				ExitLoop
			Case $msg = $Combo_thread
				; Set whether to use multi-threading
				$thread = GUICtrlRead($Combo_thread)
				IniWrite($inifle, "7-Zip", "multithread", $thread)
			Case $msg = $Combo_split
				; Select the size to split at
				$split = GUICtrlRead($Combo_split)
				IniWrite($inifle, "7-Zip", "split", $split)
			Case $msg = $Combo_method
				; Method of reporting finished in Log file
				$manner = GUICtrlRead($Combo_method)
				IniWrite($inifle, "Zip Logging", "method", $manner)
			Case $msg = $Combo_comp
				; Select the level of compression
				$compress = GUICtrlRead($Combo_comp)
				IniWrite($inifle, "7-Zip", "compression", $compress)
			Case Else
		EndSelect
	WEnd
EndFunc ;=> SetupGUI


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
	;
	$text = StringReplace($text, "!", "")
	$text = StringReplace($text, "®", "")
	$text = StringReplace($text, "™", "")
	Return $text
EndFunc ;=> CharacterReplacements

Func CheckIfComplete()
	$done = IniRead($timefile, $process, "done", "")
	If $done = 1 Then
		$process = _StringProper($process)
		_FileWriteLog($logfle, $process & " Complete.")
		AdlibUnRegister("CheckIfComplete")
	EndIf
EndFunc ;=> CheckIfComplete

Func GetLocalEpicGamesFolder()
	$epicfold = @ProgramFilesDir & "\Epic Games"
	$gamesfld = $epicfold
EndFunc ;=> GetLocalEpicGamesFolder

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

Func LinkReplacements()
	Local $after
	If StringInStr($link, "://www.igdb.com") > 0 Then
		$link = StringSplit($link, "://www.igdb.com", 1)
		$after = $link[2]
		$link = $link[1]
		$link = $link & "://www.igdb.com"
	ElseIf StringInStr($link, "://www.epicgames.com") > 0 Then
		$link = StringSplit($link, "://www.epicgames.com", 1)
		$after = $link[2]
		$link = $link[1]
		$link = $link & "://www.epicgames.com"
	Else
		$after = $link
		$link = ""
	EndIf
	$after = StringReplace($after, ":", "-")
	$after = StringReplace($after, " - ", "-")
	$after = StringReplace($after, ">", " ")
	$after = StringReplace($after, "_", " ")
	$after = StringStripWS($after, 3)
	$after = StringReplace($after, " ", "-")
	$after = StringReplace($after, '"', '')
	$after = StringReplace($after, "'", "")
	$after = StringReplace($after, ",", "")
	$after = StringReplace($after, ".", "")
	$after = StringReplace($after, "!", "")
	$after = StringReplace($after, "?", "")
	$after = StringReplace($after, "®", "")
	$after = StringReplace($after, "™", "")
	$after = StringReplace($after, "&amp;", "and")
	$after = StringStripWS($after, 4)
	$link = $link & $after
EndFunc ;=> LinkReplacements

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
		ElseIf $drmfree = "Google Docs" Then
			$entries = StringSplit($read, '</tr>', 1)
			If $entries[0] > 2 Then
				_FileCreate($freefle3)
				For $e = 3 To $entries[0]
					$entry = $entries[$e]
					$entry = StringSplit($entry, '<td>', 1)
					If $entry[0] > 5 Then
						$notes = $entry[6]
						$notes = StringSplit($notes, '</td>', 1)
						$notes = $notes[1]
						$notes = StringReplace($notes, "&nbsp;", " ")
						$notes = StringStripWS($notes, 7)
						$notes = StringReplace($notes, "&#39;", "'")
						$notes = StringReplace($notes, "&quot;", "'")
						$notes = StringReplace($notes, "&amp;", "&")
					Else
						$notes = ""
					EndIf
					If $entry[0] > 1 Then
						$entry = $entry[2]
						$game = StringSplit($entry, '</td>', 1)
						$game = $game[1]
						If $game <> "" Then
							$game = StringReplace($game, "&#39;", "'")
							$game = StringReplace($game, "&quot;", "'")
							$game = StringReplace($game, "&amp;", "&")
							If $games = "" Then
								$games = "[" & $game & "]" & @CRLF & "drm-free=1"
							Else
								$games = $games & @CRLF & "[" & $game & "]" & @CRLF & "drm-free=1"
							EndIf
							If $notes <> "" Then
								$games = $games & @CRLF & "notes=" & $notes
							EndIf
						EndIf
					EndIf
				Next
			EndIf
			FileWrite($freefle3, $games)
			$entries = $entries[0] - 2
			MsgBox(262144, "DRM-Free Games", $entries & " found.", 0, $ListGUI)
		EndIf
	EndIf
	_FileWriteLog($logfle, "Parsed the DRM-Free list.")
EndFunc ;=> ParseTheDRMFreeList

Func ParseTheGamesList()
	Local $alias
	$array = ""
	_FileReadToArray($gameslist, $games, 1)
	For $g = 1 To $games[0]
		$line = $games[$g]
		If StringLeft($line, 3) = " * " Then
			$title = StringSplit($line, "(App name:", 1)
			$appname = $title[2]
			$title = $title[1]
			$title = StringTrimLeft($title, 3)
			$title = StringStripWS($title, 3)
			If $title <> "" Then
				$link = StringLower($title)
				LinkReplacements()
				$link = "https://www.epicgames.com/store/en-US/p/" & $link
				$appname = StringSplit($appname, "|", 1)
				$appname = $appname[1]
				$appname = StringStripWS($appname, 3)
				$game = $title & " --- " & $appname & " --- " & $link
				If $array = "" Then
					$array = $game
				Else
					$array = $array & "|" & $game
				EndIf
			EndIf
			$alias = $title
			If $appname <> "" Then
				If $fixed = "" Then
					$title = CharacterReplacements($title)
					$title = StringStripWS($title, 7)
					$val = IniRead($gamesini, $title, "link", "")
					If $val = "" Then
						$val = IniRead($gamesini, $title, "image", "")
					EndIf
					If $val <> "" Then
						IniRenameSection($gamesini, $title, $appname)
					EndIf
				EndIf
			EndIf
		ElseIf StringLeft($line, 4) = "  + " Then
			$dlc = StringSplit($line, "(App name:", 1)
			$appname = $dlc[2]
			$dlc = $dlc[1]
			$dlc = StringTrimLeft($dlc, 3)
			$dlc = StringStripWS($dlc, 3)
			If $dlc <> "" Then
				;$title = $title & "-" & $dlc
				;$link = StringLower($title)
				$title = $alias & " - DLC - " & $dlc
				$link = StringLower($dlc)
				LinkReplacements()
				$link = "https://www.epicgames.com/store/en-US/p/" & $link
				$appname = StringSplit($appname, "|", 1)
				$appname = $appname[1]
				$appname = StringStripWS($appname, 3)
				$game = $title & " --- " & $appname & " --- " & $link
				If $array = "" Then
					$array = $game
				Else
					$array = $array & "|" & $game
				EndIf
			EndIf
		EndIf
	Next
	If $array <> "" Then
		$array = StringSplit($array, "|", 1)
	EndIf
EndFunc ;=> ParseTheGamesList

Func ParseTheHTMLGamesList()
	Local $addtit
	If FileExists($savpth) Then
		$lines = _FileCountLines($savpth)
		If $lines > 10 Then
			$read = FileRead($savpth)
			If $read <> "" Then
				;$array = ""
				If FileExists($titfle) Then
					$addtit = 1
					_FileReadToArray($titfle, $array, 1)
					$array = _ArrayToString($array, "|", 1)
				Else
					$addtit = ""
					$array = ""
				EndIf
				;MsgBox(262144, "$array", $array)
				$games = StringSplit($read, 'data-orderid="', 1)
				For $g = 2 To $games[0]
					$entry = $games[$g]
					;MsgBox(262144, "$entry", $entry)
					$gameID = StringSplit($entry, '">', 1)
					$gameID = $gameID[1]
					;MsgBox(262144, "$gameID", $gameID)
					$title = StringSplit($entry, "</span></button>", 1)
					$title = $title[1]
					;MsgBox(262144, "$title", $title)
					$title = StringSplit($title, "<span>", 1)
					$title = $title[$title[0]]
					$title = StringReplace($title, "&gt;", ">")
					$title = StringStripWS($title, 7)
					;MsgBox(262144, "$title", $title)
					$link = StringLower($title)
					LinkReplacements()
					$link = "https://www.epicgames.com/store/en-US/p/" & $link
					;https://cdn1.epicgames.com/salesEvent/salesEvent/EGS_PCBuildingSimulator_TheIrregularCorporation_S1_2560x1440-48cc12f45bf3eaaaae79cba6594b06d8?h=480&amp;resize=1&amp;w=854
					;<meta content="https://images.igdb.com/igdb/image/upload/t_cover_big/co3hih.jpg"
					;$game = $title & " --- " & $gameID & " --- " & $link
					$game = $title & " --- " & $link
					If $array = "" Then
						$array = $game
					Else
						$array = $array & "|" & $game
					EndIf
				Next
				;MsgBox(262144, "$array", $array)
				$games = $games[0] - 1
				;MsgBox(262144, "Games", $games & " found.")
				$array = StringSplit($array, "|", 1)
				$array = _ArrayUnique($array, 0, 1)
				_ArraySort($array, 0, 1)
				If $display = 1 Then
					_ArrayDisplay($array, "Epic Games Owned", "", 0, "|", "Title --- Link")
				EndIf
				If $addtit = "" Then _FileCreate($titfle)
				_FileWriteFromArray($titfle, $array, 1)
				If $ping > 0 Then _FileWriteLog($logfle, "Extracted game details from HTML file.")
			EndIf
		EndIf
	EndIf
EndFunc ;=> ParseTheHTMLGamesList

Func ParseTheXMLGamesList()
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
EndFunc ;=> ParseTheXMLGamesList

Func PopulateTheList()
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
EndFunc ;=> PopulateTheList

Func SetStateOfControls($state)
	GUICtrlSetState($List_games, $state)
	GUICtrlSetState($Input_index, $state)
	GUICtrlSetState($Input_size, $state)
	GUICtrlSetState($Checkbox_find, $state)
	GUICtrlSetState($Button_find, $state)
	;
	GUICtrlSetState($Checkbox_ontop, $state)
	GUICtrlSetState($Button_updater, $state)
	GUICtrlSetState($Button_more, $state)
	GUICtrlSetState($Button_fold, $state)
	GUICtrlSetState($Button_log, $state)
	GUICtrlSetState($Button_info, $state)
	GUICtrlSetState($Button_exit, $state)
	;
	GUICtrlSetState($Button_title, $state)
	GUICtrlSetState($Input_title, $state)
	GUICtrlSetState($Button_link, $state)
	GUICtrlSetState($Input_link, $state)
	GUICtrlSetState($Button_list, $state)
	GUICtrlSetState($Input_list, $state)
	If $mode = "Steam" Then
		GUICtrlSetState($Button_id, $state)
		GUICtrlSetState($Input_id, $state)
		GUICtrlSetState($Button_image, $state)
		GUICtrlSetState($Input_image, $state)
		GUICtrlSetState($Button_save, $state)
		GUICtrlSetState($Combo_list, $state)
		GUICtrlSetState($Button_options, $state)
	ElseIf $mode = "Epic" Then
		If $other = "IGDB" And $store = 1 Then
			GUICtrlSetState($Button_image, $state)
			GUICtrlSetState($Input_image, $state)
			GUICtrlSetState($Button_fix, $state)
			GUICtrlSetState($Button_save, $state)
		EndIf
		If $epic <> 3 Then
			GUICtrlSetState($Button_inf, $state)
			GUICtrlSetState($Button_id, $state)
			GUICtrlSetState($Input_id, $state)
			If $epic = 1 Then GUICtrlSetState($Button_options, $state)
		EndIf
		;MsgBox(262144, "$epic", $epic)
	EndIf
	GUICtrlSetState($Checkbox_link, $state)
	;
	GUICtrlSetState($Button_down, $state)
	GUICtrlSetState($Button_backup, $state)
	GUICtrlSetState($Combo_backup, $state)
	;
	If $buttxt = "More" Then
		GUICtrlSetState($Button_opts, $state)
		GUICtrlSetState($Input_zip, $state)
		GUICtrlSetState($Button_zip, $state)
		If $mode = "Steam" Then
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
		EndIf
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
		GUICtrlSetState($Button_notes, $state)
		If $tera = 1 Then
			GUICtrlSetState($Input_tera, $state)
			GUICtrlSetState($Button_tera, $state)
		EndIf
		;GUICtrlSetState($Input_tera, $state)
		;GUICtrlSetState($Button_tera, $state)
		GUICtrlSetState($Checkbox_tera, $state)
	EndIf
EndFunc ;=> SetStateOfControls

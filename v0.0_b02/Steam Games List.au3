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
#include <Array.au3>

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
	Local $Button_id, $Button_image, $Button_link, $Button_title, $Group_list, $Input_id, $Input_image, $Input_link, $Input_title, $List_games
	Local $a, $exStyle, $height, $left, $ListGUI, $parent, $style, $tabs, $top, $width
	$exStyle = -1
	$height = 480
	$left = -1
	$parent = 0
	$style = -1
	$top = -1
	$width = 470
	$ListGUI = GUICreate("Games Owned At Steam", $width, $height, $left, $top, $style, $exStyle, $parent)
	;, $Label_id, $Label_image, $Label_link, $Label_title
	; CONTROLS
	$Group_list = GUICtrlCreateGroup("Games", 5, 5, 460, 390)
	$List_games = GUICtrlCreateList("", 10, 20, 450, 370, $GUI_SS_DEFAULT_LIST + $LBS_USETABSTOPS)
	GUICtrlSetTip($List_games, "Select a game!")
	;$Label_title = GUICtrlCreateLabel("TITLE", 10, 400, 45, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	;GUICtrlSetBkColor($Label_title, $COLOR_BLUE)
	;GUICtrlSetColor($Label_title, $COLOR_WHITE)
	$Button_title = GUICtrlCreateButton("TITLE", 10, 400, 45, 20)
	GUICtrlSetFont($Button_title, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_title, "Click to copy title to clipboard!")
	$Input_title = GUICtrlCreateInput("", 55, 400, 405, 20)
	;$Label_id = GUICtrlCreateLabel("ID", 10, 425, 25, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	;GUICtrlSetBkColor($Label_id, $COLOR_BLACK)
	;GUICtrlSetColor($Label_id, $COLOR_WHITE)
	$Button_id = GUICtrlCreateButton("ID", 10, 425, 30, 20)
	GUICtrlSetFont($Button_id, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_id, "Click to copy ID to clipboard!")
	$Input_id = GUICtrlCreateInput("", 40, 425, 70, 20)
	;$Label_link = GUICtrlCreateLabel("URL", 115, 425, 35, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	;GUICtrlSetBkColor($Label_link, $COLOR_GREEN)
	;GUICtrlSetColor($Label_link, $COLOR_WHITE)
	$Button_link = GUICtrlCreateButton("URL", 120, 425, 40, 20)
	GUICtrlSetFont($Button_link, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_link, "Click to go to the game web page!")
	$Input_link = GUICtrlCreateInput("", 160, 425, 300, 20)
	;$Label_image = GUICtrlCreateLabel("ICON", 10, 450, 40, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	;GUICtrlSetBkColor($Label_image, $COLOR_YELLOW)
	;GUICtrlSetColor($Label_image, $COLOR_BLACK)
	$Button_image = GUICtrlCreateButton("ICON", 10, 450, 45, 20)
	GUICtrlSetFont($Button_image, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_image, "Click to show the online image in your browser!")
	$Input_image = GUICtrlCreateInput("", 55, 450, 405, 20)
	;
	; SETTINGS
	$tabs = @TAB & @TAB & @TAB & @TAB & @TAB & @TAB & @TAB & @TAB & @TAB
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

	GUISetState(@SW_SHOW)
	While 1
		$msg = GUIGetMsg()
        Select
			Case $msg = $GUI_EVENT_CLOSE
				; Exit or Close the program
				GUIDelete($ListGUI)
				ExitLoop
			Case $msg = $Button_title
				; Click to copy title to clipboard
				$title = GUICtrlRead($Input_title)
				ClipPut($title)
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
				EndIf
				GUICtrlSetData($Input_title, $title)
				GUICtrlSetData($Input_id, $gameID)
				GUICtrlSetData($Input_link, $link)
				GUICtrlSetData($Input_image, $image)
				GUICtrlSetState($Input_title, $GUI_FOCUS)
				Send("{HOME}")
				GUICtrlSetState($List_games, $GUI_FOCUS)
			Case Else
		EndSelect
	WEnd
EndFunc

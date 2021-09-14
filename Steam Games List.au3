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
#include <Array.au3>

_Singleton("steam-games-list-timboli")

Global $array, $download, $entry, $g, $game, $gameID, $games, $image, $inifle, $lines, $link, $read, $result, $title, $URL, $userID, $xmlfle

$inifle = @ScriptDir & "\Settings.ini"
$xmlfle = @ScriptDir & "\Gameslist.xml"

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
			;$games = $games[0] - 1
			;MsgBox(262144, "Games", $games & " found.")
			$array = StringSplit($array, "|", 1)
			_ArraySort($array, 0, 1)
			_ArrayDisplay($array, "Steam Games Owned", "", 0, "|", "Title --- ID --- Link --- Icon")
		EndIf
    EndIf
EndIf

Exit

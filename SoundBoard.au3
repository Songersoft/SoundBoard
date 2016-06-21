#RequireAdmin;needed to work in some games.
; I like to close and restart a lot, this saves me steps
HotKeySet('^{PAUSE}', '_hotkey_exit')

#include "Misc.au3"
#include "Array.au3"
#include "File.au3"
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "Include\GUIScrollbars_Ex.au3"

; Dock all GUI Control, Don't move or resize if GUI Window Size Changes
Opt("GUIResizeMode", $GUI_DOCKALL)

; Enum gives index specification
Enum $eHotkey_sKey, _
	$eHotkey_sFile, _
	$eHotkey_nStart, _
	$eHotkey_nEnd, _
	$eHotkey_sPlayback_device, _;
	$eHotkey_ctrl, _; GUI Controls only
	$eHotkey_alt, _
	$eHotkey_shift, _
	$eHotkey_win, _
	$eHotkey_browse, _
	$eHotkey_remove

Global $gaHotKeyData[1][5]

Global $gHotkey_control_data_max = $eHotkey_remove + 1

Global $gUrl_send_key_list = "https://www.autoitscript.com/autoit3/docs/functions/Send.htm"

Global $gHotkey_max = 128

Global $gaDropfiles[1]

Global $dragdropinclude, _
	$dragdropincludefilesfolders = $FLTAR_FILES, _
	$dragdropfoldersdeep = 10, _
	$dragdropexclude, _
	$dragdropsystem, _
	$dragdrophidden, _
	$dragdropshowoptions

; To ack GUI Resize Event
Global $gGui_resize = 0
GUIRegisterMsg($WM_SIZE, "_WM_SIZE")

; Drop Files Register
GUIRegisterMsg($WM_DROPFILES, "WM_DROPFILES_FUNC")

LoadIni()

Tray()
Opt("WinTitleMatchMode", -2)
If @OSArch = "x64" Then
	Global $VLC_Path = "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
	Global $VLC_WorkingDir = "C:\Program Files (x86)\VideoLAN\VLC\"
Else
	Global $VLC_Path = "C:\Program Files\VideoLAN\VLC\vlc.exe"
	Global $VLC_WorkingDir = "C:\Program Files\VideoLAN\VLC\"
EndIf
While 1
	Sleep(500);idle to prevent unnecessary work. 10 is the minimal we can set this value to.
WEnd
Func Tray()
	Opt("TrayAutoPause", 0)
	Opt("TrayMenuMode", 2)
	Opt("TrayOnEventMode", 1)
	TrayItemSetOnEvent(TrayCreateItem("Configure"), "ConfigureGUI")
EndFunc   ;==>Tray
Func ConfigureGUI()
	; Setup GUI
	Local $step_y = 65
	Local $button_w = 60, $button_h = 32
	Local $Form1_w = 420, $Form1_h = $button_h * 4, $tiny_margin_more = 5
	; Create GUI
	Local $Form1 = GUICreate(StringTrimRight(@ScriptName, 4)&": Hotkeys", $Form1_w, $Form1_h, -1, -1, BitOR($GUI_SS_DEFAULT_GUI,$WS_SIZEBOX,$WS_THICKFRAME))
	Local $Ok = GUICtrlCreateButton("Ok", $Form1_w - $button_w, 0, $button_w, $button_h)
	Local $Cancel = GUICtrlCreateButton("Cancel", $Form1_w - $button_w, 32, $button_w, $button_h)
	Local $Add = GUICtrlCreateButton("Add", $Form1_w - $button_w, 64, $button_w, $button_h)
	Local $url_send_names_button = GUICtrlCreateButton("Key Names", $Form1_w - $button_w, 96, $button_w, $button_h)
	GUICtrlSetTip($url_send_names_button, 'Launches ' & $gUrl_send_key_list & ' in a browser.')
	GUISetState(); Show Form1
	
	; Make sub scrollable GUI
	Local $aGui_scroll_rect = [0, 0, $Form1_w - $button_w - $tiny_margin_more, $Form1_h - $tiny_margin_more]
 	$hGui_scroll = GUICreate("", $aGui_scroll_rect[2], $aGui_scroll_rect[3], $aGui_scroll_rect[0], $aGui_scroll_rect[1], $WS_POPUP, BitOR($WS_EX_MDICHILD, $WS_EX_ACCEPTFILES), $Form1)
	GUISetBkColor(0xC0C0C0)

	; Intialise for resizing
 	_GUIScrollbars_Generate($hGui_scroll, 0, $gHotkey_max * $step_y)

	GUISetState(); Show hGui_scroll

	;out("admin: "&IsAdmin())
	;If IsAdmin() Then ; Allow to receive this messages if run elevated
	
	;https://www.autoitscript.com/forum/topic/124406-drag-and-drop-with-uac/?do=findComment&comment=864050
		_ChangeWindowMessageFilterEx($hGui_scroll, 0x233, 1) ; $WM_DROPFILES
		_ChangeWindowMessageFilterEx($hGui_scroll, $WM_COPYDATA, 1) ; redundant?
		_ChangeWindowMessageFilterEx($hGui_scroll, 0x0049, 1) ; $WM_COPYGLOBALDATA
	;EndIf

	; aHotkey_control
	Local $aHotKey_control[$gHotkey_max][$gHotkey_control_data_max]

	ConsoleWrite(@CRLF&"Ubound: "&UBound($aHotKey_control))
	ConsoleWrite(@CRLF&"Ubound: "&UBound($aHotKey_control, 2))

	Local $aSymbol = ['^', '!', '+', '#']
	; Display Hotkey Array on GUI
	Local $count = $gaHotKeyData[0][0]; It's a weird fix but it saves me changing more function parameters
	ConsoleWrite("C "&$count)
	$gaHotKeyData[0][0] = 1
	For $i= 1 to $count

		; Unset all hotkeys
		HotKeySet($gaHotKeyData[$i][$eHotkey_sKey])

		; Make hotkey controls for old hotkeys
		AddButton($hGui_scroll, $aHotKey_control)

		; Set the Data

		; Start
		GUICtrlSetData($aHotKey_control[$i][$eHotkey_nStart], $gaHotKeyData[$i][$eHotkey_nStart])
		; End
		GUICtrlSetData($aHotKey_control[$i][$eHotkey_nEnd], $gaHotKeyData[$i][$eHotkey_nEnd])

		; File
		GUICtrlSetData($aHotKey_control[$i][$eHotkey_sFile], $gaHotKeyData[$i][$eHotkey_sFile])

		; Set ToolTip to Path
		GUICtrlSetTip($aHotKey_control[$i][$eHotkey_sFile], "File Launched:"&@CRLF&$gaHotKeyData[$i][$eHotkey_sFile])
		;GUICtrlSetData($aHotKey_control[$i][$eHotkey_sKey], $gaHotKeyData[$i][$eHotkey_sKey])
		; Hotkey Modifiers
		For $ii = 0 to UBound($aSymbol) - 1
			If StringInStr($gaHotKeyData[$i][$eHotkey_sKey], $aSymbol[$ii]) > 0 Then
				;beep()
				GUICtrlSetState($aHotKey_control[$i][$eHotkey_ctrl + $ii], $GUI_CHECKED)
				$gaHotKeyData[$i][$eHotkey_sKey] = StringReplace($gaHotKeyData[$i][$eHotkey_sKey], $aSymbol[$ii], '')
			EndIf
		Next
		; Hotkey
		GUICtrlSetData($aHotKey_control[$i][$eHotkey_sKey], $gaHotKeyData[$i][$eHotkey_sKey])

	Next

	Local $confirm = 0

	While 1
		$aMsg = GUIGetMsg($GUI_EVENT_ARRAY)
		Switch $aMsg[1]
			Case $Form1
				Switch $aMsg[0]
					Case $GUI_EVENT_CLOSE, $Cancel
						ExitLoop
					Case $Ok
						$confirm = 1
						ExitLoop
					Case $Add
						AddButton($hGui_scroll, $aHotKey_control)
					Case $url_send_names_button
						ShellExecute($gUrl_send_key_list)
				EndSwitch
			Case $hGui_scroll
				For $i = 1 to $gaHotKeyData[0][0]
					Switch $aMsg[0]
						Case $aHotKey_control[$i][$eHotkey_browse]
							$sFileOpenDialog = FileOpenDialog("Select File Playable by VLC", @WorkingDir & "\", "All (*.*)", $FD_FILEMUSTEXIST)
							If @error = 0 Then
								; Set File Path Field
								GUICtrlSetData($aHotKey_control[$i][$eHotkey_sFile], $sFileOpenDialog)
								; Set ToolTip to Path
								GUICtrlSetTip($aHotKey_control[$i][$eHotkey_sFile], "File Launched:"&@CRLF&$sFileOpenDialog)
							EndIf
						Case $url_send_names_button
							If _IsPressed(11) Then; CTRL
								ShellExecute($gUrl_send_key_list)
								keyreleased(1)
							EndIf
						Case $aHotKey_control[$i][$eHotkey_remove]
							$gaHotKeyData[0][0] -= 1
							ConsoleWrite("gg "&$gaHotKeyData[0][0])
							For $ii = $i to $gaHotKeyData[0][0]
								For $iii = $i to $eHotkey_win
									GUICtrlSetData($aHotKey_control[$ii][$iii], GUICtrlRead($aHotKey_control[$ii+1][$iii]))
								Next
							Next
							For $ii = 0 to $gHotkey_control_data_max - 1
								GUICtrlDelete($aHotKey_control[ $gaHotKeyData[0][0] ][$ii])
							Next
							;$gaHotKeyData[0][0] -= 1
					EndSwitch; aMsg[0]
				Next; i gaHotKeyData[0][0]
				If $aMsg[0] = $GUI_EVENT_DROPPED Then
							; Drag / Drop Event
							$list= UBound($gaDropfiles) - 1
							For $i= 0 to $gaHotKeyData[0][0]-1; locate the id row of drop
								If $aHotKey_control[$i][$eHotkey_sFile]= @GUI_DropId Then;test for dropped on me flag
									$cell= $i;the input field to modify 0-$hotkeysonpage-1
									ExitLoop;found, lets gtfooh
								EndIf
							Next

							$temp= 0
							If $list> 0 or StringInStr(FileGetAttrib($gaDropfiles[0]), "D") > 0 Then
								If $dragdropshowoptions= 1 Then;do we show drag and drop settings
									;$parentxy= WinGetPos($hgui)
									; Dialog to change drag and drop settings
									;showsettings($parentxy[0]+10, $parentxy[1]+100, 610, 430, "settings", 1)
								EndIf
							EndIf

							For $i= 0 To $list;all the files dropped
								;If $cell+$temp < $gaHotKeyData[0][0] Then;test hotkey range
									If StringInStr(FileGetAttrib($gaDropfiles[$i]), "D") > 0 Then;when directory folder search with melba's function
										; Is Directory
										;If $dragdropincludefilesfolders= 0 or $dragdropincludefilesfolders= 2 Then;include folder names?
											;insertfunction($kid+$temp, 0, $gaDropfiles[$i])
											; Clear File field
										;	GUICtrlSetData($aHotKey_control[$cell][$eHotkey_sFile], $gaDropfiles[$i])
											;If $cell+$temp < $hotkeysonpage Then GUICtrlSetData($inputfunction[$cell+$temp], $function[$kid+$temp][0])
										;	$temp= $temp+1
										;EndIf; end if include folder names
										;             _RecFileListToArray(InitialPath,    Include_List,  Ret, Rec, Srt, fullpath=2, Exclude_List = "", $sExclude_List_Folder = "")
										; _RecFileListToArray written by melba32
										
										; Directory inserts files within
										$droparray= _FileListToArrayRec($gaDropfiles[$i], '*.*', $dragdropincludefilesfolders, $FLTAR_RECUR, $FLTAR_NOSORT, $FLTAR_FULLPATH)

										For $ii= 1 to $droparray[0]; loop through melba's return array of path strings
											;If $cell+$temp < $gaHotKeyData[0][0] Then
												$fileattrib= FileGetAttrib($droparray[$ii])
												$no= 0
												If StringInStr($fileattrib, "S") Then $no= 1
												If StringInStr($fileattrib, "H") Then $no= 1
												If $no= 0 Then
													;insertfunction($kid+$temp, 0, $droparray[$ii])
													GUICtrlSetData($aHotKey_control[$cell+$temp][$eHotkey_sFile], $droparray[$ii])
													;If $cell+$temp < $gaHotKeyData[0][0] Then GUICtrlSetData($aHotKey_control[$cell+$temp][$eHotkey_sFile], $droparray[$i])
													If $cell+$temp >= $gaHotKeyData[0][0] Then AddButton($hGui_scroll, $aHotKey_control)
													
													GUICtrlSetData($aHotKey_control[$cell+$temp][$eHotkey_sFile], $droparray[$ii])
													
													$temp= $temp+1
												EndIf
											;Else
											;	ExitLoop
											;EndIf
										Next
									;if not directory
									Else;if $dragdropincludefilesfolders= 0 or $dragdropincludefilesfolders= 2 then;include file names
										; Single Files
										$fileattrib= FileGetAttrib($gaDropfiles[$i])
										$no= 0
										If $dragdropsystem= 0 and StringInStr($fileattrib, "S") then $no= 1
										If $dragdrophidden= 0 and StringInStr($fileattrib, "H") then $no= 1
										If $no= 0 then
											; Clear File field
											;GUICtrlSetData($aHotKey_control[$cell+$temp][$eHotkey_sFile], $gaDropfiles[$i])
											;if $cell+$temp < $hotkeysonpage then guictrlsetdata($inputfunction[$cell+$temp], $function[$kid+$temp][0])
											
											If $cell+$temp >= $gaHotKeyData[0][0] Then AddButton($hGui_scroll, $aHotKey_control)
												
											GUICtrlSetData($aHotKey_control[$cell+$temp][$eHotkey_sFile], $gaDropfiles[$i])
											
											$temp= $temp+1
										EndIf
									EndIf;end test if directory folder
								;EndIf;end test hotkey range
							Next;next for $i= 0 to ubound($gaDropfiles)
						EndIf
		EndSwitch; aMsg[1]
		If $gGui_resize = 1 Then

			$gGui_resize = 0
			$aGui_rect = WinGetPos($Form1)
			; Resize the inner sub scrollable window
			WinMove($hGui_scroll, "", default, default, default, $aGui_rect[3] - 30)

		EndIf;gGui_resize = 1
	WEnd

	If $confirm = 1 Then
		; Set all hotkeys
		ConsoleWrite("$gaHotKeyData[0][0]: "&$gaHotKeyData[0][0])
		ReDim $gaHotKeyData[ $gaHotKeyData[0][0] ][5]
		$gaHotKeyData[0][0] -= 1
		; Read hotkey controls
		For $i= 1 to $gaHotKeyData[0][0]
			; Start
			$gaHotKeyData[$i][$eHotkey_nStart] = GUICtrlRead($aHotKey_control[$i][$eHotkey_nStart])
			; End
			$gaHotKeyData[$i][$eHotkey_nEnd] = GUICtrlRead($aHotKey_control[$i][$eHotkey_nEnd])

			$sKey = ''
			For $ii = 0 to UBound($aSymbol) - 1
				If GUICtrlRead($aHotKey_control[$i][$eHotkey_ctrl + $ii]) = 1 Then
					$sKey &= $aSymbol[$ii]
				EndIf
			Next
			$sKey &= GUICtrlRead($aHotKey_control[$i][$eHotkey_sKey])
			; Hotkey
			$gaHotKeyData[$i][$eHotkey_sKey] = $sKey

			; File
			$gaHotKeyData[$i][$eHotkey_sFile] = GUICtrlRead($aHotKey_control[$i][$eHotkey_sFile])

			HotKeySet($gaHotKeyData[$i][$eHotkey_sKey], "_HotKeyFunc")

		Next
	Else
		$gaHotKeyData[0][0] = $count
	EndIf
	GUIDelete($Form1)

EndFunc   ;==>ConfigureGUI
Func OkButton()
	MsgBox(0, @ScriptName, "Not Programmed!")
EndFunc   ;==>OkButton
Func CancelButton()
	;GUISetState(@SW_HIDE)
EndFunc   ;==>CancelButton
Func AddButton($hGui_scroll, ByRef $aHotKey_control)

	;GUISwitch($hGui_scroll)
	Local $step_y = 65

	; If scrolled, place control accuratly and we don't care about x so it is 0 and one call oh thank god
	$aControl_pos = _GUIScrollbars_Locate_Ctrl($hGui_scroll, 0, ($gaHotKeyData[0][0] - 1) * $step_y)

	$aHotKey_control[ $gaHotKeyData[0][0] ][$eHotKey_sFile] = GUICtrlCreateInput("", 64, $aControl_pos[1] + 0, 225, 21)
	GUICtrlSetState($aHotKey_control[ $gaHotKeyData[0][0] ][$eHotKey_sFile], $GUI_DROPACCEPTED)

	$aHotKey_control[ $gaHotKeyData[0][0] ][$eHotKey_browse] = GUICtrlCreateButton("...", 296, $aControl_pos[1] + -1, 25, 25)
	$aHotKey_control[ $gaHotKeyData[0][0] ][$eHotKey_nStart] = GUICtrlCreateInput("Start Time", 0, $aControl_pos[1] + 0, 57, 21)
	$aHotKey_control[ $gaHotKeyData[0][0] ][$eHotKey_nEnd] = GUICtrlCreateInput("End Time", 0, $aControl_pos[1] + 26, 57, 21)

	$aHotKey_control[ $gaHotKeyData[0][0] ][$eHotKey_ctrl] = GUICtrlCreateCheckbox("Ctrl", 64, $aControl_pos[1] + 32, 31, 17)
	$aHotKey_control[ $gaHotKeyData[0][0] ][$eHotKey_alt] = GUICtrlCreateCheckbox("Alt", 98, $aControl_pos[1] + 32, 29, 17)
	$aHotKey_control[ $gaHotKeyData[0][0] ][$eHotKey_shift] = GUICtrlCreateCheckbox("Shift", 128, $aControl_pos[1] + 32, 39, 17)
	$aHotKey_control[ $gaHotKeyData[0][0] ][$eHotKey_win] = GUICtrlCreateCheckbox("Win", 170, $aControl_pos[1] + 30, 36, 21)

	$aHotKey_control[ $gaHotKeyData[0][0] ][$eHotKey_sKey] = GUICtrlCreateInput("", 210, $aControl_pos[1] + 32, 70, 21)

	$aHotKey_control[ $gaHotKeyData[0][0] ][$eHotkey_remove] = GUICtrlCreateButton("Remove", 285, $aControl_pos[1] + 31, 49, 25)

	GUICtrlSetTip($aHotKey_control[ $gaHotKeyData[0][0] ][$eHotkey_nStart], "Start Time in Seconds. Decimals accepted.")
	GUICtrlSetTip($aHotKey_control[ $gaHotKeyData[0][0] ][$eHotkey_nEnd], "End Time in Seconds. Decimals accepted.")
	GUICtrlSetTip($aHotKey_control[ $gaHotKeyData[0][0] ][$eHotKey_sKey], "Keypress."& @CRLF & "Press the Key Names button to the right for a list of keypress names and values.")

	$gaHotKeyData[0][0] += 1
EndFunc   ;==>AddButton
Func LoadIni()
	$sIniName = @ScriptDir & "\SoundBoard.ini"
	; Read ini section names
	Global $aSectionList = IniReadSectionNames($sIniName)
	If @error Then
		IniWriteSection($sIniName, "Sound1", 'Hotkey="+{numpad9}"' & @CRLF & 'File="' & @UserProfileDir & '\Music\SampleTrack.mp3"' & @CRLF & 'StartTime="15.1"' & @CRLF & 'EndTime="36.7"' & @CRLF & 'PlaybackDevice="Microsoft Soundmapper"')
		MsgBox(16, "SoundBoard", "SoundBoard.ini is missing. It has been created for you.")
		ShellExecute($sIniName, "", "", "edit")
		Sleep(200)
		MsgBox(64, "SoundBoard", "Notes:" & @CRLF & "StartTime and EndTime are in seconds and can be left empty. PlaybackDevice can be empty if not using Loopback feature. All entries in each section must exist and remain in the same order.")
		InputBox("SoundBoard", "Section names ([Sound1]) must be unique. Available Hotkeys can be found at the following url:", $gUrl_send_key_list)
		Exit
	EndIf
	; Create data array to hold ini data for each HotKey
	ReDim $gaHotKeyData[UBound($aSectionList) + 1][5]
	;_ArrayDisplay($gaHotKeyData, "", Default, 8)

	ConsoleWrite("$aSectionList[0]: " &$aSectionList[0])

	$gaHotKeyData[0][0] = $aSectionList[0]
	; For each section
	For $i = 1 To $aSectionList[0]
		; Read ini section
		$aSection = IniReadSection($sIniName, $aSectionList[$i])
		; Fill HotKey data array                                                                ; example content
		$gaHotKeyData[$i][$eHotkey_sKey] = IniRead($sIniName, $aSectionList[$i], "HotKey", "Error") ; !{numpad8}
		$gaHotKeyData[$i][$eHotkey_sFile] = IniRead($sIniName, $aSectionList[$i], "File", "Error") ; C:\Users\BetaL\Music\SampleTrack1.mp3
		$gaHotKeyData[$i][$eHotkey_nStart] = IniRead($sIniName, $aSectionList[$i], "StartTime", "") ; 12
		$gaHotKeyData[$i][$eHotkey_nEnd] = IniRead($sIniName, $aSectionList[$i], "EndTime", "") ; 34
		$gaHotKeyData[$i][$eHotkey_sPlayback_device] = IniRead($sIniName, $aSectionList[$i], "PlayBackDevice", "Microsoft Soundmapper") ; Microsoft Soundmapper
		; Set HotKey to common function
		HotKeySet($gaHotKeyData[$i][$eHotkey_sKey], "_HotKeyFunc")
	Next
	HotKeySet("!^{esc}", CloseVLC)
EndFunc   ;==>LoadIni
Func _HotKeyFunc()
	;Get HotKey pressed
	$sHotKeyPressed = @HotKeyPressed
	For $i = 1 To $aSectionList[0]; needs ahotkey[0][0] count
		HotKeySet($gaHotKeyData[$i][$eHotkey_sKey])
	Next
	;ConsoleWrite($sHotKeyPressed & @CRLF)
	; Find HotKey pressed in the data array
	$iIndex = _ArraySearch($gaHotKeyData, $sHotKeyPressed)
	; Check found
	If $iIndex <> -1 Then
		; Create parameter using the data in the array
		$sParam = '--qt-start-minimized --play-and-exit --start-time="' & $gaHotKeyData[$iIndex][$eHotkey_nStart] & '" --stop-time="' & $gaHotKeyData[$iIndex][$eHotkey_nEnd] & '" --aout=waveout --waveout-audio-device="' & 		$gaHotKeyData[$iIndex][$eHotkey_sPlayback_device] & '" "file:///' & StringReplace(StringReplace($gaHotKeyData[$iIndex][$eHotkey_sFile], "\", "/"), " ", "%20") & '"'
		; Simulate passing commandline to VLC
		ConsoleWrite("ShellExecuteWait:" & @CRLF & $VLC_Path & @CRLF & $sParam & @CRLF & $VLC_WorkingDir & @CRLF & @CRLF)
		Global $PID = ShellExecute($VLC_Path, $sParam, $VLC_WorkingDir)
		ProcessWaitClose("VLC.exe")
		Beep(500, 200)
	Else
		ConsoleWrite("Not a valid HotKey" & @CRLF)
	EndIf
	For $i = 1 To $aSectionList[0]
		HotKeySet($gaHotKeyData[$i][0], "_HotKeyFunc")
	Next
EndFunc   ;==>_HotKeyFunc
Func CloseVLC()
	If ProcessClose($PID) <> 1 Then MsgBox(16, "SoundBoard", "Cannot close VLC. Error: " & @error & "-" & @extended)
EndFunc   ;==>CloseVLC
Func _hotkey_exit()
	ConsoleWrite(@CRLF & 'hotkey_exit()')
	Exit
EndFunc
Func _WM_SIZE($hWnd, $iMsg, $wParam, $lParam)
	$gGui_resize = 1
EndFunc   ;==>_WM_SIZE
Func keyreleased($_key1, $_key2 = "", $_key3 = "", $_key4 = "")
	While _IsPressed($_key1) Or _IsPressed($_key2)
		Sleep(20)
	WEnd
	While _IsPressed($_key3) Or _IsPressed($_key4)
		Sleep(20)
	WEnd
EndFunc   ;==>keyreleased
Func WM_DROPFILES_FUNC($hWnd, $msgID, $wParam, $lParam)
    local $nSize, $pFileName
    local $nAmt = dllcall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", 0xFFFFFFFF, "ptr", 0, "int", 255)
    For $i = 0 To $nAmt[0] - 1
        $nSize = dllcall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", $i, "ptr", 0, "int", 0)
        $nSize = $nSize[0] + 1
        $pFileName = DllStructCreate("char[" & $nSize & "]")
        dllcall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", $i, "ptr", DllStructGetPtr($pFileName), "int", $nSize)
        ReDim $gaDropfiles[$i+1]
        $gaDropfiles[$i] = DllStructGetData($pFileName, 1)
        $pFileName = 0
    next
	;_ArrayDisplay($gaDropfiles)
EndFunc; end WM_DROPFILES_FUNC($hWnd, $msgID, $wParam, $lParam)
Func out($output = "", $timeout = 0);debug tool
	ConsoleWrite(@CRLF & $output);to console new line, value of $output
	;MsgBox(0, @ScriptName, $output, $timeout)
EndFunc   ;==>out
Func _ChangeWindowMessageFilterEx($hWnd, $iMsg, $iAction)
	Local $aCall = DllCall("user32.dll", "bool", "ChangeWindowMessageFilterEx", _
			"hwnd", $hWnd, _
			"dword", $iMsg, _
			"dword", $iAction, _
			"ptr", 0)
	If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
	Return 1
EndFunc
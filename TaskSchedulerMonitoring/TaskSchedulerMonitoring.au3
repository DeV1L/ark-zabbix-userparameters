#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Icon256-32.ico
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Change2CUI=Y
#AutoIt3Wrapper_Res_Description=Zabbix Monitor scheduled Tasks
#AutoIt3Wrapper_Res_Fileversion=1.0.0.45
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_LegalCopyright=2015 Bernhard Linz
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Language=1031
#AutoIt3Wrapper_Res_Field=Website|http://znil.net
#AutoIt3Wrapper_Res_Field=Manual|http://znil.net/index.php?title=Zabbix:TaskSchedulerMonitoring
#AutoIt3Wrapper_Res_Field=See You|znil.net
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
Opt('MustDeclareVars', 1)
#Region    ;************ Includes ************
#Include <Array.au3>
#include <Constants.au3>
#include <Date.au3>
#EndRegion ;************ Includes ************
; ##########################################################################################################################
; ##########################################################################################################################
; # TaskSchedulerMonitoring.exe --> Tool for Check BackupJobs in Zabbix                                                    #
; # 2013 Bernhard Linz    /    Bernhard@znil.de    /    http://znil.net                                                    #
; #                                                                                                                        #
; # Latest Version of this Program and Template in German:                                                                 #
; # http://znil.net/index.php?title=Zabbix:TaskSchedulerMonitoring                                                         #
; #                                                                                                                        #
; #	         ________  .__   __.  __   __        .__   __.  _______ .___________.                                          #
; #	        |       /  |  \ |  | |  | |  |       |  \ |  | |   ____||           |                                          #
; #	        `---/  /   |   \|  | |  | |  |       |   \|  | |  |__   `---|  |----`                                          #
; #	           /  /    |  . `  | |  | |  |       |  . `  | |   __|      |  |                                               #
; #	          /  /----.|  |\   | |  | |  `----.__|  |\   | |  |____     |  |                                               #
; #	         /________||__| \__| |__| |_______(__)__| \__| |_______|    |__|                                               #
; #                                                                                                                        #
; ##########################################################################################################################
; ##########################################################################################################################

Global $s_schtasksexe

Global $s_temp1, $s_temp2
Global $a_temp1, $a_temp2
Global $a_DateTemp
Global $a_RuntimeTemp

Global $a_ScheduledTasks[1][8]		; [0][0] = Tasks Count
									; [x][1] = Original name of the task
									; [x][2] = Corrected name of the task - without spaces and specsymbols to view in Zabbix
									; [x][3] = Last Result
									; [x][4] = Last Run Time
									; [x][5] = Next Run Time
									; [x][6] = Run As User
									; [x][7] = Task To Run

Global $s_Task2IgnoreFile = @ScriptDir & "\TaskSchedulerMonitoring-ignore.txt"
Global $h_Task2IgnoreFile
Global $a_Task2Ignore[1] = [ 0 ]
Global $b_IgnoreTask = False

Global $s_CleanTaskName
Global $s_OriginalTaskName
Global $s_QueryTaskName
Global $i_ThisTask

Global $s_JSONOutput
Global $s_RunCommand

Global $iStartTime
Global $iRunTime

;                          10        20        30        40        50        60        70        80
;                 12345678901234567890123456789012345678901234567890123456789012345678901234567890
Dim $s__Header = _
		"+------------------------------------------------------------------------------" & @CRLF & _
		"| TaskSchedulderMonitoring.exe - Version " & FileGetVersion(@ScriptName) & @CRLF & _
		"+------------------------------------------------------------------------------" & @CRLF & _
		"| 2015 von Bernhard Linz für http://znil.net - Kontakt: Bernhard@znil.net" & @CRLF & _
		"+------------------------------------------------------------------------------" & @CRLF & _
		@CRLF

;                          10        20        30        40        50        60        70        80
;                 12345678901234567890123456789012345678901234567890123456789012345678901234567890
Dim $s__HilfeText = _
		"Zabbix utility for check Sheduled Tasks status" & @CRLF & _
		"For Scheduled Tasks monitoring " & @CRLF & _
		"---------------------------------------------------------------------------" & @CRLF & _
		@CRLF & _
		"Usage: " & @CRLF & _
		@CRLF & _
		@ScriptName & " <Option> <Parameter>" & @CRLF & _
		@CRLF & _
		"Options:" & @CRLF & _
		"---------" & @CRLF & _
		" /? or -?     : this help" & @CRLF & _
		@CRLF & _
		" discovertasks  : Create All Scheduled Tasks list in JSON" & @CRLF & _
		"                  for tasks in root folder \" & @CRLF & _
		"                  'Task Scheduler Library'" & @CRLF & _
		@CRLF & _
		" query          : query the task status by its name." & @CRLF & _
		"                  send result to zabbx proxy or zabbix server" & @CRLF & _
		"                  Zabbix sender used if zabbix agent installed" & @CRLF & _
		"                  and zabbix_sender.exe located in the same directory" & @CRLF & _
		"                  as zabbix_agentd.exe" & @CRLF & _
		"                  Determine program timeout in seconds" & @CRLF & _
		@CRLF & _
		"+------------------------------------------------------------------------------" & @CRLF & _
		"| TaskSchedulderMonitoring.exe is fully FREEWARE!" & @CRLF & _
		"| Kopieren, weitergeben ausdrücklich erlaubt!" & @CRLF & _
		"| Documentation:" & @CRLF & _
		"| http://znil.net/index.php?title=Zabbix:TaskSchedulerMonitoring" & @CRLF & _
		"+------------------------------------------------------------------------------" & @CRLF


; ##########################################################################################################################
; ##########################################################################################################################
;                                                                                   ########################################
; ######## ##     ## ##    ##  ######  ######## ####  #######  ##    ##  ######     ########################################
; ##       ##     ## ###   ## ##    ##    ##     ##  ##     ## ###   ## ##    ##    ########################################
; ##       ##     ## ####  ## ##          ##     ##  ##     ## ####  ## ##          ########################################
; ######   ##     ## ## ## ## ##          ##     ##  ##     ## ## ## ##  ######     ########################################
; ##       ##     ## ##  #### ##          ##     ##  ##     ## ##  ####       ##    ########################################
; ##       ##     ## ##   ### ##    ##    ##     ##  ##     ## ##   ### ##    ##    ########################################
; ##        #######  ##    ##  ######     ##    ####  #######  ##    ##  ######     ########################################
;                                                                                   ########################################
; ##########################################################################################################################
; ##########################################################################################################################
Func _schtasks($s_schtasksparameter)
	Local $s_RunCommand
	Local $outputschtasks
	Local $errorsschtasks
	Local $hschtasks
	Local $ischtasksmaxWaitTime = 20000
	Local $ischtasksmaxWaitTimeSTART
	Local $s_tdoutReadFEHLER
	; build the Command for run
	;ConsoleWrite($s_schtasksexe & " " & $s_schtasksparameter & @CRLF)
	$s_RunCommand = $s_schtasksexe & " " & $s_schtasksparameter
	; Start the timer for max wait time
	$ischtasksmaxWaitTimeSTART = TimerInit()
	; run the Command
	$hschtasks = Run($s_RunCommand, @SystemDir, @SW_HIDE, $STDIN_CHILD + $STDOUT_CHILD + $STDERR_CHILD)
	;get the output
	Do
		Sleep(5)
		; get the output
		$outputschtasks = $outputschtasks & StdoutRead($hschtasks)
		; get the errors
		$errorsschtasks = $errorsschtasks & StderrRead($hschtasks)
		; did we have an error while reading?
		$s_tdoutReadFEHLER = @error
		If $s_tdoutReadFEHLER <> "" Then
			; No error, go on
			If $outputschtasks = "" Then
				; but also no output, let us take a 2. try
				$outputschtasks = $outputschtasks & StdoutRead($hschtasks)
				If $outputschtasks = "" Then
					; anymore no output, oh oh
					If $s_tdoutReadFEHLER <> "" Then
						; but we have an error message
						ConsoleWriteError($errorsschtasks & @CRLF)
					EndIf
				EndIf
			EndIf
		EndIf
	Until $s_tdoutReadFEHLER Or TimerDiff($ischtasksmaxWaitTimeSTART) > $ischtasksmaxWaitTime
	;MsgBox(0,"",$outputschtasks)
	Return $outputschtasks
EndFunc ;<== End _schtasks()

; ###################################################################################
; _ANSI2OEM löst das Problem mit dem Umlauten und anderen Sonderzeichen. Es wandelt Text so um das er korrekt in der DOS-Box dargestellt wird
; So können hier im Quellcode auch Umlaute verwendet werden (in den Textausgaben) und diese werden dann korrekt dargestellt
; Wir zudem für die Prüfung der Gruppenzugehörigkeit benötigt für Gruppen mit Umlauten, z.B. Domänen-Admins
; Dank an Xenobiologist von AutoIt.de für diese Lösung: http://www.autoit.de/index.php?page=Thread&threadID=9461&highlight=ANSI2OEM

Func _ANSI2OEM($text)
	$text = DllCall('user32.dll', 'Int', 'CharToOem', 'str', $text, 'str', '')
	Return $text[2]
	;Return $text
EndFunc   ;==>_ANSI2OEM

; ###################################################################################
; Help output function
Func _HilfeAusgeben()
	ConsoleWrite(_ANSI2OEM($s__Header))
	ConsoleWrite(_ANSI2OEM($s__HilfeText))
EndFunc   ;==>_HilfeAusgeben

; ##################################################################################################################
;             ########    ###    ########  ########  #### ##     ##          ######   #######  ##    ## ########
;                  ##    ## ##   ##     ## ##     ##  ##   ##   ##          ##    ## ##     ## ###   ## ##
;                 ##    ##   ##  ##     ## ##     ##  ##    ## ##           ##       ##     ## ####  ## ##
;                ##    ##     ## ########  ########   ##     ###            ##       ##     ## ## ## ## ######
;               ##     ######### ##     ## ##     ##  ##    ## ##           ##       ##     ## ##  #### ##
;              ##      ##     ## ##     ## ##     ##  ##   ##   ##          ##    ## ##     ## ##   ### ##
;     ####### ######## ##     ## ########  ########  #### ##     ## #######  ######   #######  ##    ## ##
; ##################################################################################################################
Global $sZabbix_agentd_exe
Global $sZabbix_agentd_conf
Global $sZabbix_sender_exe
Global $sZabbix_Hostname
Global $sZabbix_Server
Global $iZabbix_Server_Port
Global $sZabbix_String2Send

Func _Zabbix_conf()
	Dim $sRegTMP
	Dim $iRegTMP = 0
	Dim $iLoop
	Dim $aRegTMP
	Dim $aZabbix_config
	Dim $sZabbix_config_file
	Dim $a2temp
	While 1
		$iRegTMP = $iRegTMP + 1
		$sRegTMP = RegEnumKey("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services", $iRegTMP)
		If @error Then
			ExitLoop
		EndIf
		$sRegTMP = RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\" & $sRegTMP, "ImagePath")
		If @error = 0 Then
			If StringInStr($sRegTMP, "zabbix_agentd.exe") > 0 Then
				;ConsoleWrite("Gefunden: " & $sRegTMP & @CRLF)
				$aRegTMP = StringSplit($sRegTMP, '"')
				;_ArrayDisplay($aRegTMP)
				$sZabbix_agentd_exe = $aRegTMP[2]
				$sZabbix_sender_exe = StringReplace($sZabbix_agentd_exe, "zabbix_agentd.exe", "zabbix_sender.exe")
				$sZabbix_config_file = $aRegTMP[4]
				$sZabbix_agentd_conf = $sZabbix_config_file
				$aZabbix_config = FileReadToArray($sZabbix_config_file)
				If @error = 0 Then
					For $iLoop = 0 To (UBound($aZabbix_config) -1)
						If StringLeft($aZabbix_config[$iLoop], StringLen("ServerActive=")) = "ServerActive=" Then
							$sZabbix_Server = StringReplace($aZabbix_config[$iLoop], "ServerActive=", "")
							$sZabbix_Server = StringReplace($sZabbix_Server, " ", "")
							$a2temp = StringSplit($sZabbix_Server, ":")
							If $a2temp[0] = 1 Then
								$iZabbix_Server_Port = 10051
							Else
								$sZabbix_Server = $a2temp[1]
								$iZabbix_Server_Port = $a2temp[2]
							EndIf
						EndIf
						If StringLeft($aZabbix_config[$iLoop], StringLen("Hostname=")) = "Hostname=" Then
							$sZabbix_Hostname = StringReplace($aZabbix_config[$iLoop], "Hostname=", "")
							$sZabbix_Hostname = StringReplace($sZabbix_Hostname, " ", "")
						EndIf
					Next
				Else
					ConsoleWrite("File not found: " & $sZabbix_config_file & @CRLF)
					Exit 1
				EndIf
				If FileExists($sZabbix_sender_exe) = 0 Then
					ConsoleWrite("zabbix_sender.exe not found at: " & $sZabbix_sender_exe & @CRLF)
					Exit 1
				EndIf
			EndIf
		EndIf
	WEnd
;~ 	ConsoleWrite("zabbix_agentd.exe:       " & '"' & $sZabbix_agentd_exe & '"' & @CRLF)
;~ 	ConsoleWrite("zabbix_sender.exe:       " & '"' & $sZabbix_sender_exe & '"' & @CRLF)
;~ 	ConsoleWrite("Hostname used in Zabbix: " & '"' & $sZabbix_Hostname & '"' &  @CRLF)
;~ 	ConsoleWrite("IP(:Port) Zabbix Server: " & '"' & $sZabbix_Server & '"' & @CRLF)
EndFunc

; #############################################################################################################################################################################################################################################################################
;              ######  ######## ##    ## ########  ##     ##    ###    ##       ##     ## ########         ##      ## #### ######## ##     ##         ########    ###    ########  ########  #### ##     ##          ######  ######## ##    ## ########  ######## ########
;             ##    ## ##       ###   ## ##     ## ##     ##   ## ##   ##       ##     ## ##               ##  ##  ##  ##     ##    ##     ##              ##    ## ##   ##     ## ##     ##  ##   ##   ##          ##    ## ##       ###   ## ##     ## ##       ##     ##
;             ##       ##       ####  ## ##     ## ##     ##  ##   ##  ##       ##     ## ##               ##  ##  ##  ##     ##    ##     ##             ##    ##   ##  ##     ## ##     ##  ##    ## ##           ##       ##       ####  ## ##     ## ##       ##     ##
;              ######  ######   ## ## ## ##     ## ##     ## ##     ## ##       ##     ## ######           ##  ##  ##  ##     ##    #########            ##    ##     ## ########  ########   ##     ###             ######  ######   ## ## ## ##     ## ######   ########
;                   ## ##       ##  #### ##     ##  ##   ##  ######### ##       ##     ## ##               ##  ##  ##  ##     ##    ##     ##           ##     ######### ##     ## ##     ##  ##    ## ##                 ## ##       ##  #### ##     ## ##       ##   ##
;             ##    ## ##       ##   ### ##     ##   ## ##   ##     ## ##       ##     ## ##               ##  ##  ##  ##     ##    ##     ##          ##      ##     ## ##     ## ##     ##  ##   ##   ##          ##    ## ##       ##   ### ##     ## ##       ##    ##
;     #######  ######  ######## ##    ## ########     ###    ##     ## ########  #######  ######## #######  ###  ###  ####    ##    ##     ## ####### ######## ##     ## ########  ########  #### ##     ## #######  ######  ######## ##    ## ########  ######## ##     ##
; #############################################################################################################################################################################################################################################################################

Func _SendValue_with_Zabbix_Sender($sItemName, $sItemValue)
		;ConsoleWrite('"' & $sZabbix_sender_exe & '"' & " -c " & '"' & $sZabbix_agentd_conf & '"' & " -k " & '"' & $sItemName & '" -o "' & $sItemValue & '"' & @CRLF)
		RunWait('"' & $sZabbix_sender_exe & '"' & " -c " & '"' & $sZabbix_agentd_conf & '"' & " -k " & '"' & $sItemName & '" -o "' & $sItemValue & '"', "", @SW_HIDE, $RUN_CREATE_NEW_CONSOLE)
EndFunc


; ####################################################################################################################
;             ######   ######## ########    ###    ##       ##       ########    ###     ######  ##    ##  ######
;            ##    ##  ##          ##      ## ##   ##       ##          ##      ## ##   ##    ## ##   ##  ##    ##
;            ##        ##          ##     ##   ##  ##       ##          ##     ##   ##  ##       ##  ##   ##
;            ##   #### ######      ##    ##     ## ##       ##          ##    ##     ##  ######  #####     ######
;            ##    ##  ##          ##    ######### ##       ##          ##    #########       ## ##  ##         ##
;            ##    ##  ##          ##    ##     ## ##       ##          ##    ##     ## ##    ## ##   ##  ##    ##
;     #######  ######   ########    ##    ##     ## ######## ########    ##    ##     ##  ######  ##    ##  ######
; ####################################################################################################################
Func _GetAllScheduledTasks()
	Dim $s_lastTaskName = ""
	; Get all scheduled Jobs
	$s_temp1 = _schtasks("/query /FO CSV")
	;ConsoleWrite($s_temp1 & @CRLF)
	$s_temp1 = StringReplace($s_temp1, @CRLF, "@CRLF")
	$a_temp1 = StringSplit($s_temp1, "@CRLF", 1)
	;ConsoleWrite($a_temp1[0] & @CRLF)
;	_ArrayDisplay($a_temp1)
	For $i = 2 To $a_temp1[0] ; Skip the first line with headlines
		;_ArrayDisplay($a_temp1)
		$b_IgnoreTask = False
;~ 		If StringLeft($a_temp1[$i], StringLen('"\Microsoft')) = '"\Microsoft' Then
;~ 			ExitLoop
;~ 		EndIf
		 ;ConsoleWrite($a_temp1[$i] & @CRLF)
		If StringLeft($a_temp1[$i], 2) = '"\' and Not (StringLeft($a_temp1[$i], StringLen('"\Microsoft')) = '"\Microsoft') Then
			$a_temp2 = StringSplit($a_temp1[$i],",")
			;ConsoleWrite($a_temp1[$i] & @CRLF)
			;ConsoleWrite($a_temp2[1] & @CRLF)
			If $a_temp2[0] > 1 Then
				$s_OriginalTaskName = StringTrimLeft(StringReplace($a_temp2[1], '"', "") ,1)
				$s_CleanTaskName = StringTrimLeft(StringReplace($a_temp2[1], " ", "_") ,1)
				$s_CleanTaskName = StringRegExpReplace($s_CleanTaskName, "[^\w\.@-]", "")
				If $a_Task2Ignore[0] > 0 Then
					For $j = 1 To $a_Task2Ignore[0]
						;MsgBox(0,"","$s_OriginalTaskName" & @CRLF & $a_Task2Ignore[$j] & @CRLF & @CRLF & $s_CleanTaskName & @CRLF & $a_Task2Ignore[$j])
						If StringInStr($s_OriginalTaskName, $a_Task2Ignore[$j]) > 0 Then
							$b_IgnoreTask = True
						EndIf
						If StringInStr($s_CleanTaskName, $a_Task2Ignore[$j]) > 0 Then
							$b_IgnoreTask = True
						EndIf
					Next
				EndIf
				If $s_lastTaskName = $s_OriginalTaskName Then
					$b_IgnoreTask = True
				EndIf
				If $b_IgnoreTask = False Then
					$a_ScheduledTasks[0][0] = $a_ScheduledTasks[0][0] + 1
					ReDim $a_ScheduledTasks[ $a_ScheduledTasks[0][0] + 1 ][8]
					; [x][1] = Name des Task "original"
					$a_ScheduledTasks[ $a_ScheduledTasks[0][0] ][1] = $s_OriginalTaskName
					$s_lastTaskName = $s_OriginalTaskName
					; [x][2] = Name des Tasks "bereinigt" - ohne Leerzeichen/Sonderzeichen zur Anzeige in Zabbix und zur Übergabe an dieses Programm hier
					$a_ScheduledTasks[ $a_ScheduledTasks[0][0] ][2] = $s_CleanTaskName
				EndIf
			EndIf
		Else
			; Er beginnt in Zeile 2 nach geplanten Aufgaben zu suchen. Diese Fangen mit "\ an.
			; Gibt es keine Aufgaben wird da wieder eine Kopfzeile mit den Feldbezeichnungen kommen für den nächsten Abschnitt
			; Und damit sind wir schon hier und verlassen die Schleife
			;ExitLoop
		EndIf
	Next
EndFunc

; ##########################################################################################################################
; ##########################################################################################################################
;                                       ####################################################################################
; ##     ##    ###    #### ##    ##     ####################################################################################
; ###   ###   ## ##    ##  ###   ##     ####################################################################################
; #### ####  ##   ##   ##  ####  ##     ####################################################################################
; ## ### ## ##     ##  ##  ## ## ##     ####################################################################################
; ##     ## #########  ##  ##  ####     ####################################################################################
; ##     ## ##     ##  ##  ##   ###     ####################################################################################
; ##     ## ##     ## #### ##    ##     ####################################################################################
;                                       ####################################################################################
; ##########################################################################################################################
; ##########################################################################################################################
$iStartTime = _DateDiff("s", "1970/01/01 00:00:00", _NowCalc())


If $CmdLine[0] > 0 Then
	If $CmdLine[1] = "/?" Or $CmdLine[1] = "-?" Then
		_HilfeAusgeben()
		Exit 0
	EndIf
EndIf

;~ If $CmdLine[0] = 0 Then
;~ 	_HilfeAusgeben()
;~ 	Exit 0
;~ EndIf



; Ok, we need the schtasks.exe,
$s_schtasksexe = @ComSpec & " /C " & @WindowsDir & "\system32\schtasks.exe"
$a_ScheduledTasks[0][0] = 0
$a_ScheduledTasks[0][1] = "Original Name"
$a_ScheduledTasks[0][2] = "Clean Name"
$a_ScheduledTasks[0][3] = "Last Result"
$a_ScheduledTasks[0][4] = "Last Run Time"
$a_ScheduledTasks[0][5] = "Next Run Time"
$a_ScheduledTasks[0][6] = "Run As User"
$a_ScheduledTasks[0][7] = "Task To Run"

; ##########################################################################################################################
; ##########################################################################################################################
; Some of the services are irritating, just ignore them - read items from a file
If FileExists($s_Task2IgnoreFile) = 1 Then
	$h_Task2IgnoreFile = FileOpen($s_Task2IgnoreFile, 0)
	While 1
		$s_temp1 = FileReadLine($h_Task2IgnoreFile)
		If @error = -1 Then
			ExitLoop
		Else
			If StringLen($s_temp1) > 2 Then ; at least 3 or more chars
				$a_Task2Ignore[0] = $a_Task2Ignore[0] + 1
				ReDim $a_Task2Ignore[$a_Task2Ignore[0] + 1] ;That's AutoIt - Redim an Array without data-loss
				$a_Task2Ignore[$a_Task2Ignore[0]] = $s_temp1
			EndIf
		EndIf
	WEnd
EndIf

;_ArrayDisplay($a_Task2Ignore)




If $CmdLine[1] = "discovertasks" Then
;If "discovertasks" = "discovertasks" Then
	_GetAllScheduledTasks()
	$s_JSONOutput = '{"data":[' & @CRLF
	;ConsoleWrite($a_ScheduledTasks[0][0] & @CRLF)
	For $i = 1 To $a_ScheduledTasks[0][0]
		$s_JSONOutput = $s_JSONOutput & "     " & '{' & '@CRLF' & _
									"          " & '"{#TSMTASKNAME}":"' & $a_ScheduledTasks[$i][2] & '"' & '@CRLF' & _
									"     " & '},' & '@CRLF'
	Next
	$s_JSONOutput = StringTrimRight($s_JSONOutput, StringLen("," & "@CRLF")) & @CRLF & "     " & ']' & @CRLF & '}'
	$s_JSONOutput = StringReplace($s_JSONOutput, "@CRLF", @CRLF)
	If StringLen($s_JSONOutput) < 11 Then
		ConsoleWrite('{"data":[]}' & @CRLF)
	Else
		ConsoleWrite(_ANSI2OEM($s_JSONOutput))
	EndIf
	Exit 0
EndIf





If $CmdLine[1] = "query" And $CmdLine[0] > 1 Then
	_GetAllScheduledTasks()
	$s_QueryTaskName = ""
	$i_ThisTask = 0
	If $a_ScheduledTasks[0][0] > 0 Then
		For $i = 1 To $a_ScheduledTasks[0][0]
			If $CmdLine[2] = $a_ScheduledTasks[$i][2] Then
				$s_QueryTaskName = $a_ScheduledTasks[$i][1]
				$i_ThisTask = $i
			EndIf
		Next
	EndIf
	If $s_QueryTaskName = "" Then
		ConsoleWrite("ZBX_NOTSUPPORTED" & @CRLF)
		Exit 0
	EndIf
	$s_temp1 = _schtasks("/QUERY /FO CSV /V /TN " & '"' & $s_QueryTaskName & '"')
	;ConsoleWrite($s_temp1 & @CRLF)
	$s_temp1 = StringReplace($s_temp1, @CRLF, "@CRLF")
	$a_temp1 = StringSplit($s_temp1, "@CRLF", 1)
	If $a_temp1[0] < 2 Then
		ConsoleWrite("ZBX_SUPPORTED" & @CRLF)
		Exit 0
	EndIf
	$a_temp2 = StringSplit($a_temp1[2],",")
	;_ArrayDisplay($a_temp2)

	If $a_temp2[0] > 1 Then
		;_ArrayDisplay($a_temp2)
		;Last Result
		$a_ScheduledTasks[$i_ThisTask][3] = StringReplace($a_temp2[7], '"', "")

		;Last Run Time
		; Mögliche Werte zum Beispiel: "18.04.2015 01:00:00" oder "04/14/2015 01:00:00" oder "n/a"' oder "Nicht zutreffend"
		If StringRegExp($a_temp2[6], '\d+') = 1 Then ; String enthält mindestens eine Zahl
			If StringInStr($a_temp2[6], "/") > 0 Then
				$a_temp1 = StringSplit(StringReplace($a_temp2[6], '"', ""), "/ ", 0)
				; $a_temp1[1] = MM
				; $a_temp1[2] = DD
				; $a_temp1[3] = YYYY
				; $a_temp1[4] = HH:MM:SS
				;Input Start date in the format "YYYY/MM/DD[ HH:MM:SS]"
				$a_ScheduledTasks[$i_ThisTask][4] = _DateDiff("s", "1970/01/01 00:00:00", $a_temp1[3] & "/" & $a_temp1[1] & "/" & $a_temp1[2] & " " & $a_temp1[4])
			Else
				$a_temp1 = StringSplit(StringReplace($a_temp2[6], '"', ""), ". ", 0)
				; $a_temp1[1] = DD
				; $a_temp1[2] = MM
				; $a_temp1[3] = YYYY
				; $a_temp1[4] = HH:MM:SS
				;Input Start date in the format "YYYY/MM/DD[ HH:MM:SS]"
				$a_ScheduledTasks[$i_ThisTask][4] = _DateDiff("s", "1970/01/01 00:00:00", $a_temp1[3] & "/" & $a_temp1[2] & "/" & $a_temp1[1] & " " & $a_temp1[4])
			EndIf
		Else
			$a_ScheduledTasks[$i_ThisTask][4] = "ZBX_NOTSUPPORTED"
		EndIf

		; Next Run Time
		; Mögliche Werte zum Beispiel: "18.04.2015 01:00:00" oder "04/14/2015 01:00:00" oder "n/a"' oder "Nicht zutreffend"
		If StringRegExp($a_temp2[3], '\d+') = 1 Then ; String enthält mindestens eine Zahl
			If StringInStr($a_temp2[3], "/") > 0 Then
				$a_temp1 = StringSplit(StringReplace($a_temp2[3], '"', ""), "/ ", 0)
				; $a_temp1[1] = MM
				; $a_temp1[2] = DD
				; $a_temp1[3] = YYYY
				; $a_temp1[4] = HH:MM:SS
				;Input Start date in the format "YYYY/MM/DD[ HH:MM:SS]"
				$a_ScheduledTasks[$i_ThisTask][5] = _DateDiff("s", "1970/01/01 00:00:00", $a_temp1[3] & "/" & $a_temp1[1] & "/" & $a_temp1[2] & " " & $a_temp1[4])
			Else
				$a_temp1 = StringSplit(StringReplace($a_temp2[3], '"', ""), ". ", 0)
				; $a_temp1[1] = DD
				; $a_temp1[2] = MM
				; $a_temp1[3] = YYYY
				; $a_temp1[4] = HH:MM:SS
				;Input Start date in the format "YYYY/MM/DD[ HH:MM:SS]"
				$a_ScheduledTasks[$i_ThisTask][5] = _DateDiff("s", "1970/01/01 00:00:00", $a_temp1[3] & "/" & $a_temp1[2] & "/" & $a_temp1[1] & " " & $a_temp1[4])
			EndIf
		Else
			$a_ScheduledTasks[$i_ThisTask][5] = "ZBX_NOTSUPPORTED"
		EndIf

		; Run As User
		$a_ScheduledTasks[$i_ThisTask][6] = StringReplace($a_temp2[8], '"', "")

		; Task To Run
		$a_ScheduledTasks[$i_ThisTask][7] = StringReplace($a_temp2[9], '"', "")
	Else
		ConsoleWrite("ZBX_SUPPORTED" & @CRLF)
		Exit 0
	EndIf
	_Zabbix_conf()
	;_ArrayDisplay($a_ScheduledTasks)
	;$a_ScheduledTasks[0][8]	; [0][0] = Anzahl der Tasks
								; [x][1] = Name des Task "original"
								; [x][2] = Name des Tasks "bereinigt" - ohne Leerzeichen/Sonderzeichen zur Anzeige in Zabbix und zur Übergabe an dieses Programm hier
								; [x][3] = Last Result
								; [x][4] = Last Run Time
								; [x][5] = Next Run Time
								; [x][6] = Run As User
								; [x][7] = Task To Run

	_SendValue_with_Zabbix_Sender("schtaskMonitoring.TaskSchedulerMonitoring[LastResult," 	& $a_ScheduledTasks[$i_ThisTask][2] & "]", 	$a_ScheduledTasks[$i_ThisTask][3])
	_SendValue_with_Zabbix_Sender("schtaskMonitoring.TaskSchedulerMonitoring[LastRunTime," 	& $a_ScheduledTasks[$i_ThisTask][2] & "]", 	$a_ScheduledTasks[$i_ThisTask][4])
	_SendValue_with_Zabbix_Sender("schtaskMonitoring.TaskSchedulerMonitoring[NextRunTime," 	& $a_ScheduledTasks[$i_ThisTask][2] & "]", 	$a_ScheduledTasks[$i_ThisTask][5])
	_SendValue_with_Zabbix_Sender("schtaskMonitoring.TaskSchedulerMonitoring[RunAsUser," 	& $a_ScheduledTasks[$i_ThisTask][2] & "]", 	$a_ScheduledTasks[$i_ThisTask][6])
	$iRunTime = _DateDiff("s", "1970/01/01 00:00:00", _NowCalc()) - $iStartTime
	ConsoleWrite($iRunTime & @CRLF)
	Exit 0
Else
	ConsoleWrite("ERROR - Option 'query' without Parameter - see /? vor Help")
EndIf

Exit 0
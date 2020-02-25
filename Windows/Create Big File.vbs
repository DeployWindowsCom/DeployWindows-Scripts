Option Explicit

Dim colNamedArgs
Dim intBytes
Dim intCount

Const KILOBYTE = 1024
Dim SHOWUSAGE: SHOWUSAGE = "Command line arguments:" & VbCrLf & Wscript.ScriptName & " /name:filename [/counts:n] [/Kb:n] [/Mb:n] [/Gb:n] [/Tb:n]"

Set colNamedArgs = WScript.Arguments.Named 

If NOT HasElevatedToken Then
	MsgBox "Application have to run with administrative permissions"
	Wscript.Quit(4)
End If

If colNamedArgs.Count = 0 Then
	MsgBox SHOWUSAGE
	WScript.Quit(1)
End If

If isEmpty(ColNamedArgs.Item("name")) Then
	MsgBox SHOWUSAGE
	WScript.Quit(2)
End If

If NOT isEmpty(ColNamedArgs.Item("kb")) Then
	intBytes = ConvertToByte(ColNamedArgs.Item("kb"), "kb")
ElseIf NOT isEmpty(ColNamedArgs.Item("mb")) Then
	intBytes = ConvertToByte(ColNamedArgs.Item("mb"), "mb")
ElseIf NOT isEmpty(ColNamedArgs.Item("gb")) Then
	intBytes = ConvertToByte(ColNamedArgs.Item("gb"), "gb")
ElseIf NOT isEmpty(ColNamedArgs.Item("tb")) Then
	intBytes = ConvertToByte(ColNamedArgs.Item("tb"), "tb")
End If

If isEmpty(colNamedArgs.Item("counts")) Then
	createFile colNamedArgs.Item("name"), intBytes
Else
	If IsNumeric(colNamedArgs.Item("counts")) Then
		For intCount = 1 to colNamedArgs.Item("counts")
			createFile colNamedArgs.Item("name") & intCount, intBytes
		Next
	Else
		MsgBox SHOWUSAGE
		WScript.Quit(3)
	End If
End If

Function ConvertToByte ( intSize, strUnit )
	On Error Resume Next
	If IsNumeric(intSize) Then
		Select Case strUnit
			Case "kb"	ConvertToByte = intSize * KILOBYTE
			Case "mb"	ConvertToByte = intSize * KILOBYTE * KILOBYTE
			Case "gb"	ConvertToByte = intSize * KILOBYTE * KILOBYTE * KILOBYTE
			Case "tb"	ConvertToByte = intSize * KILOBYTE * KILOBYTE * KILOBYTE * KILOBYTE
		End Select
	Else
		ConvertToByte = Null
	End If
End Function

Sub createFile ( strFileName, intBytes )
	Dim strCommand
	Dim strCurrentFolder 
	Dim strOutput
	Dim objFSO
	Dim objFile
    Dim objShell
	Dim objWshScriptExec
	Dim objStdOut
    Set objShell = CreateObject("WScript.Shell")

	If InStr(strFileName, "\") = 0 Then
		Set objFSO = CreateObject("Scripting.FileSystemObject")
		Set objFile = objFSO.GetFile(Wscript.ScriptFullName)
		strCurrentFolder = objFSO.GetParentFolderName(objFile)
		strFileName = objFSO.BuildPath(strCurrentFolder, strFileName)
	End If
	
    strCommand = "C:\Windows\System32\fsutil.exe file createnew """ & strFileName & """ " & intBytes
	'MsgBox strCommand
	'objShell.Run strCommand
	Set objWshScriptExec = objShell.Exec(strCommand)
	Set objStdOut = objWshScriptExec.StdOut
	strOutput = objStdOut.ReadAll
	If InStr(lCase(strOutput ), "error") > 0 Then
		MsgBox strOutput, 16
	End If
End Sub

'test whether user has elevated token
Function HasElevatedToken
	Dim oShell, oExecWhoami, oWhoamiOutput, strWhoamiOutput, boolHasElevatedToken 
	Set oShell = CreateObject("WScript.Shell") 
	Set oExecWhoami = oShell.Exec("whoami /groups") 
	Set oWhoamiOutput = oExecWhoami.StdOut 
	strWhoamiOutput = oWhoamiOutput.ReadAll 
	If InStr(1, strWhoamiOutput, "S-1-16-12288", vbTextCompare) Then boolHasElevatedToken = True 
	If boolHasElevatedToken Then 
		HasElevatedToken = True
		'MsgBox "Current script is running with elevated privs." 
	Else
		HasElevatedToken = False
		'MsgBox "Current script is NOT running with elevated privs." 
	End If 
End Function

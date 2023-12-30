Const ForReading = 1, ForAppending = 8
linksfile = WScript.Arguments(0)
PathOld = WScript.Arguments(1)
PathNew = WScript.Arguments(2)
JIndex = InStrRev(PathOld, ":\")
If JIndex > 0 Then
	PathOldJunc = Mid(PathOld, JIndex - 1)
Else
	PathOldJunc = PathOld
End If
' Initialize REGEX Pattern
Dim regex
Set regex = New RegExp
regex.Global = True
regex.IgnoreCase = True
regex.Pattern = "[\*\?\""\<\>\|]"
' Start The Program
PathDir = ""
WScript.Echo "Patching:" & PathOld & " With:" & PathNew
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = WScript.CreateObject("WScript.Shell")
TMPDIR = oShell.ExpandEnvironmentStrings("%TMP%")
SCGen = TMPDIR & "\ShortcutFixerGen.bat"
Call DelFile(SCGen)
Set BFile = objFSO.OpenTextFile(SCGen, ForAppending, True)
BFile.WriteLine "@ECHO OFF" & vbCrlf & "setlocal ENABLEDELAYEDEXPANSION"
Set objFile = objFSO.OpenTextFile(linksfile, 1, False)
Do Until objFile.AtEndOfStream
	line = objFile.ReadLine
	If Trim(line) <> "" Then
		IndexEnd = InStr(line, ">")
		IndexStart = InStr(line, "<")
		If IndexEnd > 0 Then
			LinkType = UCase(Mid(line,  IndexStart + 1, IndexEnd - IndexStart - 1))
			'WScript.Echo """" & LinkType & """"
			IF (LinkType = "JUNCTION") Or (LinkType = "SYMLINKD") Or (LinkType = "SYMLINK") Then
				' Parse the Path and Org Target
				UnParsedP = Mid(line, IndexEnd + 1)
				InEndP = InStr(UnParsedP, ">")
				InStartP = InStr(UnParsedP, "<")
				LinkDir = Mid(UnParsedP, InStartP + 1, InEndP - InStartP - 1)
				UnParsedA = Mid(line, IndexEnd + InEndP + 2)
				' Get Attributes
				StrAttrs = Mid(UnParsedA, InStr(UnParsedA, "<") + 1, InStr(UnParsedA, ">") - 2)
				' Get Target
				TargOrg = Mid(UnParsedA, InStrRev(UnParsedA, "<") + 1, InStrRev(UnParsedA, ">") - InStrRev(UnParsedA, "<") - 1)
				' Start the Actual Patching here
				If InStr(TargOrg, PathOld) > 0 Then
					' All other NT Meta paths are fine using MKLNK /J command Except for This Prefix due to a bug with MKLINK with Junctions Tested Win 10-11
					IF LinkType = "JUNCTION" And InStr(TargOrg, "\??\") > 0 Then
						indexJun = InStrRev(TargOrg, ":\")
						TargNew = regex.Replace(Replace(Mid(TargOrg, indexJun - 1), PathOldJunc, PathNew, 1, 1), "")
					Else
						TargNew = Replace(TargOrg, PathOld, PathNew, 1, 1)
					End If
					' WScript.Echo LinkDir & " " & LinkType & " """ & TargOrg & """ To: """ & TargNew & """"
					' Generate the Commands
					DELCMD = "RD """ & LinkDir & """"
					IF LinkType = "JUNCTION" Then
						MKFlags = " /J"
					ElseIf LinkType = "SYMLINKD" Then
						MKFlags = " /D"
					Else
						MKFlags = ""
						DELCMD = "DEL /F /Q /A """ & LinkDir & """"
					End If
					MKCMD = "MKLINK" & MKFlags & " """ & LinkDir & """ " & """" & TargNew & """"
					BFile.WriteLine "cmd /c echo " & DELCMD
					BFile.WriteLine "cmd /c echo " & MKCMD
					IF StrAttrs <> "" THEN
						LNKAttribs = GetLnkAttr(StrAttrs)
						BFile.WriteLine "cmd /c echo attrib /L " & LNKAttribs & " """ & LinkDir & """"
					End If
				'Else
					'WScript.Echo "Skipping: " & TargOrg
				End If
			End If
		End If
	End If
Loop
BFile.Close
Call runCMD("cmd /c call """ & SCGen & """")
Call DelFile(SCGen)

' Run A DAM COMMAND WITH OUTPUT
Function runCMD(strRunCmd)
 Set objExec = oShell.Exec(strRunCmd)
 Do While Not objExec.StdOut.AtEndOfStream
   cline = objExec.StdOut.ReadLine()
   WScript.Echo cline
 Loop
End Function

' Run A CMD and Get it's output as a single line
Function runCMDOut(strRunCmd)
 Set objExec = oShell.Exec(strRunCmd)
 Do While Not objExec.StdOut.AtEndOfStream
   cmdline = cmdline & objExec.StdOut.ReadLine()
 Loop
 runCMDOut = cmdline
End Function

' Get a Link's Attributes
Function GetLnkAttr(Attribs)
	For i = 1 To Len(Attribs)
		result = result & "+" & Mid(Attribs, i, 1) & " "
	Next
	GetLnkAttr = Trim(result)
End Function

' Del A file Safely
Sub DelFile(File)
  If objFSO.FileExists(File) Then
     objFSO.DeleteFile(File)
  End If
End Sub
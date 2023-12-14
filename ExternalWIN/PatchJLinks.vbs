linksfile = WScript.Arguments(0)
PathOld = WScript.Arguments(1)
PathNew = WScript.Arguments(2)
TYPESLNK = UCase(WScript.Arguments(3))
' Process Args
HASJUNC = InStr(TYPESLNK, "J") > 0
HASSYMDIR = InStr(TYPESLNK, "D") > 0
HASSYMFILE = InStr(TYPESLNK, "F") > 0
LNKTYPES = ""
If HASJUNC THEN LNKTYPES = "J" End If
If HASSYMDIR THEN LNKTYPES = LNKTYPES & "D" End If
If HASSYMFILE THEN LNKTYPES = LNKTYPES & "F" End If
PathOldJunc = Mid(PathOld, InStrRev(PathOld, ":\") - 1)
' Initialize REGEX Pattern
Dim regex
Set regex = New RegExp
regex.Global = True
regex.IgnoreCase = True
regex.Pattern = "[\*\?\""\<\>\|]"
' Start The Program
PathDir = ""
WScript.Echo "Patching LINKTYPES:" & LNKTYPES & " Replacing:" & PathOld & " With:" & PathNew
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = WScript.CreateObject("WScript.Shell")
Set objFile = objFSO.OpenTextFile(linksfile, 1, False)
Do Until objFile.AtEndOfStream
	line = objFile.ReadLine
	pos = InStr(line, ":\")
	If InStr(1, line, " ") = 1 Then
		If pos > 0 Then
			PathDir = Mid(line, pos - 1)
			IF Not Right(PathDir, 1) = "\" THEN
				PathDir = PathDir & "\"
			End If
			' WScript.Echo "Setting New Dir:" & PathDir
		End if
	ElseIf Trim(line) <> "" Then
		startIndex = InStr(line, "<")
		If startIndex > 0 Then
			LinkType = UCase(Mid(line, startIndex + 1, InStr(line, ">") - startIndex - 1))
			IF (LinkType = "JUNCTION" And HASJUNC) Or (LinkType = "SYMLINKD" And HASSYMDIR) Or (LinkType = "SYMLINK" And HASSYMFILE) Then
				LinkLine = Trim(Mid(line, InStr(line, ">") + 1))
				If InStr(LinkLine, PathOld) > 0 Then
					indexSep = InStrRev(LinkLine, "[")
					indexSanity = indexSep - 2
					If indexSanity > 0 Then
						LinkDir = PathDir & Left(LinkLine, indexSanity)
						TargOrg = Mid(LinkLine, indexSep + 1, Len(LinkLine) - indexSep - 1)
						' All other NT Meta paths are fine using MKLNK /J command Except for This Prefix due to a bug with MKLINK with Junctions Tested Win 10-11
						IF LinkType = "JUNCTION" And InStr(TargOrg, "\??\") > 0 Then
							indexJun = InStrRev(TargOrg, ":\")
							TargNew = regex.Replace(Replace(Mid(TargOrg, indexJun - 1), PathOldJunc, PathNew, 1, 1), "")
						Else
							TargNew = Replace(TargOrg, PathOld, PathNew, 1, 1)
						End If
						WScript.Echo LinkDir & " " & LinkType & " """ & TargOrg & """ To: """ & TargNew & """"
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
						LNKAttribs = GetLnkAttr(LinkDir)
						runCMD("cmd /c " & DELCMD)
						runCMD("cmd /c " & MKCMD)
						IF LNKAttribs <> "" THEN
							WScript.Echo "cmd /c attrib /L " & LNKAttribs & " """ & LinkDir & """"
							runCMD("cmd /c attrib /L " & LNKAttribs & " """ & LinkDir & """")
						End If
					Else
						WScript.Echo "ERR Skipping Maulformed Line:" & LinkLine
					End If
				Else
					WScript.Echo "Skipping: " & LinkLine
				End If
			End If
		End If
	End If
Loop

' Run A DAM COMMAND WITH OUTPUT
Function runCMD(strRunCmd)
 Set objExec = oShell.Exec(strRunCmd)
 Do While Not objExec.StdOut.AtEndOfStream
   cline = objExec.StdOut.ReadLine()
   ' WScript.Echo cline
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
Function GetLnkAttr(FileLNK)
Attribs = ""
AttLine = runCMDOut("cmd /c attrib /L """ & FileLNK & """")
indexAtt = InStr(AttLine, ":\") - 2
IF indexAtt > 0 Then
	Attribs = Replace(Left(AttLine, indexAtt), " ", "")
	' Attrib Command has File or Path Not Found
	IF Right(Attribs, 1) = "-" Then
		Attribs = ""
	Else
		For i = 1 To Len(Attribs)
			result = result & "+" & Mid(Attribs, i, 1) & " "
		Next
		Attribs = Trim(result)
	End If
End If
GetLnkAttr = Attribs
End Function
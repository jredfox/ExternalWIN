linksfile = WScript.Arguments(0)
PathOld = WScript.Arguments(1)
PathNew = WScript.Arguments(2)
PathDir = ""
WScript.Echo "Fixing Junctions And Symbolic Links:" & " Replacing:" & PathOld & " With:" & PathNew
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
			IF LinkType = "JUNCTION" Or LinkType = "SYMLINKD" Or LinkType = "SYMLINK" Then
				LinkLine = Trim(Mid(line, InStr(line, ">") + 1))
				If InStr(LinkLine, PathOld) > 0 Then
					LinkLen = Len(LinkLine)
					indexSep = InStrRev(LinkLine, "[")
					LinkDir = PathDir & Left(LinkLine, indexSep - 2)
					TargOrg = Mid(LinkLine, indexSep + 1, LinkLen - indexSep - 1)
					IF LinkType = "JUNCTION" Then
						indexJun = InStrRev(LinkLine, ":\")
						TargNew = Replace(Mid(LinkLine, indexJun - 1, LinkLen - indexJun), PathOld, PathNew, 1, 1)
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
					runCMD("cmd /c echo " & DELCMD)
					runCMD("cmd /c echo " & MKCMD)
				Else
					WScript.Echo "Skipping: " & LinkLine
				End If
			End If
		Else
			' WScript.Echo "Skipping Missing LinkType:" & line
		End If
	End If
Loop

' Run A DAM COMMAND WITH OUTPUT
Function runCMD(strRunCmd)
 Set objExec = oShell.Exec(strRunCmd)
 Do While Not objExec.StdOut.AtEndOfStream
   cline = objExec.StdOut.ReadLine()
   WScript.Echo cline
 Loop
End Function
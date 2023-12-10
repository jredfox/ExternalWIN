linksfile = WScript.Arguments(0)
PathOld = WScript.Arguments(1)
PathNew = WScript.Arguments(2)
PathDir = ""
WScript.Echo "Patching Junctions And Symbolic Links:" & " Replacing:" & PathOld & " With:" & PathNew
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
			endIndex = InStr(line, ">")
			LinkType = UCase(Mid(line, startIndex + 1, endIndex - startIndex - 1))
			IF LinkType = "JUNCTION" Or LinkType = "SYMLINKD" Or LinkType = "SYMLINK" Then
				LinkLine = Trim(Mid(line, InStr(line, ">") + 1))
				' Seperate the target from the main path
				indexColon = InStr(LinkLine, PathOld)
				If indexColon > 0 Then
					indexBracket = InStrRev(LinkLine, "[", indexColon)
					indexSanity = indexBracket - 2
					IF indexSanity > 0 Then
						LinkDir = PathDir & Left(LinkLine, indexSanity)
						TargPath = Mid(LinkLine, indexBracket + 1, Len(LinkLine) - indexBracket - 1)
						TargPathNew = Replace(TargPath, PathOld, PathNew, 1, 1)
						WScript.Echo "Patching Link '" & LinkDir & "' '" & TargPath & "' '" & TargPathNew & "'"
						DELCMD = "RD """ & LinkDir & """"
						IF LinkType = "JUNCTION" THEN
							MKFlags = " /J"
						ElseIf LinkType = "SYMLINKD" THEN
							MKFlags = " /D"
						Else
							MKFlags = ""
							DELCMD = "DEL /F /Q /A """ & LinkDir & """"
						End If
						MKCMD = "MKLINK" & MKFlags & " """ & LinkDir & """ " & """" & TargPathNew & """"
						runCMD("cmd /c " & DELCMD)
						runCMD("cmd /c " & MKCMD)
					Else
						WScript.Echo "Skipping MaulFormed Dir Entry:" & PathDir & LinkLine
					End If
				Else
					' WScript.Echo "Skipping Link:" & PathDir & LinkLine
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
  WScript.Echo objExec.StdOut.ReadLine()
 Loop
End Function
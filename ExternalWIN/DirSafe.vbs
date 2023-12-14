Const ForReading = 1, ForAppending = 8

' Function to check reparse point attribute
Function HasReparsePoint(folder)
    If (folder.Attributes And 1024) = 0 Then
        HasReparsePoint = False
    Else
        HasReparsePoint = True
    End If
End Function

' Creates the Black list into memory for fast recall
Dim BlackList(), counter
Sub LoadSrchCFG()
counter = 0
cfgpath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
Call AddSlash(cfgpath)
Set CFGFILE = objFSO.OpenTextFile(cfgpath & "DirSRCHBlacklist.cfg", ForReading, True)
Do Until CFGFILE.AtEndOfStream
	line = Trim(CFGFILE.ReadLine)
	If line <> "" Then
		IF Mid(line, 2, 1) = ":" Then
			line = Mid(line, 3)
		End If
		Call AddSlash(line)
		ReDim Preserve BlackList(counter)
        BlackList(counter) = line
        counter = counter + 1
	End If
Loop
End Sub

Sub AddSlash(ByRef str)
    If Right(str, 1) <> "\" Then
        str = str & "\"
    End If
End Sub

Function IsBlackListed(filePath)
    Call AddSlash(filePath)
	IsBlackListed = False
    FOR EACH bdir IN BlackList
		If InStr(1, Mid(filePath, 3), bdir, vbTextCompare) = 1 Then
			IsBlackListed = True
			EXIT FOR
		END IF
	NEXT
End Function

Sub EnumerateFolders(folder)
    Dim subfolder
	If Not IsBlackListed(folder.Path) Then
		On Error Resume Next
		For Each file In folder.Files
			Call PrintFile(file.Path, HasReparsePoint(file), False)
		Next
		On Error Resume Next
		For Each subfolder In folder.Subfolders
			SubPath = subfolder.Path
			If Not IsBlackListed(SubPath) Then
				IDirL = HasReparsePoint(subfolder)
				Call PrintFile(SubPath, IDirL, True)
				If Recurse And Not IDirL Then 
					EnumerateFolders(subfolder)
				End If
			End If
		Next
	End If
End Sub

Sub PrintFile(PFile, IsLink, IsDir)
	' Check If The File Attributes allows Printing of the file
	' Exit Sub 
	' Attribs = PFile.Attributes
	FileLine = PFile
	If PLnks Then
		If IsParseable Then
			FileLine = "<" & FileLine & ">"
		End If
		If IsLink Then
			FileLine = "<LINK> " & FileLine
		ElseIf IsDir Then
			FileLine = "<DIR> " & FileLine
		ElseIf IsParseable Then
			FileLine = "<FILE> " & FileLine
		End IF
	End IF
	WScript.Echo FileLine
End Sub

' Start Argument Handling
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")
If WScript.Arguments.Count < 1 Then
	Help()
End If
StrArg = WScript.Arguments(0)
IsHelp = Trim(LCase(StrArg))
If (IsHelp = "/?" Or IsHelp = "/help") Then
	Help()
End If
Set SDir = objFSO.GetFolder(objFSO.GetAbsolutePathName(StrArg))
Recurse = True
PrintType = 1
If WScript.Arguments.Count > 1 Then
	Recurse = UCase(Trim(WScript.Arguments(1))) <> "TRUE"
End If
If WScript.Arguments.Count > 2 Then
	PrintType = CInt(Trim(WScript.Arguments(2)))
	If PrintType > 4 Or PrintType < 1 Then
		WScript.Echo "ERR: PrintType Must Be a Value Between 1-4"
		WScript.Quit
	End If
End If
PLnks = PrintType > 1
IsParseable = PrintType > 2
' Print the intial starting directory
Call PrintFile(SDir.Path, HasReparsePoint(SDir), objFSO.FolderExists(SDir))
Call LoadSrchCFG()
Call EnumerateFolders(SDir)

Sub Help()
WScript.Echo ""
WScript.Echo "#####################################################"
WScript.Echo "DirSafe.vbs <BOOL RECURSE> <INT PRINTTYPE> <ATTRIBS>"
WScript.Echo "#####################################################"
WScript.Echo vbCrLf & "Print Types"
WScript.Echo "_____________________________________________________"
WScript.Echo "1 Bare = C:\Path" & vbCrLf & "2 Mimic Dir = <TYPE> Path [Target]" & vbCrLf & "3 Parsable = <TYPE> <PATH> <LINKTARGET>" & vbCrLf & "4 Hard Links = <TYPE> <PATH> <LINKTARGET> [HARDLINK1;HardLink2]" & vbCrLf
WScript.Echo "Attributes:"
WScript.Echo "_____________________________________________________"
WScript.Echo "A Archiving"
WScript.Echo "B SMR Blob"
WScript.Echo "C Compressed"
WScript.Echo "D Dirs"
WScript.Echo "E Encrypted"
WScript.Echo "H Hidden"
WScript.Echo "I Not Indexed"
WScript.Echo "L Reparse Points"
WScript.Echo "M Cloud Files"
WScript.Echo "N Null"
WScript.Echo "O Offline"
WScript.Echo "P Pinned"
WScript.Echo "R ReadOnly"
WScript.Echo "S System"
WScript.Echo "U Unpinned"
WScript.Echo "V Integrity (ReFS Only)"
WScript.Echo "X No Scrub  (ReFS Only)"
WScript.Echo "- Prefix meaning not"
WScript.Quit
End Sub
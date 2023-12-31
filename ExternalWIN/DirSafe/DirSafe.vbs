Const ForReading = 1, ForAppending = 8
Dim BlackList(), NoLnks(), counter, countera
Dim ArrDirs(), ArrWildCards(), counterDirs, counterWild

Sub EnumerateFolders(folder, index)
	FPath = folder.Path
	If Not IsBlackListed(FPath) Then
		For Each d In ArrWildCards(index)
			DPath = FPath
			Call AddSlash(DPath)
			DPath = DPath & d
			Call runDir(dircmd & " """ & DPath & """", FPath)
		Next
		On Error Resume Next
		Dim subfolder
		For Each subfolder In folder.Subfolders
			SubPath = subfolder.Path
			If Recurse And (Not IsBlackListed(SubPath)) And (Not IsDirLink(subfolder, SubPath)) Then
				Call EnumerateFolders(subfolder, index)
			End If
		Next
	End If
End Sub

' Run a command no output
Sub runDir(strRunCmd, folder)
 dir = folder
 Call AddSlash(dir)
 Set objExec = oShell.Exec(strRunCmd)
 Do While Not objExec.StdOut.AtEndOfStream
	cline = objExec.StdOut.ReadLine()
	If Bare Then
		WScript.Echo dir & cline
	Else
		cmdline = cmdline & cline & vbCrlf
	End If
 Loop
 If Not Bare And objExec.ExitCode = 0 Then
	cmdline = Left(cmdline, InStrRev(cmdline, vbCrLf) - 1)
	WScript.Echo cmdline
 End If
End Sub

Function IsDirLink(folder, FPATH)
IsDirLink = HasReparsePoint(folder)
IF IsDirLink Then
   IsDirLink = IsLink(FPATH)
End If
End Function

' Function to check reparse point attribute
Function HasReparsePoint(folder)
    If (folder.Attributes And 1024) = 0 Then
        HasReparsePoint = False
    Else
        HasReparsePoint = True
    End If
End Function

Function IsLink(FPATH)
UPath = FPATH
IsLink = True
If Right(UPath, 1) = "\" Then
	UPath = Left(UPath, Len(UPath) - 1)
End If
Set objExec = oShell.Exec("cmd /c fsutil reparsepoint query """ & UPath & """")
ReparseId = ""
' Get the ReparsePoint Id
Do While Not objExec.StdOut.AtEndOfStream
	fline = UCase(objExec.StdOut.ReadLine())
	pos = InStr(fline, ":")
	If pos > 0 Then
		pos2 = InStr(pos, fline, "0X")
		If pos2 > 0 Then
			ReparseId = Trim(Mid(fline, pos + 1))
			Exit Do
		End If
	End If
Loop
' See If Reparse Value Matches a non link reparse point value
For Each val In NoLnks
	If val = ReparseId Then
		IsLink = False
		Exit For
	End If
Next
End Function

Function IsBlackListed(fp)
	filePath = Mid(fp, 3)
    Call AddSlash(filePath)
	IsBlackListed = False
    FOR EACH bdir IN BlackList
		If InStr(1, filePath, bdir, vbTextCompare) = 1 Then
			IsBlackListed = True
			EXIT FOR
		END IF
	NEXT
End Function

Sub AddSlash(ByRef str)
    If Right(str, 1) <> "\" Then
        str = str & "\"
    End If
End Sub

' Gets the Minimum Valid index
Function MinIndex(a, b)
    If (a < 1) Or (b < a And b > 0) Then
        MinIndex = b
    Else
        MinIndex = a
    End If
End Function
' add item to array
Sub AddItem(arr, size, val)
	ReDim Preserve arr(size)
    arr(size) = val
	size = size + 1
End Sub

' Parse the Array of dirs and wildcards per dir
Sub ParseDirs(strdirs)
If strdirs = "" Then
	strdirs = objFSO.GetAbsolutePathName("")
End If
dirsplits = Split(strdirs, ";")
For Each strdir In dirsplits
	WIndex = MinIndex(InStr(strdir, "*"), InStr(strdir, "?"))
	If WIndex > 0 Then
		SlashIndex = InStrRev(strdir, "\", WIndex)
		If SlashIndex < 1 Then
			SIndex = WIndex
		Else
			SIndex = SlashIndex + 1
		End If
		DirIndex = SlashIndex - 1
		If DirIndex < 1 Then
			DirIndex = 0
		End If
		If DirIndex = 0 And Left(strdir, 1) = "\" Then
			DirIndex = DirIndex + 1
		End If
		Call AddItem(ArrDirs, counterDirs, objFSO.GetAbsolutePathName(Mid(strdir, 1, DirIndex)))
		wildcard = Mid(strdir, SIndex)
		Cards = Split(wildcard, "|")
		Call AddItem(ArrWildCards, counterWild, Cards)
	Else
		Call AddItem(ArrDirs, counterDirs, objFSO.GetAbsolutePathName(strdir))
		Call AddItem(ArrWildCards, counterWild, Array(""))
	End If
Next
End Sub

' Creates the Black list into memory for fast recall
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
CFGFILE.Close
' Load the Non Shortcuts ReparsePoint WhiteList
Set CFGLNKFILE = objFSO.OpenTextFile(cfgpath & "DirNonShortcuts.cfg", ForReading, True)
Do Until CFGLNKFILE.AtEndOfStream
	line = Trim(CFGLNKFILE.ReadLine)
	If line <> "" Then
		pos = InStr(line, "=")
		If pos > 0 Then
			line = UCase(Trim(Mid(line, pos + 1)))
			ReDim Preserve NoLnks(countera)
			NoLnks(countera) = line
			countera = countera + 1
		End If
	End if
Loop
CFGLNKFILE.Close
End Sub

' Start Argument Handling
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")
StrArg = ""
If WScript.Arguments.Count > 0 Then
	StrArg = WScript.Arguments(0)
End If
IsHelp = Trim(LCase(StrArg))
If (IsHelp = "/?" Or IsHelp = "/help") Then
	Help()
End If
Recurse = False
Bare = False
AttFilter = ""
If WScript.Arguments.Count > 1 Then
	Recurse = UCase(Trim(WScript.Arguments(1))) = "TRUE"
	If WScript.Arguments.Count > 2 Then
		Bare = UCase(Trim(WScript.Arguments(2))) = "TRUE"
	End If
	If WScript.Arguments.Count > 3 Then
		AttFilter = Trim(WScript.Arguments(3))
	End If
End If
If Bare Then
	dircmd = "cmd /c dir /B /A"
Else
	dircmd = "cmd /c dir /A"
End If
' Change /A to /A:Attribs and you can add additional flags by adding a space fallowed by arguments
If AttFilter <> "" Then
	dircmd = dircmd & ":" & AttFilter
End If
Call LoadSrchCFG()
Call ParseDirs(StrArg)
c = 0
For Each d In ArrDirs
	Call EnumerateFolders(objFSO.GetFolder(d), c)
	c = c + 1
Next

Sub Help()
WScript.Echo ""
WScript.Echo "#################################################################################"
WScript.Echo "DirSafe.vbs <DIR Or Dir;Dir2\*PDF|File*.txt> <BOOL RECURSE> <BOOL BARE> <ATTRIBS>"
WScript.Echo "#################################################################################"
WScript.Echo "A Archiving"
WScript.Echo "D Dirs"
WScript.Echo "H Hidden"
WScript.Echo "I Not Indexed"
WScript.Echo "L Reparse Points"
WScript.Echo "O Offline"
WScript.Echo "R ReadOnly"
WScript.Echo "S System"
WScript.Echo "- Prefix meaning not"
WScript.Quit
End Sub
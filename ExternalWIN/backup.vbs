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
	FPath = folder.Path
	If Not IsBlackListed(FPath) Then
		Call runDir(dircmd & " """ & folder & """", FPath)
		On Error Resume Next
		For Each subfolder In folder.Subfolders
			If Recurse And (Not IsBlackListed(subfolder.Path)) And (Not HasReparsePoint(subfolder)) Then
					EnumerateFolders(subfolder)
			End If
		Next
	End If
End Sub

' Run a command no output
Sub runDir(strRunCmd, folder)
 dir = folder
 AddSlash(dir)
 Set objExec = oShell.Exec(strRunCmd)
 Do While Not objExec.StdOut.AtEndOfStream
	cline = objExec.StdOut.ReadLine()
	If Bare Then
		WScript.Echo dir & cline
	Else
		WScript.Echo cline
	End If
 Loop
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
Set SDir = objFSO.GetFolder(objFSO.GetAbsolutePathName(StrArg))
Recurse = UCase(Trim(WScript.Arguments(1))) = "TRUE"
Bare = UCase(Trim(WScript.Arguments(2))) = "TRUE"
AttFilter = Trim(WScript.Arguments(3))
If Bare Then
	dircmd = "cmd /c dir /B /A"
Else
	dircmd = "cmd /c dir /A"
End If
' Change /A to /A:Attribs
If AttFilter <> "" Then
	dircmd = dircmd & ":" & AttFilter
End If
Call LoadSrchCFG()
Call EnumerateFolders(SDir)

Sub Help()
WScript.Echo ""
WScript.Echo "#####################################################"
WScript.Echo "DirSafe.vbs <BOOL RECURSE> <BOOL BARE> <ATTRIBS>"
WScript.Echo "#####################################################"
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
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
	' WScript.Echo "BLIST " & bdir & " " & Mid(filePath, 3)
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
			WScript.Echo file
		Next
		On Error Resume Next
		For Each subfolder In folder.Subfolders
			If Not IsBlackListed(subfolder.Path) Then 
				WScript.Echo subfolder.Path
				If Recurse And Not HasReparsePoint(subfolder) Then 
					EnumerateFolders(subfolder)
				End If
			End If
		Next
	End If
End Sub

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")
Set SDir = objFSO.GetFolder(WScript.Arguments(0))
Recurse = True
If WScript.Arguments.Count > 1 Then
	Recurse = UCase(WScript.Arguments(1)) <> "FALSE"
End If
' Print the intial starting directory
WScript.Echo SDir.Path
Call LoadSrchCFG()
Call EnumerateFolders(SDir)

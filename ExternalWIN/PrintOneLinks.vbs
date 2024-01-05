links = WScript.Arguments(0)
dirs = WScript.Arguments(1)
target = RootForm(AddSlash(WScript.Arguments(2)))
SizeTarg = Len(target)
LTarget = LCase(target)
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Check if the file path starts with the parent directory path
Function IsChildOfFile(parentDirectory, filePath)
    If InStr(1, filePath, parentDirectory, vbTextCompare) = 1 Then
        IsChildOfFile = True
    Else
        IsChildOfFile = False
    End If
End Function

' Cache all of the OneDrive Directories into memory for faster comparison per line 
Dim OneDirs(), counter
IF Trim(dirs) <> "" Then
Set objFile = objFSO.OpenTextFile(dirs, 1, False)
counter = 0
Do Until objFile.AtEndOfStream
    line = objFile.ReadLine
    If Trim(line) <> "" Then ' Check if the line is not empty
        ReDim Preserve OneDirs(counter)
        OneDirs(counter) = RootForm(AddSlash(line))
        counter = counter + 1
    End If
Loop
objFile.Close
End If

' Print OneDrive Links if and only if they are not a child of a onedrive directory
Set objFile = objFSO.OpenTextFile(links, 1, False)
Do Until objFile.AtEndOfStream
	line = RootForm(objFile.ReadLine)
	SLine = LCase(AddSlash(line))
	ShouldPrint = true
	FOR EACH OneDir IN OneDirs
		IF IsChildOfFile(OneDir, SLine) Then
			ShouldPrint = false
			EXIT FOR
		END IF
	NEXT
	IF ShouldPrint Then
		IF (SLine <> LTarget) And (InStr(1, SLine, LTarget) = 1) Then
			WScript.Echo Mid(line, SizeTarg) ' Prints only children of the root target
		END IF
	END IF
Loop
objFile.Close

' Convert The Paths to Root Form
Function RootForm(ByRef str)
	IF Mid(str, 2, 1) = ":" Then
		RootForm = Mid(str, 3)
	Else
		RootForm = str
	End IF
End Function

' Add a Slash to the paths if required
Function AddSlash(ByRef str)
    If Right(str, 1) <> "\" Then
        AddSlash = str & "\"
	Else
		AddSlash = str
    End If
End Function
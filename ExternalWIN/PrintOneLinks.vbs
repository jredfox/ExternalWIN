links = WScript.Arguments(0)
dirs = WScript.Arguments(1)
target = WScript.Arguments(2)
' Fix the Target's Directory to be in the proper root "\" format instead of Drive format
IF Mid(target, 2, 1) = ":" Then
	target = Mid(target, 3)
	IF target = "" THEN
	   target = "\"
	End If
END IF
' Ensure the target ends with a backslash
IF Len(target) > 1 And Not Right(target, 1) = "\" THEN
    target = target & "\"
END IF
Set objFSO = CreateObject("Scripting.FileSystemObject")

Function IsChildOfFile(parentDirectory, filePath)
    ' Check if the file path starts with the parent directory path
    If InStr(1, filePath, parentDirectory, vbTextCompare) = 1 Then
        IsChildOfFile = True
    Else
        IsChildOfFile = False
    End If
End Function

' Cache all of the OneDrive Directories into memory for faster comparison per line 
Dim OneDirs(), counter
Set objFile = objFSO.OpenTextFile(dirs, 1, False)
counter = 0
Do Until objFile.AtEndOfStream
    line = objFile.ReadLine
    If Trim(line) <> "" Then ' Check if the line is not empty
        ReDim Preserve OneDirs(counter)
        OneDirs(counter) = line
        counter = counter + 1
    End If
Loop
objFile.Close

' Print OneDrive Links if and only if they are not a child of a onedrive directory
Set objFile = objFSO.OpenTextFile(links, 1, False)
Do Until objFile.AtEndOfStream
    line = Mid(objFile.ReadLine, 3)
	ShouldPrint = true
	FOR EACH OneDir IN OneDirs
		IF IsChildOfFile(OneDir, line) Then
			ShouldPrint = false
			EXIT FOR
		END IF
	NEXT
	IF ShouldPrint Then
		IF InStr(1, line, target) = 1 Then
			WScript.Echo Mid(line, Len(target)) ' Convert The Path to the Perspective of the Target's Root folder Case Sensitive
		ELSE
			WScript.Echo line
		END IF
	END IF
Loop
objFile.Close
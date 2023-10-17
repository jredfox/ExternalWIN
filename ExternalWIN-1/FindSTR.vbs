' Check the number of command-line arguments
If WScript.Arguments.Count < 3 Then
    WScript.Echo "Usage: SearchScript.vbs <searchString> <filePath> <caseSensitive>"
    WScript.Quit(1) ' Exit with an error code
End If

' Retrieve the search string, file path, and caseSensitive flag from the command-line arguments
searchString = WScript.Arguments(0)
filePath = WScript.Arguments(1)
caseSensitive = CBool(WScript.Arguments(2)) ' Convert the argument to a boolean

' Create a filesystem object
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Open the file for reading
Set objFile = objFSO.OpenTextFile(filePath, 1, False)

' Initialize a variable to indicate whether the string was found
Dim found
found = False

' Loop through each line in the file
Do Until objFile.AtEndOfStream
    line = objFile.ReadLine
    If caseSensitive Then
        ' Perform a case-sensitive search for the string
        If InStr(1, line, searchString) > 0 Then
            WScript.Echo "Found (Case-Sensitive): " & line
            found = True
            Exit Do
        End If
    Else
        ' Perform a case-insensitive search for the string
        If InStr(1, LCase(line), LCase(searchString), vbTextCompare) > 0 Then
            WScript.Echo "Found: " & line
            found = True
            Exit Do
        End If
    End If
Loop

' Close the file
objFile.Close

' Clean up objects
Set objFile = Nothing
Set objFSO = Nothing

' Set the exit code based on whether the string was found
If found Then
    WScript.Quit(0) ' String was found
Else
    WScript.Quit(1) ' String was not found
End If

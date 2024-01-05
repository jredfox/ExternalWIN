input = RootForm(WScript.Arguments(0))
target = RootForm(AddSlash(WScript.Arguments(1)))

' Echo Realtive Path here
LInput = AddSlash(LCase(input))
LTarget = LCase(target)
IF (LInput <> LTarget) And (InStr(1, LInput, LTarget) = 1) Then
	WScript.Echo Mid(input, Len(target)) ' Prints only children of the target
End If
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
input = WScript.Arguments(0)
target = WScript.Arguments(1)
' Convert to a root Path of the input string
IF Mid(input, 2, 1) = ":" Then
	input = Mid(input, 3)
End IF
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
IF InStr(1, LCase(input), LCase(target)) = 1 Then
	WScript.Echo Mid(input, Len(target)) ' Convert The Path to the Perspective of the Target's Root folder
End If
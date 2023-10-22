Set objShell = CreateObject("Shell.Application")
' Set Vars
ToClose = WScript.Arguments(0)
Set windows = objShell.Windows
Const DurationInSeconds = 120
EndTime = DateAdd("s", DurationInSeconds, Now)

' Iterate through each open window and print its path
Do While Now < EndTime
For Each window in windows
    If InStr(1, window.FullName, "explorer.exe", vbTextCompare) > 0 And StrComp(window.Document.Folder.Self.Path, ToClose, vbTextCompare) = 0 Then
        WScript.Echo "Closing File Explorer Popup: " & window.Document.Folder.Self.Path
		window.Quit
    End If
Next
' Sleep for 1ms before looping again
WScript.Sleep 1
Loop

' Clean up the objects
Set objShell = Nothing
Set windows = Nothing
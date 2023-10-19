If WScript.Arguments.Count <> 1 Then
    WScript.Echo "Usage: cscript Sleep.vbs <milliseconds>"
    WScript.Quit 1
End If

Dim sleepTime
sleepTime = WScript.Arguments(0)

If IsNumeric(sleepTime) Then
    WScript.Sleep CLng(sleepTime)
    WScript.Echo "Slept for " & sleepTime & " milliseconds."
Else
    WScript.Echo "Invalid input. Please provide a valid number of milliseconds."
End If

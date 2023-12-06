wim = WScript.Arguments(0)
index = WScript.Arguments(1)
winpe = UCase(WScript.Arguments(2))
Set objShell = CreateObject("WScript.Shell")
Set objExec = objShell.Exec("dism /List-Image /ImageFile:""" & wim & """ /index:" & index)
pid = objExec.ProcessID
Do While Not objExec.StdOut.AtEndOfStream
    strLine = objExec.StdOut.ReadLine()
	' IF the WIM Image Doesn't Contain The Target then Assume it's the entire C Drive
	If Right(strLine, 1) = "\" And Len(strLine) > 2 Then
		WScript.Echo "\"
		IF winpe = "TRUE" Then
			objExec.Terminate
		Else
			objShell.Run "taskkill /F /PID " & pid, 0, True
		End If
		WScript.Quit
	End If
    If InStr(1, strLine, "\EXTWNCAP$") = 1 Then
		WScript.Echo strLine
		IF winpe = "TRUE" Then
			objExec.Terminate
		Else
			objShell.Run "taskkill /F /PID " & pid, 0, True
		End If
		WScript.Quit
    End If
Loop
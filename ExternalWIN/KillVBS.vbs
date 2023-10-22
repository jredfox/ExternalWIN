Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set colProcesses = objWMIService.ExecQuery("Select * from Win32_Process Where Name = 'cscript.exe' or Name = 'wscript.exe'")

' Specify the path of the VBScript to be terminated
ToKill = WScript.Arguments(0)

For Each objProcess in colProcesses
    CommandLine = objProcess.CommandLine
    ' Check if the process command line contains the specified script path
    If InStr(1, CommandLine, ToKill, vbTextCompare) > 0 Then
        ' Terminate the process
        objProcess.Terminate()
        WScript.Echo "Terminated process with PID: " & objProcess.ProcessId
    End If
Next

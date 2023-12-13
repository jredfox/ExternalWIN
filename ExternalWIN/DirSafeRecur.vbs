Set objFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")
Const ForReading = 1, ForAppending = 8
TargDir = objFSO.GetAbsolutePathName(WScript.Arguments(0))
TMPDIR = oShell.ExpandEnvironmentStrings("%TMP%")
TMPCMD = TMPDIR & "\EXTWNDIRCMD.txt"
TMPDIRS = TMPDIR & "\EXTWNTMPDIRS.txt"
DIRSALL = TMPDIR & "\EXTWNDIRSALL.txt"
' Cleanup TMPDIRS so the script doesn't get confused
Call DelFile(TMPDIRS)
Call DelFile(DIRSALL)
' Run the initial dir commands before looping through the text file recursively
Call InitDir(TargDir)
Set AppendTMPDIRS = objFSO.OpenTextFile(TMPDIRS, ForAppending, True)
Call runDir(TargDir)
Call UpdateDirs()
' Start Getting the directories Recursively
ShouldRun = True
CurrentDir = TargDir
Call AddSlash(CurrentDir)

Do While ShouldRun = True
WScript.Echo "Starting At Index:" & CurrentDir
ShouldRun = False
FoundDir = False
Set AppendTMPDIRS = objFSO.OpenTextFile(TMPDIRS, ForAppending, True)
Set DIRSALLFILE = objFSO.OpenTextFile(DIRSALL, ForReading, False)
Do Until DIRSALLFILE.AtEndOfStream
	dirline = DIRSALLFILE.ReadLine
	Call AddSlash(dirline)
	If FoundDir Then
		Call runDir(dirline)
		ShouldRun = True
		CurrentDir = dirline
	ElseIF CurrentDir = dirline Then
	   FoundDir = True
	End If
Loop
DIRSALLFILE.Close
Call UpdateDirs()
Loop

' Update the directories from the TMPDIRS that just generated and then delete the TMPDIRS
Sub UpdateDirs()
AppendTMPDIRS.Close
If objFSO.FileExists(TMPDIRS) Then
	Set DIRALLFILE = objFSO.OpenTextFile(DIRSALL, ForAppending, True)
	Set TMPDIRSFILE = objFSO.OpenTextFile(TMPDIRS, ForReading, False)
	Do Until TMPDIRSFILE.AtEndOfStream
		DIRALLFILE.WriteLine TMPDIRSFILE.ReadLine
	Loop
	DIRALLFILE.Close
	TMPDIRSFILE.Close
	Call DelFile(TMPDIRS)
End If
End Sub

' Runs a Single non Recursive Dir command
Sub runDir(ByRef CMDDir)
  Call DelFile(TMPCMD)
  Call AddSlash(CMDDir)
  Set objExec = oShell.Exec("cmd /c dir /B /A:D-L """ & CMDDir & """")
  Do While Not objExec.StdOut.AtEndOfStream
	cline = objExec.StdOut.ReadLine()
	If Trim(cline) <> "" Then
		AppendTMPDIRS.WriteLine CMDDir & cline
	End If
  Loop
End Sub

' Initialize the DIRSALL file with the root folder
Sub InitDir(DirINIT)
	Set DIRALLFILE = objFSO.OpenTextFile(DIRSALL, ForAppending, True)
	DIRALLFILE.WriteLine DirINIT & line
	DIRALLFILE.Close
End Sub

Sub AddSlash(ByRef str)
    If Right(str, 1) <> "\" Then
        str = str & "\"
    End If
End Sub

' Del A file Safely
Sub DelFile(File)
  If objFSO.FileExists(File) Then
     objFSO.DeleteFile(File)
  End If
End Sub

' Run a command no output
Function runCMD(strRunCmd)
 Set objExec = oShell.Exec(strRunCmd)
 Do While Not objExec.StdOut.AtEndOfStream
   cline = objExec.StdOut.ReadLine()
   ' WScript.Echo cline
 Loop
End Function
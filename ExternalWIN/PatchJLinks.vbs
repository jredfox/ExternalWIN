linksfile = WScript.Arguments(0)
PathOld = WScript.Arguments(1)
PathNew = WScript.Arguments(2)
WScript.Echo "Patching:" & linksfile & " Replacing:" & PathOld & " With:" & PathNew
Set objFSO = CreateObject("Scripting.FileSystemObject")

' TODO
Set objFile = objFSO.OpenTextFile(links, 1, False)
Do Until objFile.AtEndOfStream
	line = objFile.ReadLine
Loop
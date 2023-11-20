@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set drive=%~1
set drive=!drive:~0,1!
echo Indexing The !drive! Drive
set extindex=%TMP%\EXTWINDirIndex.txt
dir /S /A^:D-L /B !drive!^:\ >!extindex!
call "%~dp0OneDriveLinkFinder.exe" "!extindex!"
pause
@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set drive=%~1
set drive=!drive:~0,1!
set dirs=%TMP%\OneDriveDirs.txt
set EXTIndex=%TMP%\OneDriveLinks.txt
del /F "!dirs!" /s /q /a >nul 2>&1
del /F "!EXTIndex!" /s /q /a >nul 2>&1
call "%~dp0PrintOneDrive.bat" "!drive!" >!dirs!
dir /S /B /A^:LO !drive!^:\ >!EXTIndex!
cscript /nologo "%~dp0PrintOneLinks.vbs" "!EXTIndex!" "!dirs!"
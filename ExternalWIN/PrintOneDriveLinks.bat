@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set drive=%~1
IF /I "!drive:~3!" EQU "" (set drive=!drive:~0,1!^:\)
REM IF the Directory Doesn't Exist do not Continue as the Dir command will freak out and take way too long
IF NOT EXIST "!drive!" (exit /b)
set dirs=%TMP%\OneDriveDirs.txt
set EXTIndex=%TMP%\OneDriveLinks.txt
del /F "!dirs!" /s /q /a >nul 2>&1
del /F "!EXTIndex!" /s /q /a >nul 2>&1
call "%~dp0PrintOneDrive.bat" "!drive!" >!dirs!
dir /S /B /A^:LO !drive! >!EXTIndex!
dir /S /B /A^:L "!drive:~0,1!^:\Windows\System32\WDI" 2>nul>>!EXTIndex!
cscript /nologo "%~dp0PrintOneLinks.vbs" "!EXTIndex!" "!dirs!" "!drive!"
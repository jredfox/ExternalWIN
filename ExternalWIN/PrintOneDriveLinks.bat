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
call :ISBLANK "!dirs!"
REM Don't Scan The C Drive for OneDrive Links if there are no OneDrive Accounts found. Instead only scan the onedrive directories
IF "!isBlank!" EQU "T" IF /I "!OptimizedWIMCapture!" EQU "TRUE" (exit /b)
dir /S /B /A^:LO !drive! >!EXTIndex!
dir /S /B /A^:L "!drive:~0,1!^:\Windows\System32\WDI" 2>nul>>!EXTIndex!
cscript /nologo "%~dp0PrintOneLinks.vbs" "!EXTIndex!" "!dirs!" "!drive!"
exit /b

:ISBLANK
set isBlank=T
set file=%~1
FOR /F "usebackq delims=" %%A IN ("%file%") DO (
set line=%%A
set line=!line: =!
IF "!line!" NEQ "" (
set isBlank=F
exit /b
)
)
exit /b
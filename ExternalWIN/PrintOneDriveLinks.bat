@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set dirs=%TMP%\OneDriveDirs.txt
set EXTIndex=%TMP%\OneDriveLinks.txt
del /F /Q /A "!dirs!" >nul 2>&1
del /F /Q /A "!EXTIndex!" >nul 2>&1
set drive=%~1
IF /I "!drive:~3!" EQU "" (set drive=!drive:~0,1!^:\)
REM IF the Directory Doesn't Exist do not Continue as the Dir command will freak out and take way too long
IF NOT EXIST "!drive!" (exit /b)
call "%~dp0PrintOneDrive.bat" "!drive!" >"!dirs!"
REM Don't Scan The C Drive for OneDrive Links if there are no OneDrive Accounts found or If Disabled
IF /I "!OneDriveLinkScan!" EQU "FALSE" (exit /b)
IF /I "!OptimizedWIMCapture!" EQU "TRUE" (
call :ISBLANK "!dirs!"
IF "!isBlank!" EQU "T" (exit /b)
)
dir /S /B /A^:LO "!drive!" 2>nul>"!EXTIndex!"
dir /S /B /A^:L-O "!drive:~0,1!^:\Windows\System32\WDI" 2>nul>>"!EXTIndex!"
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
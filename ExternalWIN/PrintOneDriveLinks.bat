@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set dirs=%TMP%\OneDriveDirs.txt
set EXTIndex=%TMP%\OneDriveLinks.txt
del /F /Q /A "!dirs!" >nul 2>&1
del /F /Q /A "!EXTIndex!" >nul 2>&1
set drive=%~1
IF /I "!drive:~3!" EQU "" (set drive=!drive:~0,1!^:\)
call :GETDIRSAFE
REM Always Print anything found in the WDI folder as it should always be < 1GB to scan which even on a slow HDD read it should be pretty quick
call "!direxe!" "!drive:~0,1!^:\Windows\System32\WDI" "TRUE" "B" "K" "0x9000601A;0x9000001A;0x9000101A;0x9000201A;0x9000301A;0x9000401A;0x9000501A;0x9000701A;0x9000801A;0x9000901A;0x9000A01A;0x9000B01A;0x9000C01A;0x9000D01A;0x9000E01A;0x9000F01A;0x80000021;0x0000F000" 2>nul
REM IF the Directory Doesn't Exist do not Continue as the Dir command will freak out and take way too long
IF NOT EXIST "!drive!" (exit /b)
call "%~dp0PrintOneDrive.bat" "!drive!" >"!dirs!"
REM Don't Scan The C Drive for OneDrive Links if there are no OneDrive Accounts found or If Disabled
IF /I "!OneDriveLinkScan!" EQU "FALSE" (exit /b)
IF /I "!OptimizedWIMCapture!" EQU "TRUE" (
call :ISBLANK "!dirs!"
IF "!isBlank!" EQU "T" (exit /b)
)
call "!direxe!" "!drive!" "TRUE" "B" "O" "0x9000601A;0x9000001A;0x9000101A;0x9000201A;0x9000301A;0x9000401A;0x9000501A;0x9000701A;0x9000801A;0x9000901A;0x9000A01A;0x9000B01A;0x9000C01A;0x9000D01A;0x9000E01A;0x9000F01A;0x80000021;0x0000F000" 2>nul>"!EXTIndex!"
cscript /nologo "%~dp0PrintOneLinks.vbs" "!EXTIndex!" "!dirs!" "!drive!"
exit /b

:ISBLANK
set isBlank=T
set file=%~1
FOR /F "delims=" %%A IN ('type "%file%"') DO (
set line=%%A
set line=!line: =!
IF "!line!" NEQ "" (
set isBlank=F
exit /b
)
)
exit /b

:GETDIRSAFE
set dirsafedir=%~dp0DirSafe
IF /I "!PROCESSOR_ARCHITECTURE!" EQU "ARM64" (
set direxe=!dirsafedir!\DirSafe-ARM64.exe
exit /b
)
set direxe=!dirsafedir!\DirSafe-x64.exe
call "!direxe!" "/?" >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (set direxe=!dirsafedir!\DirSafe-x86.exe)
exit /b
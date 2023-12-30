@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set drive=%~1
set drive=!drive:~0,1!
set COMPNAME=%~2
set extattrib=%~3
set ttime=%time: =%
set EXTIndex=%TMP%\DLOneDriveLinks.txt
set dirs=%TMP%\DLOneDriveDirs.txt
set cfgone=%TMP%\DLOneExclusions.ini
del /F /Q /A "!dirs!" >nul 2>&1
call "%~dp0PrintOneDrive.bat" "!drive!" >"!dirs!"
call :ISBLANK "!dirs!"
IF "!isBlank!" EQU "T" (exit /b)
set /p onebackup="Backup All Users Downloaded Offline OneDrive Files [Y\N]?"
IF /I "!onebackup:~0,1!" NEQ "Y" (exit /b)
REM create backups of all OneDrives on all accounts
FOR /F "usebackq delims=" %%I IN ("!dirs!") DO (
set capdrive=!drive!^:%%I
set capwim=%%~dpIOneDriveOld.WIM
set capwim=!drive!^:!capwim:~2!
del /F /Q /A "!EXTIndex!" >nul 2>&1
del /F /Q /A "!capwim!" >nul 2>&1
del /F /Q /A "!cfgone!" >nul 2>&1
call :GETDIRSAFE
call "!direxe!" "!capdrive!" "TRUE" "B" "O" "0x9000601A;0x9000001A;0x9000101A;0x9000201A;0x9000301A;0x9000401A;0x9000501A;0x9000701A;0x9000801A;0x9000901A;0x9000A01A;0x9000B01A;0x9000C01A;0x9000D01A;0x9000E01A;0x9000F01A;0x80000021;0x0000F000" 2>nul>"!EXTIndex!"
REM create the offline onedrive exclusion list before backup
(
echo ^[ExclusionList^]
cscript /nologo "%~dp0EchoRealtivePath.vbs" "!capwim!" "!capdrive!"
cscript /nologo "%~dp0PrintOneLinks.vbs" "!EXTIndex!" "" "!capdrive!"
echo.
echo ^[CompressionExclusionList^]
echo ^*^.mp3
echo ^*^.zip
echo ^*^.cab
) >"!cfgone!"
REM Delete previous WIM FILE
echo Backing Up "OneDrive !capdrive! TO !capwim!"
dism /capture-image /imagefile:"!capwim!" /capturedir:"!capdrive!" /name:"OneDrive Offline Backup" /Description:"!COMPNAME! On !date! !ttime!" /compress:maximum /NoRpFix!extattrib! /ConfigFile:"!cfgone!"
)
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

:GETDIRSAFE
set dirsafedir=%~dp0DirSafe
set direxe=!dirsafedir!\DirSafe-x64.exe
call "!direxe!" "/?" >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (set direxe=!dirsafedir!\DirSafe-x86.exe)
exit /b
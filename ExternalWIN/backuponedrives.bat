@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set drive=%~1
set drive=!drive:~0,1!
set COMPNAME=%~2
set ttime=%time: =%
set EXTIndex=%TMP%\DLOneDriveLinks.txt
set dirs=%TMP%\DLOneDriveDirs.txt
set cfgone=%TMP%\DLOneExclusions.ini
set blank=%TMP%\Blank.txt
del /F "!dirs!" /s /q /a >nul 2>&1
call "%~dp0PrintOneDrive.bat" "!drive!" >"!dirs!"
echo. >"!blank!"
call :ISBLANK "!dirs!"
IF "!isBlank!" EQU "T" (exit /b)
set /p onebackup="Backup All Users Downloaded Offline OneDrive Files [Y\N]?"
IF /I "!onebackup:~0,1!" NEQ "Y" (exit /b)
REM create backups of all OneDrives on all accounts
FOR /F "usebackq delims=" %%I IN ("!dirs!") DO (
set capdrive=!drive!^:%%I
set capwim=%%~dpIOneDriveOld.WIM
set capwim=!drive!^:!capwim:~2!
del /F "!EXTIndex!" /s /q /a >nul 2>&1
del /F "!capwim!" /s /q /a >nul 2>&1
del /F "!cfgone!" /s /q /a >nul 2>&1
dir /S /B /A^:LO "!capdrive!" 2>nul>"!EXTIndex!"
REM create the offline onedrive exclusion list before backup
(
echo ^[ExclusionList^]
cscript /nologo "%~dp0EchoRealtivePath.vbs" "!capwim!" "!capdrive!"
cscript /nologo "%~dp0PrintOneLinks.vbs" "!EXTIndex!" "!blank!" "!capdrive!"
echo.
echo ^[CompressionExclusionList^]
echo ^*^.mp3
echo ^*^.zip
echo ^*^.cab
) >"!cfgone!"
REM Delete previous WIM FILE
echo Backing Up "OneDrive !capdrive! TO !capwim!"
dism /capture-image /imagefile:"!capwim!" /capturedir:"!capdrive!" /name:"OneDrive Offline Backup" /Description:"!COMPNAME! On !date! !ttime!" /compress:maximum /ConfigFile:"!cfgone!"
)

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
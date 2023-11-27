@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set drive=%~1
set drive=!drive:~0,1!
set COMPNAME=%~2
set ttime=%time: =%
set EXTIndex=%TMP%\OneDriveLinks.txt
set dirs=%TMP%\OneDriveDirs.txt
set cfgone=%TMP%\OfflineOneExclusions.ini
set blank=%TMP%\Blank.txt
echo. >!blank!
REM create backups of all OneDrives on all accounts
FOR /F "usebackq delims=" %%I IN ("!dirs!") DO (
set capdrive=!drive!^:%%I
set capwim=%%~dpIOneDriveOld.WIM
set capwim=!drive!^:!capwim:~2!
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
del /F "!capwim!" /s /q /a >nul 2>&1
dism /capture-image /imagefile:"!capwim!" /capturedir:"!capdrive!" /name:"OneDrive Offline Backup" /Description:"!COMPNAME! On !date! !ttime!" /compress:maximum /ConfigFile:"!cfgone!"
REM del /F "!cfgone!" /s /q /a >nul 2>&1
)
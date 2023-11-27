@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set EXTIndex=%TMP%\OneDriveLinks.txt
set dirs=%TMP%\OneDriveDirs.txt
set cfgone=%TMP%\OfflineOneExclusions.ini
set blank=%TMP%\Blank.txt
echo. >!blank!
REM create the offline onedrive exclusion list before backup
(
echo ^[ExclusionList^]
echo !wimimg!
cscript /nologo "%~dp0PrintOneLinks.vbs" "!EXTIndex!" "!blank!" "!capdrive!"
echo.
echo ^[CompressionExclusionList^]
echo ^*^.mp3
echo ^*^.zip
echo ^*^.cab
) >"!cfgone!"
REM create backups of all OneDrives on all accounts
FOR /F "usebackq delims=" %%I IN ("!dirs!") DO (
echo %%I >nul
)
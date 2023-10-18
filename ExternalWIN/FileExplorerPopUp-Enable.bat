@Echo OFF
setlocal enableDelayedExpansion
IF "!winpe!" EQU "T" (exit /b)
REM %1% IS Sleep Before and %2% is Sleep After
IF "%~1" NEQ "" (cscript "%~dp0Sleep.vbs" "%~1" >nul)
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v NoAutoplayfornonVolume /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoAutorun /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoAutoplayfornonVolume /f
cscript "%~dp0Sleep.vbs" "250" >nul
taskkill /F /FI "IMAGENAME eq FENDx86.exe*"
IF "%~2" NEQ "" (cscript "%~dp0Sleep.vbs" "%~2" >nul)
echo File Explorer Popups Enabled
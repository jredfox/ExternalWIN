@Echo OFF
IF EXIST "X:\" (exit /b)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v NoAutoplayfornonVolume /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoAutorun /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 0xFFFFFFFF /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoAutoplayfornonVolume /t REG_DWORD /d 1 /f
IF "%~1%" NEQ "" (cscript "%~dp0Sleep.vbs" "%~1" >nul)
echo File Explorer Popups Disabled
@Echo OFF
setlocal enableDelayedExpansion
IF "!winpe!" EQU "T" (exit /b)
IF "!letrecovery!" EQU "" (set letrecovery=R)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v NoAutoplayfornonVolume /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoAutorun /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 0xFFFFFFFF /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoAutoplayfornonVolume /t REG_DWORD /d 1 /f >nul
start /B "FENDx86" "%~dp0FENDx86.exe" "!letrecovery!" "120" "true"
IF "%~1" NEQ "" (cscript "%~dp0Sleep.vbs" "%~1" >nul)
IF /I "%~2" EQU "TRUE" (
taskkill /F /IM explorer.exe
start explorer.exe
)
echo File Explorer Popups Disabled
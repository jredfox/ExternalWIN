@echo off
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 0xFFFFFFFF /f
echo File Explorer Popups Disabled

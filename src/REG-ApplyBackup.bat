@Echo off
setlocal enableDelayedExpansion
reg import "%~dp0HKLM.reg"
reg import "%~dp0HKCU.reg"
reg import "%~dp0HKCR.reg"
reg import "%~dp0HKU.reg"
reg import "%~dp0HKCC.reg"
regedit /s "%~dp0HKLM.reg"
regedit /s "%~dp0HKCU.reg"
regedit /s "%~dp0HKCR.reg"
regedit /s "%~dp0HKU.reg"
regedit /s "%~dp0HKCC.reg"
echo Finished Importing REG Backups
pause
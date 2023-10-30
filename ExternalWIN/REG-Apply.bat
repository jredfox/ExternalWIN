@Echo off
setlocal enableDelayedExpansion
set regdir=%HOMEDRIVE%\ExternalWIN\Backups\REG
FOR /D %%D in ("%regdir%\*") DO (echo %%D)
:SEL
set /p regbackup="Enter Reg Backup Dir:"
set regbackup=!regbackup:"=!
IF NOT EXIST "!regbackup!" (set regbackup=!regdir!\!regbackup!)
IF NOT EXIST "!regbackup!" (GOTO SEL)
reg import "!regbackup!\HKLM.reg"
reg import "!regbackup!\HKCU.reg"
reg import "!regbackup!\HKCR.reg"
reg import "!regbackup!\HKU.reg"
reg import "!regbackup!\HKCC.reg"
regedit /s "!regbackup!\HKLM.reg"
regedit /s "!regbackup!\HKCU.reg"
regedit /s "!regbackup!\HKCR.reg"
regedit /s "!regbackup!\HKU.reg"
regedit /s "!regbackup!\HKCC.reg"
echo Finished Importing REG Backups
pause
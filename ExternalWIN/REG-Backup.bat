@ECHO OFF
setlocal enableDelayedExpansion
reg export HKLM "%~dp0HKLM.reg"
reg export HKCU "%~dp0HKCU.reg"
reg export HKCR "%~dp0HKCR.reg"
reg export HKU "%~dp0HKU.reg"
reg export HKCC "%~dp0HKCC.reg"
pause
@ECHO OFF
setlocal enableDelayedExpansion
FOR /F "tokens=1* delims=" %%A in ('call "%~dp0createregdir.bat"') DO (set regdir=%%A)
echo Capturing Registry to "!regdir!"
reg export HKLM "!regdir!\HKLM.reg"
reg export HKCU "!regdir!\HKCU.reg"
reg export HKCR "!regdir!\HKCR.reg"
reg export HKU "!regdir!\HKU.reg"
reg export HKCC "!regdir!\HKCC.reg"
pause
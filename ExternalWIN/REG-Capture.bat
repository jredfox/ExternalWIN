@ECHO OFF
setlocal enableDelayedExpansion
IF /I "!TMP:~0,1!" EQU "X" (set winpe=T) ELSE (set winpe=F)
IF "!winpe!" NEQ "F" (exit /b)
FOR /F "tokens=1* delims=" %%A in ('call "%~dp0createregdir.bat"') DO (set regdir=%%A)
echo Capturing Registry to "!regdir!"
reg export HKLM "!regdir!\HKLM.reg"
reg export HKCU "!regdir!\HKCU.reg"
reg export HKCR "!regdir!\HKCR.reg"
reg export HKU "!regdir!\HKU.reg"
reg export HKCC "!regdir!\HKCC.reg"
pause
exit /b
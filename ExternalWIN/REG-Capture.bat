@ECHO OFF
setlocal enableDelayedExpansion
call :ISWINPE
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

:ISWINPE
REM ######## WinPE support change the power plan to maximize perforamnce #########
set winpe=F
REM Check if we are in WINPE. If Either where or powershell is missing and X Drive Exists we are in WinPE
IF NOT EXIST "X:\" (exit /b)
exit /b
@ECHO OFF
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
call :PP
set /p wim=File Save As:
set /p desc=Enter Description:
diskpart /s "%~dp0ld.txt"
set /p disk=Input Disk Number:
diskpart /s "%~dp0dd.txt"
set /p let=Enter Drive:
set wim=%wim:"=%
set let=%let:"=%
set let=%let:~0,1%:
REM create parent directory
md "%wim%"
rd /s /q "%wim%"
dism /capture-image /imagefile:"%wim%" /capturedir:"%let%" /name:"%ComputerName%" /Description:"%desc%" /compress:maximum
echo "SAVED WIM TO: %wim%"
pause
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)

:PP
REM ######## WinPE support change the power plan to maximize perforamnce #########
set winpe=F
REM Check if we are in WINPE. If Either where or powershell is missing and X:\ Exists we are in WinPE
IF NOT EXIST "X:\" (exit /b)
where powershell >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
winpe=T
FOR /f "delims=" %%a in ('POWERCFG -GETACTIVESCHEME') DO @SET powerplan="%%a"
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo changed powerplan of !powerplan! to high performance 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)
exit /b
@ECHO OFF
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
call :PP
set /p wim="Enter File Name:"
set wim=%wim:"=%
set /p desc="Enter Description:"
diskpart /s "%~dp0ld.txt"
set /p disk="Input Disk Number:"
diskpart /s "%~dp0dd.txt"
set /p let="Enter Drive:"
set let=%let:"=%
md %userprofile%\Documents\%ComputerName%\WIMS
set wim=%userprofile%\Documents\%ComputerName%\WIMS\%wim%.wim
set wim=%wim:.wim.wim=.wim%
dism /capture-image /imagefile:"%wim%" /capturedir:"%let%" /name:"%ComputerName%" /Description:"%desc%" /compress:maximum
IF ERRORLEVEL 1 echo ######################### & echo Try Changing "%let%" to "%let:~0,1%:" or "%let:~0,1%" to capture the entire drive. This is a DISM.exe bug not an issue with the script & echo#########################
echo "SAVED WIM TO: %wim%"
pause
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
exit /b

:PP
REM ######## WinPE support change the power plan to maximize perforamnce #########
set winpe=F
REM Check if we are in WINPE. If Either where or powershell is missing and X Drive Exists we are in WinPE
IF NOT EXIST "X:\" (exit /b)
where powershell >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
set winpe=T
FOR /f "delims=" %%a in ('POWERCFG -GETACTIVESCHEME') DO @SET powerplan="%%a"
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo changed powerplan of !powerplan! to high performance 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)
exit /b
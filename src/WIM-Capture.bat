@ECHO OFF
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set /p wim=Enter File Name:
set wim=%wim:"=%
set /p desc=Enter Description:
diskpart /s "%~dp0ld.txt"
set /p disk=Input Disk Number:
diskpart /s "%~dp0dd.txt"
set /p let=Enter Drive:
set let=%let:"=%
md %userprofile%\Documents\%ComputerName%\WIMS
set wim=%userprofile%\Documents\%ComputerName%\WIMS\%wim%.wim
set wim=%wim:.wim.wim=.wim%
dism /capture-image /imagefile:"%wim%" /capturedir:"%let%" /name:"%ComputerName%" /Description:"%desc%" /compress:maximum
IF ERRORLEVEL 1 echo ######################### & echo Try Changing "%let%" to "%let:~0,1%:" or "%let:~0,1%" to capture the entire drive. This is a DISM.exe bug not an issue with the script & echo#########################
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
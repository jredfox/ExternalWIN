@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set /p img="Enter Image(VHD, VHDX, ISO, ESD):"
set img=%img:"=%
powershell -ExecutionPolicy Bypass -File "%~dp0IMG2WIM.ps1" -Image "%img%"
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
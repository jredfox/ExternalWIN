@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
powershell -ExecutionPolicy Bypass -File "%~dp0dismountallwims.ps1"
powershell -ExecutionPolicy Bypass -File "%~dp0dismountallvwims.ps1"
pause
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
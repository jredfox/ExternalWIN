@Echo off
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set /p disk=Enter disk:
set /p syspar=Enter Par:
diskpart /s "%~dp0Openboot-MBR.txt"

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
exit /b

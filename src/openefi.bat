@Echo off
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set /p disk=Enter Disk:
set /p syspar=Enter Par:
diskpart /s "%~dp0openboot.txt"
pause
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
)
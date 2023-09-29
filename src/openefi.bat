@Echo off
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
diskpart /s %~dp0ld.txt
set /p disk=Enter Disk:
diskpart /s %~dp0ListPar.txt
set /p syspar=Enter Par:
diskpart /s "%~dp0openboot.txt"
pause
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
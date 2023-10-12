@Echo off
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set letsys=S
diskpart /s %~dp0ld.txt
set /p disk=Enter Disk:
diskpart /s %~dp0ListPar.txt
set /p syspar=Enter Par:
diskpart /s "%~dp0Openboot.txt"

:END
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
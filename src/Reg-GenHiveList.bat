@Echo Off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"

set hivelist=%~dp0hivelist.txt
del /f /q /a "%hivelist%" >nul 2>&1
reg query HKLM\SYSTEM\CurrentControlSet\Control\hivelist >"%hivelist%"
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
exit /b
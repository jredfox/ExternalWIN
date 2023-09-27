@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set /p wim=Enter WIM Image to Dismount:
set /p save=Discard Changes to WIM Mount [Y\N]?
IF /I %save:~0,1% EQU Y (set shouldDiscard=true) ELSE (set shouldDiscard=false)
powershell -ExecutionPolicy Bypass -File "%~dp0dismountwim.ps1" -Image "%wim%" -Discard "%shouldDiscard%"
pause
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
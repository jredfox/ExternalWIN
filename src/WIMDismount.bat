@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set /p=Enter WIM Image to Dismount:
set wim=%wim:"=%
powershell -ExecutionPolicy Bypass -File "%~dp0dismountwim.ps1" -Image "%wim%"
diskpart /s "%~dp0dvhdx.txt"
del /F "%vdisk%" /s /q /a
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
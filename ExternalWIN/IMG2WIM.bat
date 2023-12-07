@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :LOADCFG
set /p img="Enter Image(VHD, VHDX, ISO, ESD):"
set img=%img:"=%
powershell -ExecutionPolicy Bypass -File "%~dp0IMG2WIM.ps1" -Image "%img%" -ExtraAttrib "!ExtendedAttrib!"
pause
exit /b

:LOADCFG
FOR /F "tokens=7 delims= " %%A in ('call "%~dp0LoadConfig.bat"') DO (
set ExtendedAttrib=%%A
)
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
)
exit /b
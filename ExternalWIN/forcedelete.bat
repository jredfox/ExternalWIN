@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
echo WARNING^: Forcibly Deleting Files Is Dangerous If You Do Not Know What you are doing
set /p warn="Do you Wish To Continue [Y/N]?"
IF /I "!warn!" NEQ "Y" (exit /b)
REM this is to force delete the extracted WIM files when mounting goes wrong. Do not Delete SYSTEM32 with this
set dir=%~1
IF "%~1" EQU "" (exit /b)
takeown /F "%dir%" /R /D Y
icacls "%dir%" /T /C /grant administrators:F System:F everyone:F
del /F "%dir%" /s /q /a
rmdir /s /q "%dir%"
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
)
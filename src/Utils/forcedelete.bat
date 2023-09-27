@Echo off
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
REM this is to force delete the extracted WIM files when mounting goes wrong. Do not Delete SYSTEM32 with this
set dir=%~1
takeown /F "%dir%" /R /D Y
icacls "%dir%" /T /C /grant administrators:F System:F everyone:F
del /F "%dir%" /s /q /a
rmdir /s /q "%dir%"
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
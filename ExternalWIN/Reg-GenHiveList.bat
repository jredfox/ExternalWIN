@Echo Off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"

set p=%~dp0
set drive=%p:~0,1%
set BaseDir=!drive!:\ExternalWIN
md "!BaseDir!" >nul 2>&1
set hivelist=!BaseDir!\hivelist.hivelist
del /F /Q /A "%hivelist%" >nul 2>&1
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
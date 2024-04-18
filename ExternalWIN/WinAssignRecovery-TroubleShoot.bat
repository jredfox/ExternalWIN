@Echo Off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)

echo WARNING^: Running Assigning Recovery After Running This Script Will Cause WinRE.wim to Self Delete Due to REAGENTC.exe
echo Please Backup The Recovery Partition Before Continuing
set /p warn="Do You Wish To Continue [Y/N]?"
IF /I "!warn!" NEQ "Y" (exit /b)
DEL %HOMEDRIVE:~0,1%^:\Windows\System32\Recovery\ReAgent.xml
reagentc /disable
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
)
exit /b
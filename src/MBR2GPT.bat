@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
echo WARNING THIS DOESN't ALWAYS WORK CORRECTLY AND YOUR DATA COULD ACCIDENTLY GET ERASED. Please backup your system as a VHDX or WIM Image Before Starting
diskpart /s "%~dp0ld.txt"
set /p disk=Enter Disk Number:
mbr2gpt /validate /disk:%disk% /allowFullOS
mbr2gpt /convert /disk:%disk% /allowFullOS
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
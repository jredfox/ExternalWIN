@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"

set letrecovery=R
diskpart /s %~dp0ld.txt
set /p disk=Enter Disk:
set /p ISMBR=Is This Disk LEGACY MBR [Y/N]?
IF /I %ISMBR:~0,1% EQU Y (set ext=-MBR.txt) else (set ext=.txt)
diskpart /s %~dp0ListPar.txt
set /p parrecovery=Enter Par:
mountvol %letrecovery%: /d
diskpart /s "%~dp0Closerecovery%ext%"

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
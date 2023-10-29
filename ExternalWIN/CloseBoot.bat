@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
diskpart /s "%~dp0ld.txt"
set /p disk="Enter Disk:"
set /p q1=MBR LEGACY DISK [Y/N]?
IF /I "%q1:~0,1%" EQU "Y" (set ext=-MBR.txt) ELSE (set ext=.txt)
diskpart /s "%~dp0ListPar.txt"
set /p syspar="Enter Par:"
set par=%syspar%
diskpart /s "%~dp0detpar.txt"
set /p drive="Enter Partition's Drive Letter:"
set drive=%drive:"=%
set drive=%drive:~0,1%
mountvol %drive%: /p
mountvol %drive%: /d
diskpart /s "%~dp0CloseBoot%ext%"

:END
pause
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
)
exit /b
@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
diskpart /s "%~dp0ld.txt"
set /p disk="Enter Disk:"
set /p q1=MBR LEGACY DISK [Y/N]?
IF /I "%q1:~0,1%" EQU "Y" (set ext=-MBR.txt) ELSE (set ext=.txt)
diskpart /s "%~dp0ListPar.txt"
set /p par="Enter Par:"
call :NXTLET
diskpart /s "%~dp0OpenPar%ext%"

:END
pause
exit /b

:NXTLET
set let=0
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set let=%drives:~0,1%
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
exit /b
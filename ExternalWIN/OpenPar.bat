@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :PP
call :LOADCFG
call "%~dp0FileExplorerPopUp-Enable.bat" >nul 2>&1
diskpart /s "%~dp0ld.txt"
set /p disk="Enter Disk:"
set /p q1=MBR LEGACY DISK [Y/N]?
IF /I "%q1:~0,1%" EQU "Y" (set ext=-MBR.txt) ELSE (set ext=.txt)
diskpart /s "%~dp0ListPar.txt"
set /p par="Enter Par:"
call :NXTLET
REM Set the recovery let to whatever the open par is in case of unwanted popups from recovery opening or closing
set letrecovery=!let!
call "%~dp0FileExplorerPopUp-Disable.bat" "!SleepDisable!" "!RestartExplorer!"
diskpart /s "%~dp0OpenPar%ext%"
call "%~dp0FileExplorerPopUp-Enable.bat" "!SleepEnable!" ""

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
exit /b 1
)
exit /b

:PP
REM ######## WinPE support change the power plan to maximize perforamnce #########
set winpe=F
REM Check if we are in WINPE. If Either where or powershell is missing and X Drive Exists we are in WinPE
IF NOT EXIST "X:\" (exit /b)
where powershell >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
set winpe=T
FOR /f "delims=" %%a in ('POWERCFG -GETACTIVESCHEME') DO @SET powerplan="%%a"
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo changed powerplan of !powerplan! to high performance 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)
exit /b

:LOADCFG
FOR /F "tokens=1-3 delims= " %%A in ('call "%~dp0LoadConfig.bat"') DO (
set SleepDisable=%%A
set SleepEnable=%%B
set RestartExplorer=%%C
)
exit /b
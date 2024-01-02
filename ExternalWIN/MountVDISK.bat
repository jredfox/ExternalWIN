@ECHO OFF
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF /I "!TMP:~0,1!" EQU "X" (set winpe=T) ELSE (set winpe=F)
set /p vdisk="Enter VDISK File:"
set /p mnt="Mount Drive [Y/N]?"
IF /I "!mnt!" EQU "Y" (set /p letvdisk="Enter VDISK Drive:")
set vdisk=%vdisk:"=%
set vdisk=!vdisk:^/=^\!
set letvdisk=%letvdisk:"=%
set letvdisk=!letvdisk:~0,1!
REM ## Dismount or Cleanup ##
diskpart /s "%~dp0dvhdx.txt" >nul
IF "!winpe!" EQU "F" (
powershell DisMount-DiskImage -ImagePath "!vdisk!" >nul 2>&1
)
IF /I "!mnt!" NEQ "Y" (exit /b)
REM ## Actual Mount Code ##
diskpart /s "%~dp0avhdx.txt" >nul

:END
exit /b

:checkAdmin
net session >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
echo %~1
pause
exit /b 1
)
exit /b
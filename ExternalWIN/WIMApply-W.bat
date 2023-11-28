@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :PP
call :LOADCFG
call "%~dp0FileExplorerPopUp-Enable.bat" >nul 2>&1
REM This Script is Made to Erase and RE-IMAGE Already Installed Paritition of Windows To Repair Boot/Recovery or Full Install Please Use Another Script
set /p wim="Input WIM/ESD:"
set wim=%wim:"=%
dism /get-imageinfo /imagefile:"%wim%"
set /p index="Input Index:"
mountvol W: /p >nul
mountvol W: /d >nul
:SEL
diskpart /s "%~dp0ld.txt"
set /p disk="Input Disk Number:"
diskpart /s "%~dp0dd.txt"
set /p volume="Input Volume Number:"
call :ISNUM "!volume!"
IF "!isNum!" EQU "F" (
echo The Volume Number Must be a Number
GOTO SEL
)
set /p ays=Are You sure this is the correct Volume %volume% [Y/N]?
IF /I %ays:~0,1% NEQ Y GOTO SEL
call "%~dp0FileExplorerPopUp-Disable.bat" "!SleepDisable!" "!RestartExplorer!" >nul
set form=NTFS
set let=W
set /p label1=Input Volume Name^:
diskpart /s "%~dp0formatvol.txt"
dism /apply-image /imagefile:"%wim%" /index:"%index%" /applydir:W^:
REM ##### RE-ASSING W:\ #############
call "%~dp0Assign-RND.bat" "true"
call "%~dp0FileExplorerPopUp-Enable.bat" "!SleepEnable!" ""
pause
exit /b

:ISNUM
set isNum=F
set var=%~1
IF "!var!" EQU "" (exit /b)
set varnum=1 2 3 4 5 6 7 8 9 0
FOR /L %%I IN (0,1,257) DO (
set varC=!var:~%%I,1!
IF "!varC!" EQU "" (exit /b)
set isNum=F
FOR %%A IN (%varnum%) DO (
IF /I !varC! EQU %%A (set isNum=T)
)
IF "!isNum!" EQU "F" (exit /b)
)
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
IF "!winpe!" EQU "T" (exit /b)
FOR /F "tokens=1-3 delims= " %%A in ('call "%~dp0LoadConfig.bat"') DO (
set SleepDisable=%%A
set SleepEnable=%%B
set RestartExplorer=%%C
)
exit /b

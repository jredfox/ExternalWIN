@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
call :PP
call "%~dp0FileExplorerPopUp-Enable.bat" >nul 2>&1
REM This Script is Made to Erase and RE-IMAGE Already Installed Paritition of Windows To Repair Boot/Recovery or Full Install Please Use Another Script
set /p wim=Input WIM/ESD:
set wim=%wim:"=%
dism /get-imageinfo /imagefile:"%wim%"
set /p index="Input Index:"
mountvol W: /p >nul
mountvol W: /d >nul
:SEL
diskpart /s "%~dp0ld.txt"
set /p disk="Input Disk Number:"
diskpart /s "%~dp0dd.txt"
set /p volume="Input Vol Number:"
set /p ays=Are You sure this is the correct Volume %volume% [Y/N]?
IF /I %ays:~0,1% NEQ Y GOTO SEL
call "%~dp0FileExplorerPopUp-Disable.bat" "1500" >nul
set form=NTFS
set let=W
set /p label1=Input Volume Name of %volume%^:
diskpart /s "%~dp0formatvol.txt"
dism /apply-image /imagefile:"%wim%" /index:"%index%" /applydir:W:\
REM ##### RE-ASSING W:\ #############
call "%~dp0Assign-RND.bat"
call "%~dp0FileExplorerPopUp-Enable.bat" "2000" ""
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
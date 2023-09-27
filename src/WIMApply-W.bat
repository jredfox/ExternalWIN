@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
REM This Script is Made to Erase and RE-IMAGE Already Installed Paritition of Windows To Repair Boot/Recovery or Full Install Please Use Another Script
set /p wim=Input WIM/ESD:
set wim=%wim:"=%
dism /get-imageinfo /imagefile:"%wim%"
set /p index=Input Index:
mountvol W: /p
mountvol W: /d
:SEL
diskpart /s "%~dp0ld.txt"
set /p disk=Input Disk Number:
diskpart /s "%~dp0dd.txt"
set /p volume=Input Vol Number:
set /p ays=Are You sure this is the correct Volume %volume% [Y/N]?
IF /I %ays:~0,1% NEQ Y GOTO SEL
set form=NTFS
set let=W
set /p label1=Input Volume Name of %volume%^:
diskpart /s "%~dp0formatvol.txt"
dism /apply-image /imagefile:"%wim%" /index:"%index%" /applydir:W:\
REM ##### RE-ASSING W:\ #############
set let=0
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set let=%drives:~0,1%
echo Assiging W:\ to %let%:\
diskpart /s "%~dp0%avl.txt"
pause
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
call :PP

set /p wim="Enter WIM Image:"
set wim=%wim:"=%
dism /get-imageinfo /imagefile:"%wim%"
set /p index="Input Index:"
set index=%index:"=%
:SEL
diskpart /s "%~dp0ld.txt"
set /p disk=Input Disk Number:
diskpart /s "%~dp0dd.txt"
set /p drive="Input Drive:"
set drive=%drive:"=%
set drive=%drive:~0,1%
set /p ays=Are You sure this is the correct Drive %drive% [Y/N]?
IF /I %ays:~0,1% NEQ Y GOTO SEL
dism /apply-image /imagefile:"%wim%" /index:"%index%" /applydir:"%drive%:"
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
REM Check if we are in WINPE. If Either where or powershell is missing and X:\ Exists we are in WinPE
IF NOT EXIST "X:\" (exit /b)
where powershell >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
winpe=T
FOR /f "delims=" %%a in ('POWERCFG -GETACTIVESCHEME') DO @SET powerplan="%%a"
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo changed powerplan of !powerplan! to high performance 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)
exit /b
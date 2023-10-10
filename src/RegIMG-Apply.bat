@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"

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
@Echo off
setlocal ENABLEDELAYEDEXPANSION
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set comp=maximum
IF "%~1" EQU "" (
set /p esd=Enter ESD File:
set sp=true
) else (
set sp=false
set esd=%~1
IF "%~2" NEQ "" (set comp=%~2)
)
set esd=%esd:"=%
set wim=%esd:.esd=.wim%
for /L %%A in (1, 1, 256) Do (
echo Extracting Index %%A
dism /Export-Image /SourceImageFile:"%esd%" /SourceIndex:%%A /DestinationImageFile:"%wim%" /compress:%comp%
IF !ERRORLEVEL! NEQ 0 (GOTO END)
echo[
echo Finished Extracting Index %%A
echo[
)
:END
echo Done Converting ESD to WIM File
IF %sp% EQU true (pause)
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
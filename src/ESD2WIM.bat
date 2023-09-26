@Echo off
setlocal ENABLEDELAYEDEXPANSION
IF "%~1%" EQU "" (
set /p esd=Enter ESD File:
set sp=true
) else (
set sp=false
set esd=%~1
)
set esd=%esd:"=%
set wim=%esd:.esd=.wim%
for /L %%A in (1, 1, 256) Do (
echo Extracting Index %%A
dism /Export-Image /SourceImageFile:"%esd%" /SourceIndex:%%A /DestinationImageFile:"%wim%" /compress:max
IF !ERRORLEVEL! NEQ 0 (GOTO END)
echo[
echo Finished Extracting Index %%A
echo[
)
:END
echo Done Converting ESD to WIM
IF %sp% EQU true (pause)
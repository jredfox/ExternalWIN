@Echo off
setlocal ENABLEDELAYEDEXPANSION
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
set comp=maximum
IF "%~1" EQU "" (
set /p esd="Enter ESD File:"
set sp=true
) else (
set sp=false
set esd=%~1
IF "%~2" NEQ "" (set comp=%~2)
)
set esd=%esd:"=%
call :GETWIMSIZE "!esd!"
set wim=%esd:.esd=.wim%
del /F "!wim!" /s /q /a >nul 2>&1
for /L %%A in (1, 1, !WIMSIZE!) Do (
echo Extracting Index %%A of !WIMSIZE!
dism /Export-Image /SourceImageFile:"%esd%" /SourceIndex:%%A /DestinationImageFile:"%wim%" /compress:%comp%
IF !ERRORLEVEL! NEQ 0 (GOTO END)
echo[
echo Finished Extracting Index %%A of !WIMSIZE!
echo[
)

:END
echo Done Converting ESD to WIM File
IF %sp% EQU true (pause)
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
)
exit /b

:GETWIMSIZE
set indexedwim=%1
set indexedwim=!indexedwim:"=!
set /A WIMSIZE=1
:LOOPINDEX
dism /get-imageinfo /imagefile:"!indexedwim!" /index^:!WIMSIZE! >nul
IF !ERRORLEVEL! NEQ 0 (
set /A WIMSIZE=!WIMSIZE! - 1
exit /b
) ELSE (
set /A WIMSIZE=!WIMSIZE! + 1
GOTO LOOPINDEX
)
exit /b
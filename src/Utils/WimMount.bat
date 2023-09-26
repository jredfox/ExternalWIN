@Echo off
setlocal enableDelayedExpansion
set /p wim=Enter WIM Image to Mount:

:SEL
set /p mntname=Enter WIM Mount Name:
set wim=%wim:"=%
set mntname=%mntname:"=%
set mnt=C:\Temp\Mnts\%mntname%
IF EXIST "%mnt%" GOTO SEL
set index=0
for /L %%i in (1, 1, 256) Do (
set index=%%i
mkdir "%mnt%\%%i"
dism /Mount-Image /ImageFile:"%wim%" /index:%%i /MountDir:"%mnt%\%%i"
IF !ERRORLEVEL! NEQ 0 (
rmdir /s /q "%mnt%\%%i"
GOTO END
)
echo Mounted "%wim%" at index "%%i" to "%mnt%\%%i"
)

:END
IF %index% EQU 0 (
echo UNABLE TO MOUNT WIM from file "%wim%" to "%mnt%"
exit /b 1
)
pause

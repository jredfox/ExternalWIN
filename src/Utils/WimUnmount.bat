@Echo off
setlocal enableDelayedExpansion
set /p mntname=Enter WIM Mount Name:
set mntname=%mntname:"=%
set mnt=C:\Temp\Mnts\%mntname%
for /L %%i in (1, 1, 256) Do (
set index=%%i
dism /Unmount-Image /MountDir:"%mnt%\%%i" /Commit
IF !ERRORLEVEL! NEQ 0 (GOTO END)
echo Unmounted index "%%i" from "%mnt%\%%i"
)

:END
takeown /F "%mnt%" /R /D Y
icacls "%mnt%" /T /C /grant administrators:F System:F everyone:F
del /F "%mnt%" /s /q /a
rmdir /s /q "%mnt%"
IF %index% EQU 0 (
echo Unable to Dismount WIM file from path "%mnt%"
)
pause
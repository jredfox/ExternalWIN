@Echo off
setlocal enableDelayedExpansion
cd C:\WINDOWS\system32
for /d %%f in (C:\Temp\Mnts\*) do (
call :loop "%%f"
echo dismounted "%%f"
)
GOTO breakloop

:loop
for /L %%i in (1, 1, 256) Do (
echo removing mnt "%%f\%%i"
dism /Unmount-Image /MountDir:"%%f\%%i" /Discard
IF !ERRORLEVEL! NEQ 0 (GOTO EOF)
)

:breakloop

set mnt=C:\Temp\Mnts
takeown /F %mnt% /A /R /D Y
icacls %mnt% /T /C /grant administrators:F System:F everyone:F
del /F %mnt% /s /q /a
rmdir /s /q "%mnt%"
pause
:EOF
@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
mountvol S: /p
mountvol S: /d
cls
set letsys=S
diskpart /s "%~dp0ld.txt"
set /p disk="Input Disk Number:"
diskpart /s "%~dp0ListPar.txt"
set /p syspar="Input System(BOOT) Partition:"
set /p q1=MBR LEGACY DISK [Y/N]?
IF /I "%q1:~0,1%" EQU "Y" (
set store=S:\Boot\BCD
set dskext=-MBR.txt
) ELSE (
set store=S:\EFI\Microsoft\Boot\BCD
set dskext=.txt
)
diskpart /s "%~dp0Openboot%dskext%"
:SELBOOT
bcdedit.exe /store "%store%" /enum
set /p guid="Enter GUID:"
set guid=%guid:{=%
set guid=%guid:}=%
bcdedit.exe /store "%store%" /delete "{%guid%}"
set /p q2=Delete Another Entry [Y/N]?
IF /I "%q2:~0,1%" EQU "Y" GOTO SELBOOT
diskpart /s "%~dp0Closeboot%dskext%"
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
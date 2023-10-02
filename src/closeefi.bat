@Echo Off
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set letsys=S
diskpart /s %~dp0ld.txt
set /p disk=Input Disk Num:
diskpart /s %~dp0ListPar.txt
set /p syspar=Input System Partition(250 MB Usually):
echo Closing EFI Boot
mountvol S: /p
diskpart /s %~dp0%Closeboot.txt
pause
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
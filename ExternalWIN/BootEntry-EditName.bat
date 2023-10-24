@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
call :PP
call "%~dp0FileExplorerPopUp-Enable.bat" >nul 2>&1
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
call "%~dp0FileExplorerPopUp-Disable.bat" "1500"
diskpart /s "%~dp0Openboot%dskext%" 
:SELBOOT
bcdedit.exe /store "%store%" /enum
set /p guid="Enter GUID:"
set guid=%guid:{=%
set guid=%guid:}=%
set /p description="Enter Description:"
set description=%description:"=%
bcdedit.exe /store "%store%" /set "{%guid%}" description "%description%"
set /p q2=Name Another Entry [Y/N]?
IF /I "%q2:~0,1%" EQU "Y" GOTO SELBOOT
mountvol S: /p >nul
mountvol S: /d >nul
diskpart /s "%~dp0Closeboot%dskext%"
call "%~dp0FileExplorerPopUp-Enable.bat" "5000" ""
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
REM Check if we are in WINPE. If Either where or powershell is missing and X Drive Exists we are in WinPE
IF NOT EXIST "X:\" (exit /b)
where powershell >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
set winpe=T
FOR /f "delims=" %%a in ('POWERCFG -GETACTIVESCHEME') DO @SET powerplan="%%a"
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo changed powerplan of !powerplan! to high performance 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)
exit /b
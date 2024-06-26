@Echo Off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :PP
call :LOADCFG
call "%~dp0FileExplorerPopUp-Enable.bat" >nul 2>&1
diskpart /s "%~dp0ld.txt"
set /p disk="Input Disk:"
set /p legacy="MBR LEGACY Installation [Y/N]?"
diskpart /s "%~dp0dd.txt"
set /p let="Input Windows Drive Letter:"
set let=%let:"=%
set let=%let:~0,1%
IF /I %legacy:~0,1% EQU Y (
set ext=-MBR.txt
set ISMBR=T
) ELSE (
set ISMBR=F
set ext=.txt
)
diskpart /s "%~dp0ListPar.txt"
set /p par="Input Recovery Partition:"
mountvol R: /d >nul
call "%~dp0FileExplorerPopUp-Disable.bat" "!SleepDisable!" "!RestartExplorer!"
set parrecovery=!par!
set letrecovery=R
REM ########## Actual Code #############
diskpart /s "%~dp0Openrecovery!ext!"
set agent=!let!:\Windows\System32\Reagentc
REM Check if the Target Reagentc can run on this computer if not use this computers reagentc
!agent! "/?" >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
echo "Can't Run !agent! on this computer is the ISA Incompatible?"
set agent=Reagentc
)

REM ## HACK REAGENTC Into Always Working ##
takeown /A /SKIPSL /F "R:\Recovery\WindowsRE"
call "%~dp0Grant-x86.exe" "R:\Recovery\WindowsRE"
del /F !let!^:\Windows\System32\Recovery\ReAgent.xml /S /Q /A
xcopy /H /K /Y "R:\Recovery\WindowsRE\WinRE.wim" "!let!:\WinRE.wim.bak*"
!agent! /disable
xcopy /H /K /Y "!let!:\WinRE.wim.bak" "R:\Recovery\WindowsRE\WinRE.wim*"
del /F "!let!:\WinRE.wim.bak" /Q /A >nul 2>&1
!agent! /Setreimage /Path R:\Recovery\WindowsRE /Target !let!:\Windows
!agent! /enable
mountvol R: /d >nul
diskpart /s "%~dp0Closerecovery!ext!"
call "%~dp0FileExplorerPopUp-Enable.bat" "!SleepEnable!" ""
pause
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
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

:LOADCFG
FOR /F "tokens=1-3 delims= " %%A in ('call "%~dp0LoadConfig.bat"') DO (
set SleepDisable=%%A
set SleepEnable=%%B
set RestartExplorer=%%C
)
exit /b
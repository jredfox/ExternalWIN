@Echo Off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
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
call "%~dp0FileExplorerPopUp-Disable.bat" "1500"
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
!agent! /disable /Target !let!:\Windows
!agent! /Setreimage /Path R:\Recovery\WindowsRE /Target !let!:\Windows
!agent! /enable /Target !let!:\Windows
mountvol R: /d >nul
diskpart /s "%~dp0Closerecovery!ext!"
call "%~dp0FileExplorerPopUp-Enable.bat" "2000" ""
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
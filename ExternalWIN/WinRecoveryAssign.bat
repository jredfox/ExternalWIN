@Echo Off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
mountvol R: /d >nul
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
set /p par="Input Partition:"
call "%~dp0FileExplorerPopUp-Disable.bat" "1500"
set parrecovery=!par!
set letrecovery=R
echo %~dp0Openrecovery!ext!
REM ########## Actual Code #############
diskpart /s "%~dp0Openrecovery!ext!"
!let!:\Windows\System32\Reagentc /Setreimage /Path R:\Recovery\WindowsRE /Target !let!:\Windows
!let!:\Windows\System32\Reagentc /enable >nul 2>&1
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
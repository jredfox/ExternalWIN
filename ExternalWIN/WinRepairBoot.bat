@ECHO OFF
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :PP
call :LOADCFG
call "%~dp0FileExplorerPopUp-Enable.bat" >nul 2>&1
:SEL
diskpart /s "%~dp0ld.txt"
set /p disk="Input Disk Number:"
set /p ISMBR="Is This Disk LEGACY MBR (NO * In GPT Section) [Y/N]?"
IF /I %ISMBR:~0,1% EQU Y ( 
set ISMBR=T
set ext=-MBR.txt
) else (
set ISMBR=F
set ext=.txt
)
diskpart /s "%~dp0ListPar.txt"
set /p par="Input System(BOOT) Partition:"
diskpart /s "%~dp0detpar.txt"
set /p ays=Are You Sure This is the Correct Partition [Y/N]?
IF /I %ays:~0,1% NEQ Y GOTO SEL

REM Open Boot and Assign Letter S
mountvol S: /p >nul
mountvol S: /d >nul
set syspar=%par%
set letsys=S
set letvdisk=V
call "%~dp0FileExplorerPopUp-Disable.bat" "!SleepDisable!" "!RestartExplorer!"
IF "%ISMBR%"=="T" ( call "%~dp0disableactivepar.bat" )
diskpart /s "%~dp0Openboot%ext%"

:SELW
REM Assign Windows Partition to W
diskpart /s "%~dp0ListPar.txt"
set /p par="Input Windows Partition:"
diskpart /s "%~dp0detpar.txt"
set /p ays=Are You Sure This is the Correct Partition [Y/N]?
IF /I %ays:~0,1% NEQ Y GOTO SELW
set let=W
set winpar=%par%
diskpart /s "%~dp0Assign.txt"
IF %ERRORLEVEL% NEQ 0 (
set ISCDRIVE=T
set /p let="Enter Windows Drive Letter (Normally C for Windows or X on WinPE):"
)
set let=%let:"=%
set let=%let:~0,1%
REM ########## Start VDISK STUFFS #################
set searchDirectory=%let%^:
for %%f in ("%searchDirectory%\*.vhd" "%searchDirectory%\*.vhdx") do (
    set hasVHD=T
	GOTO ENDLOOP1
)
:ENDLOOP1
IF "!hasVHD!" NEQ "" (set /p vr="Is this a VDISK Repair [Y/N]?")
IF /I "!vr:~0,1!" EQU "Y" (
call :PRINTVDISKS
set /p vdisk="Enter VDISK File:"
set vdisk=!vdisk:"=!
)
IF /I "!vr:~0,1!" EQU "Y" (
echo vdisk is !vdisk!
IF "%winpe%" EQU "T" (diskpart /s "%~dp0dvhdx.txt" >nul) ELSE (powershell DisMount-DiskImage -ImagePath "!vdisk!" >nul 2>&1)
mountvol V: /p >nul
mountvol V: /d >nul
diskpart /s "%~dp0avhdx.txt"
set let=V
)
REM ############## END VDISK STUFFS #############

echo Repairing Boot^.^.^.
set bootdrive=%let%
!bootdrive!:\Windows\System32\bcdboot %let%:\Windows /f ALL /s S:
IF !ERRORLEVEL! NEQ 0 (
echo Error Running BCDBOOT Attempting to inject Current Windows Boot Manager into Older Windows
set /p bootdrive="Enter BCDBOOT Drive (Normally C for Windows or X on WinPE):"
set bootdrive=!bootdrive:"=!
set bootdrive=!bootdrive:~0,1!
!bootdrive!:\Windows\System32\bcdboot %let%:\Windows /f ALL /s S:
IF !ERRORLEVEL! NEQ 0 (!bootdrive!:\Windows\System32\bcdboot %let%:\Windows /s S:)
)

REM Close Boot
IF "!vdisk!" NEQ "" (
echo Closing VHDX
IF "%winpe%" EQU "T" (diskpart /s "%~dp0dvhdx.txt" >nul) ELSE (powershell DisMount-DiskImage -ImagePath "!vdisk!" >nul 2>&1)
)
echo Closing BOOT
mountvol S: /p >nul
mountvol S: /d >nul
diskpart /s "%~dp0Closeboot%ext%"
IF "%ISCDRIVE%" EQU "T" GOTO END
set par=%winpar%
call "%~dp0Assign-RND.bat"

:END
call "%~dp0FileExplorerPopUp-Enable.bat" "!SleepEnable!" ""
echo Repairing Boot Completed
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

:PRINTVDISKS
for %%f in ("%searchDirectory%\*.vhd" "%searchDirectory%\*.vhdx") do (
    echo VDISK: %%f
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
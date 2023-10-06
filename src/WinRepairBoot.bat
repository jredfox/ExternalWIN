@ECHO OFF
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
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
set /p let="Enter Drive Letter Normally C:"
)
set let=%let:"=%
set let=%let:~0,1%
REM ########## Start VDISK STUFFS #################
set searchDirectory=%let%:
for %%f in ("%searchDirectory%\*.vhd" "%searchDirectory%\*.vhdx") do (
    set hasVHD=T
	GOTO ENDLOOP1
)
:ENDLOOP1
IF "!hasVHD!" NEQ "" (set /p vr="Is this a VDISK Repair [Y\N]?")
IF /I "!vr:~0,1!" EQU "Y" (
call :PRINTVDISKS
set /p vdisk=Enter VDISK File:
set vdisk=!vdisk:"=!
)
IF /I "!vr:~0,1!" EQU "Y" (
echo vdisk is !vdisk!
mountvol V: /p >nul
mountvol V: /d >nul
diskpart /s "%~dp0dvhdx.txt"
diskpart /s "%~dp0avhdx.txt"
set let=V
)
REM ############## END VDISK STUFFS #############

echo Repairing Boot^.^.^.
set bootdrive=%let%
!bootdrive!:\Windows\System32\bcdboot %let%:\Windows /f ALL /s S:
IF !ERRORLEVEL! NEQ 0 (
echo Error Running BCDBOOT Attempting to inject Current Windows Boot Manager into Older Windows
set /p bootdrive="enter BCDBOOT Drive(Normally C):"
set bootdrive=!bootdrive:"=!
set bootdrive=!bootdrive:~0,1!
!bootdrive!:\Windows\System32\bcdboot %let%:\Windows /f ALL /s S:
IF !ERRORLEVEL! NEQ 0 (!bootdrive!:\Windows\System32\bcdboot %let%:\Windows /s S:)
)

REM Close Boot
echo Closing BOOT
mountvol S: /p >nul
mountvol S: /d >nul
diskpart /s "%~dp0Closeboot%ext%"
IF "%vdisk%" NEQ "" (
echo Closing VHDX
diskpart /s "%~dp0dvhdx.txt"
)
IF "%ISCDRIVE%" EQU "T" GOTO END
set par=%winpar%
diskpart /s "%~dp0%Assign-RND.txt"
:END
echo Repairing Boot Completed
title %cd%
pause
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)

:PRINTVDISKS
for %%f in ("%searchDirectory%\*.vhd" "%searchDirectory%\*.vhdx") do (
    echo VDISK: %%f
)
@ECHO OFF
:SEL
setlocal enableDelayedExpansion
diskpart /s "%~dp0ld.txt"
set /p disk=Input Disk Number:
set /p ISMBR="Is This Disk LEGACY MBR (NO * In GPT Section) [Y/N]?"
IF /I %ISMBR:~0,1% EQU Y ( 
set ISMBR=T
set ext=-MBR.txt
) else (
set ISMBR=F
set ext=.txt
)
diskpart /s "%~dp0ListPar.txt"
set /p par=Input System(BOOT) Partition:
diskpart /s "%~dp0detpar.txt"
set /p ays=Are You Sure This is the Correct Partition [Y/N]?
IF /I %ays:~0,1% NEQ Y GOTO SEL

REM Open Boot and Assign Letter S
set syspar=%par%
diskpart /s "%~dp0openboot%ext%"

:SELW
REM Assign Windows Partition to W
diskpart /s "%~dp0ListPar.txt"
set /p par=Input Windows Partition:
set winpar=%par%
diskpart /s "%~dp0detpar.txt"
set /p ays=Are You Sure This is the Correct Partition [Y/N]?
IF /I %ays:~0,1% NEQ Y GOTO SELW
set let=W
diskpart /s "%~dp0reassignW.txt"
IF %ERRORLEVEL% NEQ 0 (set /p let="Enter Drive Letter Normally C:")
set let=%let:~0,1%

echo Repairing Boot^.^.^.
%let%:\Windows\System32\bcdboot %let%:\Windows /f ALL /s S:
IF %ERRORLEVEL% NEQ 0 (
echo[
echo[
echo ###################################################################
echo Attempting to create Boot file by running BCDBoot for older Windows
echo ###################################################################
%let%:\Windows\System32\bcdboot %let%:\Windows /s S:
)

REM Close Boot
mountvol S: /p
mountvol S: /d
diskpart /s "%~dp0closeboot%ext%"
rem ####Grab the next Drive Letter#####
IF %let% EQU C GOTO END
set let=W
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set let=%drives:~0,1%
echo Assiging W:\ to %let%:\
diskpart /s "%~dp0%reassignW.txt"
:END
echo Repairing Boot Completed
title %cd%
pause
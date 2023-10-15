@ECHO OFF
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
call :PP

:SELFILE
set msg="Enter File Name:"
IF "%winpe%" EQU "T" (set msg=Enter File Save As^:)
set /p wim=%msg%
set wim=!wim:"=!
IF "!winpe!" EQU "T" (
IF "!wim:~1,1!" NEQ ":" (
echo Enter Full Path of the File to Save As
GOTO SELFILE
)
)
set /p desc="Enter Name of Backup:"
diskpart /s "%~dp0ld.txt"
set /p disk="Input Disk Number:"
diskpart /s "%~dp0dd.txt"
set /p let="Enter Capture Drive:"
set let=!let:"=!
REM IF We are only capturing the whole drive fix the drive letter to make DISM happy
IF "!let:~3,3!" EQU "" (set let=!let:~0,1!^:)

REM ######## SANITY CHECK ###################
set tdrive=!let:~0,1!
set workdir=%~dp0
IF "!wim:~1,1!" EQU ":" (set wdrive=!wim:~0,1!) ELSE (set wdrive=!workdir:~0,1!)
echo target !tdrive! wim drive !wdrive!

IF /I "!tdrive!" EQU "!wdrive!" (
IF "!let:~3,3!" EQU "" (
echo ERR Cannot Capture The Entire Drive The WIM Image Is Being Saved to
GOTO SELFILE
)
echo WARNING Capturing the Same Drive as your saving to Could Cause an "Infinite Read/Write Loop" till Disk space runs out
set /p ays="Do You Wish To Continue [Y/N]?"
IF /I "!ays:~0,1!" NEQ "Y" (GOTO SELFILE)
)

REM ######## Find the ComputerName ############
set drive=!let:~0,1!
set comp=!drive!:\Windows\System32\Config\SYSTEM
IF NOT EXIST "!comp!" (
set /p drive="Enter Windows Drive Letter:"
set drive=!drive:"=!
set drive=!drive:~0,1!
set comp=!drive!:\Windows\System32\Config\SYSTEM
)
IF NOT EXIST "!comp!" (
set /p COMPNAME="AutoDetection Failed Enter Computer Name:"
set COMPNAME=!COMPNAME:"=!
GOTO INSTALL
)
reg load HKLM\OfflineSystem "!comp!" >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (GOTO CHK)
for /f "tokens=3*" %%a in ('reg query HKLM\OfflineSystem\ControlSet001\Control\ComputerName\ComputerName /v ComputerName') do (set COMPNAME=%%a)
reg unload HKLM\OfflineSystem

:CHK
REM ### IF Computer Name is Still Blank It Means We are Capturing on the Same Computer As We are Currently Running On ###
IF "!COMPNAME!" EQU "" (set COMPNAME=!ComputerName!)

:INSTALL
echo Capturing !let! on Computer !COMPNAME!
REM If USER Specified a Relitive Path Then Store it in Documents
IF "!wim:~1,1!" NEQ ":" (set wim=!USERPROFILE!\Documents\!COMPNAME!\WIMS\!wim!)
set wim=!wim!.wim
set wim=!wim:.wim.wim=.wim!
md "%wim%" >nul 2>&1
rd /q "%wim%" >nul 2>&1

IF NOT EXIST "%wim%" (
dism /capture-image /imagefile:"%wim%" /capturedir:"%let%" /name:"%desc%" /Description:"%COMPNAME% On %date% %time%" /compress:maximum
) ELSE (
dism /append-image /imagefile:"%wim%" /capturedir:"%let%" /name:"%desc%" /Description:"%COMPNAME% On %date% %time%"
)
pause
exit /b

:checkAdmin
net session >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
echo !~1
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
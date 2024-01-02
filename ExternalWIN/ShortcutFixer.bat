@ECHO OFF
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :PP
set reecurse=T
IF "%~1" NEQ "" (
set scandir=%1
set oldpath=%2
set newpath=%3
set reecurse=%~4
set lnkSearch=%~5
) ELSE (
set /p scandir="Enter Drive to Scan:"
set /p oldpath="Enter Old Drive Letter(W Normally):"
set /p newpath="Enter New Drive Letter(C Normally):"
)
REM ## Set the Default search to include All Types JUNCTIONS SYMDIRS AND SYMFILES ##
IF "!lnkSearch!" EQU "" (set lnkSearch=JDF)
REM ##Process JDF Booleans from lnkSearch var ##
IF "!lnkSearch:J=!" NEQ "!lnkSearch!" (set JSrch=0xA0000003)
IF "!lnkSearch:D=!" NEQ "!lnkSearch!" (
set DSrch=D
set SYMSrch=0xA000000C^=
)
IF "!lnkSearch:F=!" NEQ "!lnkSearch!" (
set FSrch=F
set SYMSrch=0xA000000C^=
)
set Symval=!SYMSrch!!DSrch!!FSrch!
IF "!JSrch!" NEQ "" (
If "!Symval!" NEQ "" (
set JSrch=!JSrch!^;
)
)
REM ## Remove Quotes Safley from the path without screwing things up ##
set scandir=!scandir:"=!
set oldpath=!oldpath:"=!
set newpath=!newpath:"=!
REM ## Fix Lazy Drive Letters ##
IF "!scandir:~3,1!" EQU "" (set scandir=!scandir:~0,1!^:\)
IF "!oldpath:~3,1!" EQU "" (set oldpath=!oldpath:~0,1!^:\)
IF "!newpath:~3,1!" EQU "" (set newpath=!newpath:~0,1!^:\)
REM ## Ensure the Scan Dir, Old Path, New Path all end in backslash ##
IF "!scandir:~-1!" NEQ "\" (SET scandir=!scandir!^\)
IF "!oldpath:~-1!" NEQ "\" (SET oldpath=!oldpath!^\)
IF "!newpath:~-1!" NEQ "\" (SET newpath=!newpath!^\)
IF /I "!reecurse:~0,1!" NEQ "F" (set reflag=TRUE) ELSE (set reflag=FALSE)
set JLinks=%TMP%\JLinks.txt
del /F /Q /A "!JLinks!" >nul 2>&1
set NewDrive=!newpath:~0,1!
call :HASDRIVE "!NewDrive!"
IF "!HASDRIVE!" NEQ "T" (
set /p createDummy="Create Dummy Drive to Patch Junctions And SYMLINKS [Y/N]?"
IF /I "!createDummy!" EQU "Y" (call :CREATEDUMMY "!NewDrive!" "!scandir:~0,1!")
)
echo Scanning for Juntions and Symbolic Links in "!scandir!"
call :GETDIRSAFE
call "!direxe!" "/Attr^:RASHOIXVPUB" "!scandir!" "!reflag!" "P" "K" "!JSrch!!Symval!" 2>nul>"!JLinks!"
cscript /nologo "%~dp0PatchJLinks.vbs" "!JLinks!" "!oldpath!" "!newpath!"
pause
exit /b

REM ## USAGE TARGDRIVE, SCANDRIVE ONE SINGLE DRIVE LETTER ##
:CREATEDUMMY
set TargDrive=%~1
set ScanDrive=%~2
set WORKINGDRIVE=!HOMEDRIVE!
IF "!WORKINGDRIVE!" EQU "" (set WORKINGDRIVE=!ScanDrive!)
call :GETDUMMY
IF "!DummyDrive!" EQU "" (
echo Creating Dummy Drive^.^.^.
diskpart /s "%~dp0createdummy.txt"
IF !ERRORLEVEL! NEQ 0 (
set /p WORKINGDRIVE="Creation Of Dummy Drive Failed Enter Windows Drive to Shrink 10MB:"
set WORKINGDRIVE=!WORKINGDRIVE:"=!
set WORKINGDRIVE=!WORKINGDRIVE:~0,1!
diskpart /s "%~dp0createdummy.txt"
)
call :GETDUMMY
) ELSE (
set volume=!DummyDrive:~0,1!
set let=!TargDrive!
echo Assigning Dummy Drive letter !TargDrive!^:
diskpart /s "%~dp0AssignVol.txt"
)
exit /b

:GETDUMMY
FOR /F "tokens=1* delims= " %%a in ('wmic volume where "Label='EXTWNDUMMY'" get Caption 2^>nul') DO (
set caption=%%a
IF "!caption:~1,1!" EQU ":" (set DummyDrive=!caption!)
)
exit /b

:HASDRIVE
set SRCHDrive=%~1
set SRCHDrive=!SRCHDrive:~0,1!
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
FOR /F "delims=:" %%A IN ('wmic logicaldisk get caption') DO set "drives=!drives:%%A=!"
set drivess=!drives:%SRCHDrive%=!
IF "!drivess!" NEQ "!drives!" (set HASDRIVE=F) ELSE (set HASDRIVE=T)
exit /b

:checkAdmin
net session >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
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

:GETDIRSAFE
set dirsafedir=%~dp0DirSafe
set direxe=!dirsafedir!\DirSafe-x64.exe
call "!direxe!" "/?" >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (set direxe=!dirsafedir!\DirSafe-x86.exe)
exit /b
@ECHO OFF
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :PP
call :LOADCFG

:SELFILE
set msg="Enter File Name:"
IF "%winpe%" EQU "T" (set msg=Enter File Save As^:)
set /p wim=%msg%
set wim=!wim:"=!
set wim=!wim:^/=^\!
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
set let=!let:^/=^\!
REM ## Remove Extra Backslash In case of User Error ##
IF "!let:~-1!" EQU "\" (SET let=!let:~0,-1!)
REM IF We are only capturing the whole drive fix the drive letter to make DISM happy
IF "!let:~3,1!" EQU "" (
set let=!let:~0,1!^:
set ISROOT=T
)
set drive=!let:~0,1!
REM ## REMOVE ATTRIBUTES Of Configurable Directories ##
IF "%winpe%" EQU "T" (call "%~dp0removeatt.bat" "!drive!")

REM ######## Find the ComputerName ############
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
echo Capturing "!let!" on Computer "!COMPNAME!"
REM If USER Specified a Relitive Path in Non WinPE Then Store it in Documents
IF "!wim:~1,1!" NEQ ":" (set wim=!HOMEDRIVE:~0,1!^:\ExternalWIN\ImageBackups\!COMPNAME!\WIMS\!wim!)
set wim=!wim!.wim
set wim=!wim:.wim.wim=.wim!
md "%wim%" >nul 2>&1
rd /q "%wim%" >nul 2>&1
set ttime=%time: =%

REM ## CREATE Exclusion ONEDRIVE List to prevent accidental erasing of onedrive and work around for Windows 11 DISM bugs ##
echo Creating DISM Exclusion List
set EXTDISMCFG=%TMP%\EXTWINDISMCapture.ini
call "%~dp0CreateDISMCFG.bat" "!let!" "!wim!"

REM ## CREATE ONEDRIVE WIM Backups if Specified ##
set BackupOneDrive=F
IF "!ISROOT!" EQU "T" (set BackupOneDrive=T)
IF /I "!let:~2!" EQU "\Users" (set BackupOneDrive=T)
IF "!BackupOneDrive!" EQU "T" (call "%~dp0backuponedrives.bat" "!drive!" "!COMPNAME!" "!extattrib!")

REM ## Create TARGET PATH FILE FOR TARGET DETECTION ##
call :PTF "!let!"
IF "!file!" EQU "ERR" (
echo Invalid Target Directory it cannot contains PATH SEPERATOR SEQUENCE "^#^@"
exit /b
)
set targ=!let!\EXTWNCAP!file!
del /F /Q /A "!let!\EXTWNCAP^$^*^." >nul 2>&1
type NUL >"!targ!"

IF NOT EXIST "%wim%" (
dism /capture-image /imagefile:"%wim%" /capturedir:"%let%" /name:"%desc%" /Description:"%COMPNAME% On %date% %ttime%" /compress:maximum /NoRpFix!extattrib! /ConfigFile:"!EXTDISMCFG!"
IF !ERRORLEVEL! EQU 0 (echo Captured WIM Successfully to "!wim!") ELSE (echo Capture WIM FAILED Please Delete "!wim!")
) ELSE (
dism /append-image /imagefile:"%wim%" /capturedir:"%let%" /name:"%desc%" /Description:"%COMPNAME% On %date% %ttime%" /NoRpFix!extattrib! /ConfigFile:"!EXTDISMCFG!"
IF !ERRORLEVEL! EQU 0 (echo Captured WIM Successfully to "!wim!") ELSE (echo Capture WIM FAILED Delete the Latest Index If a New Index was Created In "!wim!")
)
del /F /Q /A "!targ!" >nul 2>&1
pause
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

:LOADCFG
FOR /F "tokens=4-5,7 delims= " %%A in ('call "%~dp0LoadConfig.bat"') DO (
set OptimizedWIMCapture=%%A
set OneDriveLinkScan=%%B
set ExtendedAttrib=%%C
)
IF /I "!ExtendedAttrib!" EQU "TRUE" (set extattrib= /EA)
exit /b

:FTP
set file=%1
set file=!file:"=!
set PHOLDER=^#^@
set PSEP=^$
set file=!file:%PSEP%=^\!
set file=!file:%PHOLDER%=%PSEP%!
exit /b

:PTF
set file=%1
set file=!file:"=!
set PHOLDER=^#^@
set PSEP=^$
call :CONTAINS "!file!" "!PHOLDER!"
IF /I "!STRCONTAINS!" EQU "T" (
set file=ERR
exit /b
)
IF "!file:~1,1!" EQU ":" (set file=!file:~2!)
IF "!file!" EQU "" (set file=^\)
set file=!file:%PSEP%=%PHOLDER%!
set file=!file:^\=%PSEP%!
exit /b

:CONTAINS
REM contains function that doesn't support quotes in strings
set str=%1
set strs=%2
set str=!str:"=!
set strs=!strs:"=!
set strnew=!str:%strs%=!
IF "!str!" EQU "!strnew!" (set STRCONTAINS=F) ELSE (set STRCONTAINS=T)
exit /b
@ECHO OFF
Setlocal EnableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
title ExternalWin VHDX Version RC 1.0.0

rem ############ CLEANUP ##################
set letvdisk=V
set labelvhdx=VDISK
IF "%vdisk%"=="" ( GOTO CLEANUP ) else ( GOTO CLEANUP2 )
:CLEANUP
md %userprofile%\Documents\%ComputerName%\VDISKS\
set vdisk=%userprofile%\Documents\%ComputerName%\VDISKS\windows.vhdx
diskpart /s "%~dp0dvhdx.txt"
mountvol W: /p >nul
mountvol S: /p >nul
mountvol V: /p >nul
mountvol W: /d >nul
mountvol S: /d >nul
mountvol V: /d >nul
del /f /q /a "%vdisk%" >nul
IF EXIST "%vdisk%" (
  echo ERR^: Unable to Detach ^& Delete the vdisk during cleanup %vdisk%
  echo ERR^: PLEASE REBOOT YOUR PC Before trying again
  set /p a=Press ENTER To Continue^.^.^.
  exit /b 0
)
GOTO CREATE
:CLEANUP2
mountvol W: /p >nul
mountvol S: /p >nul
mountvol V: /p >nul
mountvol W: /d >nul
mountvol S: /d >nul
mountvol V: /d >nul
echo Custom VDISK Detected: %vdisk%
GOTO SETVARS

rem ############# CREATE VHDX #############
:CREATE
set /p iso="Input Windows Install.esd / Install.wim:"
set iso=%iso:"=%
dism /get-imageinfo /imagefile:"%iso%"
set /p index="Input Windows ISO Index:"
set /p vhdsize="Input VHDX Size In GB:"
diskpart /s "%~dp0createvhdx.txt"
echo vdisk saved to %vdisk%
dism /Apply-Image /ImageFile:"%iso%" /index:"%index%" /ApplyDir:V:\
echo VHDX Created in^: %vdisk%
set /p con=Would you like to Install It [Y/N]?
IF /I %con:~0,1% NEQ Y exit /b 0

rem ####### SET VARS ####################
:SETVARS
diskpart /s "%~dp0ld.txt"
set /p disk="Input Disk Number:"
set /p legacy=MBR LEGACY Installation[Y/N]?
set fsprime=NTFS
set labelprime=VDISKS
set letprime=W
set sizesys=280
set labelsys=BOOTVHDX
set letsys=S
IF /I %legacy:~0,1% EQU Y ( 
  set dskext=-MBR.txt
  set ISMBR=T
) else ( 
  set dskext=.txt
  set ISMBR=F
)

rem ######### INIT DISK SETUP ###########
set /p e=ERASE THE DRIVE [Y/N]?
IF /I %e:~0,1% EQU Y ( GOTO ERASE ) else ( GOTO PARSEC )

:ERASE
echo erasing disk %disk%....
diskpart /s "%~dp0Clean%dskext%"
GOTO PAR

:PARSEC
set /p gtp=Is Windows Previously Installed on this Disk [Y/N]?
IF "%ISMBR%"=="T" ( call "%~dp0disableactivepar.bat" )
IF /I %gtp:~0,1% NEQ Y GOTO PAR
set /p cp1=Create System Boot Partition [Y/N]?
IF /I %cp1:~0,1% EQU Y ( diskpart /s "%~dp0ParSYS%dskext%" )
call "%~dp0CreateMSRPar.bat"
set /p cp2=Create Windows VDISKS Partition [Y/N]?
IF /I %cp2:~0,1% EQU Y ( 
set /p sizeprime="Input VDISKS Partition Size in GB:"
set sizeprime=!sizeprime!000
)
IF /I %cp2:~0,1% EQU Y ( diskpart /s "%~dp0ParPrime.txt" )
rem ##### IF We Did not Create System Par or Windows Par then Open System Par and Re-Assign Windows Par to W #####
IF NOT EXIST S:\ (
diskpart /s "%~dp0ListPar.txt"
set /p syspar="Input System Partition(Usually Around 280MB):"
)
IF NOT EXIST S:\ ( diskpart /s "%~dp0Openboot%dskext%" )
IF NOT EXIST W:\ (
diskpart /s "%~dp0ListPar.txt"
set /p winpar="Input Windows VDISKS Partition(64GB+):"
)
IF NOT EXIST W:\ (
set par=%winpar%
set let=W
diskpart /s "%~dp0Assign.txt"
)
GOTO INSTALL

:PAR
set /p sizeprime="Input VDISKS Partition Size in GB:"
set sizeprime=%sizeprime%000
echo partitioning the hard drive...
echo Creating System Boot Partition
diskpart /s "%~dp0ParSYS%dskext%"
call "%~dp0CreateMSRPar.bat"
echo Creating Windows Partition of %sizeprime% MB
diskpart /s "%~dp0ParPrime.txt"

:INSTALL
echo detatching VHDX %vdisk%
diskpart /s "%~dp0dvhdx.txt"
:LOOP
set /p vdiskhome="Enter Windows VHDX File Name:"
ECHO.%vdiskhome% | FIND /I "\">Nul && ( 
echo VDISK Name Cannot Contain Path Characters
GOTO LOOP
)
ECHO.%vdiskhome% | FIND /I "/">Nul && ( 
echo VDISK Name Cannot Contain Path Characters
GOTO LOOP
)
set vdiskhome=W:\%vdiskhome%.vhdx
set vdiskhome=%vdiskhome:.vhdx.vhdx=.vhdx%
IF EXIST "%vdiskhome%" (
  echo File Already Exists %vdiskhome%
  GOTO LOOP
)
echo copying VHDX to it's new home
copy "%vdisk%" "%vdiskhome%"
set vdisk=%vdiskhome%
diskpart /s "%~dp0avhdx.txt"
echo Creating Boot Files
set windrive=V
set bootdrive=%windrive%
V:\Windows\System32\bcdboot V:\Windows /f ALL /s S:
IF !ERRORLEVEL! NEQ 0 (
echo Error Running BCDBOOT Attempting to inject Current Windows Boot Manager into Older Windows
set /p bootdrive="enter BCDBOOT Drive(Normally C):"
set bootdrive=!bootdrive:"=!
set bootdrive=!bootdrive:~0,1!
!bootdrive!:\Windows\System32\bcdboot %windrive%:\Windows /f ALL /s S:
IF !ERRORLEVEL! NEQ 0 (!bootdrive!:\Windows\System32\bcdboot %windrive%:\Windows /s S:)
)

set /p sid=Stop Windows from Accessing Internal Disks [Y/N]?
IF /I %sid:~0,1% EQU Y ( GOTO SIDS ) else ( GOTO POSTINSTALL )

:SIDS
xcopy "%~dp0san_policy.xml" V:\
dism /Image:V:\ /Apply-Unattend:V:\san_policy.xml

:POSTINSTALL
diskpart /s "%~dp0ListPar.txt"
IF NOT "%ISMBR%"=="T" ( 
IF "%syspar%"=="" (
    set /p syspar="Input System Partition(280 MB Usually):"
  )
)
echo Closing Boot
mountvol S: /p >nul
mountvol S: /d >nul
IF NOT "%ISMBR%"=="T" ( diskpart /s "%~dp0Closeboot.txt" )
echo Closing VHDX
diskpart /s "%~dp0dvhdx.txt"
rem ####Grab the next Drive Letter & Re-Assign W:\#####
IF "%winpar%" EQU "" ( set /p winpar="Input Windows(VDISKS) Partition(64+GB Usually):" )
set par=%winpar%
diskpart /s "%~dp0%Assign-RND.txt"
echo ####################FINISHED############################
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
exit /b
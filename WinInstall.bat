@Echo Off
rem #######Disk Image Selection#########
title ExternalWin Version RC 1.0.0 b10
set /p wim=Mount Windows ISO ^& Input ^"Install.esd / Install.wim" located in resources:
dism /get-imageinfo /imagefile:"%wim%"
set /p index=Input Windows Image Index Number:
set /p wnum=Input Windows Version Number:
set /p legacy=MBR LEGACY Installation[Y/N]?
set /p cdrive=Input Windows Partition Size in GB:

rem #######SET VARS####################
set OSL=Win%wnum%
IF /I %legacy:~0,1% EQU Y ( 
set dskext=-MBR.txt
set ISMBR=T
set EFIL=BIOSW
) else ( 
set dskext=.txt
set EFIL=EFIW
)

rem #######INIT DISK SETUP############
rem remove reserved drive letters
mountvol W: /p
mountvol S: /p
diskpart /s "%~dp0ld.txt"
set /p disk=Input Disk Number:
set /p e=ERASE THE DRIVE (clean install) [Y/N]?
IF /I %e:~0,1% EQU Y GOTO ERASE
IF /I %e:~0,1% NEQ Y GOTO PARSEC

:PARSEC
set /p mer=Merge Previous Boot Partition [Y/N]?
IF /I %mer:~0,1% EQU Y (
  GOTO MERGE
)
set flag=Y
IF "%ISMBR%"=="T" (
  set /p flag=WARNING: MBR DISKS ONLY SUPPORTS 1 ACTIVE BOOT PARTITION. DO YOU WISH TO CONTINUE [Y/N]?
)
IF /I %flag:~0,1% NEQ Y GOTO MERGE
set EFIL=%EFIL%%wnum%
GOTO PAR

:MERGE
diskpart /s "%~dp0ListPar.txt"
set /p oldsyspar=Input Previous Windows Boot Partition:
diskpart /s "%~dp0PartitionMerge%dskext%"
GOTO INSTALL

:ERASE
echo erasing disk %disk%....
diskpart /s "%~dp0Clean%dskext%"

:PAR
echo partitioning the hard drive...
diskpart /s "%~dp0Partition%dskext%"

rem ########Install################
:INSTALL
dism /apply-image /imagefile:"%wim%" /index:"%index%" /applydir:W:\
echo Creating Boot Files
W:\Windows\System32\bcdboot W:\Windows /f ALL /s S:
set /p sid=Stop Windows from Accessing Internal Disks [Y/N]?
IF /I %sid:~0,1% EQU Y GOTO SIDS
IF /I %sid% NEQ Y GOTO POSTINSTALL

:SIDS
xcopy "%~dp0san_policy.xml" W:\
dism /Image:W:\ /Apply-Unattend:W:\san_policy.xml

rem #######POST INSTALL############
:POSTINSTALL
diskpart /s "%~dp0ListPar.txt"
set /p syspar=Input System Partition(250 MB Usually):
echo Closing EFI Boot
mountvol S: /p
IF NOT "%ISMBR%"=="T" (
  diskpart /s "%~dp0closeboot%dskext%"
)
set /p winpar=Input Windows Partition(64+GB Usually):
rem ####Grab the next Drive Letter#####
setlocal enableDelayedExpansion
set let=0
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set let=%drives:~0,1%
echo Assiging W:\ to %let%:\
diskpart /s "%~dp0%reassignW.txt"
echo External Installation of Windows Completed :)
title %cd%
pause
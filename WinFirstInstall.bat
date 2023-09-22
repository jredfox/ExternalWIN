@Echo Off
rem #######Disk Image Selection#########
title ExternalWin Version 1.0.0
set /p wim=Mount Windows ISO ^& Input ^"Install.esd / Install.wim" located in resources:
dism /get-imageinfo /imagefile:%wim%
set /p index=Input Windows Image Index Number:
set /p cdrive=Input Windows Partition Size in GB:

rem #INIT SETUP
diskpart /s %~dp0%\ld.txt
set /p disk=Input Disk Number:
set /p e=ERASE THE DRIVE (clean install) [Y/N]?
IF /I %e% EQU Y GOTO ERASE
IF /I %e% NEQ Y GOTO PARSEC

:PARSEC
set /p mer=Merge Previous Boot Partition [Y/N]?
IF /I %mer% EQU Y (
  diskpart /s %~dp0ListPar.txt
  set /p oldsyspar=Input Previous Windows Boot Partition:
  diskpart /s %~dp0PartitionMerge.txt
  GOTO INSTALL
)
IF /I %mer% NEQ Y GOTO PAR

:ERASE
echo erasing disk %disk%....
diskpart /s %~dp0Clean.txt

:PAR
echo partitioning the hard drive...
diskpart /s %~dp0Partition.txt

rem ########Install################
:INSTALL
dism /apply-image /imagefile:%wim% /index:%index% /applydir:W:\
echo Creating Boot Files
W:\Windows\System32\bcdboot W:\Windows /f ALL /s S:
set /p sid=Stop Windows from Accessing Internal Disks [Y/N]?
IF /I %sid% EQU Y GOTO SIDS
IF /I %sid% NEQ Y GOTO POSTINSTALL

:SIDS
xcopy %~dp0san_policy.xml W:\
dism /Image:W:\ /Apply-Unattend:W:\san_policy.xml

rem #######POST INSTALL############
:POSTINSTALL
diskpart /s %~dp0ListPar.txt
set /p syspar=Input System Partition(250 MB Usually):
echo Closing EFI Boot
set drive=S:
mountvol %drive% /p
diskpart /s %~dp0%closeboot.txt
set /p winpar=Input Windows Partition(64+GB Usually):
rem ####Grab the next Drive Letter#####
setlocal enableDelayedExpansion
set let=0
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set let=%drives:~0,1%
echo Assiging W:\ to %let%:\
diskpart /s %~dp0%reassignW.txt
pause
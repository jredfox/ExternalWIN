@ECHO OFF
Setlocal EnableDelayedExpansion
title ExternalWin VHDX Version RC 1.0.0 b10
rem ############ CLEANUP ##################
set vdisk=C:\windows.vhdx
diskpart /s "%~dp0dvhdx.txt"
del /f /q /a "%vdisk%"
mountvol W: /p
mountvol S: /p
rem cls TODO: REMOVE REM
rem ############# CREATE VHDX #############
set /p iso=Input Windows Install.esd / Install.wim:
dism /get-imageinfo /imagefile:"%iso%"
set /p index=Input Windows ISO Index:
set /p legacy=MBR LEGACY Installation[Y/N]?
set /p vhdsize=Input VHDX Size In GB:
diskpart /s "%~dp0createvhdx.txt"
dism /Apply-Image /ImageFile:"%iso%" /index:"%index%" /ApplyDir:V:\
set /p con=VHDX Created in: %vdisk% Would you like to Install It [Y/N]?
IF /I %con:~0,1% NEQ Y exit /b 0

rem ####### SET VARS ####################
set OSL=VHDXS
set EFIL=BOOTVHDX
IF /I %legacy:~0,1% EQU Y ( 
  set dskext=-MBR.txt
  set ISMBR=T
) else ( 
  set dskext=.txt
  set ISMBR=F
)

rem ######### INIT DISK SETUP ###########
set /p cdrive=Input VHDX(S) Partition Size in GB:
diskpart /s "%~dp0ld.txt"
set /p disk=Input Disk Number:
set /p e=ERASE THE DRIVE [Y/N]?
IF /I %e:~0,1% EQU Y ( GOTO ERASE ) else ( GOTO PARSEC )

:ERASE
echo erasing disk %disk%....
diskpart /s "%~dp0Clean%dskext%"
GOTO PAR

:PARSEC
set /p gtp=Is Windows Previously Installed on this Disk [Y/N]?
IF /I %gtp:~0,1% NEQ Y GOTO PAR
set /p prev=Create new System Partition [Y/N]?
IF /I %prev:~0,1% EQU Y (
  
)
set /p parvhd=Create new VHDX(S) Partition [Y/N]?
IF /I %parvhd:~0,1% EQU Y (
  
)
GOTO INSTALL

:PAR
echo partitioning the hard drive...
diskpart /s "%~dp0Partition%dskext%"

:INSTALL
echo detatching VHDX %vdisk%
diskpart /s "%~dp0dvhdx.txt"
echo copying VHDX to it's new home UWU
xcopy "%vdisk%" W:\
echo deleting VHDX %vdisk%
del /f /q /a "%vdisk%"
set vdisk=W:\windows.vhdx
diskpart /s "%~dp0avhdx.txt"
echo Creating Boot Files
V:\Windows\System32\bcdboot V:\Windows /f ALL /s S:
set /p sid=Stop Windows from Accessing Internal Disks [Y/N]?
IF /I %sid:~0,1% EQU Y ( GOTO SIDS ) else ( GOTO POSTINSTALL )

:SIDS
xcopy "%~dp0san_policy.xml" V:\
dism /Image:V:\ /Apply-Unattend:V:\san_policy.xml

:POSTINSTALL
diskpart /s "%~dp0ListPar.txt"
set /p syspar=Input System Partition(250 MB Usually):
echo Closing EFI Boot
mountvol S: /p
IF NOT "%ISMBR%"=="T" (
  diskpart /s "%~dp0closeboot%dskext%"
)
echo Closing VHDX
diskpart /s "%~dp0dvhdx.txt"
rem ####Grab the next Drive Letter & Re-Assign W:\#####
set /p winpar=Input Windows(VHDXS) Partition(64+GB Usually):
setlocal enableDelayedExpansion
set let=0
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set let=%drives:~0,1%
echo Assiging W:\ to %let%:\
diskpart /s "%~dp0%reassignW.txt"
echo ####################FINISHED############################
title %cd%
pause
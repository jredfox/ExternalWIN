@Echo Off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
title ExternalWin Version 1.0.11
call :PP
call :LOADCFG
call "%~dp0FileExplorerPopUp-Enable.bat" >nul 2>&1
Reagentc /enable >nul 2>&1
rem #######Disk Image Selection#########
set /p wim="Mount Windows ISO & Input (Install.esd / Install.wim) located in sources:"
set wim=%wim:"=%
dism /get-imageinfo /imagefile:"%wim%"
set /p index="Input Windows Image Index Number:"
set /p wnum="Input Windows Version Number:"
diskpart /s "%~dp0ld.txt"
set /p disk="Input Disk Number:"
set /p legacy=MBR LEGACY Installation [Y/N]?
set /p sizebase="Input Windows Partition Size in GB:"

rem #######SET VARS####################
set sizeprime=%sizebase%000
set labelprime=Win%wnum%
set letprime=W
set fsprime=NTFS
set sizesys=280
set letsys=S
IF /I %legacy:~0,1% EQU Y ( 
set dskext=-MBR.txt
set ISMBR=T
set labelsys=BIOSW
) ELSE ( 
set ISMBR=F
set dskext=.txt
set labelsys=EFIW
)

REM #######INIT DISK SETUP############
REM remove reserved drive letters
mountvol W: /p >nul
mountvol S: /p >nul
mountvol W: /d >nul
mountvol S: /d >nul
mountvol R: /d >nul
set /p e=ERASE THE DRIVE (clean install) [Y/N]?
call "%~dp0FileExplorerPopUp-Disable.bat" "!SleepDisable!" "!RestartExplorer!"
IF /I %e:~0,1% EQU Y GOTO ERASE
IF /I %e:~0,1% NEQ Y GOTO PARSEC

:PARSEC
set secinstall=T
set /p mer=Merge Previous Boot Partition [Y/N]?
IF /I %mer:~0,1% EQU Y (
  GOTO MERGE
)
set flag=Y
IF "%ISMBR%"=="T" (
  set /p flag="WARNING: MBR DISKS ONLY SUPPORTS 1 ACTIVE BOOT PARTITION. DO YOU WISH TO CONTINUE [Y/N]?"
)
IF /I %flag:~0,1% NEQ Y GOTO MERGE
set labelsys=%labelsys%%wnum%
GOTO PAR

:MERGE
diskpart /s "%~dp0ListPar.txt"
set /p syspar="Input Previous Windows Boot Partition(280 MB Usually):"
IF "%ISMBR%"=="T" (call "%~dp0disableactivepar.bat")
echo Opening Up Boot Partition
diskpart /s "%~dp0OpenBoot%dskext%"
call "%~dp0CreateMSRPar.bat"
echo Creating Windows Partition of %sizeprime% MB
diskpart /s "%~dp0ParPrime.txt"
GOTO INSTALL

:ERASE
echo Erasing the Disk %disk%^.^.^.^.
diskpart /s "%~dp0Clean%dskext%"

:PAR
echo Partitioning the hard drive^.^.^.
IF "%secinstall%" NEQ "" (
IF "%ISMBR%"=="T" (call "%~dp0disableactivepar.bat")
)
echo Creating System Boot Partition
diskpart /s "%~dp0ParSYS%dskext%"
call "%~dp0CreateMSRPar.bat"
echo Creating Windows Partition of %sizeprime% MB
diskpart /s "%~dp0ParPrime.txt"

rem ########Install################
:INSTALL
dism /apply-image /imagefile:"%wim%" /index:"%index%" /applydir:W:\
echo Creating Boot Files
set bootdrive=W
!bootdrive!:\Windows\System32\bcdboot W:\Windows /f ALL /s S:
IF !ERRORLEVEL! NEQ 0 (
echo Error Running BCDBOOT Attempting to inject Current Windows Boot Manager into Older Windows
set /p bootdrive="Enter BCDBOOT Drive (Normally C for Windows or X on WinPE):"
set bootdrive=!bootdrive:"=!
set bootdrive=!bootdrive:~0,1!
!bootdrive!:\Windows\System32\bcdboot W:\Windows /f ALL /s S:
IF !ERRORLEVEL! NEQ 0 (!bootdrive!:\Windows\System32\bcdboot W:\Windows /s S:)
)

REM ############ CUSTOM BIOS NAMES #####################################
:BIOSNAME
set /p biosname="Enter Bios Name Default is Windows Boot Manager:"
set biosname=%biosname:"=%
%bootdrive%:\Windows\System32\bcdedit.exe /store S:\Boot\BCD /set {bootmgr} description "%biosname%"
%bootdrive%:\Windows\System32\bcdedit.exe /store S:\EFI\Microsoft\Boot\BCD /set {bootmgr} description "%biosname%"

REM ############## STOP WINDOWS 10 & 11 From Requiring the Internet
echo OOBE Bypass NRO. Out of Box Experience Bypassing Network Requirement Option
reg load HKLM\OfflineSOFTWARE W:\Windows\System32\Config\SOFTWARE
reg add HKLM\OfflineSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
reg unload HKLM\OfflineSOFTWARE

set /p sid=Stop Windows from Accessing Internal Disks [Y/N]?
IF /I %sid:~0,1% EQU Y GOTO SIDS
IF /I %sid:~0,1% NEQ Y GOTO ENDSIDS

:SIDS
reg load HKLM\OfflineSystem W:\Windows\System32\Config\SYSTEM
reg import "%~dp0DisableDiskAccess.reg"
reg unload HKLM\OfflineSystem
REM this is the old code that only works for Win10+ and only supported AMD64 and x86 or ARM64 which is microsoft surface and future devices. Older Windows 10 doesnt' regonize the arch of AMD64 so errors on that to
REM xcopy "%~dp0san_policy.xml" W:\
REM dism /Image:W:\ /Apply-Unattend:W:\san_policy.xml
:ENDSIDS

REM ###### Create & Register Recovery Files ####################
:RECOVERY
set recovery=F
set /p rp=Do You Want to Create a Recovery Partition [Y/N]?
IF /I %rp:~0,1% NEQ Y GOTO ENDRECOVERY
set recovery=T
set sizerecovery=1024
set labelrecovery=Recovery
set letrecovery=R
diskpart /s "%~dp0Createrecovery.txt"
IF NOT EXIST "W:\Windows\System32\Recovery\Winre.wim" (
echo Missing Winre^.wim You can Use your BackedUp OEM Recovery Partition WIM with WimApply-Universal^.bat and WinAssignRecovery^.bat after the Installation
GOTO ENDRECOVERY
)
md R:\Recovery\WindowsRE >nul 2>&1
REM Check if the Target Reagentc can run on this computer if not use this computers reagentc
set agent=W:\Windows\System32\Reagentc
!agent! "/?" >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
echo "Can't Run !agent! on this computer is the ISA Incompatible?"
set agent=Reagentc
)
xcopy /h W:\Windows\System32\Recovery\Winre.wim R:\Recovery\WindowsRE\
!agent! /disable
!agent! /Setreimage /Path R:\Recovery\WindowsRE /Target W:\Windows
!agent! /enable
:ENDRECOVERY

REM ########## BACKUP SYSTEM BOOT #####################
set backupdir=W:\ExternalWIN\Backups
set rbackupdir=R:\ExternalWIN\Backups
md "%backupdir%" >nul 2>&1
set bootfile=%backupdir%\boot.wim
set name=Boot of Windows %wnum%
echo Backuping Up Boot to %bootfile%
dism /capture-image /imagefile:"%bootfile%" /capturedir:"S:" /name:"%name%" /Description:"%name%" /compress:maximum
IF EXIST "R:\" (
md "%rbackupdir%" >nul 2>&1
copy "%bootfile%" "%rbackupdir%\boot.wim"
)
echo It's Recommended to use REG-Capture.bat for your new Windows Installation as well as WIM-Capture.bat to backup your Windows Partition

rem #######POST INSTALL############
:POSTINSTALL
diskpart /s "%~dp0ListPar.txt"
IF NOT "%ISMBR%" EQU "T" ( 
IF "%syspar%" EQU "" (
    set /p syspar="Input System(BOOT) Partition(280 MB Usually):"
  )
)
echo Closing Boot
mountvol S: /p >nul
mountvol S: /d >nul
mountvol R: /d >nul
IF NOT "%ISMBR%"=="T" ( diskpart /s "%~dp0Closeboot%dskext%" )
set /p par="Input Windows Partition(64+GB Usually):"
call "%~dp0Assign-RND.bat"
IF "%recovery%" EQU "T" (set /p parrecovery="Input Recovery Partition(1GB Usually):")
IF "%recovery%" EQU "T" (diskpart /s "%~dp0Closerecovery%dskext%")
call "%~dp0FileExplorerPopUp-Enable.bat" "!SleepEnable!" ""
echo External Installation of Windows Completed :)
title %cd%
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
IF "!winpe!" EQU "T" (exit /b)
FOR /F "tokens=1-3 delims= " %%A in ('call "%~dp0LoadConfig.bat"') DO (
set SleepDisable=%%A
set SleepEnable=%%B
set RestartExplorer=%%C
)
exit /b

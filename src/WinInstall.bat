@Echo Off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
call :PP
rem #######Disk Image Selection#########
title ExternalWin Version RC 1.0.0
set /p wim="Mount Windows ISO & Input (Install.esd / Install.wim) located in resources:"
set wim=%wim:"=%
dism /get-imageinfo /imagefile:"%wim%"
set /p index="Input Windows Image Index Number:"
set /p wnum="Input Windows Version Number:"
set /p legacy=MBR LEGACY Installation [Y/N]?
set /p cdrive="Input Windows Partition Size in GB:"

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
mountvol R: /p
mountvol W: /d
mountvol S: /d
mountvol R: /d
diskpart /s "%~dp0ld.txt"
set /p disk="Input Disk Number:"
set /p e=ERASE THE DRIVE (clean install) [Y/N]?
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
set EFIL=%EFIL%%wnum%
GOTO PAR

:MERGE
diskpart /s "%~dp0ListPar.txt"
set /p syspar="Input Previous Windows Boot Partition:"
IF "%ISMBR%"=="T" (
echo disabling active partition^.^.^.
call "%~dp0disableactivepar.bat"
)
diskpart /s "%~dp0PartitionMerge%dskext%"
GOTO INSTALL

:ERASE
echo erasing disk %disk%^.^.^.^.
diskpart /s "%~dp0Clean%dskext%"

:PAR
echo partitioning the hard drive^.^.^.
IF "%secinstall%" NEQ "" (
IF "%ISMBR%"=="T" (
echo disabling active partition^.^.^.
call "%~dp0disableactivepar.bat"
)
)
diskpart /s "%~dp0Partition%dskext%"

rem ########Install################
:INSTALL
dism /apply-image /imagefile:"%wim%" /index:"%index%" /applydir:W:\
echo Creating Boot Files
set bootdrive=W
!bootdrive!:\Windows\System32\bcdboot W:\Windows /f ALL /s S:
IF !ERRORLEVEL! NEQ 0 (
echo Error Running BCDBOOT Attempting to inject Current Windows Boot Manager into Older Windows
set /p bootdrive="enter BCDBOOT Drive(Normally C):"
set bootdrive=!bootdrive:"=!
set bootdrive=!bootdrive:~0,1!
!bootdrive!:\Windows\System32\bcdboot W:\Windows /f ALL /s S:
IF !ERRORLEVEL! NEQ 0 (!bootdrive!:\Windows\System32\bcdboot W:\Windows /s S:)
)

set /p sid=Stop Windows from Accessing Internal Disks [Y/N]?
IF /I %sid:~0,1% EQU Y GOTO SIDS
IF /I %sid:~0,1% NEQ Y GOTO ENDSIDS

:SIDS
xcopy "%~dp0san_policy.xml" W:\
dism /Image:W:\ /Apply-Unattend:W:\san_policy.xml

:ENDSIDS

REM ############ CUSTOM BIOS NAMES #####################################
:BIOSNAME
set /p biosname="Enter Bios Name Default is Windows Boot Manager:"
set biosname=%biosname:"=%
%bootdrive%:\Windows\System32\bcdedit.exe /store S:\Boot\BCD /set {bootmgr} description "%biosname%"
%bootdrive%:\Windows\System32\bcdedit.exe /store S:\EFI\Microsoft\Boot\BCD /set {bootmgr} description "%biosname%"

REM ###### Create & Register Recovery Files ####################
set /p rp=Do You Want to Create a Recovery Partition [Y\N]?
IF /I %rp:~0,1% NEQ Y GOTO POSTINSTALL
diskpart /s "%~dp0createrecovery.txt"
md R:\Recovery\WindowsRE
xcopy /h W:\Windows\System32\Recovery\Winre.wim R:\Recovery\WindowsRE\
W:\Windows\System32\Reagentc /Setreimage /Path R:\Recovery\WindowsRE /Target W:\Windows
diskpart /s "%~dp0ListPar.txt"
set /p par="Input Recovery Partition(1,000 MB Usually):"
mountvol R: /p
mountvol R: /d
diskpart /s "%~dp0closerecovery%dskext%"

rem #######POST INSTALL############
:POSTINSTALL
diskpart /s "%~dp0ListPar.txt"
IF NOT "%ISMBR%"=="T" ( 
IF "%syspar%"=="" (
    set /p syspar="Input System Partition(250 MB Usually):"
  )
)
echo Closing Boot
mountvol S: /p
mountvol S: /d
IF NOT "%ISMBR%"=="T" ( diskpart /s "%~dp0closeboot%dskext%" )
set /p winpar="Input Windows Partition(64+GB Usually):"
rem ####Grab the next Drive Letter#####
set let=0
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set let=%drives:~0,1%
echo Assiging W:\ to %let%:\
diskpart /s "%~dp0%reassignW.txt"
call :REVPP
echo External Installation of Windows Completed :)
title %cd%
pause
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
exit /b

:PP
REM ######## WinPE support change the power plan to maximize perforamnce #########
IF EXIST "X:\" (
FOR /f "delims=" %%a in ('POWERCFG -GETACTIVESCHEME') DO @SET powerplan="%%a"
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo changed powerplan of !powerplan! to high performance 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)
exit /b

:REVPP
IF EXIST "X:\" (
powercfg /s !powerplan!
)
exit /b


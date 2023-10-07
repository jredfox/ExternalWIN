@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
call "%~dp0FileExplorerPopUp-Enable.bat" >nul 2>&1
mountvol W: /p >nul
mountvol S: /p >nul
mountvol W: /d >nul
mountvol S: /d >nul
mountvol R: /d >nul
set /p wim=Input WIM/ESD:
set wim=%wim:"=%
dism /get-imageinfo /imagefile:"%wim%"
set /p index=Input Index:
diskpart /s "%~dp0ld.txt"
set /p disk=Input Disk Number:
set /p ISMBR=Is This Disk LEGACY MBR [Y/N]?
IF /I %ISMBR:~0,1% EQU Y ( 
set ISMBR=T
set ext=-MBR.txt
) else (
set ISMBR=F
set ext=.txt
)

:SEL
diskpart /s "%~dp0ListPar.txt"
set /p par=Input Partition:
diskpart /s "%~dp0detpar.txt"
set /p ays=Are You Sure This is the Correct Partition [Y/N]?
IF /I %ays:~0,1% NEQ Y GOTO SEL

:TYPE
set /p type="Set Par Type [S/B=Boot, W=Windows or Storage, R=Recovery]:"
set type=%type:~0,1%
IF /I "%type%" EQU "B" set type=S
IF /I "%type%" NEQ "S" IF /I "%type%" NEQ "W" IF /I "%type%" NEQ "R" (
echo INVALID TYPE "%type%"
GOTO TYPE
)
REM ##### OPEN BOOT / RECOVERY & ASSIGN VARS ##############
call "%~dp0FileExplorerPopUp-Disable.bat"
timeout /t 2 /NOBREAK >nul
IF /I !type! EQU S (
set let=S
set letsys=!let!
set syspar=!par!
)
IF /I !type! EQU S (diskpart /s "%~dp0Openboot!ext!")

IF /I !type! EQU R (
set let=R
set letrecovery=!let!
set parrecovery=!par!
)
IF /I !type! EQU R (diskpart /s "%~dp0Openrecovery!ext!")

IF /I !type! EQU W (
set let=W
)

:SELF
diskpart /s "%~dp0detpar.txt"
REM The reason why we can't assume NTFS or FAT32 for boot/windows is because this is a Universal Script that can apply any WIM image to any partition
set /p q2="Input File System Format[F=FAT32(SYSTEM BOOT / USB), N=NTFS(Windows or Storage), X=EXFAT(USB)]:"
set q2=%q2:~0,1%
IF /I "%q2%" NEQ "F" IF /I "%q2%" NEQ "N" IF /I "%q2%" NEQ "X" (
echo Invalid File Format "%q2%"
GOTO SELF
)
IF /I "%q2%" EQU "F" (set form=FAT32) ELSE IF /I "%q2%" EQU "N" (set form=NTFS) ELSE IF /I "%q2%" EQU "X" (set form=EXFAT)
diskpart /s "%~dp0detpar.txt"
set /p label=Input Partition Label:
set label=%label:"=%
diskpart /s "%~dp0formatpar.txt"

rem #### INSTALL ####################
dism /apply-image /imagefile:"%wim%" /index:"%index%" /applydir:%let%:\

rem ##### POST INSTALL ##############
IF /I %type% EQU S (
mountvol S: /p >nul
mountvol S: /d >nul
diskpart /s "%~dp0Closeboot%ext%"
GOTO END
)
IF /I %type% EQU R (
 mountvol R: /d >nul
 diskpart /s "%~dp0Closerecovery%ext%"
 GOTO END
)
diskpart /s "%~dp0Assign-RND.txt"
:END
timeout /t 2 /NOBREAK >nul
call "%~dp0FileExplorerPopUp-Enable.bat"
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
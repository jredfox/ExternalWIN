@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
mountvol W: /p
mountvol S: /p
mountvol R: /p
mountvol W: /d
mountvol S: /d
mountvol R: /d
cls
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
IF /I %type% EQU S (
set syspar=%par%
set let=S
diskpart /s "%~dp0openboot%ext%"
) ELSE (
IF /I %type% EQU R (
set let=R
diskpart /s "%~dp0openrecovery%ext%"
) ELSE (
    set let=W
  )
)

:SELF
diskpart /s "%~dp0detpar.txt"
REM The reason why we can't assume NTFS or FAT32 for boot is because this is a Universal Script that can apply any WIM image to any partition
set /p q2="Input File System Format[F=FAT32(SYSTEM BOOT / USB), N=NTFS(Windows), X=EXFAT(USB)]:"
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
mountvol S: /p
mountvol S: /d
diskpart /s "%~dp0Closeboot%ext%"
GOTO END
)
IF /I %type% EQU R (
 mountvol R: /p
 mountvol R: /d
 diskpart /s "%~dp0Closerecovery%ext%"
 GOTO END
)
diskpart /s "%~dp0%Assign-RND.txt"
:END
pause
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
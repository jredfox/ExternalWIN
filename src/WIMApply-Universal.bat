REM @Echo off
setlocal enableDelayedExpansion
mountvol W: /p
mountvol S: /p
REM cls
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
set /p type="Set Par Type [S/B=Boot, W=Windows, R=Recovery]:"
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
set let=W
)

:SELF
diskpart /s "%~dp0detpar.txt"
set /p q2="Input File System Format[F=FAT32(SYSTEM / WIN USB), N=NTFS(Win or Recovery), X=EXFAT(WIN USB)]:"
set q2=%q2:~0,1%
IF /I "%q2%" NEQ "F" IF /I "%q2%" NEQ "N" IF /I "%q2%" NEQ "X" (
echo Invalid File Format "%q2%"
GOTO SELF
)
IF /I "%q2%" EQU "F" (set form=FAT32) ELSE IF /I "%q2%" EQU "N" (set form=NTFS) ELSE IF /I "%q2%" EQU "X" (set form=EXFAT)
diskpart /s "%~dp0detpar.txt"
set /p label=Input Partition Label:
set label=%label:"=%
diskpart /s %~dp0formatpar.txt"

rem #### INSTALL ####################
dism /apply-image /imagefile:"%wim%" /index:"%index%" /applydir:%let%:\

rem ##### POST INSTALL ##############
IF /I %type% EQU S (
mountvol %let% /p
diskpart /s "%~dp0closeboot%ext%"
) ELSE (
set let=0
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set let=%drives:~0,1%
set winpar=%par%
diskpart /s "%~dp0%reassignW.txt"
)
pause
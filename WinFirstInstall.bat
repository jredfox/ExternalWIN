@Echo Off
rem #######Disk Image Selection#########
set /p wim=Mount Windows ISO ^& Input ^"Install.esd / Install.wim" located in resources:
dism /get-imageinfo /imagefile:%wim%
set /p index=Input Windows Image Index Number:

rem #INIT SETUP
diskpart /s %~dp0%\ld.txt
set /p disk=Input Disk Number:
set /p e=ERASE THE DRIVE (clean install) [Y/N]?
IF /I %e% EQU Y GOTO ERASE
IF /I %e% NEQ Y GOTO PAR

:ERASE
echo erasing disk %disk%....
diskpart /s %~dp0Clean.txt

:PAR
echo partitioning the hard drive...
diskpart /s %~dp0Partition.txt

rem ########Install################
dism /apply-image /imagefile:%wim% /index:%index% /applydir:W:\
echo Creating Boot Files....
W:\Windows\System32\bcdboot W:\Windows /f ALL /s S:

rem #######POST INSTALL############
diskpart /s %~dp0ListPar.txt
set /p syspar=Input System Partition(250 MB Usually):
echo Closing EFI Boot
diskpart /s %~dp0%closeboot.txt
set /p winpar=Input Windows Partition(64+GB Usually):
rem Grab the next Drive Letter
set let=0
rem #A-B are floppy Drives, C is reserved for Computer, D-E are sometimes disk drives and can sometimes appear as free when it's not free
for %%D in (F G H I J K L M N O P Q R S T U V W X Y Z B A D E) do ( 
if not exist %%D:\ (
set let=%%D
GOTO :END
)
)

:END
echo Assiging W:\ to %let%:\
diskpart /s %~dp0%reassignW.txt
pause
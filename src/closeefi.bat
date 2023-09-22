@Echo Off
diskpart /s %~dp0ld.txt
set /p disk=Input Disk Num:
diskpart /s %~dp0ListPar.txt
set /p syspar=Input System Partition(250 MB Usually):
echo Closing EFI Boot
mountvol S: /p
diskpart /s %~dp0%closeboot.txt
pause
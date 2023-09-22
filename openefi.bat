@Echo off
set /p disk=Enter Disk:
set /p syspar=Enter Par:
diskpart /s "%~dp0openboot.txt"
pause
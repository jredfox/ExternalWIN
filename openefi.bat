@Echo off
set /p disk=Enter Disk:
set /p oldsyspar=Enter Par:
diskpart /s "%~dp0openboot.txt"
pause
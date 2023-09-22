@ECHO OFF
set /p wim=Enter File Name:
diskpart /s "%~dp0ld.txt"
set /p disk=Input Disk Number:
diskpart /s "%~dp0dd.txt"
set /p let=Enter Drive:
md %userprofile%\Documents\%ComputerName%
set wim=%userprofile%\Documents\%ComputerName%\%wim%.wim
dism /capture-image /imagefile:"%wim%" /capturedir:"%let%" /name:"%ComputerName%" /compress:max
IF ERRORLEVEL 1 echo ######################### & echo Try Changing "%let%" to "%let:~0,1%:" or "%let:~0,1%" to capture the entire drive. This is a DISM.exe bug not an issue with the script & echo#########################
echo "SAVED WIM TO: %wim%"
pause
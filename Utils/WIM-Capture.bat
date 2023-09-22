@ECHO OFF
set /p wim=Enter File Name:
set /p let=Enter Drive:
set wim=%userprofile%\Documents\%ComputerName%\%wim%.wim
dism /capture-image /imagefile:"%wim%" /capturedir:"%let%" /name:"%ComputerName%" /compress:max
echo "SAVED WIM TO: %wim%"
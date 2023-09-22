@ECHO OFF
set /p wim=Enter File Name:
set /p let=Enter Drive:
set /p wim=Enter File Save As:
dism /capture-image /imagefile:"%wim%" /capturedir:"%let%" /name:"%ComputerName%" /compress:max
echo "SAVED WIM TO: %wim%"
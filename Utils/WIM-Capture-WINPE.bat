@ECHO OFF
set /p wim=File Save As:
set /p let=Enter Drive:
set wim=%wim:"=%
set let=%let:"=%
REM create parent directory
md "%wim%"
rd /s /q "%wim%"
dism /capture-image /imagefile:"%wim%" /capturedir:"%let%" /name:%ComputerName% /compress:max
echo "SAVED WIM TO: %wim%"
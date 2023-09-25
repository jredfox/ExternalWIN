@ECHO OFF
setlocal enableDelayedExpansion
set /p wim=File Save As:
set /p desc=Enter Description:
diskpart /s "%~dp0ld.txt"
set /p disk=Input Disk Number:
diskpart /s "%~dp0dd.txt"
set /p let=Enter Drive:
set wim=%wim:"=%
set let=%let:"=%
set let=%let:~0,1%:
REM create parent directory
md "%wim%"
rd /s /q "%wim%"
dism /capture-image /imagefile:"%wim%" /capturedir:"%let%" /name:"%ComputerName%" /Description:"%desc%" /compress:max
echo "SAVED WIM TO: %wim%"
pause
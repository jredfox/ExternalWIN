@ECHO OFF
setlocal enableDelayedExpansion
set type=%TMP%\type.txt
set type2=%TMP%\type2.txt
del /F /Q /A "!type!" >nul 2>&1
del /F /Q /A "!type2!" >nul 2>&1
FOR /F "tokens=1* delims= " %%A IN ('wmic logicaldisk get caption') DO (
set caption=%%A
IF "!caption:~1,1!" EQU ":" (
call :CHECK "!caption!"
del /F /Q /A "!type!" >nul 2>&1
del /F /Q /A "!type2!" >nul 2>&1
)
)

:END
exit /b

:CHECK
set chkdrive=%~1
set chkdrive=!chkdrive:~0,1!
IF EXIST "!chkdrive!:\" (exit /b)
fsutil fsinfo drivetype !chkdrive!^:\ >"!type!"
cscript "%~dp0FindSTR.vbs" "CD-@$DVD-@$BLUERAY-@$Floppy" "!type!" "false" >nul
IF !ERRORLEVEL! EQU 0 (exit /b)
FOR /F "tokens=2 delims==" %%I in ('wmic logicaldisk where "DeviceID='!chkdrive!:'" get description /value') do (set desc=%%I)
(
  echo %desc%
) >"!type2!"
cscript "%~dp0FindSTR.vbs" "CD-@$DVD-@$BLUERAY-@$Floppy" "!type2!" "false" >nul
IF !ERRORLEVEL! EQU 0 (exit /b)
echo Dismounting Invalid Drive "!chkdrive!:"
mountvol "!chkdrive!:" /p
exit /b
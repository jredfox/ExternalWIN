@echo off
setlocal enabledelayedexpansion
set type=%TMP%\type.txt
set type2=%TMP%\type2.txt
for /f "delims=:" %%a in ('wmic logicaldisk get caption') do (
IF NOT EXIST "%%a:\" (
call :CHECK "%%a"
del "!type!" >nul 2>&1
del "!type2!" >nul 2>&1
)
)

:END
exit /b

:CHECK
set arg=%~1
set d=!arg:~0,1!
IF "%arg:~3,3%" NEQ "" (exit /b)
fsutil fsinfo drivetype !arg!:\ >"!type!"
cscript "%~dp0FindSTR.vbs" "CD-@$DVD-@$BLUERAY-@$Floppy" "!type!" "false" >nul
IF !ERRORLEVEL! EQU 0 (exit /b)
FOR /F "tokens=2 delims==" %%I in ('wmic logicaldisk where "DeviceID='!d!:'" get description /value') do (set desc=%%I)
(
  echo %desc%
) >"!type2!"
cscript "%~dp0FindSTR.vbs" "CD-@$DVD-@$BLUERAY-@$Floppy" "!type2!" "false" >nul
IF !ERRORLEVEL! EQU 0 (exit /b)
echo Dismounting Invalid Drive "!arg!:"
mountvol "!arg!:" /p
exit /b
@echo off
setlocal enabledelayedexpansion
for /f "delims=:" %%a in ('wmic logicaldisk get caption') do (
IF NOT EXIST "%%a:\" (
call :CHECK "%%a"
del "%~dp0type.txt" >nul 2>&1
)
)

:END
exit /b

:CHECK
set arg=%~1
IF "%arg:~3,3%" NEQ "" (exit /b)
fsutil fsinfo drivetype !arg!:\ >"%~dp0type.txt"
cscript "%~dp0FindSTR.vbs" "CD-" "%~dp0type.txt" "false" >nul
IF !ERRORLEVEL! EQU 0 (exit /b)
cscript "%~dp0FindSTR.vbs" "DVD-" "%~dp0type.txt" "false" >nul
IF !ERRORLEVEL! EQU 0 (exit /b)
cscript "%~dp0FindSTR.vbs" "BLUERAY-" "%~dp0type.txt" "false" >nul
IF !ERRORLEVEL! EQU 0 (exit /b)
echo Dismounting Invalid Drive "!arg!:"
mountvol "!arg!:" /p
exit /b
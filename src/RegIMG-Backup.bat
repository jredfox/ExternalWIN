@Echo Off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
call :PP

set hivelist=%~dp0hivelist.txt
IF NOT EXIST "%hivelist%" (
echo Use Reg-GenHiveList.bat on an online windows installation first then run this script in WinPE Installation Media
pause
exit /b 1
)
set /p letprime="Enter Windows Drive:"
set /p regimg="Enter File to Save REGIMG:"
set letprime=%letprime:"=%
set letprime=%letprime:~0,1%
set regimg=%regimg:"=%

REM ### Create a VDISK for the REG Image ######
call :GETFREEDRIVE
set letreg=%letrnd%
set vdisk=%~dp0regvdisk.vhdx
diskpart /s "%~dp0dvhdx.txt" >nul
del /f /q /a "%vdisk%" >nul 2>&1
call "%~dp0createvhdx-expand.bat" "%vdisk%" "1" "NTFS" "REGIMG" "%letreg%"

REM #### split the registry and get the paths at index 3. Then Copy the Paths to a new vdisk #####
for /f "usebackq tokens=3*" %%a in ("%hivelist%") do (
    set device=%%a
REM #### Handle Spaced paths ####
    IF "%%b" NEQ "" (
    set device=!device! %%b
    )
    FOR /f "tokens=3* delims=\" %%c IN ("!device!") do (
      set p=%%c\%%d
      set PathPrime=!letprime!:\!p!
      IF EXIST "!PathPrime!" (
      xcopy /h /r /k /o /y "!PathPrime!" "!letreg!:\!p!*"
      ) ELSE (
      echo Path Not Found !PathPrime!
      )
    )
)

REM ### Convert the VDISK to a WIM Image ##########
set name=Registry Image Backup %date% %time%
dism /capture-image /imagefile:"%regimg%" /capturedir:"%letreg%:" /name:"%name%" /Description:"%name%" /compress:maximum

REM ## Post Install ##
diskpart /s "%~dp0dvhdx.txt" >nul
del /f /q /a "%vdisk%" >nul 2>&1
pause
exit /b

:GETFREEDRIVE
set letrnd=0
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set letrnd=%drives:~0,1%
exit /b

:GETBASENAME
for /F "delims=" %%i in ("%~1") do set basename=%%~ni
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
exit /b

:PP
REM ######## WinPE support change the power plan to maximize perforamnce #########
set winpe=F
REM Check if we are in WINPE. If Either where or powershell is missing and X:\ Exists we are in WinPE
IF NOT EXIST "X:\" (exit /b)
where powershell >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
winpe=T
FOR /f "delims=" %%a in ('POWERCFG -GETACTIVESCHEME') DO @SET powerplan="%%a"
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo changed powerplan of !powerplan! to high performance 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)
exit /b
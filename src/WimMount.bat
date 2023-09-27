@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set /p wim=Enter WIM Image to Mount:
set wim=%wim:"=%
call :BaseName "%wim%"
set mntindex=0
:NAME
set vdisk=C:\Temp\Mnt\%basename%-%mntindex%.vhdx
IF EXIST "%vdisk%" (
set /A mntindex = %mntindex% + 1
GOTO NAME
)
REM #### ERROR HANDLING ####
powershell -ExecutionPolicy Bypass -File "%~dp0mountcheck.ps1" -Image "%wim%"
IF %ERRORLEVEL% NEQ 0 (
echo ERROR IMAGE File is already Mounted "%wim%"
echo[
pause
exit /b 1
)
call :NextDrive
call %~dp0createvhdx-expand.bat "%vdisk%" "25" "NTFS" "WIM Mount" "%let%"
for /L %%i in (1, 1, 256) Do (
mkdir "%let%:\%%i"
dism /Mount-Image /ImageFile:"%wim%" /Index:%%i /MountDir:"%let%:\%%i"
IF !ERRORLEVEL! NEQ 0 (
rmdir /s /q "%let%:\%%i"
GOTO END
)
echo Mounted "%wim%" at index "%%i" to "%let%:\%%i"
)

REM ##### Exit the Script the code below is batch functions
GOTO END

rem ####Grab the next Drive Letter#####
:NextDrive
set let=0
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set let=%drives:~0,1%
exit /b

rem #### Get's the filename including the extension
:BaseName
set basename=%~n1
exit /b

:END
pause
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
)
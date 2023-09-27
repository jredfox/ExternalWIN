@Echo off
setlocal enableDelayedExpansion
set /p wim=Enter WIM Image to Mount:
set wim=%wim:"=%
set vdisk=%wim:.wim=.vhdx%
REM #### CLEANUP ########
powershell -ExecutionPolicy Bypass -File "%~dp0dismountwim.ps1" "%wim%"
diskpart /s "%~dp0dvhdx.txt"
del /F "%vdisk%" /s /q /a
REM #####################
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
GOTO :END

rem ####Grab the next Drive Letter#####
:NextDrive
set let=0
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set let=%drives:~0,1%
GOTO EOF

:END
pause
:EOF
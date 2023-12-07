@Echo off
setlocal ENABLEDELAYEDEXPANSION
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :PP
set sp=true
set /p wimFrom="Enter WIM Extracting From:"
set /p wimTarget="Enter WIM Extracting To(Target):"
set wimFrom=%wimFrom:"=%
set wimTarget=%wimTarget:"=%
dism /get-imageinfo /imagefile:"%wimFrom%"
call :GETWIMSIZE "!wimFrom!"
set /p index="Enter WIM Index Or * For All !WIMSIZE! Indexes:"
set /p comp="Enter WIM Compression Level [maximum (DEFAULT), fast, none]:"
set index=%index:"=%
set comp=%comp:"=%
REM DO Single Index Merge
IF "%index%" NEQ "*" (
dism /Export-Image /SourceImageFile:"%wimFrom%" /SourceIndex:%index% /DestinationImageFile:"%wimTarget%" /compress:%comp%
GOTO END
)
REM Do All Indexes Merge
FOR /L %%i IN (1, 1, !WIMSIZE!) Do (
dism /Export-Image /SourceImageFile:"%wimFrom%" /SourceIndex:%%i /DestinationImageFile:"%wimTarget%" /compress:%comp%
IF !ERRORLEVEL! NEQ 0 GOTO END
echo Merged "%wimFrom%" at index %%i of !WIMSIZE! to "%wimTarget%"
)

:END
IF %sp% EQU true (pause)
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
)
exit /b

:GETWIMSIZE
set indexedwim=%1
set indexedwim=!indexedwim:"=!
set /A WIMSIZE=1
:LOOPINDEX
dism /get-imageinfo /imagefile:"!indexedwim!" /index^:!WIMSIZE! >nul
IF !ERRORLEVEL! NEQ 0 (
set /A WIMSIZE=!WIMSIZE! - 1
exit /b
) ELSE (
set /A WIMSIZE=!WIMSIZE! + 1
GOTO LOOPINDEX
)
exit /b

:PP
REM ######## WinPE support change the power plan to maximize perforamnce #########
set winpe=F
REM Check if we are in WINPE. If Either where or powershell is missing and X Drive Exists we are in WinPE
IF NOT EXIST "X:\" (exit /b)
where powershell >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
set winpe=T
FOR /f "delims=" %%a in ('POWERCFG -GETACTIVESCHEME') DO @SET powerplan="%%a"
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo changed powerplan of !powerplan! to high performance 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)
exit /b
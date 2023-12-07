@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :PP
call :LOADCFG
IF /I "!ExtendedAttrib!" EQU "TRUE" (set extattrib= /EA)
echo WARNING^: Extracting WIM Images of Entire OS Could Result In Hard To Delete Files
set /p warn="Do you Wish To Continue [Y/N]?"
IF /I "!warn!" NEQ "Y" (exit /b)
set /p wim="Input WIM/ESD File:"
set wim=%wim:"=%
call :GETWIMSIZE "!wim!"
set /p dir="Input Directory To Extract TO:"
set dir=%dir:"=%
set dir=%dir:.wim=%
set dir=%dir:.esd=%
set /p index="Enter Index or ^* for all !WIMSIZE! Indexes:"
IF "%index:~0,1%" EQU "*" (GOTO EXTRACTALL)
REM #### Extracts a single index ####
mkdir "%dir%\%index%"
call :APPLYCFG
dism /apply-image /imagefile:"%wim%" /index:%index% /NoRpFix!extattrib! /applydir:"%dir%\%index%"!cmdcfg!
GOTO END

REM #### Extracts all indexes ##############
:EXTRACTALL
for /L %%i in (1, 1, !WIMSIZE!) Do (
mkdir "%dir%\%%i"
set index=%%i
call :APPLYCFG
dism /apply-image /imagefile:"%wim%" /index:%%i /NoRpFix!extattrib! /applydir:"%dir%\%%i"!cmdcfg!
IF !ERRORLEVEL! NEQ 0 (
rmdir /s /q "%dir%\%%i"
GOTO END
)
echo Extracted Index %%i of !WIMSIZE! Successfully from "%wim%"
)

:END
pause
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
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

:LOADCFG
IF "!winpe!" EQU "T" (exit /b)
FOR /F "tokens=6-7 delims= " %%A in ('call "%~dp0LoadConfig.bat"') DO (
set ApplyExclusions=%%A
set ExtendedAttrib=%%B
)
exit /b

:APPLYCFG
set applyini=%TMP%\EXTWINDISMApply.ini
IF /I "!ApplyExclusions:~0,1!" NEQ "T" (exit /b)
echo Generating Apply Exclusion List For Index^:!index!
call "%~dp0CreateApplyExclusions.bat" "!wim!" "!index!" "!winpe!" "ExtractExclusions.cfg"
set cmdcfg= ^/ConfigFile^:"!applyini!"
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
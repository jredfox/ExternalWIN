@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :LOADCFG
IF /I "!ExtendedAttrib!" EQU "TRUE" (set extattrib= /EA)
echo WARNING^: Extracting WIM Images of Entire OS Could Result In Hard To Delete Files
set /p warn="Do you Wish To Continue [Y/N]?"
IF /I "!warn!" NEQ "Y" (exit /b)
set /p wim=Input WIM/ESD File:
set wim=%wim:"=%
set /p dir=Input Directory To Extract TO:
set dir=%dir:.wim=%
set dir=%dir:.esd=%
set dir=%dir:"=%
set /p index="Enter Index or ^* for all Indexes:"
IF "%index:~0,1%" EQU "*" (GOTO EXTRACTALL)
REM #### Extracts a single index ####
mkdir "%dir%\%index%"
call :APPLYCFG
dism /apply-image /imagefile:"%wim%" /index:%index% /NoRpFix!extattrib! /applydir:"%dir%\%index%"!cmdcfg!
GOTO END

REM #### Extracts all indexes ##############
:EXTRACTALL
for /L %%i in (1, 1, 256) Do (
mkdir "%dir%\%%i"
set index=%%i
call :APPLYCFG
dism /apply-image /imagefile:"%wim%" /index:%%i /NoRpFix!extattrib! /applydir:"%dir%\%%i"!cmdcfg!
IF !ERRORLEVEL! NEQ 0 (
rmdir /s /q "%dir%\%%i"
GOTO END
)
echo Extracted Index %%i Successfully from "%wim%"
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
@ECHO OFF
setlocal enableDelayedExpansion
set wim=%1
set wim=!wim:"=!
set index=%~2
set winpe=%~3
set CFGNAME=%~4
IF /I "!winpe:~0,1!" EQU "T" (set winpe=TRUE) ELSE (set winpe=FALSE)
set targ=%TMP%\EXTWNTARG.txt
set cfgini=%TMP%\EXTWINDISMApply.ini
call :CREATECFG
del /F /Q /A "!targ!" >nul 2>&1
cscript /nologo "%~dp0GetWIMTarg.vbs" "!wim!" "!index!" "!winpe!" >"!targ!"
FOR /F "usebackq delims=" %%I IN ("!targ!") DO (set target=%%I)
call :FTP "!target!"
set targpath=!file!
echo TARGET FOUND^:!target! PATH^:!targpath!
del /F /Q /A "!cfgini!" >nul 2>&1
(
echo ^[ExclusionList^]
echo ^\EXTWNCAP^$^*
call :CUSTOMEXCLUSIONS
echo.
echo ^[CompressionExclusionList^]
echo ^*^.mp3
echo ^*^.zip
echo ^*^.cab
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\WINDOWS^\inf^\^*^.pnf" "!targpath!"
)>"!cfgini!"

:END
exit /b

:FTP
set file=%1
set file=!file:"=!
set PHOLDER=^#^@
set PSEP=^$
set file=!file:%PSEP%=^\!
set file=!file:%PHOLDER%=%PSEP%!
exit /b

:CREATECFG
IF "!CFGNAME!" EQU "" (set DISMAPPLYCFG=%~dp0ApplyExclusions.cfg) ELSE (set DISMAPPLYCFG=%~dp0!CFGNAME!)
IF NOT EXIST "!DISMAPPLYCFG!" (type NUL >"!DISMAPPLYCFG!")
exit /b

:CUSTOMEXCLUSIONS
FOR /F "usebackq delims=" %%i IN ("!DISMAPPLYCFG!") DO (
set dir=%%i
set dir=!dir:^/=^\!
IF "!dir:~-1!" EQU "\" (SET dir=!dir:~0,-1!)
IF "!dir:~0,2!" EQU "S:" (echo !dir:~2!) ELSE (cscript /nologo "%~dp0EchoRealtivePath.vbs" "!dir!" "!targpath!")
)
exit /b
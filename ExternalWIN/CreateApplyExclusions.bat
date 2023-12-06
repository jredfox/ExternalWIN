@ECHO OFF
setlocal enableDelayedExpansion
set wim=%1
set wim=!wim:"=!
set index=%~2
set winpe=%~3
set targ=%TMP%\EXTWNTARG.txt
set cfgini=%TMP%\EXTWINDISMApply.ini
call :CREATECFG
del /F "!targ!" /s /q /a >nul 2>&1
cscript /nologo "%~dp0GetWIMTarg.vbs" "!wim!" "!index!" "!winpe!" >"!targ!"
FOR /F "usebackq delims=" %%I IN ("!targ!") DO (set target=%%I)
call :FTP "!target!"
set targpath=!file!
echo TARGET FOUND^:!target! PATH^:!targpath!
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
set DISMAPPLYCFG=%~dp0ApplyExclusions.cfg
IF NOT EXIST "!DISMAPPLYCFG!" (type NUL >"!DISMAPPLYCFG!")
exit /b

:CUSTOMEXCLUSIONS
FOR /F "usebackq delims=" %%i IN ("!DISMAPPLYCFG!") DO (
set dir=%%i
IF "!dir:~0,2!" EQU "S:" (echo !dir:~2!) ELSE (cscript /nologo "%~dp0EchoRealtivePath.vbs" "!dir!" "!targpath!")
)
exit /b
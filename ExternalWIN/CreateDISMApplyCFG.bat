@Echo Off
setlocal enableDelayedExpansion
set EXTCFG=%~1
set cfgini=%TMP%\EXTWINDISMApply.ini
call :CREATEEXCLUSIONS
del /F "!cfgini!" /s /q /a >nul 2>&1
(
echo ^[ExclusionList^]
call :APPLYEXCLUSIONS
echo.
echo ^[CompressionExclusionList^]
echo ^*^.mp3
echo ^*^.zip
echo ^*^.cab
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\WINDOWS^\inf^\^*^.pnf" "!drive!"
) >"!cfgini!"

:APPLYEXCLUSIONS
set DISMCAPCFG=%~dp0DISMApplyExclusions.cfg
IF NOT EXIST "!DISMCAPCFG!" (echo. >!DISMCAPCFG!)
FOR /F "usebackq delims=" %%i IN ("!DISMCAPCFG!") DO (
echo %%i
)
exit /b
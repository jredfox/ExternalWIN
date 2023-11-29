@Echo Off
setlocal enableDelayedExpansion
set EXTCFG=%~1
set TargFile=%~2
set TargIndex=%~3
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
echo ^\WINDOWS^\inf^\^*^.pnf
) >"!cfgini!"

:APPLYEXCLUSIONS
set DISMCAPCFG=%~dp0DISMApplyExclusions.cfg
IF NOT EXIST "!DISMCAPCFG!" (echo. >!DISMCAPCFG!)
FOR /F "usebackq delims=" %%i IN ("!DISMCAPCFG!") DO (
echo %%i
)
exit /b
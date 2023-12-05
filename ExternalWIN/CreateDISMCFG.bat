@Echo Off
setlocal enableDelayedExpansion
set drive=%~1
set cfgini=%TMP%\EXTWINDISMCapture.ini
set wimimg=%~2
set wimimg=!wimimg:~2!
call :CREATEEXCLUSIONS
del /F "!cfgini!" /s /q /a >nul 2>&1
(
echo ^[ExclusionList^]
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\^$ntfs^.log" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\hiberfil^.sys" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\pagefile^.sys" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\swapfile^.sys" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\System Volume Information" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\RECYCLER" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Windows^\CSC" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\found^.^*" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Users^\defaultuser1^*" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Users^\defaultuser2^*" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Users^\defaultuser3^*" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Users^\defaultuser4^*" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Users^\defaultuser5^*" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Users^\defaultuser6^*" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Users^\defaultuser7^*" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Users^\defaultuser8^*" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Users^\defaultuser9^*" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Users^\defaultuser0^*" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\ExternalWIN" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "!wimimg!" "!drive!"
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\Users^\^*^\OneDrive" "!drive!"
call "%~dp0PrintOneDrive.bat" "!drive!"
call "%~dp0PrintOneDriveLinks.bat" "!drive!"
call :CUSTOMEXCLUSIONS
echo.
echo ^[CompressionExclusionList^]
echo ^*^.mp3
echo ^*^.zip
echo ^*^.cab
cscript /nologo "%~dp0EchoRealtivePath.vbs" "^\WINDOWS^\inf^\^*^.pnf" "!drive!"
) >"!cfgini!"
exit /b

:CUSTOMEXCLUSIONS
FOR /F "usebackq delims=" %%i IN ("!DISMCAPCFG!") DO (
set dir=%%i
cscript /nologo "%~dp0EchoRealtivePath.vbs" "!dir!" "!drive!"
)
exit /b

:CREATEEXCLUSIONS
set DISMCAPCFG=%~dp0DISMExclusions.cfg
IF NOT EXIST "!DISMCAPCFG!" (
(
echo.
) >"!DISMCAPCFG!"
)
exit /b
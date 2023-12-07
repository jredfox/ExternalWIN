@Echo Off
setlocal enableDelayedExpansion
set drive=%~1
set cfgini=%TMP%\EXTWINDISMCapture.ini
set tmpdrive=%TMP%\OneDriveFolders.txt
set wimimg=%~2
set wimimg=!wimimg:~2!
call :CREATEEXCLUSIONS
del /F /Q /A "!cfgini!" >nul 2>&1
del /F /Q /A "!tmpdrive!" >nul 2>&1
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
call "%~dp0PrintOneDrive.bat" "!drive!" >"!tmpdrive!"
cscript /nologo "%~dp0PrintOneLinks.vbs" "!tmpdrive!" "" "!drive!"
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

:CREATEEXCLUSIONS
set DISMCAPCFG=%~dp0CaptureExclusions.cfg
IF NOT EXIST "!DISMCAPCFG!" (type NUL >"!DISMCAPCFG!")
exit /b

:CUSTOMEXCLUSIONS
FOR /F "usebackq delims=" %%i IN ("!DISMCAPCFG!") DO (
set dir=%%i
set dir=!dir:^/=^\!
IF "!dir:~-1!" EQU "\" (SET dir=!dir:~0,-1!)
IF "!dir:~0,2!" EQU "S:" (echo !dir:~2!) ELSE (cscript /nologo "%~dp0EchoRealtivePath.vbs" "!dir!" "!drive!")
)
exit /b
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
echo ^\^$ntfs^.log
echo ^\hiberfil^.sys
echo ^\pagefile^.sys
echo ^\swapfile^.sys
echo ^\System Volume Information
echo ^\RECYCLER
echo ^\Windows^\CSC
echo !wimimg!
echo ^\found^.^*
echo ^\Users^\defaultuser1^*
echo ^\Users^\defaultuser2^*
echo ^\Users^\defaultuser3^*
echo ^\Users^\defaultuser4^*
echo ^\Users^\defaultuser5^*
echo ^\Users^\defaultuser6^*
echo ^\Users^\defaultuser7^*
echo ^\Users^\defaultuser8^*
echo ^\Users^\defaultuser9^*
echo ^\Users^\defaultuser0^*
echo ^\Users^\^*^\OneDrive
call "%~dp0PrintOneDrive.bat" "!drive!"
call "%~dp0PrintOneDriveLinks.bat" "!drive!"
call :CUSTOMEXCLUSIONS
echo.
echo ^[CompressionExclusionList^]
echo ^*^.mp3
echo ^*^.zip
echo ^*^.cab
echo ^\WINDOWS^\inf^\^*^.pnf
) >"!cfgini!"
exit /b

:CUSTOMEXCLUSIONS
FOR /F "usebackq delims=" %%i IN ("!DISMCAPCFG!") DO (
set dir=%%i
IF "!dir:~1,1!" EQU ":" (set dir=!dir:~2!)
echo !dir!
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
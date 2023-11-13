@Echo Off
set cfgini=%TMP%\EXTWINDISMCapture.ini
set wimimg=%~2
set wimimg=!wimimg:~2!
del /F "!cfgini!" /s /q /a >nul 2>&1
setlocal ENABLEDELAYEDEXPANSION
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
echo ^\Users^\^*^\OneDrive
call "%~dp0PrintOneDrive.bat" "%~1"
echo.
echo ^[CompressionExclusionList^]
echo ^*^.mp3
echo ^*^.zip
echo ^*^.cab
echo ^\WINDOWS^\inf^\^*^.pnf
) >!cfgini!

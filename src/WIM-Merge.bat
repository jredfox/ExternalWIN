@Echo off
setlocal ENABLEDELAYEDEXPANSION
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set sp=true
set /p wimFrom="Enter WIM Extracting From:"
set /p wimTarget="Enter WIM Extracting To(Target):"
set wimFrom=%wimFrom:"=%
set wimTarget=%wimTarget:"=%
dism /get-imageinfo /imagefile:"%wimFrom%"
set /p index="Enter WIM Index Or * For All Indexes:"
set /p comp="Enter WIM Compression Level [maximum (DEFAULT), fast, none]:"
set index=%index:"=%
set comp=%comp:"=%
IF "%index%" NEQ "*" (
dism /Export-Image /SourceImageFile:"%wimFrom%" /SourceIndex:%index% /DestinationImageFile:"%wimTarget%" /compress:%comp%
) ELSE (
for /L %%i in (1, 1, 256) Do (
dism /Export-Image /SourceImageFile:"%wimFrom%" /SourceIndex:%%i /DestinationImageFile:"%wimTarget%" /compress:%comp%
IF !ERRORLEVEL! NEQ 0 GOTO END
echo Merged "%wimFrom%" at index "%%i" to "%wimTarget%"
)
)

:END
IF %sp% EQU true (pause)
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
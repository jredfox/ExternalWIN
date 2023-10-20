@Echo off
setlocal ENABLEDELAYEDEXPANSION
set rmatt=%~dp0removeatt.cfg
IF "%~1" NEQ "" (
set drive=%~1
set drive=!drive:"=!
set drive=!drive:~0,1!
)
FOR /F "usebackq delims=" %%i IN ("!rmatt!") DO (
set dir=%%i
set dir=!dir:"=!
REM re-assign the drive letter to the correct one
set dir=!drive!!dir:~1!
IF EXIST "!dir!" (call :REMOVEATT "!dir!") ELSE (echo skipping removing attr on path^:"!dir!")
)
exit /b

:REMOVEATT
REM ##### Copies Dir A to Dir B Replacing Existing and Not Keeping Attirbutes By Default like is hidden or security things#####
set host=%~1
echo removing attr on path^:!host!
xcopy "!host!" "!host!2" /S /E /I /G /H /R /B /Y /Q
del /F "!host!" /s /q /a >nul 2>&1
rmdir /s /q "!host!" >nul 2>&1
xcopy "!host!2" "!host!" /S /E /I /G /H /R /B /Y /Q
del /F "!host!2" /s /q /a >nul 2>&1
rmdir /s /q "!host!2" >nul 2>&1
exit /b
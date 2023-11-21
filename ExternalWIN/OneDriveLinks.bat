@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set drive=%~1
set drive=!drive:~0,1!
set dirs=%TMP%\OneDriveDirs.txt
set EXTIndex=%TMP%\OneDriveLinks.txt
call "%~dp0PrintOneDrive.bat" "%~1" >!dirs!
echo Indexing The !drive! Drive
dir /S /B /A:LO !drive!^:\ >!EXTIndex!
FOR /F "usebackq delims=" %%I IN ("!EXTIndex!") DO (
set path=%%I
set path=!path:~2!
call :INONEDRIVE "!path!"
IF "!ISONE!" EQU "F" (echo !path!)
)
exit /b

:INONEDRIVE
set ISONE=F
FOR /F "usebackq delims=" %%D IN ("!dirs!") DO (
call :ISFILECHILD "%%D" "!path!"
IF "!ISCHILD!" EQU "T" (set ISONE=T)
)
exit /b

:ISFILECHILD
set Parent=%~1
set Child=%~2
set ISCHILD=F
cscript "%~dp0Len.vbs%" "!Parent!" >nul
call :STRLEN "!Parent!"
IF /I "!Child:~0,%strlen%!" EQU "%Parent%" (set ISCHILD=T)
exit /b

:STRLEN
FOR /F %%a IN ('cscript "%~dp0Len.vbs" "%~1"') DO (set strlen=%%a)
exit /b
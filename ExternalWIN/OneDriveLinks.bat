@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set drive=%~1
set drive=!drive:~0,1!
set dirs=%TMP%\OneDriveDirs.txt
call "%~dp0PrintOneDrive.bat" "%~1" >!dirs!
echo Indexing The !drive! Drive
FOR /F "delims=" %%I in ('dir /S /B /A^:LO !drive!^:\') DO (
set path=%%I
set path=!path:~2!
echo !path!
)
exit /b

:ISFILECHILD
set Parent=%~1
set Child=%~2
set ISCHILD=F
cscript "%~dp0Len.vbs%" "!Parent!" >nul
call :STRLEN "!Parent!"
echo "!Child:~0,%strlen%!"
IF /I "!Child:~0,%strlen%!" EQU "%Parent%" (set ISCHILD=T)
exit /b

:STRLEN
FOR /F %%a IN ('cscript "%~dp0Len.vbs" "%~1"') DO (set strlen=%%a)
exit /b
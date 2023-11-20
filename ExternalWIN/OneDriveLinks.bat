@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set drive=%~1
set drive=!drive:~0,1!
echo Indexing The !drive! Drive
FOR /F "delims=" %%I in ('dir /S /B /A^:LO !drive!^:\') DO (
set path=%%I
set path=!path:~2!
echo !path!
)
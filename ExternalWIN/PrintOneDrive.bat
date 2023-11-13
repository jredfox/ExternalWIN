@Echo Off
setlocal ENABLEDELAYEDEXPANSION
set drive=%~1
set EXTWINUSER=!drive!:\Users

REM #### Load the USERDATA into REGEDIT #####
FOR /D %%D in ("!EXTWINUSER!\*") DO (
set dirpath=%%D\NTUSER.DAT
set dirname=%%~nxD
IF /I "!dirname!" NEQ ".DEFAULT" IF /I "!dirname!" NEQ "Public" (
reg load "HKU\!dirname!" "!dirpath!" >nul 2>&1
)
)

FOR /F "delims=" %%I IN ('reg query HKEY_USERS') DO (
FOR /F "tokens=3*" %%B IN ('reg query "%%I\SOFTWARE\Microsoft\OneDrive" /v UserFolder 2^>nul') DO (
set OnePath=%%B
IF "!OnePath:~1,1!" EQU ":" (
echo !OnePath:~2!
)
)
)

REM ##### UNLOAD the USERDATA from REGEDIT #####
FOR /D %%D in ("!EXTWINUSER!\*") DO (
set dirname=%%~nxD
IF /I "!dirname!" NEQ ".DEFAULT" IF /I "!dirname!" NEQ "Public" (
reg unload "HKU\!dirname!" >nul 2>&1
)
)

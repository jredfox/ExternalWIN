@ECHO OFF
setlocal enableDelayedExpansion
set reecurse=T
IF "%~1" NEQ "" (
set scandir=%1
set oldpath=%2
set newpath=%3
set reecurse=%~4
) ELSE (
set /p scandir="Enter Drive to Scan:"
set oldpath="Enter Old Drive Letter(W Normally):"
set newpath="Enter New Drive Letter(C Normally):"
)
set scandir=!scandir:"=!
set oldpath=!oldpath:"=!
set newpath=!newpath:"=!
IF "!scandir:~3,1!" EQU "" (set scandir=!scandir:~0,1!^:\)
IF "!oldpath:~3,1!" EQU "" (set oldpath=!oldpath:~0,1!^:\)
IF "!newpath:~3,1!" EQU "" (set newpath=!newpath:~0,1!^:\)
IF /I "!reecurse:~0,1!" NEQ "F" (set reflag=/S )
set JLinks=%TMP%\JLinks.txt
del /F /Q /A "!JLinks!" >nul 2>&1
echo Scanning for Juntions and Symbolic Links in "!scandir!"
dir !reflag!/A^:L-O "!scandir!" >"!JLinks!"
echo Patching Juntions and Symbolic Links
cscript /nologo "%~dp0PatchJLinks.vbs" "!JLinks!" "!oldpath!" "!newpath!"
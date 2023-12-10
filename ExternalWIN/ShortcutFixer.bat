@ECHO OFF
setlocal enableDelayedExpansion
set reecurse=T
IF "%~1" NEQ "" (
set scandir=%1
set oldpath=%2
set newpath=%3
set reecurse=%~4
set lnkSearch=%~5
) ELSE (
set /p scandir="Enter Drive to Scan:"
set /p oldpath="Enter Old Drive Letter(W Normally):"
set /p newpath="Enter New Drive Letter(C Normally):"
)
REM ## Set the Default search to include All Types JUNCTIONS SYMDIRS AND SYMFILES ##
IF "!lnkSearch!" EQU "" (set lnkSearch=JDF)
REM ## Remove Quotes Safley from the path without screwing things up ##
set scandir=!scandir:"=!
set oldpath=!oldpath:"=!
set newpath=!newpath:"=!
REM ## Fix Lazy Drive Letters ##
IF "!scandir:~3,1!" EQU "" (set scandir=!scandir:~0,1!^:\)
IF "!oldpath:~3,1!" EQU "" (set oldpath=!oldpath:~0,1!^:\)
IF "!newpath:~3,1!" EQU "" (set newpath=!newpath:~0,1!^:\)
REM ## Ensure the Scan Dir, Old Path, New Path all end in backslash ##
IF "!scandir:~-1!" NEQ "\" (SET scandir=!scandir!^\)
IF "!oldpath:~-1!" NEQ "\" (SET oldpath=!oldpath!^\)
IF "!newpath:~-1!" NEQ "\" (SET newpath=!newpath!^\)
IF /I "!reecurse:~0,1!" NEQ "F" (set reflag=/S )
set JLinks=%TMP%\JLinks.txt
del /F /Q /A "!JLinks!" >nul 2>&1
echo Scanning for Juntions and Symbolic Links in "!scandir!"
dir !reflag!/A^:L-O "!scandir!" >"!JLinks!"
cscript /nologo "%~dp0PatchJLinks.vbs" "!JLinks!" "!oldpath!" "!newpath!" "!lnkSearch!"

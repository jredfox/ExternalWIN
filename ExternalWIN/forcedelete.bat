@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :GETGRANT
set dir=%~1
REM Stop Accidental Deletion of System32 or current directory of Command Prompt
IF "!dir:~1,1!" NEQ ":" (exit /b)
REM ## Remove Extra Backslash In case of User Error ##
IF "!dir:~-1!" EQU "\" (set dir=!dir:~0,-1!)
echo WARNING^: Forcibly Deleting Files Is Dangerous If You Do Not Know What you are doing
set /p warn="Do you Wish To Continue [Y/N]?"
IF /I "!warn!" NEQ "Y" (exit /b)
set glp=^\^\^?^\
call :ISDIR "!dir!"
REM ## Handle indivdual file deletion requests ##
IF "!ISDIR!" EQU "F" (
takeown /A /SKIPSL /F "!dir!" >nul 2>&1
"!grantexe!" "!dir!"
del /F "!glp!!dir!" /S /Q /A >nul 2>&1
exit /b
)
REM ## Handle Entire Directories Recursively ##
echo Takeown Dir^: "!dir!"
takeown /A /SKIPSL /R /F "!dir!" /D Y >nul 2>&1
"!grantexe!" "!dir!"
echo DEL Dir^: "!dir!"
del /F "!glp!!dir!^\" /S /Q /A >nul 2>&1
echo RMDIR Dir^: "!dir!"
rmdir /S /Q "!glp!!dir!^\" >nul 2>&1
exit /b

:ISDIR
set ATTR=%~a1
call :CONTAINS "!ATTR!" "D"
IF "!STRCONTAINS!" EQU "T" (set ISDIR=T) ELSE (set ISDIR=F)
IF "!ISDIR!" EQU "T" (exit /b)
call :CONTAINS "!ATTR!" "d"
IF "!STRCONTAINS!" EQU "T" (set ISDIR=T) ELSE (set ISDIR=F)
exit /b

:CONTAINS
REM contains function that doesn't support quotes in strings
set str=%1
set strs=%2
set str=!str:"=!
set strs=!strs:"=!
set strnew=!str:%strs%=!
IF "!str!" EQU "!strnew!" (set STRCONTAINS=F) ELSE (set STRCONTAINS=T)
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
)
exit /b

:GETGRANT
IF /I "!PROCESSOR_ARCHITECTURE!" EQU "ARM64" (
set grantexe=%~dp0Grant-ARM64.exe
exit /b
)
set grantexe=%~dp0Grant-x64.exe
call "!grantexe!" "/?" >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (set grantexe=%~dp0Grant-x86.exe)
exit /b
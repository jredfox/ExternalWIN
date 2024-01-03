@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
call :GETGRANT
set dir=%~1
REM Stop Accidental Deletion of System32 or current directory of Command Prompt
IF "!dir:~1,1!" NEQ ":" (exit /b)
REM ## Remove Extra Backslash In case of User Error ##
IF "!dir!" NEQ "\" (
IF "!dir:~-1!" EQU "\" (set dir=!dir:~0,-1!)
)
echo WARNING^: Forcibly Deleting Files Is Dangerous If You Do Not Know What you are doing
set /p warn="Do you Wish To Continue [Y/N]?"
IF /I "!warn!" NEQ "Y" (exit /b)
set glp=^\^\^?^\
echo Takeown Dir^: "!dir!"
takeown /A /SKIPSL /R /F "%dir%" /D Y >nul 2>&1
"!grantexe!" "!dir!"
echo DEL Dir^: "!dir!"
del /F "%dir%" /s /q /a >nul 2>&1
del /F "!glp!!dir!" /s /q /a >nul 2>&1
echo RMDIR Dir^: "!dir!"
rmdir /s /q "%dir%" >nul 2>&1
rmdir /s /q "!glp!!dir!" >nul 2>&1
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
@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
call :GETDIRSAFE
IF !ERRORLEVEL! NEQ 0 (exit /b !ERRORLEVEL!)
set dir=%~1
REM Stop Accidental Deletion of System32 or current directory of Command Prompt
IF "!dir:~1,1!" NEQ ":" (exit /b)
echo WARNING^: Forcibly Deleting Files Is Dangerous If You Do Not Know What you are doing
set /p warn="Do you Wish To Continue [Y/N]?"
IF /I "!warn!" NEQ "Y" (exit /b)
REM Delete JUNCTION and SYMLIND Dirs to prevent accidental deletion of unintended folders
FOR /F "delims=" %%I IN ('call "!direxe!" "!dir!" "TRUE" "B" "DL" 2^>nul') DO (
echo RD^:%%I
RD "%%I"
)
takeown /A /SKIPSL /R /F "%dir%" /D Y
icacls "%dir%" /L /T /C /grant administrators:F System:F everyone:F
REM Delete JUNCTION and SYMLIND Dirs to prevent accidental deletion of unintended folders
FOR /F "delims=" %%I IN ('call "!direxe!" "!dir!" "TRUE" "B" "DL" 2^>nul') DO (
echo RD^:%%I
RD "%%I"
)
del /F "%dir%" /s /q /a
rmdir /s /q "%dir%"
exit /b

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit /b 1
)
exit /b

:GETDIRSAFE
set dirsafedir=%~dp0DirSafe
set direxe=!dirsafedir!\DirSafe-x64.exe
call "!direxe!" "/?" >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (set direxe=!dirsafedir!\DirSafe-x86.exe)
exit /b
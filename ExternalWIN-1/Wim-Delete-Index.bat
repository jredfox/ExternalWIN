@Echo off
setlocal ENABLEDELAYEDEXPANSION
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set /p wim="Enter WIM/ESD:"
set wim=%wim:"=%
dism /get-imageinfo /imagefile:"%wim%"
set /p index="Enter WIM/ESD Index:"
set index=%index:"=%
dism /Delete-Image /ImageFile:"%wim%" /Index:%index%
pause
exit /b

REM #######ADMIN CHECK###########
:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
exit /b
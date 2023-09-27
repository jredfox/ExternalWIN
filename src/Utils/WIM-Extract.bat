@Echo off
setlocal enableDelayedExpansion
call :checkAdmin "You Need to run ExternalWIN Scripts as Administrator in order to use them"
set /p wim=Input WIM/ESD File:
set wim=%wim:"=%
set /p dir=Input Directory To Extract TO:
set dir=%dir:.wim=%
set dir=%dir:.esd=%
set /p all=Extract All Indexes [Y\N]?
for /L %%i in (1, 1, 256) Do (
mkdir "%dir%\%%i"
dism /apply-image /imagefile:"%wim%" /index:%%i /applydir:"%dir%\%%i"
IF !ERRORLEVEL! NEQ 0 (
rmdir /s /q "%dir%\%%i"
GOTO END
)
echo Extracted Index %%i Successfully from "%wim%"
IF /I %all:~0,1% NEQ Y GOTO END
)
:END
pause
exit /b 0

:checkAdmin
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
echo %~1
pause
exit 1
)
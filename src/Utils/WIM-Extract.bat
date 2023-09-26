@Echo off
setlocal enableDelayedExpansion
set /p wim=Input WIM/ESD File:
set wim=%wim:"=%
set /p dir=Input Directory To Extract TO:
set dir=%dir:.wim=%
set dir=%dir:.esd=%
for /L %%i in (1, 1, 256) Do (
mkdir "%dir%\%%i"
dism /apply-image /imagefile:"%wim%" /index:%%i /applydir:"%dir%\%%i"
IF !ERRORLEVEL! NEQ 0 (
rmdir /s /q "%dir%\%%i"
GOTO END
)
echo Extracted Index %%i Successfully from "%wim%"
)
:END
pause
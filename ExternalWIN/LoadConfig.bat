@Echo off
setlocal ENABLEDELAYEDEXPANSION
set cfg=%~dp0ExternalWIN.cfg
IF NOT EXIST "!cfg!" (call :CREATECFG)
FOR /F "usebackq delims=" %%i IN ("!cfg!") DO (
set line=%%i
IF /I "!line:~0,13!" EQU "SleepDisable:" (
set SleepDisable=!line:~13!
)
IF /I "!line:~0,12!" EQU "SleepEnable:" (
set SleepEnable=!line:~12!
)
IF /I "!line:~0,16!" EQU "RestartExplorer:" (
call :GETBOOL "!line:~16!"
set RestartExplorer=!getbool!
)
IF /I "!line:~0,20!" EQU "OptimizedWIMCapture:" (
call :GETBOOL "!line:~20!"
set OptimizedWIMCapture=!getbool!
)
IF /I "!line:~0,17!" EQU "OneDriveLinkScan:" (
call :GETBOOL "!line:~17!"
set OneDriveLinkScan=!getbool!
)
IF /I "!line:~0,16!" EQU "ApplyExclusions:" (
call :GETBOOL "!line:~16!"
set ApplyExclusions=!getbool!
)
)
REM VERIFY
(
IF "!SleepDisable!" EQU "" (
set SleepDisable=1750
echo SleepDisable^:1750
)
IF "!SleepEnable!" EQU "" (
set SleepEnable=2000
echo SleepEnable^:2000
)
IF "!RestartExplorer!" EQU "" (
set RestartExplorer=false
echo RestartExplorer^:false
)
IF "!OptimizedWIMCapture!" EQU "" (
set OptimizedWIMCapture=true
echo OptimizedWIMCapture^:true
)
IF "!OneDriveLinkScan!" EQU "" (
set OneDriveLinkScan=true
echo OneDriveLinkScan^:true
)
IF "!ApplyExclusions!" EQU "" (
set ApplyExclusions=true
echo ApplyExclusions^:true
)
)>>"!cfg!"
REM PRINT OUTPUT
echo !SleepDisable! !SleepEnable! !RestartExplorer! !OptimizedWIMCapture! !OneDriveLinkScan! !ApplyExclusions!
exit /b

:GETBOOL
set varb=%~1
IF /I "!varb:~0,1!" EQU "T" (set getbool=true) ELSE (set getbool=false)
exit /b

:CREATECFG
(
  echo SleepDisable^:1750
  echo SleepEnable^:2000
  echo RestartExplorer^:false
  echo OptimizedWIMCapture^:true
  echo OneDriveLinkScan^:true
  echo ApplyExclusions^:true
) >"!cfg!"
exit /b
@Echo off
setlocal ENABLEDELAYEDEXPANSION
set cfg=%~dp0ExternalWIN.cfg
IF NOT EXIST "!cfg!" (call :CREATECFG)
FOR /F "usebackq delims=" %%i IN ("!cfg!") DO (
set line=%%i
IF /I "!line:~0,13!" EQU "SleepDisable:" (set SleepDisable=!line:~13!)
IF /I "!line:~0,12!" EQU "SleepEnable:" (set SleepEnable=!line:~12!)
IF /I "!line:~0,16!" EQU "RestartExplorer:" (
set RestartExplorer=!line:~16!
call :GETBOOL "!RestartExplorer!"
set RestartExplorer=!getbool!
)
)
echo !SleepDisable! !SleepEnable! !RestartExplorer!
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
) >"!cfg!"
exit /b
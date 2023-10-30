@ECHO OFF
setlocal enableDelayedExpansion

REM Get current date and time
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
    set "month=%%a"
    set "day=%%b"
    set "year=%%c"
)
set ttime=%time: =%
for /f "tokens=1-3 delims=:,." %%a in ("!ttime!") do (
    set "hour=%%a"
    set "minute=%%b"
    set "second=%%c"
)

REM Create directory based on current date and time
set "dirname=%HOMEDRIVE%\ExternalWIN\Backups\REG\%year%-%month%-%day%-%hour%-%minute%-%second%"
mkdir "%dirname%"
echo %dirname%

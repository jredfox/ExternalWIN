@echo off
rem #####CREDIT GOES TO: https://ss64.org/viewtopic.php?t=26######
setlocal enableDelayedExpansion
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"

echo all unused letters = %drives%
echo next unused letter = %drives:~0,1%
echo last unused letter = %drives:~-1%
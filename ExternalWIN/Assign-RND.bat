@Echo Off
setlocal enableDelayedExpansion
set let=0
set "drives=DEFGHIJKLMNOPQRSTUVWXYZABC"
for /f "delims=:" %%A in ('wmic logicaldisk get caption') do set "drives=!drives:%%A=!"
set let=%drives:~0,1%
echo Assign Drive Letter^: %let% for Partition %par% of Disk %disk%
IF /I "%~1" EQU "TRUE" (diskpart /s "%~dp0AssignVol.txt") ELSE (diskpart /s "%~dp0Assign.txt")
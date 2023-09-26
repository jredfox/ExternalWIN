@Echo off
set vdisk=%~1
set vhdsize=%~2
set fs=%~3
set label=%~4
set let=%~5
diskpart /s "%~dp0newvhdx-expand.txt"
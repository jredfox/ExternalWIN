$files = Get-ChildItem "C:\Temp\Mnt\"
foreach ($f in $files)
{
   $env:vdisk = $f.FullName
   Write-Host ("DisMounting VDISK: " + $env:vdisk)
   $cmd = (Get-Item -Path $PSScriptRoot).FullName + "\dvhdx.txt"
   diskpart /s "$cmd"
   cmd /c del /F $env:vdisk /s /q /a
}
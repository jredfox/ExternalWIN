param(
[Parameter(Mandatory=$true)]
[string]$Image,
[string]$Discard
)
Get-WindowsImage -Mounted | ForEach {
Measure-Command {
  if($_.ImagePath -eq $Image) 
  {
     if($Discard -eq "false") {
       Dismount-WindowsImage -Commit -Path $_.Path
     }
     else {
       Dismount-WindowsImage -Discard -Path $_.Path
     }
     $vdiskpath = $_.Path
  }
}
}
if ($vdiskpath -eq $null)
{
    Write-Host "Error WIM Mount Not Found For Image: $Image"
    exit 1
}
#Dismount the VHDX and Delete it
$drive = Out-String -InputObject $vdiskpath
$drive = $drive.Substring(0,2)
$env:vdisk = (Get-DiskImage -DevicePath "\\.\$drive").ImagePath
$cmd = (Get-Item -Path $PSScriptRoot).FullName + "\dvhdx.txt"
diskpart /s "$cmd"
cmd /c del /F $env:vdisk /s /q /a
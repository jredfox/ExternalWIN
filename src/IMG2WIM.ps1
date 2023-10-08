param(
[Parameter(Mandatory=$true)]
[string]$Image
)
$Directory = (Get-Item -Path $Image).Directory
$extn = [IO.Path]::GetExtension($Image)
if($extn -eq ".WIM")
{
  Write-Host "Error: Cannot Convert WIM $Image TO WIM As it's Already a WIM"
  exit 1
}
if($extn -eq ".ESD")
{
  cmd.exe /c "$PSScriptRoot\ESD2WIM.bat" "$Image"
  exit
}
#start cleanup
$wimfile = "$Directory\" + (Get-Item -Path $Image).BaseName + ".wim"
if (test-path $wimfile) {
Remove-Item $wimfile
}
DisMount-DiskImage -ImagePath $Image | Out-Null
#end cleanup
#support ISO and other possible virtual disk images
if ($extn -ne ".VHD" -and $extn -ne ".VHDX")
{
   $name = (Get-Item -Path $Image).BaseName
   $MountedVhd = Mount-DiskImage -ImagePath $Image -PassThru
   $drive = (Get-DiskImage -ImagePath $Image | Get-Volume).DriveLetter + ":"
   dism /Capture-Image /ImageFile:"$wimfile" /CaptureDir:"$drive" /Name:"$name" /Description:"$name" /compress:maximum
   DisMount-DiskImage -ImagePath $Image | Out-Null
   exit
}
$MountPath = "C:\Temp\VHD\" # This folder must pre-exist
New-Item -Path $MountPath -ItemType Directory -Force | Out-Null #Creates a Directory
$MountedVhd = Mount-DiskImage -ImagePath $Image -NoDriveLetter -PassThru | Get-Disk
$Partitions = $MountedVhd | Get-Partition
$operation = "/Capture-Image"
if (($Partitions | Get-Volume) -ne $Null) {
    $DriveNumberPath = $MountPath + "D" + $MountedVhd.Number
    New-Item $DriveNumberPath -ItemType Directory -Force | Out-Null
    foreach ($Partition in ($Partitions | where {($_ | Get-Volume) -ne $Null})) {
        $PartitionMountPath = $DriveNumberPath + "\P" + $Partition.PartitionNumber
        New-Item $PartitionMountPath -ItemType Directory -Force | Out-Null
        $Partition | Add-PartitionAccessPath -AccessPath $PartitionMountPath
        $pname = ($Partition | Get-Volume).FileSystemLabel
        $size = [math]::round(($Partition | Get-Volume).Size / 1MB, 2)
        $fs = "Format: " + ($Partition | Get-Volume).FileSystem + " Size: " + $size + " MB"
        dism $operation /ImageFile:"$wimfile" /CaptureDir:"$PartitionMountPath" /Name:"$pname" /Description:"$fs" /compress:maximum
        $Partition | Remove-PartitionAccessPath -AccessPath $PartitionMountPath
        $operation = "/Append-Image" #combine future volumes into the same WIM file
    }
}
DisMount-DiskImage -ImagePath $Image | Out-Null
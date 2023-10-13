param(
[Parameter(Mandatory=$true)]
[string]$Image
)
$Directory = $Image | split-path
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
$wimfile = "$Directory\" + ([io.fileinfo]"$Image").BaseName + ".wim"
DisMount-DiskImage -ImagePath $Image | Out-Null
if (test-path $wimfile) {
Remove-Item $wimfile
}
#end cleanup
#support ISO and other possible virtual disk images
if ($extn -ne ".VHD" -and $extn -ne ".VHDX")
{
   $name = ([io.fileinfo]"$Image").BaseName
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
$comp = "/compress:maximum"
if (($Partitions | Get-Volume) -ne $Null) {
    $DriveNumberPath = $MountPath + "D" + $MountedVhd.Number
    New-Item $DriveNumberPath -ItemType Directory -Force | Out-Null
    foreach ($Partition in ($Partitions | where {($_ | Get-Volume) -ne $Null})) {
        $PartitionMountPath = $DriveNumberPath + "\P" + $Partition.PartitionNumber
        New-Item $PartitionMountPath -ItemType Directory -Force | Out-Null
        #We have to remove the partition path mount before we can mount it in case a previous conversion was stopped
        try {
            $Partition | Remove-PartitionAccessPath -AccessPath $PartitionMountPath -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            
        }
        $Partition | Add-PartitionAccessPath -AccessPath $PartitionMountPath
        $pname = ($Partition | Get-Volume).FileSystemLabel
        if ([string]::IsNullOrEmpty($pname)) 
        {
           $pname = "Null Label"
        }
        $size = [math]::round(($Partition | Get-Volume).Size / 1MB, 2)
        $fs = "Format: " + ($Partition | Get-Volume).FileSystem + " Size: " + $size + " MB"
        dism $operation /ImageFile:"$wimfile" /CaptureDir:"$PartitionMountPath" /Name:"$pname" /Description:"$fs" $comp
        $Partition | Remove-PartitionAccessPath -AccessPath $PartitionMountPath
        $operation = "/Append-Image" #combine future volumes into the same WIM file
        $comp = ""
    }
}
DisMount-DiskImage -ImagePath $Image | Out-Null
Remove-Item $DriveNumberPath -Recurse
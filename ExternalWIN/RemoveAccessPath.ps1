# Define the access path you want to remove
param(
[Parameter(Mandatory=$true)]
[string]$Path
)

# Get all disks
$disks = Get-Disk

# Iterate through each disk
foreach ($disk in $disks) {
    # Get volumes on the current disk
    $volumes = Get-Partition -DiskNumber $disk.Number

    # Iterate through each volume on the disk
    foreach ($volume in $volumes) {
        if ($volume.AccessPaths -like "*$Path*") {
            Remove-PartitionAccessPath -DiskNumber $disk.Number -PartitionNumber $volume.PartitionNumber -AccessPath $Path -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

param(
[Parameter(Mandatory=$true)]
[string]$Image,
[string]$Discard
)
Get-WindowsImage -Mounted | ForEach {
Measure-Command {
  if($_.ImagePath -eq $DisMount) 
  {
     if($Discard -eq "false") {
       Dismount-WindowsImage -Commit -Path $_.Path
     }
     else {
       Dismount-WindowsImage -Discard -Path $_.Path
     }
  }
}
}
param(
[Parameter(Mandatory=$true)]
[string]$Image
)
Get-WindowsImage -Mounted | ForEach {
Measure-Command {
  if($_.ImagePath -eq $Image) 
  {
      exit 1
  }
}
}
exit 0
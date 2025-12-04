# iis-check.ps1  (requires WebAdministration module)
Import-Module WebAdministration -ErrorAction Stop
$OutDir="C:\Temp\vm-health"; New-Item -Path $OutDir -ItemType Directory -Force | Out-Null

# AppPool status + worker processes
Get-ChildItem IIS:\AppPools | Select-Object Name, State, PipelineMode, AutoStart | Export-Csv (Join-Path $OutDir "app-pools.csv") -NoTypeInformation

# Worker process info (w3wp)
Get-WmiObject Win32_Process -Filter "Name='w3wp.exe'" | Select-Object ProcessId,CommandLine,WorkingSetSize | Export-Csv (Join-Path $OutDir "w3wp-procs.csv") -NoTypeInformation

# Sites + bindings + physical path
Get-ChildItem IIS:\Sites | Select-Object Name, State, Bindings, PhysicalPath | Export-Csv (Join-Path $OutDir "iis-sites.csv") -NoTypeInformation

Write-Output "IIS checks saved to $OutDir"

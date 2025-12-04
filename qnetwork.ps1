# quick-net-test-ps.ps1
param($Targets=@('8.8.8.8','www.microsoft.com'), $TcpPorts=@(80,443))
$OutDir="C:\Temp\vm-health"; New-Item -Path $OutDir -ItemType Directory -Force | Out-Null
$out=(Join-Path $OutDir "nettest-$(Get-Date -Format yyyyMMddHHmmss).txt")
"Quick net test on $(hostname) at $(Get-Date)" | Out-File $out
"Local IPs:" | Out-File $out -Append
Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' } | Format-Table IPAddress,InterfaceAlias -AutoSize | Out-String | Out-File $out -Append

foreach ($t in $Targets) {
  "`n---- $t ----`n" | Out-File $out -Append
  "Ping:" | Out-File $out -Append
  Test-Connection -Count 4 -ComputerName $t | Select-Object Address,ResponseTime,ReplyStatus | Out-String | Out-File $out -Append
  if ($t -match '\w') {
    "Resolve:" | Out-File $out -Append
    try { [System.Net.Dns]::GetHostAddresses($t) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | ForEach-Object { $_.IPAddressToString } | Out-File $out -Append } catch { "DNS fail: $_" | Out-File $out -Append }
  }
  "TCP ports:" | Out-File $out -Append
  foreach ($p in $TcpPorts) {
    $res = Test-NetConnection -ComputerName $t -Port $p -WarningAction SilentlyContinue
    ("{0}:{1} => TcpTest:{2}" -f $t,$p,$res.TcpTestSucceeded) | Out-File $out -Append
  }
}
Write-Output "Saved network test to $out"

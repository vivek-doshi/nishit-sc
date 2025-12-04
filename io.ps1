# quick-ps-disk-test.ps1
$OutDir="C:\Temp\vm-health"; New-Item -Path $OutDir -ItemType Directory -Force | Out-Null
$TestFile = "C:\Temp\vm-health\ps_disk_test.dat"
# parameters
$SizeMB = 256
$RandomIOs = 5000

# simple sequential write
$sw=[System.Diagnostics.Stopwatch]::StartNew()
$fs=[IO.File]::Open($TestFile,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::None)
$buffer = New-Object byte[] (64kb)
(new-object Random).NextBytes($buffer)
$written=0
$total = $SizeMB * 1MB
while ($written -lt $total) {
  $toWrite = [Math]::Min($buffer.Length, $total - $written)
  $fs.Write($buffer,0,$toWrite)
  $written += $toWrite
}
$fs.Flush(); $fs.Close()
$sw.Stop()
$seqWriteMBps = [math]::Round(($total/1MB)/$sw.Elapsed.TotalSeconds,2)

# sequential read
$sr=[System.Diagnostics.Stopwatch]::StartNew()
$fs=[IO.File]::Open($TestFile,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
$buf = New-Object byte[] 65536
while ($fs.Position -lt $fs.Length) { $fs.Read($buf,0,$buf.Length) | Out-Null }
$fs.Close()
$sr.Stop()
$seqReadMBps = [math]::Round(($total/1MB)/$sr.Elapsed.TotalSeconds,2)

# random read
$fs=[IO.File]::Open($TestFile,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
$rand = New-Object Random
$sw2=[System.Diagnostics.Stopwatch]::StartNew()
for ($i=0;$i -lt $RandomIOs;$i++) {
  $pos = [int]($rand.NextDouble()*($fs.Length-4096))
  $fs.Seek($pos,'Begin') | Out-Null
  $fs.Read($buf,0,4096) | Out-Null
}
$sw2.Stop(); $fs.Close()
$randIOPS = [math]::Round($RandomIOs/$sw2.Elapsed.TotalSeconds,2)

# save
$report = @"
SeqWrite_MBps: $seqWriteMBps
SeqRead_MBps:  $seqReadMBps
Rand4K_IOPS:   $randIOPS
"@
$report | Out-File (Join-Path $OutDir "disk-test-$(Get-Date -Format yyyyMMddHHmmss).txt")
Remove-Item $TestFile -Force
Write-Output "Disk test complete. Report saved."

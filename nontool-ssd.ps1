# quick-ps-disk-test.ps1
param(
  [string]$TestFilePath = "C:\Temp\ps_disk_test.dat",
  [int]$SizeMB = 512,
  [int]$BlockKB = 64,
  [int]$RandomIOs = 10000
)
New-Item -ItemType Directory -Path (Split-Path $TestFilePath) -Force | Out-Null

# Check free space
$drive = Get-PSDrive -Name (Split-Path $TestFilePath -Qualifier).TrimEnd(':')
$freeMB = [math]::Floor($drive.Free/1MB)
if ($freeMB -lt $SizeMB + 50) { throw "Not enough free space on drive. Free: $freeMB MB" }

function Measure-SeqWrite {
  param($path, $sizeMB, $blockKB)
  $blockBytes = $blockKB * 1024
  $totalBytes = $sizeMB * 1MB
  $buffer = New-Object byte[] $blockBytes
  (New-Object Random).NextBytes($buffer)
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $fs = [System.IO.File]::Open($path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
  try {
    $written = 0
    while ($written -lt $totalBytes) {
      $toWrite = [Math]::Min($blockBytes, $totalBytes - $written)
      $fs.Write($buffer, 0, $toWrite)
      $written += $toWrite
    }
  } finally {
    $fs.Flush()
    $fs.Close()
    $sw.Stop()
  }
  $mbPerSec = ($totalBytes/1MB) / $sw.Elapsed.TotalSeconds
  return [PSCustomObject]@{Operation='SeqWrite';SizeMB=$sizeMB;BlockKB=$blockKB;Seconds=$sw.Elapsed.TotalSeconds;MBps=[math]::Round($mbPerSec,2)}
}

function Measure-SeqRead {
  param($path)
  $total = (Get-Item $path).Length
  $buffer = New-Object byte[] 65536
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $fs = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
  try {
    while ($fs.Position -lt $fs.Length) {
      $count = $fs.Read($buffer, 0, $buffer.Length)
      if ($count -le 0) { break }
    }
  } finally {
    $fs.Close()
    $sw.Stop()
  }
  $mbPerSec = ($total/1MB) / $sw.Elapsed.TotalSeconds
  return [PSCustomObject]@{Operation='SeqRead';SizeMB=([math]::Round($total/1MB,2));Seconds=$sw.Elapsed.TotalSeconds;MBps=[math]::Round($mbPerSec,2)}
}

function Measure-RandomReadIOPS {
  param($path, $randomIOs)
  $fs = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
  try {
    $len = $fs.Length
    $block = New-Object byte[] 4096
    $rand = New-Object System.Random
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    for ($i=0; $i -lt $randomIOs; $i++) {
      $pos = [int]($rand.NextDouble() * ($len - 4096))
      $fs.Seek($pos, 'Begin') | Out-Null
      $fs.Read($block,0,4096) | Out-Null
    }
    $sw.Stop()
  } finally {
    $fs.Close()
  }
  $iops = $randomIOs / $sw.Elapsed.TotalSeconds
  return [PSCustomObject]@{Operation='RandomRead4K';IOs=$randomIOs;Seconds=$sw.Elapsed.TotalSeconds;IOPS=[math]::Round($iops,2)}
}

Write-Output "Starting sequential write..."
$w = Measure-SeqWrite -path $TestFilePath -sizeMB $SizeMB -blockKB $BlockKB
Write-Output $w | Format-List

Start-Sleep -Seconds 2
Write-Output "Starting sequential read..."
$r = Measure-SeqRead -path $TestFilePath
Write-Output $r | Format-List

Start-Sleep -Seconds 2
Write-Output "Starting random 4K reads (approx IOPS)..."
$rand = Measure-RandomReadIOPS -path $TestFilePath -randomIOs $RandomIOs
Write-Output $rand | Format-List

# Clean up
Write-Output "Removing test file..."
Remove-Item $TestFilePath -Force

Write-Output "Done."

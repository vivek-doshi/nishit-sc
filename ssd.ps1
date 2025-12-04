# run-diskspd-test.ps1
param(
    [string]$TestFolder = "C:\Temp",
    [int]$TestFileSizeMB = 1024,    # size of test file (MB) - reduce for small disks
    [int]$DurationSeconds = 30,
    [string]$DiskSpdUrl = "https://aka.ms/diskspd"  # redirect to latest zip from MS
)

# Ensure folder exists
if (-not (Test-Path $TestFolder)) { New-Item -ItemType Directory -Path $TestFolder | Out-Null }

$diskspdZip = Join-Path $env:TEMP "diskspd.zip"
$diskspdExe = Join-Path $TestFolder "diskspd.exe"
$testFile = Join-Path $TestFolder "diskspd_testfile.dat"

Write-Output "Checking free disk space..."
$freeMB = [math]::Floor((Get-PSDrive -Name (Get-Item $TestFolder).PSDrive.Name).Free / 1MB)
if ($freeMB -lt $TestFileSizeMB + 100) {
    throw "Not enough free space on the volume. Free MB: $freeMB; required: $($TestFileSizeMB + 100)"
}

# Download diskspd zip if exe missing
if (-not (Test-Path $diskspdExe)) {
    Write-Output "Downloading DiskSpd..."
    Invoke-WebRequest -Uri $DiskSpdUrl -OutFile $diskspdZip -UseBasicParsing
    # attempt to extract diskspd.exe from zip
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($diskspdZip, $TestFolder)
    Remove-Item $diskspdZip -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $diskspdExe)) { throw "diskspd.exe not found in $TestFolder" }

# Create test file (diskspd -c creates file automatically; here we'll use diskspd's create flag)
# Example tests:
#  - Sequential read: 1 thread, large block (128K)
#  - Random 4K read: multiple outstanding IOs to measure IOPS
#  - Mixed read/write: 70/30 random (optional)

$logFolder = Join-Path $TestFolder "diskspd_logs"
if (-not (Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder | Out-Null }

# Build and run commands (non-destructive to other files; diskspd creates and removes testfile by -c flag)
$sizeArg = "${TestFileSizeMB}M"

# Sequential write then read (sequential throughput)
$seqCmd = "`"$diskspdExe`" -d$DurationSeconds -w100 -b128K -o8 -t1 -c$sizeArg `"$testFile`" > `"$logFolder\seq.txt`" 2>&1"
# Random read (IOPS)
$randReadCmd = "`"$diskspdExe`" -d$DurationSeconds -w0 -b4K -o32 -t4 -r -c$sizeArg `"$testFile`" > `"$logFolder\randread.txt`" 2>&1"
# Random mixed read/write 70/30
$mixedCmd = "`"$diskspdExe`" -d$DurationSeconds -w30 -b4K -o32 -t4 -r -c$sizeArg `"$testFile`" > `"$logFolder\mixed.txt`" 2>&1"

Write-Output "Running sequential write test (log: $logFolder\seq.txt) ..."
cmd.exe /c $seqCmd
Write-Output "Running sequential read test (log: $logFolder\seq.txt) - done."

Write-Output "Running random read test (log: $logFolder\randread.txt) ..."
cmd.exe /c $randReadCmd
Write-Output "Random read test - done."

Write-Output "Running mixed read/write test (log: $logFolder\mixed.txt) ..."
cmd.exe /c $mixedCmd
Write-Output "Mixed test - done."

Write-Output "Cleaning up test file..."
if (Test-Path $testFile) { Remove-Item $testFile -Force -ErrorAction SilentlyContinue }

Write-Output "Logs saved to: $logFolder"
Write-Output "Review logs for MB/s (throughput), IOPS, and latency results."

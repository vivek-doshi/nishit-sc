$threshold = 80
$cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue

$logDir = "C:\cpulogs"
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$logFile = Join-Path $logDir "CPU_Snapshot.txt"
$lockFile = Join-Path $logDir "CPU_Snapshot.lock"

if ($cpuUsage -gt $threshold) {
    # If lock file exists, check its timestamp
    if (Test-Path $lockFile) {
        $lockTime = Get-Content $lockFile | Out-String | ConvertTo-DateTime
        if ((Get-Date) -lt $lockTime.AddMinutes(5)) {
            Write-Host "CPU above threshold and log file recently written. Skipping log for 5 minutes."
            return
        }
    }
    # Write log and update lock file
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "C:\cpulogs\CPU_Snapshot_$timestamp.txt"
    "CPU usage: $cpuUsage%" | Out-File $outputFile
    
    # Get top processes with CommandLine from WMI
    $processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 15
    $processInfo = foreach ($proc in $processes) {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
        [PSCustomObject]@{
            Id = $proc.Id
            Name = $proc.Name
            CPU = $proc.CPU
            CommandLine = if ($cmdLine) { $cmdLine } else { "N/A" }
        }
    }
    $processInfo | Format-Table -AutoSize | Out-String | Out-File -Append $outputFile
    # Write current time to lock file
    (Get-Date).ToString("o") | Out-File $lockFile -Force
}
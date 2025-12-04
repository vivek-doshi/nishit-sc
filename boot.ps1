param(
    [string]$RG = "SCRAPRIGHT",
    [string]$VM = "IIS1",
    [string]$LogPath = "C:\Temp\boot-log.txt"
)

Write-Output "Fetching boot diagnostics..."
$data = Get-AzVMBootDiagnosticsData -ResourceGroupName $RG -Name $VM

Invoke-WebRequest -Uri $data.SerialConsoleLogUri -OutFile $LogPath -UseBasicParsing

Write-Output "Boot log saved to $LogPath"
Write-Output "Scanning for warnings/errors..."

$patterns = @("error", "failed", "exception", "warning", "critical", "bsod", "panic")
$results = Select-String -Path $LogPath -Pattern $patterns -SimpleMatch

if ($results) {
    Write-Output "`n=== Issues Detected ==="
    $results | Format-Table
} else {
    Write-Output "`nNo warnings or errors found in boot diagnostics."
}

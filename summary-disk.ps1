# ===============================
# Disk Info Report Script (Exclude A:, Sorted Drives, With Teams-Safe Icons)
# ===============================

# Teams Webhook URL (from Workflows app - Incoming Webhook)
$webhookUrl = "https://default7f63de80bc5645439e11da7b548818.95.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/7a1c14e184f64ef3aca472fc54fb3d04/triggers/manual/paths/invoke/?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=tQhZmxp7aXt99lcNgFIW-nlH6MpHYAN1PcaxAUXvx7M" 

# Warning & Critical thresholds in GB
$warningThresholdGB = 10
$criticalThresholdGB = 5

# Collect current time and computer name
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$computerName = $env:COMPUTERNAME

# Collect disk space info for ALL drives, exclude A:, sort by Name
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne "A" } | Sort-Object Name

# Build card body
$cardBody = @(
    @{
        type = "TextBlock"
        text = "Disk Space Report — $computerName — $timestamp"
        weight = "Bolder"
        size = "Medium"
    }
)

foreach ($drive in $drives) {
    $freeGB  = [math]::Round($drive.Free/1GB,2)
    $totalGB = [math]::Round(($drive.Used/1GB + $drive.Free/1GB),2)

    if ($totalGB -gt 0) {
        $percentFree = [math]::Round(($freeGB / $totalGB) * 100,2)
    }
    else {
        $percentFree = 0
    }

    # Choose icon based on thresholds
    if ($freeGB -lt $criticalThresholdGB) {
        $line = "⛔ Drive ($($drive.Name)): $freeGB GB free of $totalGB GB ($percentFree% free)"
    }
    elseif ($freeGB -lt $warningThresholdGB) {
        $line = "⚡ Drive ($($drive.Name)): $freeGB GB free of $totalGB GB ($percentFree% free)"
    }
    else {
        $line = "Drive ($($drive.Name)): $freeGB GB free of $totalGB GB ($percentFree% free)"
    }

    $cardBody += @{
        type = "TextBlock"
        text = $line
        wrap = $true
    }
}

# Build JSON payload for Teams
$payload = @{
    type = "message"
    attachments = @(@{
        contentType = "application/vnd.microsoft.card.adaptive"
        content = @{
            type = "AdaptiveCard"
            version = "1.4"
            body = $cardBody
        }
    })
} | ConvertTo-Json -Depth 5

# Send to Teams
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType 'application/json'

# Also print to console if run manually
Write-Output "📊 Disk Space Report — $computerName — $timestamp"
$drives | ForEach-Object {
    $freeGB  = [math]::Round($_.Free/1GB,2)
    $totalGB = [math]::Round(($_.Used/1GB + $_.Free/1GB),2)
    $percentFree = if ($totalGB -gt 0) { [math]::Round(($freeGB / $totalGB) * 100,2) } else { 0 }

    if ($freeGB -lt $criticalThresholdGB) {
        Write-Output "⛔ Drive ($($_.Name)): $freeGB GB free of $totalGB GB ($percentFree% free)"
    }
    elseif ($freeGB -lt $warningThresholdGB) {
        Write-Output "⚡ Drive ($($_.Name)): $freeGB GB free of $totalGB GB ($percentFree% free)"
    }
    else {
        Write-Output "Drive ($($_.Name)): $freeGB GB free of $totalGB GB ($percentFree% free)"
    }
}

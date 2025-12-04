param(
    [int]$ThresholdGB = 10,
    [switch]$NoTeams
)

# Paths & Teams Workflow webhook
$logPath = "C:\Logs"
$logFile = "$logPath\DiskCheck.log"
$teamsWebhookUrl = "https://default7f63de80bc5645439e11da7b548818.95.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/7a1c14e184f64ef3aca472fc54fb3d04/triggers/manual/paths/invoke/?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=tQhZmxp7aXt99lcNgFIW-nlH6MpHYAN1PcaxAUXvx7M" 
# ^ Replace with your Workflow Webhook URL

# Ensure log folder exists
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}

# Function to log messages with timestamp
function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "$timestamp - $Message"
    Write-Output $entry
    Add-Content -Path $logFile -Value $entry
}

# Function to send Teams alert via Workflow Webhook
function Send-TeamsAlert {
    param([string]$Title, [string]$Message)

    # Adaptive Card payload
    $adaptiveCard = @{
        type = "message"
        attachments = @(
            @{
                contentType = "application/vnd.microsoft.card.adaptive"
                content = @{
                    type = "AdaptiveCard"
                    version = "1.4"
                    body = @(
                        @{
                            type = "TextBlock"
                            size = "Large"
                            weight = "Bolder"
                            text = $Title
                        },
                        @{
                            type = "TextBlock"
                            wrap = $true
                            text = $Message
                        }
                    )
                }
            }
        )
    } | ConvertTo-Json -Depth 5 -Compress

    try {
        Invoke-RestMethod -Uri $teamsWebhookUrl -Method Post -Body $adaptiveCard -ContentType 'application/json'
        Write-Log "ALERT: Teams notification sent."
    } catch {
        Write-Log "ERROR: Failed to send Teams notification - $($_.Exception.Message)"
    }
}

# Get all fixed drives
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }

foreach ($drive in $drives) {
    $freeGB = [math]::Round($drive.Free/1GB, 2)
    $totalGB = [math]::Round(($drive.Used + $drive.Free)/1GB, 2)
    $percentFree = [math]::Round(($freeGB / $totalGB) * 100, 2)

    # Print & log status
    Write-Log "Drive $($drive.Name): $freeGB GB free of $totalGB GB ($percentFree% free)"

    # Check threshold
    if ($freeGB -lt $ThresholdGB) {
        $title = "Disk Space Alert: $($drive.Name) on $env:COMPUTERNAME"
        $body = "Drive $($drive.Name) has only $freeGB GB free of $totalGB GB"

        if (-not $NoTeams) {
            Send-TeamsAlert -Title $title -Message $body
        } else {
            Write-Log "ALERT: $($drive.Name) below threshold, but Teams alert disabled (-NoTeams flag set)."
        }
    }
}

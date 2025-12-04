<#
 quick-net-test.ps1
 Runs: basic ping tests, DNS resolution, route, TCP port checks, and HTTP check.
#>

param(
    [string[]]$Targets = @("8.8.8.8","www.microsoft.com"),
    [int[]]$TcpPorts = @(80,443),
    [int]$PingCount = 4,
    [int]$TcpTimeoutSeconds = 5
)

Write-Output "=== Quick Network Test: $(Get-Date -Format s) ==="
Write-Output "Hostname: $env:COMPUTERNAME"
Write-Output ""

# Show local IPs
Write-Output ">>> Local IP configuration"
Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' } | Select-Object IPAddress, InterfaceAlias, AddressState
Write-Output ""

# Default gateway
Write-Output ">>> Default Gateway"
Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object -First 1 | Format-Table -AutoSize
Write-Output ""

# DNS servers
Write-Output ">>> DNS Servers"
Get-DnsClientServerAddress | Select-Object InterfaceAlias, ServerAddresses
Write-Output ""

foreach ($t in $Targets) {
    Write-Output ""
    Write-Output ">>> Testing target: $t"

    # Ping
    Write-Output "Ping ($PingCount)"
    Test-Connection -Count $PingCount -Quiet -ComputerName $t | ForEach-Object {
        if ($_ -eq $true) { Write-Output "Ping to ${t}: Success" }
        else { Write-Output "Ping to ${t}: Failed" }
    }

    # DNS resolution (if hostname)
    if ($t -match "[a-zA-Z]") {
        Write-Output "DNS Resolve"
        try {
            $ips = [System.Net.Dns]::GetHostAddresses($t) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | ForEach-Object { $_.IPAddressToString }
            if ($ips) { Write-Output "Resolved ${t} -> $($ips -join ', ')" } else { Write-Output "No A records found." }
        } catch {
            Write-Output "DNS resolution error: $_"
        }
    }

    # Traceroute
    Write-Output "Traceroute (max 30 hops)"
    tracert -h 30 $t

    # TCP ports
    foreach ($p in $TcpPorts) {
        Write-Output "TCP Connect test ${t}:$p (timeout ${TcpTimeoutSeconds}s)"
        $res = Test-NetConnection -ComputerName $t -Port $p -WarningAction SilentlyContinue -InformationLevel Quiet
        if ($res.TcpTestSucceeded) { Write-Output "TCP $p to ${t}: SUCCESS" } else { Write-Output "TCP $p to ${t}: FAILED" }
    }

    # HTTP(S) quick check (if port 80/443 present)
    foreach ($p in @(80,443)) {
        if ($Targets -contains $t -or $t -match "http") {
            $url = if ($p -eq 443) { "https://$t" } else { "http://$t" }
            Write-Output "HTTP GET $url (timeout ${TcpTimeoutSeconds}s)"
            try {
                $resp = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec $TcpTimeoutSeconds -ErrorAction Stop
                Write-Output "HTTP status: $($resp.StatusCode) $($resp.StatusDescription)"
            } catch {
                Write-Output "HTTP check failed: $($_.Exception.Message)"
            }
        }
    }
}

Write-Output ""
Write-Output "=== End test ==="

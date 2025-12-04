# folder-counter.ps1
# Traverses a path and displays all first-level folders with their sizes in GB

param(
    [string]$Path = "F:\"
)

# Check if path exists
if (-not (Test-Path $Path)) {
    Write-Error "Path not found: $Path"
    exit 1
}

Write-Output "Scanning folders in: $Path"
Write-Output "Please wait, calculating folder sizes..."
Write-Output ""

# Get all first-level directories
$folders = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue

$folderSizes = foreach ($folder in $folders) {
    try {
        # Calculate total size of folder including all subfolders and files
        $size = (Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum).Sum
        
        # Convert bytes to GB
        $sizeGB = [math]::Round($size / 1GB, 2)
        
        [PSCustomObject]@{
            FolderName = $folder.Name
            'Size (GB)' = $sizeGB
            FullPath = $folder.FullName
        }
    }
    catch {
        [PSCustomObject]@{
            FolderName = $folder.Name
            'Size (GB)' = "Error"
            FullPath = $folder.FullName
        }
    }
}

# Sort by size descending
$sortedFolders = $folderSizes | Sort-Object 'Size (GB)' -Descending

# Display results
$sortedFolders | Format-Table -AutoSize

# Export to CSV
$logDir = "C:\logs"
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvFile = Join-Path $logDir "FolderSizes_$timestamp.csv"
$sortedFolders | Select-Object FolderName, 'Size (GB)' | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

# Display summary
$totalSize = ($folderSizes | Where-Object { $_.'Size (GB)' -ne "Error" } | Measure-Object -Property 'Size (GB)' -Sum).Sum
Write-Output ""
Write-Output "Total size of all folders: $([math]::Round($totalSize, 2)) GB"
Write-Output "Total folders scanned: $($folders.Count)"
Write-Output "CSV file created: $csvFile"

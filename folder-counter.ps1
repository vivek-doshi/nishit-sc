# filepath: d:\Personal\Projects\Scrapright\folder-counter.ps1
# folder-counter.ps1
# Traverses a path and displays all first-level folders with their sizes in GB

param(
   [string]$Path = "F:\"
)

# Check if the provided path exists
if (-not (Test-Path $Path)) {
   Write-Error "The specified path was not found: $Path"
   exit 1
}

# Output the scanning message and start folder size calculation
Write-Output "Scanning folders in: $Path"
$folders = Get-ChildItem -Path $Path -Directory -ErrorAction Stop

try {
   # Calculate the size of each folder including all subfolders and files
   $folderSizes = foreach ($folder in $folders) {
       try {
           $size = (Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction Stop | Measure-Object -Property Length -Sum).Sum
           [PSCustomObject]@{
               FolderName = $folder.Name
               'Size (GB)' = [math]::Round($size / 1GB, 2)
               FullPath = $folder.FullName
           }
       } catch {
           [PSCustomObject]@{
               FolderName = $folder.Name
               'Size (GB)' = "Error"
               FullPath = $folder.FullName
           }
       }
   }
} catch {
   Write-Error "Failed to calculate size for one or more folders."
   exit 1
}

# Sort the folders by their size in GB, in descending order
$sortedFolders = $folderSizes | Sort-Object 'Size (GB)' -Descending

# Display the sorted folder sizes in a table format
$sortedFolders | Format-Table -AutoSize

# Define and create a log directory for storing CSV files if it doesn't exist
$logDir = "C:\logs"
if (-not (Test-Path $logDir)) {
   New-Item -ItemType Directory -Path $logDir | Out-Null
}

# Generate a timestamped CSV file name and export the folder sizes to this file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvFile = Join-Path $logDir "FolderSizes_$timestamp.csv"
$sortedFolders | Select-Object FolderName, 'Size (GB)' | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

# Calculate the total size of all folders and output this information
$totalSize = ($folderSizes | Where-Object { $_.'Size (GB)' -ne "Error" } | Measure-Object -Property 'Size (GB)' -Sum).Sum
Write-Output ""
Write-Output "Total size of all folders: $([math]::Round($totalSize, 2)) GB"
Write-Output "Total folders scanned: $($folders.Count)"
Write-Output "CSV file created: $csvFile"
<#
.SYNOPSIS
    Clears the contents of the user's %TEMP% and the system's Temp folders.

.DESCRIPTION
    This script identifies the paths for the user's temporary directory (%TEMP%)
    and the system's temporary directory (usually C:\Windows\Temp).
    It then attempts to remove all files and subdirectories within these
    locations. Error handling is included to skip files/folders that are
    in use or cannot be accessed, and it provides feedback on the operation.

.NOTES
    Author: Vivek
    Date: 2025-07-21
    Version: 1.0

    IMPORTANT: Running this script will permanently delete files.
    Ensure you understand the implications before execution.
    It is recommended to close all applications before running this script
    to minimize "file in use" errors.
#>

# --- Configuration ---
# Define the paths for the temporary directories.
# %TEMP% refers to the user's temporary directory (e.g., C:\Users\<username>\AppData\Local\Temp)
# $env:TEMP is the PowerShell way to access the %TEMP% environment variable.

$userTempPath = $env:TEMP

# The system's Temp directory is typically C:\Windows\Temp.
# Ensure this path is correct for your system if it differs.

$systemTempPath = "$env:SystemRoot\Temp"


# --- Function to clear a specific directory ---
function Clear-TempDirectory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    Write-Host "Attempting to clear: $Path" -ForegroundColor Cyan

    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-Warning "Directory not found: $Path. Skipping."
        return
    }

    try {
        # Get all items (files and directories) within the target path, but not the directory itself.
        # -ErrorAction SilentlyContinue prevents individual file errors from stopping the script.
        $itemsToDelete = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue

        if ($itemsToDelete.Count -eq 0) {
            Write-Host "No items found to delete in $Path." -ForegroundColor Yellow
            return
        }

        foreach ($item in $itemsToDelete) {
            try {
                # Remove the item (file or directory) recursively and forcefully.
                # -ErrorAction SilentlyContinue handles items that might be in use or locked.
                Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Deleted: $($item.FullName)" -ForegroundColor DarkGreen
            }
            catch {
                Write-Warning "Could not delete $($item.FullName): $($_.Exception.Message)"
            }
        }
        Write-Host "Finished attempting to clear: $Path" -ForegroundColor Green
    }
    catch {
        Write-Error "An error occurred while processing $Path $($_.Exception.Message)"
    }
    Write-Host "" # Add a blank line for readability
}

# --- Main Script Execution ---
Write-Host "Starting temporary folder cleanup..." -ForegroundColor Yellow

# Clear the user's temporary folder
Clear-TempDirectory -Path $userTempPath

# Clear the system's temporary folder
Clear-TempDirectory -Path $systemTempPath

# Empty the Recycle Bin
Write-Host "Attempting to empty the Recycle Bin..." -ForegroundColor Cyan
try {
    Clear-RecycleBin -Force -ErrorAction Stop
    Write-Host "Recycle Bin emptied successfully." -ForegroundColor Green
} catch {
    Write-Warning "Could not empty Recycle Bin: $($_.Exception.Message)"
}
Write-Host ""

Write-Host "Temporary folder cleanup complete." -ForegroundColor Yellow
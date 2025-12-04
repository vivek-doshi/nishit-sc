# Set the base directory to search for folders and define the log file path
$BasePath = "F:\"
$LogFile = Join-Path $BasePath "Delete.log"

# Calculate the cutoff date (7 days ago) for log deletion
$CutoffDate = (Get-Date).AddDays(-7)
$CutoffDateString = $CutoffDate.ToString("ddMMyyyy")

# Start the log file with a timestamp
"Log deletion started at $(Get-Date)" | Out-File -FilePath $LogFile -Encoding UTF8

# Retrieve all directories in the base path
$Folders = Get-ChildItem -Path $BasePath -Directory -ErrorAction SilentlyContinue

foreach ($Folder in $Folders) {


    ###################################################################################################################################################################
    ###################################################################WEB/LOG/* DELETE###################################
    # Construct the path to the Web\Logs directory inside each folder
    $LogsPath = Join-Path $Folder.FullName "Web\Logs"
    
    # If the Web\Logs directory does not exist, log and skip to the next folder
    if (-not (Test-Path $LogsPath)) {
        "Skipped: $LogsPath (path not found)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
        continue
    }
    # Get all log files in the format error_*.log within the Logs directory
    $LogFiles = Get-ChildItem -Path $LogsPath -Filter "error_*.log" -ErrorAction SilentlyContinue
    
    $DeletedCount = 0
    foreach ($File in $LogFiles) {
        # Extract the date from the filename (expects format error_DDMMYYYY.log)
        if ($File.Name -match "error_(\d{8})\.log") {
            $FileDateString = $Matches[1]
            
            # Delete the file if its date is older than the cutoff date
            if ($FileDateString -lt $CutoffDateString) {
                try {
                    Remove-Item $File.FullName -Force
                    "Deleted: $($File.FullName)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                    $DeletedCount++
                }
                catch {
                    "Failed to delete: $($File.FullName) - $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                }
            }
        }
    }

###################################################################WEB/LOG/* DELETE###################################
###################################################################################################################################################################




###################################################################################################################################################################
###################################################################WEB/CRReports/LOG/* DELETE###################################
     # --- Web\CRReports\logs section ---
    $CRReportsLogsPath = Join-Path $Folder.FullName "Web\CRReports\logs"
    if (-not (Test-Path $CRReportsLogsPath)) {
        "Skipped: $CRReportsLogsPath (path not found)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    } else {
        $CRReportsLogFiles = Get-ChildItem -Path $CRReportsLogsPath -Filter "error_*.log" -ErrorAction SilentlyContinue
        $CRReportsDeletedCount = 0
        foreach ($File in $CRReportsLogFiles) {
            # Extract the date from the filename (expects format error_DDMMYYYY.log)
            if ($File.Name -match "error_(\d{8})\.log") {
                $FileDateString = $Matches[1]
                if ($FileDateString -lt $CutoffDateString) {
                    try {
                        Remove-Item $File.FullName -Force
                        "Deleted: $($File.FullName)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                        $CRReportsDeletedCount++
                    }
                    catch {
                        "Failed to delete: $($File.FullName) - $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                    }
                }
            }
        }
        "Folder: $($Folder.Name) - CRReports\\logs Deleted $CRReportsDeletedCount files" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
    ###################################################################WEB/CRReports/LOG/* DELETE###################################
    ###################################################################################################################################################################

    
###################################################################################################################################################################
###################################################################/DeviceHubLogs/LOG/* DELETE###################################

    # Log the number of deleted files for the current folder
    "Folder: $($Folder.Name) - Deleted $DeletedCount files" | Out-File -FilePath $LogFile -Append -Encoding UTF8

    # --- DeviceHubLogs section ---
    $DeviceHubLogsPath = Join-Path $Folder.FullName "DeviceHubLogs"
    if (-not (Test-Path $DeviceHubLogsPath)) {
        "Skipped: $DeviceHubLogsPath (path not found)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
        continue
    }

    $DeviceHubLogFiles = Get-ChildItem -Path $DeviceHubLogsPath -Filter "DeviceHubLogs_*.txt" -ErrorAction SilentlyContinue
    $DeviceHubDeletedCount = 0
    foreach ($File in $DeviceHubLogFiles) {
        # Extract the date from the filename (expects format DeviceHubLogs_DD-MMM-YYYY.txt)
        if ($File.Name -match "DeviceHubLogs_(\d{2})-([A-Za-z]{3})-(\d{4})\.txt") {
            $Day = $Matches[1]
            $Month = $Matches[2]
            $Year = $Matches[3]
            $FileDate = [datetime]::ParseExact("$Day-$Month-$Year", "dd-MMM-yyyy", $null)
            if ($FileDate -lt $CutoffDate) {
                try {
                    Remove-Item $File.FullName -Force
                    "Deleted: $($File.FullName)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                    $DeviceHubDeletedCount++
                }
                catch {
                    "Failed to delete: $($File.FullName) - $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                }
            }
        }
    }
    "Folder: $($Folder.Name) - DeviceHubLogs Deleted $DeviceHubDeletedCount files" | Out-File -FilePath $LogFile -Append -Encoding UTF8

###################################################################/DeviceHubLogs/LOG/* DELETE###################################
###################################################################################################################################################################




###################################################################################################################################################################
###################################################################WEB/MOBILEAPPLOGS/* DELETE###################################
    # --- Web\MobileAppLogs section ---
    $MobileAppLogsPath = Join-Path $Folder.FullName "Web\MobileAppLogs"
    if (-not (Test-Path $MobileAppLogsPath)) {
        "Skipped: $MobileAppLogsPath (path not found)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    } else {
        $MobileAppLogFiles = Get-ChildItem -Path $MobileAppLogsPath -Filter "Log_*.txt" -ErrorAction SilentlyContinue
        $MobileAppDeletedCount = 0
        foreach ($File in $MobileAppLogFiles) {
            # Extract the date from the filename (expects format Log_DD-MMM-YYYY.txt)
            if ($File.Name -match "Log_(\d{2})-([A-Za-z]{3})-(\d{4})\.txt") {
                $Day = $Matches[1]
                $Month = $Matches[2]
                $Year = $Matches[3]
                $FileDate = [datetime]::ParseExact("$Day-$Month-$Year", "dd-MMM-yyyy", $null)
                if ($FileDate -lt $CutoffDate) {
                    try {
                        Remove-Item $File.FullName -Force
                        "Deleted: $($File.FullName)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                        $MobileAppDeletedCount++
                    }
                    catch {
                        "Failed to delete: $($File.FullName) - $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                    }
                }
            }
        }
        "Folder: $($Folder.Name) - Web\\MobileAppLogs Deleted $MobileAppDeletedCount files" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
###################################################################WEB/MOBILEAPPLOGS/* DELETE###################################
###################################################################################################################################################################




###################################################################################################################################################################
###################################################################/WEB/ATTACHMENTS/* PURGE###################################
    # --- Web\Attachments section ---
    #$AttachmentsPath = Join-Path $Folder.FullName "Web\Attachments"
    #if (-not (Test-Path $AttachmentsPath)) {
    #    "Skipped: $AttachmentsPath (path not found)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    #} else {
    #    $AttachmentFiles = Get-ChildItem -Path $AttachmentsPath -File -ErrorAction SilentlyContinue
    #    $AttachmentDeletedCount = 0
    #    foreach ($File in $AttachmentFiles) {
     #       try {
      #          Remove-Item $File.FullName -Force
       #         "Deleted: $($File.FullName)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
        #        $AttachmentDeletedCount++
         #   }
          #  catch {
           #     "Failed to delete: $($File.FullName) - $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
            #}
        #}
        #"Folder: $($Folder.Name) - Web\\attachments Deleted $AttachmentDeletedCount files" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    #}
###################################################################/WEB/ATTACHMENTS/* PURGE###################################
###################################################################################################################################################################

###################################################################/WEB/ATTACHMENTS/POLICEREPORT/* PURGE###################################
    # --- Web\Attachments\PoliceReport section ---
###################################################################/WEB/ATTACHMENTS/POLICEREPORT/* PURGE###################################

###################################################################/WEB/TEMP/* PURGE###################################
    # --- Web\Temp section ---
    $WebTempPath = Join-Path $Folder.FullName "Web\Temp"
    if (-not (Test-Path $WebTempPath)) {
        "Skipped: $WebTempPath (path not found)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    } else {
        $WebTempFiles = Get-ChildItem -Path $WebTempPath -File -ErrorAction SilentlyContinue
        $WebTempDeletedCount = 0
        foreach ($File in $WebTempFiles) {
            try {
                Remove-Item $File.FullName -Force
                "Deleted: $($File.FullName)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                $WebTempDeletedCount++
            }
            catch {
                "Failed to delete: $($File.FullName) - $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
            }
        }
        "Folder: $($Folder.Name) - Web\\Temp Deleted $WebTempDeletedCount files" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
###################################################################/WEB/TEMP/* PURGE###################################
###################################################################################################################################################################


###################################################################################################################################################################
###################################################################/TEMP/* PURGE###################################
    # --- Temp section ---
    $TempPath = Join-Path $Folder.FullName "Temp"
    if (-not (Test-Path $TempPath)) {
        "Skipped: $TempPath (path not found)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    } else {
        $TempFiles = Get-ChildItem -Path $TempPath -File -ErrorAction SilentlyContinue
        $TempDeletedCount = 0
        foreach ($File in $TempFiles) {
            try {
                Remove-Item $File.FullName -Force
                "Deleted: $($File.FullName)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
                $TempDeletedCount++
            }
            catch {
                "Failed to delete: $($File.FullName) - $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
            }
        }
        "Folder: $($Folder.Name) - Temp Deleted $TempDeletedCount files" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
    ###################################################################/TEMP/* PURGE###################################
    ###################################################################################################################################################################
}

# Log completion with a timestamp
"Log deletion completed at $(Get-Date)" | Out-File -FilePath $LogFile -Append -Encoding UTF8



####### files are getting deleted from these locations:
#F:\{Site}\Web\Logs (deletes error_*.log files older than 7 days)
#F:\{Site}\Web\Attachments (purges all files, no retention) -> don't have this include. 
#F:\{Site}\Web\PoliceReport  (purges all files, no retention)
#F:\{Site}\Web\CRReports\logs (deletes error_*.log files older than 7 days)
#F:\{Site}\DeviceHubLogs (deletes DeviceHubLogs_*.txt files older than 7 days)
#F:\{Site}\Web\MobileAppLogs (deletes Log_*.txt files older than 7 days)
#F:\{Site}\Web\Temp (deletes all files, no retention)
#F:\{Site}\Temp (deletes all files, no retention)
#########
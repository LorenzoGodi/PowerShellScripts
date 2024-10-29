param (
    [Parameter(Mandatory=$true)]$FolderToWatch, # Folder to watch
    [Parameter(Mandatory=$true)]$TypeToWatch, # File type to watch
    [switch]$DeleteAfter # Delete file after execution
)

# Function to process the file
function ProcessFile($filePath, $fileName) {
    Write-Host "     A new .$($TypeToWatch) file has been detected:"
    Write-Host "     $($fileName)"
    
    # Wait until the file is fully available
    while (-not (Test-Path $filePath)) {
        Start-Sleep -Milliseconds 100
    }
    
    try {
        # Open the file
        Start-Process -FilePath $filePath -ErrorAction Stop
        Write-Host "     $fileName has been opened."

        # Delete the file
        if ($DeleteAfter) {
            Start-Sleep -Seconds 1  # Wait before deletion

            Remove-Item -Path $filePath -Force -ErrorAction Stop
            Write-Host "     $fileName has been deleted."
        }
    } catch {
        Write-Host "     Error: $($_.Exception.Message)"
    }
}

# Define the action to be triggered when a new file is created
$actionCreated = {
    Write-Host ""
    Write-Host "File Created Event Triggered."
    $filePath = $Event.SourceEventArgs.FullPath
    $fileName = $Event.SourceEventArgs.Name

    ProcessFile $filePath $fileName
}

# Define the action to be triggered when a file is renamed
$actionRenamed = {
    Write-Host ""
    Write-Host "File Renamed Event Triggered."
    $filePath = $Event.SourceEventArgs.FullPath
    $fileName = $Event.SourceEventArgs.Name

    ProcessFile $filePath $fileName
}


# Create a new FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $FolderToWatch
$watcher.Filter = "*.$($TypeToWatch)"  # Monitor all file types
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName'

# Register the events
Register-ObjectEvent $watcher Created -Action $actionCreated
Register-ObjectEvent $watcher Renamed -Action $actionRenamed

Write-Host "FileSystemWatcher is registered. Monitoring type: .$($TypeToWatch) on folder: $FolderToWatch"

# Keep the script running
while ($true) { Start-Sleep -Seconds 1 }

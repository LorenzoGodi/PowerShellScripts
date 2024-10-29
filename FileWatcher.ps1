param (
    [Parameter(Mandatory=$true)]$Folder, # Folder to watch
    [Parameter(Mandatory=$true)]$Type, # File type to watch
    [switch]$DeleteAfter # Delete file after execution
)


# Remove all event handlers and events
@( "FileCreated", "FileRenamed" ) | ForEach-Object {
    Unregister-Event -SourceIdentifier $_ -ErrorAction SilentlyContinue
    Remove-Event -SourceIdentifier $_ -ErrorAction SilentlyContinue
}

# Do the file watching on the $Path argument's full path
[string]$fullPath = (Convert-Path $Folder)

# Create a new FileSystemWatcher [System.IO.FileSystemWatcher]
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $fullPath
$watcher.Filter = "*.$Type"
$watcher.IncludeSubdirectories = $false

# Register the events
Register-ObjectEvent $watcher Created -SourceIdentifier "FileCreated"
Register-ObjectEvent $watcher Renamed -SourceIdentifier "FileRenamed"

Write-Host -backgroundcolor Green "Watching $fullPath for new .$Type files..."

# Start monitoring
$watcher.EnableRaisingEvents = $true 

[bool]$exitRequested = $false

do {
    # Wait for an event
    [System.Management.Automation.PSEventArgs]$e = Wait-Event

    # Get the name of the file
    [string]$name = $e.SourceEventArgs.Name
    # The time and date of the event
    [string]$timeStamp = $e.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")

    Write-Host ""
    Write-Host -foregroundcolor Green "$timeStamp File detected: $name"

    # Open file
    $filePath = $e.SourceEventArgs.FullPath
    Start-Process -FilePath $filePath -ErrorAction Stop
    Write-Host "File has been opened."

    # Delete file
    if ($DeleteAfter) {
        Start-Sleep -Seconds 1  # Wait before deletion
        Remove-Item -Path $filePath -Force -ErrorAction Stop
        Write-Host "File has been deleted."
        Start-Sleep -Milliseconds 200
    }

    # Remove the event because we handled it
    Remove-Event -EventIdentifier $($e.EventIdentifier)

} while (!$exitRequested)


Unregister-Event FileCreated
Unregister-Event FileRenamed


Write-Host "Exited."

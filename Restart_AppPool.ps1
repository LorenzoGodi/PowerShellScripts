$pools = Get-IISAppPool

# Define a list of options
$options = $pools | ForEach-Object {$_.Name}

# Display the options to the user
for ($i = 0; $i -lt $options.Count; $i++) {
    Write-Host "$($i + 1): $($options[$i])"
}

# Prompt the user to select an option
$selectionIndex = Read-Host "Enter the number of the AppPool you want to restart"

# Convert the input to an integer and select the corresponding option
$selection = $options[$selectionIndex - 1]

Write-Host ""

# Stop AppPool
$appPool = Get-IISAppPool -Name $selection
if ($appPool.State -eq "Stopped") {
    # If the app pool is stopped, start it
    Start-WebAppPool -Name $selection
    Write-Host "AppPool '$selection' has been started."
} elseif ($appPool.State -eq "Started") {
    # If the app pool is already running, restart it
    Restart-WebAppPool -Name $selection
    Write-Host "AppPool '$selection' has been restarted."
} else {
    Write-Host "AppPool '$selection' is in an unknown state: $($appPool.State)"
}

# Done
Read-Host "All done!"

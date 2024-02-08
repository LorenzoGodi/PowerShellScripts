$OutputDir = 'C:\'


Function Get-IP ($hn) {
    try {
        ([System.Net.Dns]::GetHostAddresses($hn)).IPAddressToString
    }
    catch {
        'X'
    }
}


$WindowsServers = Get-ADComputer -Filter 'OperatingSystem -like "*windows server*"'


$tab = @()
for ($i = 0; $i -lt $WindowsServers.Length; $i++){
    $tab += [PSCustomObject]@{
        hostname = $WindowsServers[$i].name
        ipadd = Get-IP($WindowsServers[$i].name)
    }
    Write-Progress -activity "Getting all servers..." -status "Completed: $i of $($WindowsServers.Length)" -percentComplete (($i / $WindowsServers.Length)  * 100)
}
$tab | Export-Csv -Path ($OutputDir + 'GetWinSer.csv') -NoTypeInformation

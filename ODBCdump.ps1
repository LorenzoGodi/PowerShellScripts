$outputFolder = "C:\"

#"Driver","APILevel","FileUsage,"Setup","ConnectFunctions","CPTimeout","DriverODBCVer","SQLLevel","HelpRootDirectory"
$keys = @("Driver","APILevel","FileUsage","Setup","ConnectFunctions","CPTimeout","DriverODBCVer","SQLLevel","HelpRootDirectory")

$drivers = Get-OdbcDriver | Sort-Object -Property Name

# Columns
$names = New-Object System.Collections.Generic.List[String]
$columns = New-Object System.Collections.Generic.List[PSObject]

$names.Add("Name")
$names.Add("Platform")

$columns.Add(($drivers | ForEach-Object {$_.Name}))
$columns.Add(($drivers | ForEach-Object {$_.Platform}))

foreach ($key in $keys){
    $names.Add($key)
    $columns.Add(($drivers | ForEach-Object {$_.Attribute[$key]}))
}

# Get data
$rows = New-Object System.Collections.Generic.List[PSObject]

for ($i = 0; $i -lt $drivers.Length; $i++){
    $row = New-Object PSObject

    $j = 0
    foreach ($col in $columns){
        $row | Add-Member -NotePropertyName $names[$j++] -NotePropertyValue $col[$i]
    }

    $rows.Add($row)
}

# Export
$rows | Export-Csv -Path ($outputFolder + "ODBC.csv") -NoTypeInformation

$rows | Where-Object {$_.Platform -eq "32-bit"} | Export-Csv -Path ($outputFolder + "ODBC_32.csv") -NoTypeInformation
$rows | Where-Object {$_.Platform -eq "64-bit"} | Export-Csv -Path ($outputFolder + "ODBC_64.csv") -NoTypeInformation

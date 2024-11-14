param (
    [Parameter(Mandatory=$false)] $Path,
    [Parameter(Mandatory=$false)] $Lv = 2
)

# Get path from clipboard if present
$clipAd = ''
if (!$PSBoundParameters.ContainsKey('Path')) {
    $clipAd = '(ClipBoard) '
    $Path = Get-Clipboard

    $clipAd += ' '
}

# Get all acls for main directory
$acls = (Get-Acl $Path).Access | Sort-Object -Property IsInherited

$aclFull = $acls | Where-Object { $_.FileSystemRights -like 'FullControl' }
$aclMody = $acls | Where-Object { $_.FileSystemRights -like '*Modify*' } | Where-Object { $_ -notin $aclFull }
$aclExec = $acls | Where-Object { $_.FileSystemRights -like '*ReadAndExecute*' } | Where-Object { $_ -notin $aclMody }
$aclTrav = $acls | Where-Object { $_ -notin $aclExec -and $_ -notin $aclMody  -and $_ -notin $aclFull }

$types = @('(F)  ', '(M)  ', '(RX) ', '(RD) ')
$arrs = @($aclFull, $aclMody, $aclExec, $aclTrav)

# output is a simple array of strings
$sep = '------   ------   ------   ------   ------   ------'
Write-Host ''
Write-Host $sep
Write-Host "$($clipAd)ACLs for: $($Path)"
Write-Host $sep


# Check for folders with non-canonical acls
Write-Host ''
Write-Host 'Folders with inheritance disabled:'
$noSpecial = $true

# Get all subfolders
$subFolders = Get-ChildItem -Path $Path -Recurse -Depth $Lv -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

# Check
$lvCount = 0
$startingSlashCount = ([regex]::Matches($Path, "\\" )).count
foreach ($sf in $subFolders) {
    # Get all inherited acls for directory
    $acls = (Get-Acl $sf.FullName).Access | Where-Object { $_.IsInherited -eq $true }

    if ($acls -eq $null) {
        $slashCount = ([regex]::Matches($sf.FullName, "\\" )).count
        if ($startingSlashCount -ne $slashCount) {
            $lvCount += $slashCount - $startingSlashCount
            $startingSlashCount = $slashCount
            Write-Host '    ' "[$($lvCount)]"
        }
        Write-Host '    ' $sf.FullName
        $noSpecial = $false
    }
}

if ($noSpecial) {
    Write-Host '    # none #'
}


Write-Host ''

# ACLs
for ($i = 0; $i -lt 4; $i++) {
    Write-Host ''
    foreach ($gp in $arrs[$i]) {
        $inh = '    '
        if ($gp.IsInherited) {
            $inh = '[H] '
        }
       Write-Host $inh $types[$i] $gp.IdentityReference
    }
}

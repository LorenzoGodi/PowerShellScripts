function Get-SimpleAcl {
    param (
        [Parameter(Mandatory=$false)]
        $Path
    )

    # Get path from clipboard if present
    $clipAd = ''
    if (!$PSBoundParameters.ContainsKey('Path')) {
        $clipAd = '(Path from ClipBoard) '
        $Path = Get-Clipboard
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
    $result = @('', "$($clipAd) Acls for:", $Path)

    for ($i = 0; $i -lt 4; $i++) {
        $result += ''
        foreach ($gp in $arrs[$i]) {
            $inh = '    '
            if ($gp.IsInherited) {
                $inh = '[H] '
            }
            $result += $inh + $types[$i] + $gp.IdentityReference
        }
    }


    # Check for folders with non-canonical acls
    $result += ''
    $result += 'Folders with inheritance disabled:'
    $noSpecial = $true

    # Get all subfolders
    $subFolders = Get-ChildItem -Path $Path -Recurse -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

    # Check
    foreach ($sf in $subFolders) {
        # Get all inherited acls for directory
        $acls = (Get-Acl $Path).Access | Where-Object { $_.IsInherited -eq $true }

        if ($acls -eq $null) {
            $result += $sf
            $noSpecial = $false
        }
    }

    if ($noSpecial) {
        $result += '# none #'
    }

    # Return
    return $result
}

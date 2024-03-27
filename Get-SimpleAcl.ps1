function Get-SimpleAcl {
    param (
        [Parameter(Mandatory=$false)]
        $Path
    )

    $clipAd = ''
    if (!$PSBoundParameters.ContainsKey('Path')) {
        $clipAd = '(Path from ClipBoard) '
        $Path = Get-Clipboard
    }

    $acls = (Get-Acl $Path).Access | Sort-Object -Property IsInherited
    
    $aclFull = $acls | Where-Object { $_.FileSystemRights -like 'FullControl' }
    $aclMody = $acls | Where-Object { $_.FileSystemRights -like '*Modify*' } | Where-Object { $_ -notin $aclFull }
    $aclExec = $acls | Where-Object { $_.FileSystemRights -like '*ReadAndExecute*' } | Where-Object { $_ -notin $aclMody }
    $aclTrav = $acls | Where-Object { $_ -notin $aclExec -and $_ -notin $aclMody  -and $_ -notin $aclFull }

    $types = @('(F)  ', '(M)  ', '(RX) ', '(RD) ')
    $arrs = @($aclFull, $aclMody, $aclExec, $aclTrav)

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

    return $result
}

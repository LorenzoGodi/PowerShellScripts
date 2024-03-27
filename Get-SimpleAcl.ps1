function Get-SimpleAcl {
    param (
        [Parameter(Mandatory=$true)]
        $Path
    )

    $acls = (Get-Acl $Path).Access | Sort-Object -Property IsInherited
    
    $aclFull = $acls | Where-Object { $_.FileSystemRights -like 'FullControl' }
    $aclMody = $acls | Where-Object { $_.FileSystemRights -like '*Modify*' } | Where-Object { $_ -notin $aclFull }
    $aclExec = $acls | Where-Object { $_.FileSystemRights -like '*ReadAndExecute*' } | Where-Object { $_ -notin $aclMody }
    $aclTrav = $acls | Where-Object { $_ -notin $aclExec -and $_ -notin $aclMody  -and $_ -notin $aclFull }

    $types = @('(F)  ', '(M)  ', '(RX) ', '(RD) ')
    $arrs = @($aclFull, $aclMody, $aclExec, $aclTrav)

    $result = @()

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

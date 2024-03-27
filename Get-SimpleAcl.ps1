function Get-SimpleAcl {
    param (
        [Parameter(Mandatory=$true)]
        $Path
    )

    $acls = (Get-Acl $Path).Access | Where-Object {$_.IsInherited -eq $false}
    
    $aclFull = $acls | Where-Object { $_.FileSystemRights -like 'FullControl' }
    $aclMody = $acls | Where-Object { $_.FileSystemRights -like '*Modify*' }         | Where-Object { $_ -notin $aclFull }
    $aclExec = $acls | Where-Object { $_.FileSystemRights -like '*ReadAndExecute*' } | Where-Object { $_ -notin $aclMody }
    $aclTrav = $acls | Where-Object { $_.FileSystemRights -like 'FullControl' }      | Where-Object { $_ -notin $aclExec -and $_ -notin $aclMody }

    $types = @('(F)  ', '(M)  ', '(RX) ', '(RD) ')
    $arrs = @($aclFull, $aclMody, $aclExec, $aclTrav)

    $result = @()

    for ($i = 0; $i -lt 4; $i++) {
        $result += ''
        foreach ($gp in $arrs[$i]) {
            $result += $types[$i] + $gp.IdentityReference
        }
    }

    return $result
}

function Get-FoldersAcl {

    param (
        [Parameter(Mandatory=$true)]
        $MainPath,
        [Parameter(Mandatory=$true)]
        $Levels,
        [Parameter(Mandatory=$false)]
        $IgnoreLinkFolders = $true,
        [Parameter(Mandatory=$false)]
        $ReturnCommons = $true,
        [Parameter(Mandatory=$false)]
        $ShowProgress = $true
    )
    
    # Create list of objects representing folders
    $folders = @()

    # Create list of members who own access to all folders
    $aclCommonMembers = @()

    # Get all folders excluding link folders
    $FoldersRaw = Get-ChildItem -Path $MainPath -Directory -Force -ErrorAction SilentlyContinue

    # Remove link folders if not requested
    if ($IgnoreLinkFolders) {
        $FoldersRaw = $FoldersRaw | Where-Object {$_.Mode -notmatch "d----l"}
    }

    # Check if there's actually any folder
    $directoryHasFolders = $FoldersRaw.Length -gt 0

    # If directory contains folders, collect them
    if ($directoryHasFolders) {
        # Get ACLs from a folder
        $aclCommonMembers = (Get-Acl $FoldersRaw[0].PSPath).Access

        # Process them
        for ($i = 0; $i -lt $FoldersRaw.Length; $i++) {
            $folderRaw = $FoldersRaw[$i]

            # Create folder object
            $folder = new-object PSObject
            $folder | Add-Member -NotePropertyName Name -NotePropertyValue $folderRaw.Name
            $folder | Add-Member -NotePropertyName Path -NotePropertyValue $folderRaw.PSPath.Substring($folderRaw.PSPath.IndexOf("::") + 2)

            # Get ACLs
            $folderAcl = (Get-Acl $folder.Path).Access

            if ($ReturnCommons) {
                # Leave in common acls only shared ones
                $aclCommonMembersNew = @()
                foreach ($oldAcl in $aclCommonMembers) {
                    # Tells if acl is still common
                    $stillCommon = $false

                    # If found, boolean becomes true
                    foreach ($fldAcl in $folderAcl) {
                        if ($fldAcl.IdentityReference -eq $oldAcl.IdentityReference) {
                            $stillCommon = $true
                        }
                    }

                    # If found, keep in commons
                    $aclCommonMembersNew += $oldAcl
                }
                $aclCommonMembers = $aclCommonMembersNew
            }

            # Add ACLs
            $folder | Add-Member -NotePropertyName Access -NotePropertyValue $folderAcl

            # If necessary, collect subfolders
            if ($Levels -gt 1) {
                # Get all subfolders
                $subFolders = Get-FoldersAcl -MainPath $folder.Path -Levels ($Levels - 1) -IgnoreLinkFolders $true -ReturnCommons $false -ShowProgress $false

                # Add
                $folder | Add-Member -NotePropertyName Children -NotePropertyValue $subFolders
            }

            # Add object to array
            $folders += $folder
            
            # Write progress
            if ($ShowProgress) {
                Write-Progress -activity "Collecting all folders..." -status "Completed: $i of $($foldersRaw.Length) items scanned" -percentComplete (($i / $foldersRaw.Length)  * 100)
            }
        }
    }
    
    # Order by name
    $folders = $folders | Sort-Object -Property Name

    # Return multiple objects
    $result = new-object PSObject
    $result | Add-Member -NotePropertyName Folders -NotePropertyValue $folders
    $result | Add-Member -NotePropertyName CommonAcls -NotePropertyValue $aclCommonMembers


    # Return
    if ($ReturnCommons) {
        return $result
    } else {
        return $folders
    }
}


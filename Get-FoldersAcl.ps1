$AclCommonMembers = @(
    'NT AUTHORITY\SYSTEM'
    'BUILTIN\Administrators'
)

function Get-FoldersAcl {

    param (
        [Parameter(Mandatory=$true)]
        $MainPath,
        [Parameter(Mandatory=$true)]
        $Levels,
        [Parameter(Mandatory=$false)]
        $IgnoreLinkFolders = $true,
        [Parameter(Mandatory=$false)]
        $ShowProgress = $true
    )
    
    # Create list of objects representing folders
    $folders = @()

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
        # Process them
        for ($i = 0; $i -lt $FoldersRaw.Length; $i++) {
            $folderRaw = $FoldersRaw[$i]

            # Create folder object
            $folder = new-object PSObject
            $folder | Add-Member -NotePropertyName Name -NotePropertyValue $folderRaw.Name
            $folder | Add-Member -NotePropertyName Path -NotePropertyValue $folderRaw.PSPath.Substring($folderRaw.PSPath.IndexOf("::") + 2)

            # Get ACLs
            #Write-Output $folder.Path
            $folderAclCommon = (Get-Acl $folder.Path).Access | Where-Object {$_.IdentityReference -in $AclCommonMembers}
            $folderAclNotCommon = (Get-Acl $folder.Path).Access | Where-Object {$_.IdentityReference -notin $AclCommonMembers}

            # Add ACLs
            $folder | Add-Member -NotePropertyName AccessCommon -NotePropertyValue $folderAclCommon
            $folder | Add-Member -NotePropertyName Access -NotePropertyValue ($folderAclNotCommon | Where-Object {$_.IsInherited -eq $false})
            $folder | Add-Member -NotePropertyName AccessInherited -NotePropertyValue ($folderAclNotCommon | Where-Object {$_.IsInherited -eq $true})

            # If necessary, collect subfolders
            if ($Levels -gt 1) {
                # Get all subfolders
                $subFolders = Get-FoldersAcl -MainPath $folder.Path -Levels ($Levels - 1) -ShowProgress $false

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
    
    # Return
    return ($folders | Sort-Object -Property Name)
}


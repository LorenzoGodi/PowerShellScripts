function Test-PathActive {
    param (
        [Parameter(Mandatory=$true)]
        $Path
    )

    $script = "Test-Path -Path " + $Path
    $ps = [powershell]::create().addscript($script)
    
    # execute it asynchronously
    $handle = $ps.begininvoke()
    
    # wait 4 seconds for it to finish
    if(-not $handle.asyncwaithandle.waitone(4000)){
        return $false
    }
    
    # waitone() returned $true, let's fetch the result
    $result = $ps.endinvoke($handle)
    
    return $result
}

function Get-FoldersAcl {
    param (
        [Parameter(Mandatory=$true)]
        $MainPath,
        [Parameter(Mandatory=$true)]
        $IsDFS,
        [Parameter(Mandatory=$true)]
        $Levels
    )

    $ScpProgressActivity = "Collecting all folders. Arm yourself with patience..."
    $scpProgressIndex = -1
    $scpProgressTotal = -1
    $scpProgressPercent = 0
    $scpProgressScan = ""

    return Get-FoldersAclRec -MainPath $MainPath -IsDFS $IsDFS -Levels $Levels -ReturnCommons $true
}

function Get-FoldersAclRec {
    param (
        [Parameter(Mandatory=$true)]
        $MainPath,
        [Parameter(Mandatory=$true)]
        $IsDFS,
        [Parameter(Mandatory=$true)]
        $Levels,
        [Parameter(Mandatory=$true)]
        $ReturnCommons
    )

    $ImRoot = $scpProgressIndex -eq -1
    
    # Create list of objects representing folders
    $folders = @()

    # Create list of members who own access to all folders
    $aclCommonMembers = @()

    # Get all folders excluding link folders
    $FoldersRaw = Get-ChildItem -Path $MainPath -Directory -Force -ErrorAction SilentlyContinue

    # Remove link folders if not dfs
    if (!$IsDFS) {
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

            # Get name and path
            $folderName = $folderRaw.Name
            $folderPath = $folderRaw.PSPath.Split("::")[-1]

            # Update main progress values if root function
            if ($ImRoot) {
                $scpProgressIndex = $i + 1
                $scpProgressTotal = $FoldersRaw.Length
                $scpProgressPercent = ($scpProgressIndex / $scpProgressTotal)  * 100
            }
            
            # Write progress
            $strStatus = "$($scpProgressIndex - 1) of $scpProgressTotal folders scanned."
            $strStatus += " Now scanning: $folderPath"
            Write-Progress -activity $ScpProgressActivity -status $strStatus -percentComplete $scpProgressPercent

            if ($IsDFS) {
                # Obtained path was dfs
                $folder | Add-Member -NotePropertyName LinkName -NotePropertyValue $folderName
                $folder | Add-Member -NotePropertyName LinkPath -NotePropertyValue $folderPath

                # Get Target folder
                $folderTargets = Get-DfsnFolderTarget -Path $folderPath | Where-Object {$_.State -eq "Online"} | ForEach-Object {$_.TargetPath} | Select -Unique

                # Effective paths
                $folder | Add-Member -NotePropertyName DFSPaths -NotePropertyValue $folderTargets

                # Set one effective path for getting acls
                #$folderPathMissing = $true
                #$i = -1
                #while ($folderPathMissing) {
                #    $folderPathMissing = -not (Test-PathActive -Path $folderTargets[++$i])
                #}
                #$folderPath = $folderTargets[$i]
                $folderPath = $folderTargets[0]

                # Set effective name
                $folderName = $folderPath.Split("\")[-1]
            }

            # Effective name and path
            $folder | Add-Member -NotePropertyName Name -NotePropertyValue $folderName
            $folder | Add-Member -NotePropertyName Path -NotePropertyValue $folderPath

            # Get ACLs
            $folderAcl = (Get-Acl $folder.Path).Access

            #
            $subAclCommonMembers = @()

            # If necessary, collect subfolders
            if ($Levels -gt 1) {
                # Get all subfolders
                $subReturns = Get-FoldersAclRec -MainPath $folder.Path -IsDFS $false -Levels ($Levels - 1)

                # Add
                $folder | Add-Member -NotePropertyName Children -NotePropertyValue $subReturns.folders

                # Leave in common acls only shared ones
                $aclCommonMembers = $aclCommonMembers| Where-Object {$_.IdentityReference -in ($subReturns.CommoncAcls | Select -Property IdentityReference)}
            }

            # Filter
            if ($ReturnCommons) {
                # Leave in common acls only shared ones
                $aclCommonMembers = $aclCommonMembers | Where-Object {$_.IdentityReference -in ($folderAcl | Select -Property IdentityReference)}
            }

            # Add ACLs
            $folder | Add-Member -NotePropertyName Access -NotePropertyValue $folderAcl

            # Add object to array
            $folders += $folder
        }
    }
    
    # Order by name
    $folders = $folders | Sort-Object -Property Name

    # Return
    if ($ReturnCommons) {
        # Return multiple objects
        $result = new-object PSObject
        $result | Add-Member -NotePropertyName Folders -NotePropertyValue $folders
        $result | Add-Member -NotePropertyName CommoncAcls -NotePropertyValue $aclCommonMembers

        return $result
    } else {
        return $folders
    }
}


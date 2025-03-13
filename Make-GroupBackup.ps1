
function Get-UserArray {
    # Initialise the user array
    $userArray = @()

    # Define the OUs to search
    $OUs = @(
    "OU=Users,OU=1343,OU=1200-1399,OU=Expert-Store,OU=NO,OU=Expert-Mgmt,DC=expert,DC=local", # 1343
    "OU=Users,OU=1344,OU=1200-1399,OU=Expert-Store,OU=NO,OU=Expert-Mgmt,DC=expert,DC=local", # 1344
    "OU=Users,OU=1345,OU=1200-1399,OU=Expert-Store,OU=NO,OU=Expert-Mgmt,DC=expert,DC=local" # 1345"
)

    # Loop over each OU
    foreach ($OU in $OUs) {
        # Get all userobjects in the OU
        $users = Get-ADUser -Filter * -SearchBase $OU -SearchScope Subtree -Properties MemberOf,Enabled

        foreach ($user in $users) {
            if ($user.Enabled -eq $true) {
            $userArray += [PSCustomObject]@{
                UserName = $user.Name
                SamAccountName = $user.SamAccountName
                MemberOf = $user.MemberOf
                }
            }
        } 
    }
    return $userArray
}

function Save-GroupMembership {
    param ($groupInfo, $username)

    # Create the output file path
    $csvPath = "C:\temp\group_backup\$username`_GroupMembership.csv"

    # Export the group information to a CSV file
    try {
        $groupInfo | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    }
    catch {
        Write-Error "Failed to export group membership to CSV file: $_"
    }
    Write-Host "`nGroup membership for $username has been exported to $csvPath" -ForegroundColor Green
}

function Get-GroupMembership {
    param ($username)
    
    # Get the user object
    $user = Get-ADUser -Identity $username -Properties MemberOf
    
    # Get all groups the user is a member of
    $groups = $user.MemberOf | ForEach-Object {
        Get-ADGroup -Identity $_ -Properties Name, Description
    }
    
    # Create an array to hold the group information
    $groupInfo = @()
    
    # Populate the array with group details
    foreach ($group in $groups) {
        $groupInfo += [PSCustomObject]@{
            GroupName = $group.Name
            Description = if ($group.Description) { $group.Description } else { "N/A" }
        }
    }
    
    # Sort the groups alphabetically by name
    $groupInfo = $groupInfo | Sort-Object GroupName
    
    return $groupInfo
}

function Main {
    # Initialise counter
    $counter = 0

    $userArray = Get-UserArray
    foreach ($user in $userArray) {
        if ($null -ne $user.MemberOf) {
            # Increment counter
            $counter++
            # Get group membership
            $groupInfo = Get-GroupMembership -username $user.SamAccountName
            # Save group membership to CSV file
            Save-GroupMembership -groupInfo $groupInfo -username $user.SamAccountName
        }
    }
    Write-Output "Total users with group memberships: $counter"
}

Main
function Select-User {
    param ($username)
    $user = Get-ADUser -Identity $username -Properties Name,Mail,Enabled,Title,Description,Office,Department,DistinguishedName
    # Show user information
    Write-Host "`nName: $($user.Name)" -ForegroundColor DarkYellow
    Write-Host "Mail: $($user.Mail)" -ForegroundColor DarkYellow
    Write-Host "Enabled: $($user.Enabled)" -ForegroundColor DarkYellow
    Write-Host "Title: $($user.Title)" -ForegroundColor DarkYellow
    Write-Host "Description: $($user.Description)" -ForegroundColor DarkYellow
    Write-Host "Office: $($user.Office)" -ForegroundColor DarkYellow
    Write-Host "Department: $($user.Department)" -ForegroundColor DarkYellow
    Write-Host "DistinguishedName: $($user.DistinguishedName)`n" -ForegroundColor DarkYellow

        # Confirm user information
        $confirm = Read-Host "Is this the correct user account '$username'? (y/N)"
        if ($confirm -ne "y") {
            return $false
        }
        else {
            return $true
        }
}

function Get-GroupMembership {
    param ($username)
    
    # Get the user object
    $user = Get-ADUser -Identity $username -Properties MemberOf
    
    # Get all groups the user is a member of
    $groups = $user.MemberOf | ForEach-Object {
        Get-ADGroup -Identity $_ -Properties Name
    }
    
    # Create an array to hold the group information
    $groupInfo = @()
    
    # Populate the array with group details
    foreach ($group in $groups) {
        $groupInfo += [PSCustomObject]@{
            GroupName = $group.Name
        }
    }
    
    # Sort the groups alphabetically by name
    $groupInfo = $groupInfo | Sort-Object GroupName
    
    return $groupInfo
}

function Save-GroupMembership {
    param ($groupInfo, $username)

    # Create the output file path
    $csvPath = "C:\temp\$username`_GroupMembership.csv"

    # Export the group information to a CSV file
    try {
        $groupInfo | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    }
    catch {
        Write-Error "Failed to export group membership to CSV file: $_"
    }
    Write-Host "`nGroup membership for $username has been exported to $csvPath" -ForegroundColor Green
}



function Main {
    
    while ($true) {
        #Prompt for the username
        $username = Read-Host "Write the username of the user account`nOr type (exit) to exit >> "
    
        # Check if the user wants to exit
        if ($username -eq "exit") {
            break
        }

        # Check if the user was selected
        try {
            $userSelected = Select-User -username $username
            if ($userSelected -eq $true) {
                Write-Host "`nUser account '$username' has been selected" -ForegroundColor Green
                
                $groupInfo = Get-GroupMembership -username $username
                if ($null -ne $groupInfo) {
                    Save-GroupMembership -groupInfo $groupInfo -username $username
                }

            } else {
                Write-Host "`nUser account '$username' was not selected." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Error "An error occurred: $_"
        }
    }
}

Main
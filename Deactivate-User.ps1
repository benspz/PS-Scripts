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
        $confirm = Read-Host "Do you want to disable the user account '$username'? (y/N)"
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

    # Create timespamp variable
    $timestamp = (Get-Date).ToString("yyyyMMdd")
    
    # Check if you can access potet02
    if (Test-Path -Path "\\nooslpotet02\It\User Groups BACKUP\") {
        # If true save csv to potet02
        $csvPath = "\\nooslpotet02\It\User Groups BACKUP\$username`_GroupMembership_$timestamp`.csv"
    }
    else { # Else save to local temp folder.
        $csvPath = "C:\temp\$username`_GroupMembership_$timestamp`.csv"
    }
    

    # Export the group information to a CSV file
    try {
        $groupInfo | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    }
    catch {
        Write-Error "Failed to export group membership to CSV file: $_"
    }
    Write-Host "`nGroup membership for $username has been exported to $csvPath" -ForegroundColor Green
}


function Remove-GroupMemberships {
    param ($groupInfo, $username)

    # Remove the user from all groups
    foreach ($group in $groupInfo) {
        Remove-ADGroupMember -Identity $group.GroupName -Members $username -Confirm:$false
    }
    Write-Host "`nUser account '$username' has been removed from all groups." -ForegroundColor Green
}

function Clear-UserAttributes {  # Add attribute backup functionality
    param ($username)

    # Create list of attributes to clear
    $attributes = @("title", "manager", "physicalDeliveryOfficeName", "department", "mobile", "telephoneNumber", "description", "extensionAttribute2", "extensionAttribute3",
                    "extensionAttribute4", "extensionAttribute5", "extensionAttribute6", "extensionAttribute7", "extensionAttribute8",
                    "extensionAttribute9", "extensionAttribute12", "extensionAttribute13", "extensionAttribute14", "extensionAttribute15")
    
    # Clear each attribute
    foreach ($attribute in $attributes) {
        Set-ADUser -Identity $username -Clear $attribute
    }
}

function Disable-UserAccount {
    param ($username)
    
    # Disable the user account
    Disable-ADAccount -Identity $username

    Write-Host "`nUser account '$username' has been disabled and moved to the Disabled Users OU." -ForegroundColor Green
}

function Move-UserAccount {
    param ($username)
    
    # Get the users distinguished name
    $user = Get-ADUser -Identity $username
    if ($user) {
        $distinguishedName = $user.DistinguishedName

        try {
            # Move the user account to the Disabled Users OU
            Move-ADObject -Identity $distinguishedName -TargetPath "OU=Disabled Users,DC=expert,DC=local"
            Write-Host "`nUser account '$username' has been moved to the Disabled Users OU." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to move user account '$username': $_"
        }
    }
}

function Main {

    # Main loop to select and disable user accounts
    while ($true) {

        # Prompt for the username
        $username = Read-Host "Write the username of the user account to disable`nOr type (exit) to exit >> "
        
        # Check if the user wants to exit
        if ($username -eq "exit") {
            break
        }

        # Check if the user was selected
        try {
            $userSelected = Select-User -username $username
            if ($userSelected -eq $true) {
                Write-Host "`nUser account '$username' has been selected and will be disabled." -ForegroundColor Green
                
                # Main functionality to disable the user account
                $groupInfo = Get-GroupMembership -username $username
                if ($null -ne $groupInfo) {
                    Save-GroupMembership -groupInfo $groupInfo -username $username
                    Remove-GroupMemberships -groupInfo $groupInfo -username $username
                }
                Clear-UserAttributes -username $username
                Disable-UserAccount -username $username
                Move-UserAccount -username $username

            } else {
                Write-Host "`nUser account '$username' was not selected." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Error "An error occurred: $_"
        }
    }
}

# Call the main function
Main
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

function Import-GroupsFromCsv {

    $csvPath = Read-Host "Enter path to csv file: "

    if (Test-Path -Path $csvPath) {
        $groups = Import-Csv -Path $csvPath -Header GroupName
        return $groups
    }
    Write-Error "Can't find csv"
}

function Add-Groups {
    param($groups, $username)

    $counter = 0
    try {
        foreach ($group in $groups) {
            Add-ADGroupMember -Identity $group.GroupName -Members $username
            Write-Host "$($username) added to group: $($group.GroupName)"
            $counter++
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
    Write-Host "$($counter) groups added to $($username)"
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
                
                $groups = Import-GroupsFromCsv
                Write-Host "`nGroups imported" -ForegroundColor Green

                Add-Groups -groups $groups -username $username

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
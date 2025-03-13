# Function to search for members of an Active Directory group
function Search-ADGroup {
    param (
        [string]$Group  # The name of the AD group to search
    )
    # Initialise empty array to store results
    $results = @()
    $userObjects = @()

    # Get members of the specified AD group
    $members = Get-ADGroupMember -Identity $Group
    foreach ($member in $members) {
        # Check if the member is a user
        if ($member.objectClass -eq 'user') {
            # Retrieve user properties using the distinguished name (DN)
            $user = Get-ADUser -Identity $member.DistinguishedName -Properties DisplayName,EmailAddress,Title,Mobile,Enabled
            # Check if the user is enabled
            if ($user.Enabled -eq $true) {
                $userObjects += $user
            }
        }
    }

    # Populate the results array with user details
    foreach ($user in $userObjects) {
        $results += [PSCustomObject]@{
            Name = $user.DisplayName
            Email = $user.EmailAddress
            Title = $user.Title
            Mobile = $user.Mobile
            Enabled = $user.Enabled
        }
    }
    return $results
}

# Initialize a flag to control the loop
$continue = $true

# Loop to repeatedly prompt the user for an AD group name
while ($continue) {
    Clear-Host  # Clear the console screen
    Write-Host "Search and List Member(s) of AD Groups"
    Write-Host "Enter the AD group name to search (or type 'exit' to quit)"
    [string]$Group = Read-Host  # Read the group name from user input

    if ($Group -eq 'exit') {
        $continue = $false  # Exit the loop if the user types 'exit'
    }
    else {
        try {
            # Search for the group members and display the results in a table
            $results = Search-ADGroup -Group $Group
            $results | Format-Table -AutoSize
            
            # Check if any members were found
            if ($results.Count -eq 0) {
                Write-Host "No members found in the group or the group doesn't exist."
            }
            else {
                Write-Host "Total members: $($results.Count)"
            }
        }
        catch {
            # Display an error message if an exception occurs
            Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
        }

        Write-Host "`nPress Enter to continue..."
        Read-Host  # Pause to allow the user to read the results
    }
}

# Uncomment the following lines if you want the script to wait for user input before closing
# Write-Host "Script is exiting. Press Enter to close."
# Read-Host
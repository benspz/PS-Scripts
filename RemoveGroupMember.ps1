# Ensure the Active Directory module is loaded
Import-Module ActiveDirectory

# Define the AD group name
$groupName = "group_name"

# List of usernames to remove
$usernames = @(
    ...
)

# Attempt to remove each user from the group
foreach ($username in $usernames) {
    try {
        Remove-ADGroupMember -Identity $groupName -Members $username -Confirm:$false -ErrorAction Stop
        Write-Output "Removed $username from $groupName"
    } catch {
        Write-Warning "Failed to remove $username : $_"
    }
}

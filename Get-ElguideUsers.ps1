# Define the OUs to search
$OUs = @(
    ...
)

# Initialise counter
$counter = 0

# Loop over each OU
foreach ($OU in $OUs) {
    # Get all users in the OU
    $users = Get-ADUser -Filter * -SearchBase $OU -Properties Name, extensionAttribute11, EmployeeID | Where-Object {$_.extensionAttribute11}

    foreach ($user in $users) {
        $counter++
            
        # Write the output to a CSV file
        $csvOutput = [PSCustomObject]@{
            Name = $user.Name
            Elguide = $user.extensionAttribute11
        }
        $csvOutput | Export-Csv -Append -Path C:\temp\elguide_users.csv -NoTypeInformation -Encoding "utf8"
    }
}
Write-Output "Total users with extension attribute 11: $counter"
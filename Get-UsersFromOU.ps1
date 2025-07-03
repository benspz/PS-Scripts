# Define the OUs to search
$OUs = @(
    
)

# Initialise counter
$counter = 0

# Loop over each OU
foreach ($OU in $OUs) {
    # Get all users in the OU
    $users = Get-ADUser -Filter * -SearchBase $OU -SearchScope OneLevel -Properties Name, SamAccountName, Description, extensionAttribute9

    foreach ($user in $users) {
        $counter++
            
        # Write the output to a CSV file
        $csvOutput = [PSCustomObject]@{
            Name = $user.Name
            SamAccountName = $user.SamAccountName
            Description = $user.Description
            ExtensionAttribute9 = $user.extensionAttribute9
        }
        $csvOutput | Export-Csv -Append -Path C:\temp\users.csv -NoTypeInformation -Encoding "utf8"
    }
}
Write-Output "Total users: $counter"
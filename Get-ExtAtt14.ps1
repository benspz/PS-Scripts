# Define the OUs to search
$OUs = @(
    "DC=expert,DC=local"
)

# Define the extension attributes to check
$extensionAttribute = "extensionAttribute14"

# Initialise counter
$counter = 0

# Loop over each OU
foreach ($OU in $OUs) {
    # Get all users in the OU
    $users = Get-ADUser -Filter * -SearchBase $OU -SearchScope Subtree -Properties $extensionAttribute

    foreach ($user in $users) {
        $attr = $user.$extensionAttribute

        if ($null -ne $attr) {
            $counter++
            
            # Write the output to a CSV file
            $csvOutput = [PSCustomObject]@{
                SamAccountName = $user.SamAccountName
                ExtensionAttribute = $attr
            }
            $csvOutput | Export-Csv -Append -Path C:\temp\ext_att14.csv -NoTypeInformation -Encoding "utf8"
        }
    }
}
Write-Output "Total users with extension attribute 14: $counter"
# Path to the CSV file
$csvPath = "C:/temp/ext_att14.csv"

# Import the CSV file
$users = Import-Csv -Path $csvPath

# Initialise counter
$counter = 0

# Iterate over csv
foreach($user in $users) {
    # Increment counter
    $counter++

    # Split on , and trim whitespace from either sides
    $strippedExtAtt14 = $user.ExtensionAttribute.Split(",")[-1].Trim()


    # Write the output to a CSV file
    $csvOutput = [PSCustomObject]@{
        UserName = $user.UserName
        SamAccountName = $user.SamAccountName
        ExtensionAttribute = $strippedExtAtt14
    }
    $csvOutput | Export-Csv -Append -Path C:\temp\stripped_ext_att14.csv -NoTypeInformation
}

Write-Host "Changed $($counter) attributes"
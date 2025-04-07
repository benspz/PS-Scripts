# Import csv file
$csvPath = "C:\temp\stripped_ext_att14.csv"
$users = Import-Csv -Path $csvPath

# Initialise variables
$successcount = 0
$failurecount = 0
$failedusers = @()

# Main loop
foreach ($user in $users) {
    try {  # Change attribute and record successes
        Set-ADUser -Identity $user.SamAccountName -Replace @{
            ExtensionAttribute14 = $user.ExtensionAttribute
        }
        $successcount++
    }
    catch { # Record failures
        $failurecount++
        $failedusers += $user.SamAccountName
        Write-Host "Error processing user $_" -ForegroundColor Red
    }
}

# Export failures to csv and report total changes
$failedusers | Export-Csv -Path "C:\temp\failed_user_changes.csv"
Write-Host "$($successcount) users where changed successfully" -ForegroundColor Green
Write-Host "`n$($failurecount) users failed" -ForegroundColor Red
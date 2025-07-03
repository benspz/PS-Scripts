$users = @( )



$counter = 0
$successcount = 0
$failurecount = 0
$failedusers = @()


foreach ($user in $users) {

    $counter++

    try {  # Change attribute and record successes
        Set-ADUser -Identity $user -Clear ExtensionAttribute6
        $successcount++
    }
    catch { # Record failures
        $failurecount++
        $failedusers += $user
        Write-Host "Error processing user $_" -ForegroundColor Red
    }
}

Write-Host "-------------------------"
Write-Host "Total users processed: $counter"
Write-Host "Successful: $successcount"
Write-Host "Failed: $failurecount"

if ($failedusers.Count -gt 0) {
    Write-Host "Failed Users:" -ForegroundColor Yellow
    $failedusers | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
}
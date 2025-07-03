# Set the OU for searchbase
$OU = "OU=Expert-Store,OU=NO,OU=Expert-Mgmt,DC=expert,DC=local"

# Set Store Number variable
$storeNumber = 1620

# Get all the users with a specific storenumber in extensionAttribute9
$users = Get-ADUser -Filter { extensionAttribute9 -eq $storeNumber } -SearchBase $OU -Properties * | Where-Object {$_.EmployeeID}

# Find users by role
$owner = $users | Where-Object {$_.extensionAttribute12 -in @("Owner")}
$dailyManager = $users | Where-Object {$_.extensionAttribute12 -in @("DailyManager")}
$storeManager = $users | Where-Object {$_.extensionAttribute12 -in @("StoreManager", "StoreManager1")}
 
# Set variable for Manager's Manager
$AndersNormandbo = "CN=Anders Normandbo,OU=Lorenskog,OU=Users,OU=NOOSL,OU=Admin-HQ,OU=NO,OU=Expert-Mgmt,DC=expert,DC=local"

Write-Host "Total users found: $($users.Count)"
Write-Host "Owners: $($owner.Count), DailyManagers: $($dailyManager.Count), StoreManagers: $($storeManager.Count)"


# Assign managers according to hierarchy
foreach ($user in $users) {
    $role = $user.extensionAttribute12

    switch -Wildcard ($role) {
        "Owner" {
            Set-ADUser -Identity $user.SamAccountName -Manager $AndersNormandbo
        }

        "DailyManager" {
            if ($owner.Count -gt 0) {
                Set-ADUser -Identity $user.SamAccountName -Manager $owner[0].DistinguishedName
            }
            else {
                Set-ADUser -Identity $user.SamAccountName -Manager $AndersNormandbo
            }
        }

        "StoreManager*" {
            if ($dailyManager.Count -gt 0) {
                Set-ADUser -Identity $user.SamAccountName -Manager $dailyManager[0].DistinguishedName
            }
            elseif ($owner.Count -gt 0) {
                Set-ADUser -Identity $user.SamAccountName -Manager $owner[0].DistinguishedName
            }
            else {
                Set-ADUser -Identity $user.SamAccountName -Manager $AndersNormandbo
            }
        }

        default {
            if ($storeManager.Count -gt 0) {
                Set-ADUser -Identity $user.SamAccountName -Manager $storeManager[0].DistinguishedName
            }
            elseif ($dailyManager.Count -gt 0) {
                Set-ADUser -Identity $user.SamAccountName -Manager $dailyManager[0].DistinguishedName
            }
            elseif ($owner.Count -gt 0) {
                Set-ADUser -Identity $user.SamAccountName -Manager $owner[0].DistinguishedName
            }
        }
    }
}
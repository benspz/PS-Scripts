# Requires ImportExcel Module

function Update-Manager {
    param ($users, $owner, $dailyManager, $storeManager, $managersManager)
    # Assign managers according to hierarchy
    foreach ($user in $users) {
        $role = $user.extensionAttribute12

        switch -Wildcard ($role) {
            "Owner" {
                Set-ADUser -Identity $user.SamAccountName -Manager $managersManager.DistinguishedName
            }

            "DailyManager" {
                if ($owner.Count -gt 0) {
                    Set-ADUser -Identity $user.SamAccountName -Manager $owner[0].DistinguishedName
                }
                else {
                    Set-ADUser -Identity $user.SamAccountName -Manager $managersManager.DistinguishedName
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
                    Set-ADUser -Identity $user.SamAccountName -Manager $managersManager.DistinguishedName
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
    Write-Host "Total users found: $($users.Count)"
    Write-Host "Owners: $($owner.Count), DailyManagers: $($dailyManager.Count), StoreManagers: $($storeManager.Count)"
}

function Get-UserLists {
    param($storeNumber, $OU, $managersManagerEmail)

    # Get all the users with a specific storenumber in extensionAttribute9
    $users = Get-ADUser -Filter "extensionAttribute9 -eq '$storeNumber'" -SearchBase $OU -Properties * | Where-Object {$_.EmployeeID}

    # Find users by role
    $owner = $users | Where-Object {$_.extensionAttribute12 -in @("Owner")}
    $dailyManager = $users | Where-Object {$_.extensionAttribute12 -in @("DailyManager")}
    $storeManager = $users | Where-Object {$_.extensionAttribute12 -in @("StoreManager", "StoreManager1")}
    
    $managersManager = Get-ADUser -Filter "EmailAddress -eq '$managersManagerEmail'" -Properties *

    return [PSCustomObject]@{
        Users = $users
        Owner = $owner
        DailyManager = $dailyManager
        StoreManager = $storeManager
        ManagersManager = $managersManager
    }
}

function Get-HashTable {

    # Define file paths
    $excelFiles = @(
        "C:\Users\305079\Desktop\testfile.xlsx"
    )

    $hashTable = @{}

    # Loop over each excel file
    foreach ($file in $excelFiles) {

        # Get data from first worksheet in current file
        $data = Import-Excel -Path $file -WorksheetName (Get-ExcelSheetInfo -Path $file)[0].Name

        # Loop over each row
        foreach ($row in $data) {
            # Skip rows with null values
            if ($null -eq $row.StoreCode -or $null -eq $row.ManagersManager) {
                # Write-Warning "Missing data in file '$file': StoreCode='$($row.StoreCode)', ManagersManager='$($row.ManagersManager)'"
                continue
            }
            # Append StoreCode/ManagersManager to hashtable as key/value
            $hashTable[$row.StoreCode] = $row.ManagersManager
        }
    }
    return $hashTable
}


function Main {

    # Set the OU for searchbase
    $OU = "OU=Expert-Store,OU=NO,OU=Expert-Mgmt,DC=expert,DC=local"

    $hashTable = Get-HashTable

    foreach ($key in $hashTable.Keys) {

        $storeNumber = $key
        $managersManagerEmail = $hashTable[$key]

        $data = Get-UserLists -storeNumber $storeNumber -OU $OU -managersManagerEmail $managersManagerEmail

        Update-Manager -users $data.Users -owner $data.Owner -dailyManager $data.DailyManager -storeManager $data.StoreManager -managersManager $data.ManagersManager
    }
}

Main

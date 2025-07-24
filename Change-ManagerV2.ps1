# Requires ImportExcel Module
# Run the command below if you don't have the module installed
# Install-Module ImportExcel

# Initialize list for Log objects
$global:ManagerUpdateLog = @()

function Update-Manager {
    param ($users, $owner, $dailyManager, $storeManager, $managersManager)

    # Initialize counter
    $counter = 0

    # Assign managers according to hierarchy
    foreach ($user in $users) {
        $role = $user.extensionAttribute12
        $originalManagerDN = $user.Manager
        $originalManager = if ($originalManagerDN) { Get-ADUser -Identity $originalManagerDN } else { $null }
        $newManager = $null

        # Checks role and assigns correct manager
        switch -Wildcard ($role) {
            "Owner" {
                $newManager = $managersManager
            }

            "DailyManager" {
                if ($owner.Count -gt 0) {
                    $newManager = $owner[0]
                }
                else {
                    $newManager = $managersManager
                }
            }

            "StoreManager*" {
                if ($dailyManager.Count -gt 0) {
                    $newManager = $dailyManager[0]
                }
                elseif ($owner.Count -gt 0) {
                    $newManager = $owner[0]
                }
                else {
                    $newManager = $managersManager
                }
            }

            default {  # Regular store employees
                if ($storeManager.Count -gt 0) {
                    $newManager = $storeManager[0]
                }
                elseif ($dailyManager.Count -gt 0) {
                    $newManager = $dailyManager[0]
                }
                elseif ($owner.Count -gt 0) {
                    $newManager = $owner[0]
                }
            }
        }
        if ($newManager) {
            # Only updates manager if newManager and originalManager are different
            if ($originalManagerDN -ne $newManager.DistinguishedName) {
                $counter += 1
                Set-ADUser -Identity $user.SamAccountName -Manager $newManager.DistinguishedName

                Write-Host "Updating $($user.SamAccountName)" -ForegroundColor Green

                # Add to log object
                $global:ManagerUpdateLog += [PSCustomObject]@{
                    StoreNumber = $user.extensionAttribute9
                    User = $user.SamAccountName
                    Role = $user.extensionAttribute12
                    OldManager = if ($originalManager) { $originalManager.SamAccountName } else { $null }
                    NewManager = $newManager.SamAccountName
                }
            }
        }
    }
    # Informational output, mostly for debugging, but it's nice to see I guess
    Write-Host "`nTotal users found: $($users.Count)"
    Write-Host "Owners: $($owner.Count), DailyManagers: $($dailyManager.Count), StoreManagers: $($storeManager.Count)"
    Write-Host "Total users updated: $($counter)"
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

    # Checks if log directory exists and creates one if not
    $logDir = "C:\Logs"
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force
    }

    # Set the OU for searchbase
    $OU = "OU=Expert-Store,OU=NO,OU=Expert-Mgmt,DC=expert,DC=local"

    # Creates hashtable with storenumbers as keys and manager's manager as value
    $hashTable = Get-HashTable

    # Main logic
    # For each storecode in the table it gets a list of users and updates managers if neccessary
    foreach ($key in $hashTable.Keys) {

        $storeNumber = $key
        $managersManagerEmail = $hashTable[$key]

        $data = Get-UserLists -storeNumber $storeNumber -OU $OU -managersManagerEmail $managersManagerEmail

        Write-Host "`nProcessing store: $storeNumber (Manager's Manager': $managersManagerEmail)`n" -ForegroundColor Cyan

        Update-Manager -users $data.Users -owner $data.Owner -dailyManager $data.DailyManager -storeManager $data.StoreManager -managersManager $data.ManagersManager
    }

    # Creates logfile
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $logPath = "C:\Logs\ManagerUpdate_$timestamp.csv"
    $global:ManagerUpdateLog | Export-Csv -Path $logPath -NoTypeInformation -Encoding utf8

    Write-Host "`nLog exported to $logPath" -ForegroundColor Yellow
}

Main

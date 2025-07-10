# Requires ImportExcel Module

# Define file paths
$excelFiles = @(
    "C:\Users\305079\Desktop\ServiceConsept_Roller_NO - Copy.xlsx"
)

# Initialize hash table
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

# For testing
$hashTable.GetEnumerator() | Sort-Object Name

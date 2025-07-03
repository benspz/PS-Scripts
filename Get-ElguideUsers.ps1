Import-Module ActiveDirectory

$users = Get-ADUser -Filter * -SearchBase "OU=Expert-Mgmt,DC=expert,DC=local" -Properties extensionAttribute11, Surname, GivenName


$filteredUsers = @()

foreach ($user in $users) {
    if ($null -ne $user.extensionAttribute11) {
        $filteredUsers += $user
    }
}


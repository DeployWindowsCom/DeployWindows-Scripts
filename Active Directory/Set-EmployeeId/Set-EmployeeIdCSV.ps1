try
{
    $Users = Import-Csv -Path employeeid.csv
} 
Catch [Exception]
{
    Write-Host "Error reading CSV file" -BackgroundColor Red
    break;
}


foreach ($user in $users.GetEnumerator())
{
#    Write-Host "Looking for $($user.samaccount) to set $($user.employeeid)"

    $sam = $user.samaccount
    $Identity = Get-ADUser -Properties EmployeeId -Filter {(SamAccountName -like $sam ) -and (ObjectClass -eq "user")} 

    try {
        Set-ADUser -Identity $Identity -EmployeeID $user.employeeid
        Write-Host "EmployeeID was set for $($user.samaccount)"
    }
    Catch [Exception] 
    {
        Write-Host "Error setting employeeId for $($user.samaccount)" -BackgroundColor Red
    }
}

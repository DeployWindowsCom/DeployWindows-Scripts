# Translate the S-1-5-32-544 (.\Administrators) SID to a group name, the name varies depending on the language version of Windows.
$sid2 = 'S-1-5-32-544'
$objSID2 = New-Object System.Security.Principal.SecurityIdentifier($sid2)
$localadminsgroup = (( $objSID2.Translate([System.Security.Principal.NTAccount]) ).Value).Split("\")[1]

# Add the users that should be in the group
$accounts = @("AzureAD\account1@domain.com","AzureAD\account2@domain.com")

# Add the security principal name to the local administrators group. (used old style of adding group members due to compatibility reasons)

try {
    foreach ($account in $accounts) {
        Write-Host "Adding security principal: $($account) to the $($localadminsgroup) group..."

        net localgroup $localadminsgroup $account /add            
    }
}
Catch {
    write-host $_.Exception.Message
}
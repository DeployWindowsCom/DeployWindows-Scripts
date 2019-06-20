# Translate the S-1-5-32-544 (.\Administrators) SID to a group name, the name varies depending on the language version of Windows.
$sid2 = 'S-1-5-32-544'
$objSID2 = New-Object System.Security.Principal.SecurityIdentifier($sid2)
$localadminsgroup = (( $objSID2.Translate([System.Security.Principal.NTAccount]) ).Value).Split("\")[1]

# Translate the S-1-5-4 (NT AUTHORITY\Interactive) SID to an account name, the name varies depending on the language version of Windows.
$sid1 = 'S-1-5-4'
$auth = New-Object System.Security.Principal.SecurityIdentifier($sid1) 
$interactive = $auth.Translate([System.Security.Principal.NTAccount])


# Add the security principal name to the local administrators group. (used old style of adding group members due to compatibility reasons)

try {
    Write-Host "Adding security principal: $interactive to the $localadminsgroup group..."

    net localgroup $localadminsgroup $interactive /delete
}
Catch {
    write-host $_.Exception.Message
}
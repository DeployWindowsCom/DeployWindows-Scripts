$excludeUsers = @( 
        "Administratör", 
        "username1")

# Translate the S-1-5-32-544 (.\Administrators) SID to a group name, the name varies depending on the language version of Windows.
$sid = 'S-1-5-32-544'
$objSID = New-Object System.Security.Principal.SecurityIdentifier($sid)
$localadminsgroup = (( $objSID.Translate([System.Security.Principal.NTAccount]) ).Value).Split("\")[1]

$group = [ADSI]("WinNT://$($env:COMPUTERNAME)/$($localadminsgroup),group")
foreach ($user in $group.Members() )
{
    $adsPath = $user.GetType().InvokeMember('Adspath', 'GetProperty', $null, $user, $null)
    $username = $adsPath.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)[-1]
    $domain = $adsPath.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)[-2]

    if ($excludeUsers -contains $username)
    {
        Write-Host "Do not remove $($username)"
    }
    elseif ($domain -ne "WinNT:")
    {
        Write-Host "Remove the user $($username)"
        try
        {
            $group.Remove("WinNT://$($env:COMPUTERNAME)/$($domain)/$($username)")
        }
        catch
        {
            Write-Host "Trying to remove user $($username) $($_.Exception.Message)" -BackgroundColor Red
        }
    }
}

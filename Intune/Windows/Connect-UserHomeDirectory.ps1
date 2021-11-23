# Connects home directory with H: by creating registry settings under HKCU\Network\H
# It featches dynamically the home diretory attribute from on-premes AD if a domain controller is accessible
# To be used as a Proative Remediation script, this is the remediation script
# Remember to run the script using the logged-on user

$domainControllers = @("dc1.deploywindows.com", "dc2.deploywindows.com")

$domainPath = "dc=ad,dc=deploywindows,dc=com"
$registryPath = "HKCU:\Network\H"

$homeDirectoryConnected = $false
$ErrorExitCode = 100
$message = ""

$username = $env:USERNAME
if ($null -eq $username) {
	$username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.split('\')[1]
}

foreach ($dc in $domainControllers) {
    $message += "Trying to connect $($dc)..`n"

    #TCP Port 636 for LDAPs and 389 for LDAP
    if (((Test-NetConnection -ComputerName $dc -Port 636).TcpTestSucceeded -eq $true) -or 
        ((Test-NetConnection -ComputerName $dc -Port 389).TcpTestSucceeded -eq $true)) {
        try {
            $message += "Connected to DC, searching for user, $($username), in path $($domainPath)..`n"
            $domainInfo = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($dc)/$($domainPath)")
            $ad = New-Object System.DirectoryServices.DirectorySearcher($domainInfo)
            $ad.Filter = "(&(ObjectCategory=user)(samaccountname=$($username)))"
            $user = $ad.FindOne()

            if ($null -eq $user) {
                $message += "Found nothing, was looking for $($whoAmI)`n"
                $ErrorExitCode = 404
            
            } else {
                if ($null -eq $user.Properties.homedirectory) {
                    $message += "User's home directory is empty, removing drive`n"
                    if ((Get-Item -Path $registryPath -ErrorAction SilentlyContinue)) { 
                        Remove-Item -Path $registryPath -Force | Out-Null
                    }
                } else {
                    # Adding registry settings for drive mapping
                    if (-not (Get-Item -Path $registryPath -ErrorAction SilentlyContinue)) { 
                        $message += "Creating registry path $($registryPath)`n"
                        New-Item -Path $registryPath -ItemType Registry -Force | Out-Null
                    }

                    New-ItemProperty -Path $registryPath -Name "ConnectionType" -PropertyType DWORD -Value 1 -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name "DeferFlags" -PropertyType DWORD -Value 4 -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name "ProviderType" -PropertyType DWORD -Value 0x20000 -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name "ProviderName" -PropertyType STRING -Value "Microsoft Windows Network" -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name "UserName" -PropertyType STRING -Value "" -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name "RemotePath" -PropertyType STRING -Value $user.Properties.homedirectory -Force | Out-Null

                    $message += "Path added for $($user.Properties.homedirectory)`n"
                }
                $homeDirectoryConnected = $true
            }

        } catch [Exception] {

            $message += "Something wrong looking up user: $($_.Exception.Message)`n"
            $ErrorExitCode = 200

        }       
    } else {
        $message += "Cannot connect to $($dc) over TCP port 636 or 389`n"
        $ErrorExitCode = 300

    }
    if ($homeDirectoryConnected) { break; }
}

Write-Output $message
if ($homeDirectoryConnected) {
    #Exit with standard exit code 0 - if home directory is connected
    Exit 0 

} else {
    #Exit with non standard exit code - if home directory is NOT connected
    Exit $ErrorExitCode

}

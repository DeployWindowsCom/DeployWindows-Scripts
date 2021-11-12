$domainControllers = @("dc1.deploywindows.com", "dc2.deploywindows.com")

$domainPath = "dc=ad,dc=deploywindows,dc=com"
$registryPath = "HKCU:\Network\H"

$homeDirectoryConnected = $false
$ErrorExitCode = 100

foreach ($dc in $domainControllers) {
    Write-Host "Trying to connect $($dc).."

    #TCP Port 636 for LDAPs and 389 for LDAP
    if (((Test-NetConnection -ComputerName $dc -Port 636).TcpTestSucceeded -eq $true) -or 
        ((Test-NetConnection -ComputerName $dc -Port 389).TcpTestSucceeded -eq $true)) {
        try {
            Write-Host "Connected to DC, searching for user, $($env:USERNAME), in path $($domainPath).."
            $domainInfo = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($dc)/$($domainPath)")
            $ad = New-Object System.DirectoryServices.DirectorySearcher($domainInfo)
            $ad.Filter = "(&(ObjectCategory=user)(samaccountname=$($env:USERNAME)))"
            $user = $ad.FindOne()

            if ($null -eq $user) {
                Write-Host "Found nothing, was looking for $($whoAmI)"
                $ErrorExitCode = 404

            
            } else {
                if ($null -eq $user.Properties.homedirectory) {
                    Write-Host "User's home directory is empty, removing drive"
                    if ((Get-Item -Path $registryPath -ErrorAction SilentlyContinue)) { 
                        Remove-Item -Path $registryPath -Force | Out-Null
                    }
                } else {
                    # Adding registry settings for drive mapping
                    if (-not (Get-Item -Path $registryPath -ErrorAction SilentlyContinue)) { 
                        Write-Host "Creating registry path $($registryPath)"
                        New-Item -Path $registryPath -ItemType Registry -Force | Out-Null
                    }

                    New-ItemProperty -Path $registryPath -Name "ConnectionType" -PropertyType DWORD -Value 1 -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name "DeferFlags" -PropertyType DWORD -Value 4 -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name "ProviderType" -PropertyType DWORD -Value 0x20000 -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name "ProviderName" -PropertyType STRING -Value "Microsoft Windows Network" -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name "UserName" -PropertyType STRING -Value "" -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name "RemotePath" -PropertyType STRING -Value $user.Properties.homedirectory -Force | Out-Null

                    Write-Host "Path added for $($user.Properties.homedirectory)"
                }
                $homeDirectoryConnected = $true
            }

        } catch [Exception] {

            Write-host "Something wrong looking up user: $($_.Exception.Message)"
            $ErrorExitCode = 100

        }       
    } else {
        Write-Host "Cannot connect to $($dc) over TCP port 636 or 389"
        $ErrorExitCode = 101

    }
    if ($homeDirectoryConnected) { break; }
}

if ($homeDirectoryConnected) {
    #Exit with standard exit code 0 - if home directory is connected
    Exit 0 

} else {
    #Exit with non standard exit code - if home directory is NOT connected
    Exit $ErrorExitCode

}

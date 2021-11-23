# Connects home directory with H: by creating registry settings under HKCU\Network\H
# To be used as a Proative Remediation script, this is the detection script
# Remember to run the script using the logged-on user


$domainControllers = @("dc1.deploywindows.com", "dc2.deploywindows.com")

$domainPath = "dc=ad,dc=deploywindows,dc=com"
$registryPath = "HKCU:\Network\H"

$errorExitCode = 100
$message = ""

$username = $env:USERNAME
if ($null -eq $username) {
	$username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.split('\')[1]
}

foreach ($dc in $domainControllers) {
    $message += "Trying to connect $($dc)...."

    #TCP Port 636 for LDAPs and 389 for LDAP
    if (((Test-NetConnection -ComputerName $dc -Port 636).TcpTestSucceeded -eq $true) -or 
        ((Test-NetConnection -ComputerName $dc -Port 389).TcpTestSucceeded -eq $true)) {
            #if connection to DC is successful, return ERROR to run remediation

            try {
                $message += "Connected to $($dc), searching for user, $($username), in path $($domainPath).."
                $domainInfo = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($dc)/$($domainPath)")
                $ad = New-Object System.DirectoryServices.DirectorySearcher($domainInfo)
                $ad.Filter = "(&(ObjectCategory=user)(samaccountname=$($username)))"
                $user = $ad.FindOne()
    
                if ($null -eq $user) {
                    $message += "Found nothing, was looking for $($whoAmI).."
                    $errorExitCode = 404
                    
                } else {
                    if ($null -eq $user.Properties.homedirectory) {
                        if ((Get-Item -Path $registryPath -ErrorAction SilentlyContinue)) { 
                            $message += "User's home directory is empty and registry exists, exit with ERROR.."
                            $errorExitCode = 200

                        } else {
                            $message += "User's home directory is empty and NO registry exist, exit with SUCCESS .."
                            $errorExitCode = 0

                        }
                    } else {
                        # home directory found
                        if (-not (Get-Item -Path $registryPath -ErrorAction SilentlyContinue)) { 
                            # nothing in registry is found
                            $message += "User's home directory found but registry is NOT found, exit with error.."
                            $errorExitCode = 300

                        } else {
                            # registry for home directory is found
                            if ($null -eq (Get-ItemProperty -Path $registryPath).RemotePath) { 
                                # Path to home directory is empty
                                $message += "User's home directory found but registry remotePath is empty, exit with error.."
                                $errorExitCode = 400

                            } else {
                                # Path to home directory is NOT empty
                                if ((Get-ItemProperty -Path $registryPath).RemotePath -eq $user.Properties.homedirectory) {
                                    # Everything fine, AD and Registy is equal
                                    $message += "User's home directory found AND registry remotePath is EQUAL, exit with SUCCESS.."
                                    $errorExitCode = 0
    
                                } else {
                                    # Nothing is fine, AD and Registy is NOT equal
                                    $message += "User's home directory found AND registry remotePath is found but NOT EQUAL, exit with error.."
                                    $errorExitCode = 500
    
                                }
                            }
                        }
                    }
                }

            } catch [Exception] {
                $message += "Something is wrong looking up dc/user: $($_.Exception.Message).."
                $ErrorExitCode = 600
    
            }

    } else {
        $message += "Cannot connect to $($dc) over TCP port 636 or 389.."
        
        if ((Get-Item -Path $registryPath -ErrorAction SilentlyContinue)) { 
            $message += "Drive mapping exist in registry.."
            # Drive mapping in registry found, return OK
            $errorExitCode = 0

        } else {
            $message += "Drive mapping does not exist in registy, $($registryPath).."
            # Drive mapping in registry NOT found, return ERROR to run remediation
            $errorExitCode = 700

        }

    }
    if ($errorExitCode -eq 0) { break; }
}

$message += "Exit with code $($errorExitCode)"
Write-Output $message
Exit $errorExitCode

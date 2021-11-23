#Version history
#   0.1 MA  First version

$logFile = "$($env:temp)\MEM_Install-RestrictDriverInstallationToAdministrators.log"
$message = ""
$errorExitCode = 100


# Add registry to allow standard users to install printers
#HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint\
#RestrictDriverInstallationToAdministrators DWORD = 0
$test = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint\" -Name RestrictDriverInstallationToAdministrators -ErrorAction SilentlyContinue
if ($test) {
    try { 
        $message += "RestrictDriverInstallationToAdministrators already configured removing..`n"
        $errorExitCode = 0
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint\" -Name RestrictDriverInstallationToAdministrators -Value 0 -PropertyType DWORD -Force -ErrorAction Stop
    } catch {
        $message += "Error while removing RestrictDriverInstallationToAdministrators registry $($_.Exception.Message)`n"
        $message | Out-File -FilePath $logFile
        $errorExitCode = 200
    }
} else {
    $message += "RestrictDriverInstallationToAdministrators does not exist`n"
    $message | Out-File -FilePath $logFile
    $errorExitCode = 0
}

$message += "Exit with code $($errorExitCode)"
Write-Host $message
$message | Out-File -FilePath $logFile
Exit $errorExitCode

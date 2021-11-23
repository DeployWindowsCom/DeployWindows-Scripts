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
    $message += "RestrictDriverInstallationToAdministrators already configured `n"
    $message | Out-File -FilePath $logFile
    $errorExitCode = 0
} else {
    try { 
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint\" -Force -ErrorAction Stop
        New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint\" -Name RestrictDriverInstallationToAdministrators -Value 0 -PropertyType DWORD -Force -ErrorAction Stop
        $message += "RestrictDriverInstallationToAdministrators configured`n"
        $message | Out-File -FilePath $logFile
        $errorExitCode = 0
    } catch {
        $message += "Error while adding RestrictDriverInstallationToAdministrators registry $($_.Exception.Message)`n"
        $message | Out-File -FilePath $logFile
        $errorExitCode = 200
    }
}

$message += "Exit with code $($errorExitCode)"
Write-Host $message
$message | Out-File -FilePath $logFile
Exit $errorExitCode

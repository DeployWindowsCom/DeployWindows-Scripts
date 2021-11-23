#Version history
#   0.1 MA  First version

#region Main script

$Printer = "\\server01.domain.com\IntuneTest"
$message = ""
$errorExitCode = 0

if (Get-Printer -Name $Printer) {
    # Printer is installed
    $message += "Printer installed`n"

} else {
    $message += "Printer NOT installed`n"
    $errorExitCode = 100
    
}

Write-Host $message
Exit $errorExitCode

#endregion Main script
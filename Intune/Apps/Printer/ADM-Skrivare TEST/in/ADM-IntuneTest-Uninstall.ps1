#Version history
#   0.2 MA  Added ErrorAction Stop for catch to work

#region Main script

$Printer = "\\server01.domain.com\IntuneTest"
$message = ""
$errorExitCode = 0

# Adding printer
try {
    Remove-Printer -ConnectionName $Printer -ErrorAction Stop
    $message += "Printer removed `n"    
    $errorExitCode = 0
}
catch {
    $message += "Error during removing printer $($_.Exception.Message)`n"
    $errorExitCode = 100
}

Write-Host $message
Exit $errorExitCode

#endregion Main script
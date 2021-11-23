#Version history
#   0.4 MA  Added ErrorAction Stop for catch to work and log settings for PointAndPrinter
#   0.6 MA  Test logic updated with TcpTestSucceeded

#region Main script

$Printer = "\\server01.domain.com\IntuneTest"
$message = ""
$errorExitCode = 0
$logFile = "$($env:temp)\MEM_Install-printer.log"

# Checking if print server is possible to reach
$test = (Test-NetConnection -ComputerName $($printer.split('\')[2]) -CommonTCPPort SMB)
if ($test.TcpTestSucceeded -eq $true) { 
    $message += "Successfull connection to print server $($printer.split('\')[2])`n"
    $message | Out-File -FilePath $logFile

    # Adding printer
    try {
        Add-Printer -ConnectionName $Printer -ErrorAction Stop
        $message += "Printer added, hold script for 5 min to validate successfull installation `n"
        $message | Out-File -FilePath $logFile

        #Wait for printer to get installed or 5 minutes (60*5 = 300 seconds = 30 sec * 10 counts)
        $count = 0
        do {
            $message += "Waiting for installation count $($count) `n"
            $message | Out-File -FilePath $logFile
            Start-Sleep -Seconds 30
            $count++
        } until (((@(Get-Printer -Name $Printer -ErrorAction SilentlyContinue)).Count -ge 1) `
            -or ($count -ge 10))

        if ((@(Get-Printer -Name $Printer -ErrorAction SilentlyContinue)).Count -ge 1) {
            $message += "Printer is installed"
            $message | Out-File -FilePath $logFile
            $errorExitCode = 0

        } else {
            $message += "Printer is NOT installed"
            $message | Out-File -FilePath $logFile
            $errorExitCode = 200

        }
    }
    catch {
        $message += "Error during installing printer, permission? `nMessage`t $($_.Exception.Message)`nMessageId`t$($_.Exception.nMessageId)"
        $message += "HKLM\..\PointAndPrint: $(Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint\' -ErrorAction SilentlyContinue)"
        $message += "HKCU\..\PointAndPrint: $(Get-ItemProperty 'HKCU:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint\' -ErrorAction SilentlyContinue)"
        $message | Out-File -FilePath $logFile
        $errorExitCode = 300
    }

} else { 
    $message += "Failed connection to print server $($printer.split('\')[2])`n"
    $message | Out-File -FilePath $logFile
	$errorExitCode = 100

}

$message += "Exit with code $($errorExitCode)"
Write-Host $message
$message | Out-File -FilePath $logFile
Exit $errorExitCode

#endregion Main script
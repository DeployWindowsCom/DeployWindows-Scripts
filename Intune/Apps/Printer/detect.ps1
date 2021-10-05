
$PrintDriverName = "RICOH PCL6 UniversalDriver V4.10"
$Printer = "\\server.domain.com\printer01"

# Checking print driver
if (@(Get-PrinterDriver -Name $PrintDriverName).Count -le 0) { 
	Write-Host "No print driver installed"
	Exit 1
} else {
	Write-Host "Print driver installed"
}

# Adding printer
if (@(Get-Printer -Name $printer).Count -le 0) { 
	Write-Host "No printer installed"
	Exit 2
} else {
	Write-Host "Printer installed"
}

Exit 0
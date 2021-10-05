
$Printer = "\\server.domain.com\printer01"
$PrintDriverName = "RICOH PCL6 UniversalDriver V4.10"

# Remove print driver
Remove-PrinterDriver -Name $PrintDriverName 

# Removing printer
Remove-Printer -ConnectionName $Printer

Exit 0

#Checks if any event occured the last 3 minutes
#Exit with 0 if there is more than 1 event

$Date = (Get-Date).AddMinutes(-3)
if ((Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'; StartTime=$Date; Id='208' }).Count -ge 1) {
	Write-Host "0"
	Exit 0
} else {
	write-host "1"
	Exit 1
}

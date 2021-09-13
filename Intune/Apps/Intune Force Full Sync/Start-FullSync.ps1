
Start-Transcript -Path "$($env:Temp)\ForceSync.log" -Force

Write-Output "Trigger Intune full sync Scheduled task"
Get-ScheduledTask -TaskName "Schedule #3 created by enrollment client" | Start-ScheduledTask

Write-Output "Trigger full sync of IME, Intune Management Extension"
$Shell = New-Object -ComObject Shell.Application
$Shell.open("intunemanagementextension://syncapp")

Write-Output "Sleep for a while, might take a small while until it logs the sync event"
Start-Sleep -Seconds 90

Stop-Transcript

Write-Host "Always exit successfully"
Exit 0

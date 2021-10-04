
$StartTime = (Get-Date).AddDays(-14)
$appEvents = @(Get-WinEvent -ErrorAction SilentlyContinue -FilterHashtable @{Logname="System"; ProviderName="Display"; EventId="4101"; StartTime=$StartTime})
#$appEvents.Count

$errorCount = 0
foreach ($appEvent in $appEvents) {
        $errorCount++
}

if ($errorCount -gt 0)
{
    Write-Host "$($errorCount)`tCrashes for application found" -BackgroundColor Red
#    Exit $errorCount
}
else
{
    Write-Host "No crasches found"
#    Exit 0
}


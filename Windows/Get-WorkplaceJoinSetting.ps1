
#Get values for workplace join settings
$registryPath = "HKLM:\Software\Policies\Microsoft\Windows\WorkplaceJoin"
if(!(Test-Path $registryPath)) {
    Write-Host "Policy not set ($($registryPath)) - workplace join is enabled"
} else {
    if ((Get-Item -Path $registryPath).Property.contains("autoWorkplaceJoin")) {
        Write-Host "autoWorkplaceJoin is set to: $(Get-ItemPropertyValue -Path $registryPath -Name "autoWorkplaceJoin")"
    } else {
        Write-Host "Policy not set ($($registryPath)). These values are set: $((Get-Item -Path $registryPath).Property)"
    }
}



#Remove the "local SCP" for controlled validation
#https://docs.microsoft.com/en-us/azure/active-directory/devices/hybrid-azuread-join-control
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\AAD"
$Name = @("TenantId", "TenantName")
Remove-ItemProperty $registryPath $Name[0] -Force | Out-Null
Remove-ItemProperty $registryPath $Name[1] -Force | Out-Null

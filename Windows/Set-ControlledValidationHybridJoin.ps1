#Configure "local SCP" for controlled validation
#https://docs.microsoft.com/en-us/azure/active-directory/devices/hybrid-azuread-join-control
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\AAD"
$Name = @("TenantId", "TenantName")
$value = @("TENANTID", "domain.onmicrosoft.com")

if(!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}
New-ItemProperty -Path $registryPath -Name $name[0] -Value $value[0] -PropertyType String -Force | Out-Null
New-ItemProperty -Path $registryPath -Name $name[1] -Value $value[1] -PropertyType String -Force | Out-Null


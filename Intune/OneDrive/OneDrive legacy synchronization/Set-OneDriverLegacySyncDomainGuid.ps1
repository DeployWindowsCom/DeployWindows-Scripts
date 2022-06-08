# This script will set a registry key to allow OneDrive to synchronize to legacy domain settings

# Get domain GUID with the following PS command
#    Get-ADDomain -Current LocalComputer
$script:DomainGUID = "aaaaaaaa-2222-1111-0000-aaaaaaaa"
$script:RegistryPath = "HKLM:\Software\Policies\Microsoft\OneDrive"

if (Test-Path -Path $script:RegistryPath) {
    Write-Host "$($RegistryPath) exists, set the domain Guid.."
} else {
    Write-Host "$($RegistryPath) does not exist, create the path and set the Guid.."
    New-Item -ItemType directory -Path $script:RegistryPath -Force
}

Set-ItemProperty -Path $script:RegistryPath -Name "AADJMachineDomainGuid" -Value $DomainGUID -Force


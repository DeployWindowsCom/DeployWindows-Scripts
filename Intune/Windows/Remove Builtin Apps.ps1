<#PSScriptInfo

.VERSION 1.0

.GUID 

.AUTHOR Mattias Fors

.COMPANYNAME DeployWindows.com

.COPYRIGHT 

.TAGS Windows Intune Remove Apps Appx AppxPackages Automation PowerShell 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
Version 1.0:  Original

#>

<#
.SYNOPSIS
Remove specified built-in apps from Windows

.DESCRIPTION
This script will try to remove the specified apps from the running Windows 10 target machine


.EXAMPLE

#>

#Use this command to list all appx package
# Get-AppxPackage -PackageTypeFilter Bundle -AllUsers | Select-Object -Property Name, PackageFullName | Sort-Object -Property Name

$AppsList = @(
  "Microsoft.XboxApp",
  "Microsoft.SkypeApp",
  "Microsoft.MicrosoftOfficeHub",
  "Microsoft.Getstarted",
  "Microsoft.WindowsFeedbackHub",
  "Microsoft.GetHelp",
  "Microsoft.Messaging",
  "Microsoft.MicrosoftSolitaireCollection",
  "Microsoft.Office.OneNote",
  "Microsoft.OneConnect",
  "Microsoft.Wallet",
  "Microsoft.ZuneMusic",
  "Microsoft.ZuneVideo",
  "Microsoft.WindowsCommunicationsApps"
)

ForEach ($App in $AppsList) {
  Write-Host "Removing $($App)"

  $PackageFullName = Get-AppxPackage -Name $App | Select-Object -ExpandProperty PackageFullName -First 1
  $ProPackageFullName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App } | Select-Object -ExpandProperty PackageName -First 1
  Write-Host "$($PackageFullName) - $($ProPackageFullName)"

 # This will attempt to remove the appx package
  if ($PackageFullName -ne $null) {
    try {
      Write-Host "Removing Package: $($PackageFullName)"
      Remove-AppxPackage -Package $PackageFullName -ErrorAction Stop | Out-Null
    }
    catch [System.Exception] {
      Write-Host "Removing AppxPackage '$($PackageFullName)' failed: $($_.Exception.Message)"
    }
  }
  else {
    Write-Host "Unable to locate AppxPackage: $($PackageFullName)"
  }

 # This will attempt to remove the provision package
  if ($ProPackageFullName -ne $null) {
    try {
      Write-Host "Removing AppxProvisioningPackage: $($ProPackageFullName)"
      Remove-AppxProvisionedPackage -PackageName $ProPackageFullName -Online -ErrorAction Stop | Out-Null
    }
    catch [System.Exception] {
      Write-Host "Removing AppxProvisioningPackage '$($ProPackageFullName)' failed: $($_.Exception.Message)"
    }
  }
  else {
    Write-Host "Unable to locate AppxProvisioningPackage: $($ProPackageFullName)"
  }
} 


<#PSScriptInfo

.VERSION 1.0

.GUID 

.AUTHOR Mattias Fors

.COMPANYNAME DeployWindows.com

.COPYRIGHT 

.TAGS Windows Intune Printer Automation PowerShell 

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
Automatically install shared printer from a Windows print server

.DESCRIPTION
This script will add a shared printer


.EXAMPLE

#>


$Printer = "\\printserver.deploywindows.com\PRINTER-SHARED-NAME"

try {
  Add-Printer -ConnectionName $Printer
  Write-Host "Printer added: $($Printer)"
}
Catch [System.Exception] {
  Write-Host "Error adding printer $($Printer) with error $($_.Exception.Message)"
}


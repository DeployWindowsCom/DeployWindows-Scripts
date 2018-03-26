<#PSScriptInfo

.VERSION 1.0

.GUID 

.AUTHOR Mattias Fors

.COMPANYNAME DeployWindows.com

.COPYRIGHT 

.TAGS Windows Intune Computername Serialnumber

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
Set Computername to serial number
.DESCRIPTION
This script uses WMI to retrieve the serial number from Win32_Bios and renames the computer
.EXAMPLE
.\Set-ComputerNameToSN.ps1

#>

Begin {
    $SerialNumber = $null;
    $ComputerName = $null;
}

Process
{
    $SerialNumber = (Get-WmiObject Win32_BIOS -Property SerialNumber).SerialNumber

    if ($SerialNumber) {
        Write-Host "I found this serial number $($SerialNumber)"
        $ComputerName = $SerialNumber.Replace("\","").Replace("/","").Replace(":","").Replace("*","").Replace("?","").Replace("`"","").Replace("<","").Replace(">","").Replace("|","")
    
        if ($ComputerName.Length -gt 15) {
            $ComputerName = $SerialNumber.SubString(0,15)
        }
        Write-Host "After some translation, this is the computername I want to set: $($ComputerName)"
    }
}

End {
    if ($ComputerName) {
        #Rename-Computer -NewName $ComputerName
        Write-Host "Computer name is now changed"
    }
}


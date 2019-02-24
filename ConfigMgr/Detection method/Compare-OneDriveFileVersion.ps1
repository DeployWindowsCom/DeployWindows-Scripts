<#PSScriptInfo

.VERSION 1.0

.GUID 

.AUTHOR Mattias Fors

.COMPANYNAME DeployWindows.com

.COPYRIGHT 

.TAGS Windows OneDrive ConfigMgr SCCM Configuration Manager PowerShell

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
Use this for detection method for upgrading OneDrive for Business
Check the version of OneDrive.exe towards a target version

.DESCRIPTION
This will check the file version of %localappdata%\Microsoft\OneDrive\OneDrive.exe
If version is less than specified target version, return nothing, else return $true
Will log to C:\Windows\Logs\OneDriveDetection.log
Use this as an alterative to detection method in Microsoft deployment package
    URL: https://docs.microsoft.com/en-us/onedrive/deploy-on-windows

.EXAMPLE

#>
$OneDriveTargetVersion = [Version]"18.091.0506"

[String]$LogfileName = "OneDriveDetection"
[String]$Logfile = "$env:SystemRoot\logs\$LogfileName.log"
Function Write-Log
{
	Param ([string]$logstring)
	If (Test-Path $Logfile)
	{
		If ((Get-Item $Logfile).Length -gt 2MB)
		{
			Rename-Item $Logfile $Logfile".bak" -Force
		}
	}
	$WriteLine = (Get-Date).ToString() + " " + $logstring
	Add-content $Logfile -value $WriteLine
}

$User = gwmi win32_computersystem -Property Username
$UserName = $User.UserName
$UserSplit = $User.UserName.Split("\")
$OneDrive = "$env:SystemDrive\users\" + $UserSplit[1] +"\appdata\local\microsoft\onedrive\onedrive.exe"
# Parameter to Log
Write-Log "Start Script Execution"
Write-Log "Logged on User: $UserName"
Write-Log "Detection-String: $OneDrive"
If(Test-Path $OneDrive)
{
	Write-Log "Found DetectionFile"
	$OneDriveFile = Get-Item $OneDrive
	Write-Log "Get File Details"
	Write-Log "Version found:$($OneDriveFile.VersionInfo.FileVersion)"
	Write-Log "Script Exectuion End!"
    Write-Log "Comparing version to $($OneDriveTargetVersion)"
    $OneDriveVersion = [Version]$OneDriveFile.VersionInfo.FileVersion
    if ($OneDriveVersion -le $OneDriveTargetVersion) {
        Write-Log "Warning: Time to upgrade you are running $($OneDriveVersion) and you need higher than $($OneDriveTargetVersion)!"

    } else {
        Write-Log "You are runinng correct version, doing nothing"
	    Write-Log ""
	    Return $true

    }
}
Else
{
	Write-Log "Warning: OneDrive.exe not found – need to install App!"

}

<#PSScriptInfo

.VERSION 1.0

.GUID 

.AUTHOR Mattias Fors

.COMPANYNAME DeployWindows.com

.COPYRIGHT 

.TAGS Windows Intune SID username UPN

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
Get SID, Username or UPN from local registry/WMI

.DESCRIPTION
This will try to figure out the username, sid and UPN of a logon user

Note! This will not work if you are running terminal sessions or enhanced mode in Hyper-V

.EXAMPLE
.\Get-UserInfo.ps1

#>



$username = Gwmi -Class Win32_ComputerSystem | select username
$objuser = New-Object System.Security.Principal.NTAccount($username.username)
$sid = $objuser.Translate([System.Security.Principal.SecurityIdentifier])
$upn = Get-ItemPropertyValue -path HKLM:\SOFTWARE\Microsoft\IdentityStore\Cache\$($sid.value)\IdentityCache\$($sid.value) -Name "UserName"

Write-Host "User information: "
Write-Host $username.username
if ($username.username.IndexOf("\") -gt 0) { Write-Host $username.username.Split("\")[0] }
if ($username.username.IndexOf("\") -gt 0) { Write-Host $username.username.Split("\")[1] }
Write-Host $sid.Value
Write-Host $upn



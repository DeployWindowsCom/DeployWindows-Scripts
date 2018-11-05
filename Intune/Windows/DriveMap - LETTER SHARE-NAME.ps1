<#PSScriptInfo

.VERSION 1.0

.GUID 

.AUTHOR Mattias Fors

.COMPANYNAME DeployWindows.com

.COPYRIGHT 

.TAGS Windows Intune Map DriveLetter Automation PowerShell 

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
Automatically maps drives

.DESCRIPTION
This script will map drives and create network share in NetHood.
The Script will rerun until it is successfull and mapped the drive letter AND created the network share
The script will log information in Event log in the source EventSystem, with ID 10, 11, 12	

.EXAMPLE

#>
$UNC = "\\filserver.deploywindows.com\user$\$($env:USERNAME)"
$Letter = "U"
#$UNC = "\\localhost\admin$"

$ShortcutName = $UNC.Split("\")[$UNC.Split("\").Count -1].Replace("$","")


$WshShell = New-Object -comObject WScript.Shell
$UserNetHood = $WshShell.SpecialFolders("NetHood")

$Script:RetErr = $false


function CreateShortcut ($ShortcutLocation, $TargetPath, $TargetArgs)
{
    Write-Host "Creating shortcut: $($ShortcutLocation), TargetPath: $($TargetPath), TargetArgs: $($TargetArgs)"

    try {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutLocation)
        $Shortcut.TargetPath = $TargetPath
        $Shortcut.Arguments = $TargetArgs
        $Shortcut.Save() 
    }
    catch [System.Exception] {
        $ErrorDesc = "Shortcut error: $($ShortcutLocation) ($($_.Exception.Message))"
        Write-Host $ErrorDescr
        Write-EventLog -LogName "Application" -Source "EventSystem" -EventId 11 -Message $ErrorDescr -EntryType Error 

    	$Script:RetErr = $True
    }
}

function CreateDriveMap ($DriveLetter, $UNCPath)
{
    Write-Host "Creating drive map: $($DriveLetter), UNCPath: $($UNCPath)"

    try {
        New-PSDrive -Name $DriveLetter -PSProvider "FileSystem" -Root $UNCPath -Persist -Scope Global -ErrorAction Stop
#        Old style mapping
#        $WshNet = New-Object -comObject WScript.Network
#        $WshNet.RemoveNetworkDrive($DriveLetter)
#        $WshNet.MapNetworkDrive($DriveLetter, $UNCPath)
    }
    catch [System.Exception] {
        $ErrorDescr = "Drive map error: $($UNCPath) ($($_.Exception.Message)"
        Write-Host $ErrorDescr
        Write-EventLog -LogName "Application" -Source "EventSystem" -EventId 12 -Message $ErrorDescr -EntryType Error 

    	$Script:RetErr = $True
    }
    if (Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue) {
        Write-Host "Drive exists"
    }
    else {
        Write-Host "Drive does not exist"
        $Script:RetErr = $true
    }
}

CreateDriveMap $Letter $UNC
CreateShortcut "$($UserNetHood)\$($ShortcutName).lnk" $UNC ""


if ($Script:RetErr -eq $true) {
    $ErrorDescr = "This is a Microsoft Intune Script.`nMapping did not work. $($Letter) = $($UNC)"
	Write-Host $ErrorDescr
    Write-EventLog -LogName "Application" -Source "EventSystem" -EventId 10 -Message $ErrorDescr -EntryType Error 

	Exit 10
}

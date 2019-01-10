<#PSScriptInfo

.VERSION 1.0

.GUID 

.AUTHOR Mattias Fors

.COMPANYNAME DeployWindows.com

.COPYRIGHT 

.TAGS Windows Intune OneDrive Automation Silent

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
Upgrade and automate OneDrive logon for users

.DESCRIPTION
This script will help users to simplify the OneDrive upgrade and logon process


.EXAMPLE
.\Update-OneDrive.ps1

#>

#if the installed version is less than this version, it will initialize an upgrade
$MinimumOneDriveVersion = "18.091.0506"

$OneDriveUserFolder = $env:OneDrive
$OneDriveAppFolder = $null
$OneDriveVersion = $null
$OneDriveRegistryKey = "HKCU:\Software\Microsoft\OneDrive"
$OneDriveRegistryVersion = "Version"
$OneDriveRegistryCurrentVersionPath = "CurrentVersionPath"

#region Restart into 64-bit
$Is64Bit = [System.Environment]::Is64BitProcess;
$Is64OS = $false; if (($env:PROCESSOR_ARCHITEW6432 -like "AMD64") -or ($env:PROCESSOR_ARCHITECTURE -like "AMD64")) { $Is64OS = $true; }

if (($Is64OS) -and (-not $Is64Bit)) {
    # Running AMD64 but no AMD64 Process, Restart script
    $Invocation = $PSCommandPath
    if ($null -eq $Invocation) { return }
    $SysNativePath = $PSHOME.ToLower().Replace("syswow64", "sysnative")
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "$SysNativePath\powershell.exe"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.WindowStyle = "hidden"
    $pinfo.Arguments = "-ex ByPass -file `"$Invocation`" "
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $pinfo
    $proc.Start() | Out-Null
    $proc.WaitForExit()
    $StdErr = $proc.StandardError.ReadToEnd()
    $StdOut = $proc.StandardOutput.ReadToEnd()
    $ExitCode = $proc.ExitCode
    if ($StdErr) { Write-Error -Message "$($StdErr)" }
    Write-Host $ExitCode
    Exit $ExitCode
} elseif ((-not $Is64OS) -and (-not $Is64Bit)) {
    #Running x86 and no AMD64 Process, Do not bother restarting
}
#endregion

#region Main
Start-Transcript -Path (Join-Path $env:TEMP "AutomateOneDrive.log") -Append -Force

if (Test-Path $OneDriveRegistryKey) {
    #Get current version for OneDrive application
    if (Get-ItemProperty -Path $OneDriveRegistryKey -Name $OneDriveRegistryVersion -ErrorAction SilentlyContinue) {
        $OneDriveVersion = Get-ItemPropertyValue -Path $OneDriveRegistryKey -Name $OneDriveRegistryVersion -ErrorAction SilentlyContinue
        Write-Host "Found version: $($OneDriveVersion)"
    } else {
        $OneDriveVersion = $null
        Write-Host "Error getting: $($OneDriveRegistryKey) $($OneDriveRegistryVersion)"
    }

    #Get current path for OneDrive application
    if (Get-ItemProperty -Path $OneDriveRegistryKey -Name $OneDriveRegistryCurrentVersionPath -ErrorAction SilentlyContinue) {
        $OneDriveAppFolder = Get-ItemPropertyValue -Path $OneDriveRegistryKey -Name $OneDriveRegistryCurrentVersionPath -ErrorAction SilentlyContinue
        Write-Host "Found Folder $($OneDriveAppFolder)"
    } else {
        $OneDriveAppFolder = $null
        Write-Host "Error getting: $($OneDriveRegistryKey) $($OneDriveRegistryCurrentVersionPath)"
    }
}

Write-Host "OneDrive version: $($OneDriveVersion)"
Write-Host "OneDrive application folder: $($OneDriveAppFolder)"

#Upgrade OneDrive if needed
if ($OneDriveVersion -ge $MinimumOneDriveVersion) {
    Write-Host "OneDrive client is up to date"
} else {
    Write-Host "Intialize an OneDrive upgrade..."
    $filepath =  (Join-Path $env:localappdata "Microsoft\OneDrive\OneDriveStandaloneUpdater.exe")
    if (-not (Test-Path  $filepath)) {
    	Write-Error -Message "The file ($($filepath)) does not exist, exit the script with a exit code to make sure it runs again" -Category OperationStopped
    }
    Start-Process -FilePath $filepath -NoNewWindow -Wait
}

Stop-Transcript
#endregion
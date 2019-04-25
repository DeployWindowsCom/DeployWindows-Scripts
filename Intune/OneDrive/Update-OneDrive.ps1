<#PSScriptInfo

.VERSION 1.1

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
Version 1.1: Updated for to install OneDrive for all users

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
# Release info https://support.office.com/en-us/article/onedrive-release-notes-845dcf18-f921-435e-bf28-4e24b95e5fc0
$MinimumOneDriveVersion = "19.043.0304.0003"

$OneDriveUserFolder = $env:OneDrive
$OneDriveAppFolder = $null
$OneDriveVersion = $null
$OneDriveHKCURegistryKey = "HKCU:\Software\Microsoft\OneDrive"
$OneDriveHKLMRegistryKey = "HKLM:\Software\Microsoft\OneDrive"
$OneDriveRegistryVersion = "Version"
$OneDriveRegistryCurrentVersionPath = "CurrentVersionPath"
$OneDriveDownloadURI = "https://go.microsoft.com/fwlink/?linkid=2083517"

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

# Guessing OneDrive Folder
$OneDriveAppFolder = $null
if (Test-Path (Join-Path $env:localappdata "Microsoft\OneDrive\OneDrive.exe")) {
    $OneDriveAppFolder = (Join-Path $env:localappdata "Microsoft\OneDrive")
} else {
    $OneDriveAppFolder = (Join-Path ${env:ProgramFiles(x86)} "Microsoft OneDrive")
    Write-Host "Found folder $($OneDriveAppFolder)"
}
$OneDriveVersion = (Get-Item $(Join-Path $OneDriveAppFolder "OneDrive.exe")).VersionInfo.ProductVersion

Write-Host "OneDrive version: $($OneDriveVersion)"
Write-Host "OneDrive application folder: $($OneDriveAppFolder)"

#Need to escape these characters \ ( ) 
if ($OneDriveAppFolder -match ((${env:ProgramFiles(x86)}).Replace("\","\\").Replace("(","\(").Replace(")","\)"))) {
    Write-Host "Already installed in Program folder, $($OneDriveAppFolder)"
} else {
    #Upgrade OneDrive if needed
    if ($OneDriveVersion -ge $MinimumOneDriveVersion) {
        Write-Host "OneDrive client is up to date $($OneDriveVersion)"
    } else {
        Write-Host "Intialize an OneDrive upgrade..."
        $filepath =  (Join-Path $env:localappdata "Microsoft\OneDrive\OneDriveStandaloneUpdater.exe")
        if (-not (Test-Path  $filepath)) {
            Write-Error -Message "The file ($($filepath)) does not exist, exit the script with a exit code to make sure it runs again" -Category OperationStopped
        } 
        Start-Process -FilePath $filepath -NoNewWindow -Wait
    }

    $OneDriveVersion = (Get-Item $(Join-Path $OneDriveAppFolder "OneDrive.exe")).VersionInfo.ProductVersion

    #Check if version is updated, and if not already installed in Program files folder
    if ($OneDriveVersion -ge $MinimumOneDriveVersion) {
        Write-Host "OneDrive client is up to date $($OneDriveVersion), we can install in Program folder"
        $OneDriveSetup = $(Join-Path $OneDriveAppFolder "$($OneDriveVersion)\OneDriveSetup.exe")
    } else {
        #Start download 
        Write-Host "Starting download new OneDrive client"
        Invoke-WebRequest -Uri $OneDriveDownloadURI -OutFile (Join-Path "$($env:TEMP)" "OneDriveSetup.exe")
        Write-Host "Initialize OneDriveSetup with allusers argument..."
        $OneDriveSetup = (Join-Path "$($env:TEMP)" "OneDriveSetup.exe")
    }

    Write-Host "Now time to install OneDrive in program folder $($OneDriveSetup) /allusers"
    Start-Process -FilePath $OneDriveSetup -ArgumentList "/allusers" -NoNewWindow
}

Stop-Transcript
#endregion
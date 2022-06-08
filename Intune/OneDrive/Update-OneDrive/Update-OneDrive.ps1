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
Version 1.2: Totally rewritten to only download and install per-machine

#>

<#
.SYNOPSIS
Download lastest and set installation to per-machine OneDrive

.DESCRIPTION
Download lastest and set installation to per-machine OneDrive
Recommendation is to update if running version c

.EXAMPLE
.\Update-OneDrive.ps1

#>

#if the installed version is less than this version, it will initialize an upgrade
# Release info https://support.office.com/en-us/article/onedrive-release-notes-845dcf18-f921-435e-bf28-4e24b95e5fc0
$OneDriveDownloadURI = "https://go.microsoft.com/fwlink/?linkid=844652"

#region Restart into 64-bit
$Is64Bit = [System.Environment]::Is64BitProcess;
$Is64OS = $false; if (($env:PROCESSOR_ARCHITEW6432 -like "AMD64") -or ($env:PROCESSOR_ARCHITECTURE -like "AMD64")) { $Is64OS = $true; }

if (($Is64OS) -and (-not $Is64Bit)) {
    # Running AMD64 but no AMD64 Process, Restart script
    & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"
    Exit $LASTEXITCODE
}
#endregion

#region Main
Start-Transcript -Path (Join-Path $env:TEMP "OneDrive.log") -Append -Force

#Start download 
Write-Host "Starting download latest OneDrive client"
Invoke-WebRequest -Uri $OneDriveDownloadURI -OutFile (Join-Path "$($env:TEMP)" "OneDriveSetup.exe")

Write-Host "Initialize OneDriveSetup with allusers argument..."
$OneDriveSetup = (Join-Path "$($env:TEMP)" "OneDriveSetup.exe")

Write-Host "Now time to install OneDrive in program folder $($OneDriveSetup) /allusers"
$proc = Start-Process -FilePath $OneDriveSetup -ArgumentList "/allusers" -WindowStyle Hidden -PassThru
$proc.WaitForExit()
Write-Host "OneDriveSetup exit code: $($proc.ExitCode)"

# Create a file just so Intune knows this was installed
if (-not (Test-Path "$($env:ProgramData)\Microsoft OneDrive\setup"))
{
    Mkdir "$($env:ProgramData)\Microsoft OneDrive\setup"
}
Set-Content -Path "$($env:ProgramData)\Microsoft OneDrive\setup\Update-OneDrive.ps1.tag" -Value "Installed"


Stop-Transcript
#endregion
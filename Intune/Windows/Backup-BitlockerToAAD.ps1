##############################
#.SYNOPSIS
#  This will backup your BitLocker RecoveryPassword to Azure Active Directory
#
#.EXAMPLE
#
#.NOTES
#
#Version
# 1.0  First release
#
##############################
#Author
#@MattiasFors
#https://deploywindows.com
#https://github.com/DeployWindowsCom/DeployWindows-Scripts
##############################


#region Your content goes here
$ScriptName = $PSCommandPath.Split("\")[$PSCommandPath.Split("\").Count -1];
Start-Transcript -Path "$($env:TEMP)\$($ScriptName).log" -Append -Force


try {
    Backup-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId "1$(@(((Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" })[0]).KeyProtectorId)" -ErrorAction Stop
        
}
catch {
    Write-Error "Failed to backup to AAD"

}


Stop-Transcript
#endregion
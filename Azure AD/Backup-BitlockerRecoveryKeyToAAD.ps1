BackupToAAD-BitLockerKeyProtector -MountPoint C: -KeyProtectorId ((Get-BitLockerVolume c:).KeyProtector | where {$_.KeyProtectorType -eq "RecoveryPassword" }).KeyProtectorId

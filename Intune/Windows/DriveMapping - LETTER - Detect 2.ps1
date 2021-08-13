
# Change only Drive letter here
$DriveLetter = "H"
$Version = "2"

$schtaskName = "Intune-$($DriveLetter) DriveMapping $($Version)"

try {
    if (Get-ScheduledTask $schtaskName -ErrorAction Stop) {
        Write-Host "$($schtaskName) exist"
        exit 0
    }
}
catch {
    Write-Host "$($schtaskName) do NOT exist"
    exit 1
}


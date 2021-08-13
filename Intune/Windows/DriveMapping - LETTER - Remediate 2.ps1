# Change only Drive UNC and letter here
$DriveUNC = "\\server.domain.local\dfs\homefolders\%USERNAME%"
$DriveLetter = "H"
$Version = "2"

$schtaskName = "Intune-$($DriveLetter) DriveMapping $($Version)"
$schtaskDescription = "Map network drives from Intune"
 try {
    $schtaskTrigger = New-ScheduledTaskTrigger -AtLogOn
    # Users in Local group USERS will run this task
    $schtaskPrincipal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -Id "Author"
    $schtaskAction = New-ScheduledTaskAction -Execute "%comspec%" -Argument "/c start /i /min net.exe use $($DriveLetter): `"$($DriveUNC)`" /PERSISTENT:Yes"
    $schtaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    
    $null = Register-ScheduledTask -TaskName $schtaskName -Trigger $schtaskTrigger -Action $schtaskAction  -Principal $schtaskPrincipal -Settings $schtaskSettings -Description $schtaskDescription -Force -ErrorAction Stop
    
    Start-ScheduledTask -TaskName $schtaskName
    exit 0         
 }
 catch {
    Write-Host "Error while creating network mapping $($schtaskName)" 
    exit 1
 }


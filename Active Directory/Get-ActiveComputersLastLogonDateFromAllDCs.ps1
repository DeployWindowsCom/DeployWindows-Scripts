$DebugPreference = "Continue"
$VerbosePreference = "Silently"
Write-Host "Script warming up......"

$Computers = @{}
$ComputersVersion = @{}

Write-Host "Script starting......"

$DomainControllers = @(Get-ADDomainController -Filter *)

$DomainControllers | foreach {
    #get computers for each dc here
    $dc = $_.HostName

    $tempComputers = $null
    $tempComputers = Get-ADComputer -Filter 'objectCategory -like "computer" -and operatingsystem -notlike "*server*" -and enabled -eq "true"' -Properties Name,Operatingsystem,OperatingSystemVersion,LastLogonDate,SID,DistinguishedName -Server $dc

    foreach ($computer in $tempComputers.GetEnumerator()) {
        #check if the computer is in the list and if the logon stamp is the latest
        Write-Debug "Computer $($computer.Name)"
        if ($Computers.Contains($computer.Name)) {
            Write-Debug "$($computer.LastLogonDate) -greater than $($computers[$computer.Name]) = $(($computer.LastLogonDate) -gt $Computers[$computer.Name]))"
            if ($computer.LastLogonDate -gt $Computers[$computer.Name]) {
                Write-Debug "This DC has the lasted date"
                $Computers[$computer.Name] = $computer.LastLogonDate
            } elseif ($computer.LastLogonDate -lt $Computers[$computer.Name]) {
                Write-Debug "Lastest date already in the list"
            } else {
                Write-Debug "Same date, do nothing"
            }
        } else {
            Write-Debug "Add computer to list"
            $Computers.Add($computer.Name, $computer.LastLogonDate)
            if ($computer.OperatingSystemVersion -like "*(*") {
                $ComputersVersion.Add($computer.Name, $computer.OperatingSystemVersion.Replace(" (",".").Replace(")",""))
            } else {
                $ComputersVersion.Add($computer.Name, $computer.OperatingSystemVersion)
            }
        }
        
        Write-Host
    }
}

Write-Host "Script done.."

"`"Name`",`"Version`",`"LastLogonDate`"" | Out-File -FilePath .\computers.csv
foreach ($computer in $Computers.GetEnumerator()) {
    "`"$($computer.Name)`",`"$($ComputersVersion[$computer.Name])`",`"$($computer.Value)`"" | Out-File -FilePath .\computers.csv -Append
}

#$Computers.GetEnumerator() | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath .\computers.csv

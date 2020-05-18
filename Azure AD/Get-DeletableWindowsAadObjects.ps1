
Connect-AzureAD

$allDevices = Get-AzureADDevice -All $true | Where-Object { $_.DeviceOSType -eq "Windows" } 
Write-Host "We found $($allDevices.Count) Windows devices that are connected to Azure AD"

#All Hybrid Joined devices
$allHybridDevices = $allDevices | Where-Object { $_.DeviceTrustType -eq "ServerAd" }
Write-Host "We found $($allHybridDevices.Count) Windows devices that are Hybrid joined" -BackgroundColor Yellow

#All Azure AD regged devices
$allAadRegDevices = $allDevices | Where-Object { $_.DeviceTrustType -eq "Workplace" }
Write-Host "We found $($allAadRegDevices.Count) Windows devices that are Azure AD registred" -BackgroundColor Yellow

$dups = 0
$deleteDevices = @{}
foreach ($device in $allAadRegDevices)
{
    #Check if the Azure AD registred name have a corresponding hybrid joined device as well
    #add more logic if neccessary...
    if ($device.DisplayName -in $allHybridDevices.DisplayName)
    {
        #Write-Host "Device found as Hybrid Joined and Azure AD device registred `t$($device.DisplayName)  `t$($device.DeviceTrustType)`t$($device.ObjectId)" 
        $hybrid = $allHybridDevices | Where-Object { $_.DisplayName -eq $device.DisplayName }
        
        #Only delete the object where the computer is Intune managed
        if ($hybrid.IsManaged -eq $true)
        {
            Write-Host "$($hybrid.DisplayName) `tfound as MDM managed and the corresponding Azure AD registred device may be removed = $($device.ObjectId)"
            $dups++
            $deleteDevices.Add($device.ObjectId,$device.DisplayName)
        }
    }
}

if ($dups -eq $deleteDevices.Count)
{
    Write-Host "Found $($dups) for subject to be removed" -BackgroundColor Yellow
    Write-Host

    foreach ($delete in $deleteDevices.GetEnumerator())
    {
        $deldevice = Get-AzureADDevice -ObjectId $delete.Name
        Write-Host "Removing $($deldevice.ObjectId) $($deldevice.DisplayName)..."

        #Remove this comment to actually remove the objects
        #Remove-AzureADDevice -ObjectId $deldevice.ObjectId

        #remove the break if you want to delete all objects or only the first one in the hash list
        break
    }
}




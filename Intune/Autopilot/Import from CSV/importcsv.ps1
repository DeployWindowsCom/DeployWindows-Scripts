
$devices = @(Import-Csv -Path .\import.csv -Delimiter ",")


Write-Host "We found $($devices.Count) devices (more than 500 is not supported)"
if ($devices.count -gt 500) { Exit -1 }
Write-Host


# Connect to Microsoft Graph
Write-Progress -Activity "Connecting to Microsoft Graph" -Status "Connect to Microsoft Graph"
try {
    Connect-MSGraph | Out-Null
} catch
{
    Write-Host "Not successfully connected to Microsoft Graph" -Background Red
    Write-Host
    break
}
Write-Host "Connected to Microsoft Graph"
Write-Host


foreach ($device in $devices) {
    if ($device.OrderId)
    {
        Write-Host "Order ID is set, please change to Group Tag" -BackgroundColor Red
        Exit -1
    }

    if ($device.'Group Tag')
    {
        $script:groupTag = $device.'Group Tag'    
    }
    else 
    {
        Write-Host "Group tag is empty for $($device.'Device Serial Number')" -BackgroundColor Yellow
        $script:groupTag = ""
    }

    if ($device.'Device Serial Number')
    {
        $script:serialNumber = $device.'Device Serial Number'
    }
    else {
        Write-Host "Device Serial number is empty, exiting" -BackgroundColor Red
        Break
    }

    if ($device.'Hardware Hash')
    {
        $script:deviceHardwareData = $device.'Hardware Hash'
    }
    else {
        Write-Host "Hardware hash is empty, exiting" -BackgroundColor Red
        Break
    }

    $script:productKey = ""

    $script:jsonContent = @{
        "@odata.type" = "#microsoft.graph.importedWindowsAutopilotDeviceIdentity"
        "orderIdentifier" = "$($script:groupTag)"
        "serialNumber" = "$($script:serialNumber)"
        "productKey" = "$($script:productKey)"
        "hardwareIdentifier" = "$($script:deviceHardwareData)"
        "state" = @{
            "@odata.type" = "microsoft.graph.importedWindowsAutopilotDeviceIdentityState"
            "deviceImportStatus" = "pending"
            "deviceRegistrationId" = ""
            "deviceErrorCode" = 0
            "deviceErrorName" = ""
        }
      }

    Write-Host "importing $($script:serialNumber)"

    # Import the device
    $script:autopilotDevice = Invoke-MSGraphRequest -Url "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities" -Content $script:jsonContent -HttpMethod POST

    $script:autopilotDevice
}





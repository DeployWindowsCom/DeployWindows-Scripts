##################################################################################################
#
# Clean up wrong default save file type settings in Office, Word, Excel and PowerPoint
#
##################################################################################################

$WordTypeRegPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Word\Options"
$WordTypeRegName = "DefaultFormat"
$PowerPointTypeRegPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\PowerPoint\Options"
$PowerPointTypeRegName = "DefaultFormat"
$ExcelTypeRegPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Excel\Options"
$ExcelTypeRegName = "DefaultFormat"

$WordType = (Get-ItemProperty  -Path $WordTypeRegPath -Name $WordTypeRegName).DefaultFormat
if (($null -eq $WordType) -or ($WordType -eq ""))  {
    Write-Host "Word default file type are correct"
} else {
    Write-Host "Word default file type is incorrect: $($WordType). Removing..."
    try {
        Remove-ItemProperty -Path $WordTypeRegPath -Name $WordTypeRegName -Force
    } catch {
        Write-Host "Registry property could not be removed"
    }
}

try {
    $ExcelType = (Get-ItemProperty  -Path $ExcelTypeRegPath -Name $ExcelTypeRegName -ErrorAction SilentlyContinue).DefaultFormat
    if (($null -eq $ExcelType) -or ($ExcelType -eq "51"))  {
        Write-Host "Excel default file type are correct"
    } else {
        Write-Host "Excel default file type is incorrect: $($ExcelType). Removing..."
        try {
            Remove-ItemProperty -Path $ExcelTypeRegPath -Name $ExcelTypeRegName -Force
        } catch {
            Write-Host "Registry property could not be removed"
        }
    }    
} catch {
    Write-Host "Excel default file type looks fine"
}

try {
    $PowerPointType = (Get-ItemProperty  -Path $PowerPointTypeRegPath -Name $PowerPointTypeRegName -ErrorAction SilentlyContinue).DefaultFormat
    if (($null -eq $PowerPointType) -or ($PowerPointType -eq "27"))  {
        Write-Host "PowerPoint default file type are correct"
    } else {
        Write-Host "PowerPoint default file type is incorrect: $($PowerPointType). Removing..."
        try {
            Remove-ItemProperty -Path $PowerPointTypeRegPath -Name $PowerPointTypeRegName -Force
        } catch {
            Write-Host "Registry property could not be removed"
        }
    }
} catch {
    Write-Host "PowerPoint default file type looks fine"
}


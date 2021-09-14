
# This script will configure wireless network settings
# WIFI1         - Will set this network as Private if not already identified as DomainAuthenticated already
# WIFIGuest      - Will set this network as Public and manual connect


foreach ($wifi in $(Get-NetConnectionProfile -InterfaceAlias Wi-Fi*)) {
    Write-Host "$($wifi.Name) with index $($wifi.InterfaceIndex)"

    switch -Regex ($wifi.Name) {
        "wifi1" {
            #if network is not identified as DomainAuthenticated set as private
            switch ((Get-NetConnectionProfile -InterfaceIndex $wifi.InterfaceIndex).NetworkCategory) {
                "DomainAuthenticated" {
                    Write-Host "$($wifi.Name) identified as DomainAuthenticated. Do nothing"
                 }
                "Public" {
                    Write-Host "$($wifi.Name) identified as Public, set as Private"
                    Set-NetConnectionProfile -InterfaceIndex $wifi.InterfaceIndex -NetworkCategory Private
                 }
                Default {}
            }
         }
        "wifiguest" { 
            #if network is not identified something else than Public set as Public
            switch ((Get-NetConnectionProfile -InterfaceIndex $wifi.InterfaceIndex).NetworkCategory) {
                "Public" {
                    Write-Host "$($wifi.Name) identified as Public, do nothing"
                 }
                Default {
                    Write-Host "$($wifi.Name) identified as NON-Public, set as Public"
                    Set-NetConnectionProfile -InterfaceIndex $wifi.InterfaceIndex -NetworkCategory Public
                }
            }
         }
        Default {}
    }

}

#Set network to manual connect rather than automatic
$ssid = "wifiguest"
$ret = netsh wlan show profiles name="$($ssid)" | select-string "Connection mode"
if ($null -ne $ret) {
    if ($ret -match "Connect manually") {
        Write-Host "$($ssid) is already set to Manual"
    } else {
        Write-Host "$($ssid) is set to automatic"
        #Set SSID to connect manual not auto
        $retProcess = Start-Process -FilePath "netsh.exe" -ArgumentList "wlan set profileparameter name=`"$($ssid)`" ConnectionMode=manual" -PassThru -Wait -WindowStyle Hidden
        Write-host $retProcess
    }
} else {
    Write-Host "No WiFi profiles found with name $($ssid)"
}

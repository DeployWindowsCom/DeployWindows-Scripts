
# This script will configure wireless network settings
# WIFI1         - Will set this network as Private if not already identified as DomainAuthenticated already
# WIFIGuest      - Will set this network as Public and manual connect


foreach ($wifi in $(Get-NetConnectionProfile -InterfaceAlias Wi-Fi*)) {
    Write-Host "Found WiFi: $($wifi.Name) with index $($wifi.InterfaceIndex)"

    switch -Regex ($wifi.Name) {
        "wifi1" {
            #if network is not identified as DomainAuthenticated set as private
            switch ((Get-NetConnectionProfile -InterfaceIndex $wifi.InterfaceIndex).NetworkCategory) {
                "Public" {
                    Write-Host "$($wifi.Name) is identified as public: $($wifi.NetworkCategory). Need fixing"
                    exit 1
                 }
                Default {}
            }
         }
        "wifiguest" { 
            #if network is not identified something else than Public set as Public
            switch ((Get-NetConnectionProfile -InterfaceIndex $wifi.InterfaceIndex).NetworkCategory) {
                "Public" {
                 }
                Default {
                    Write-Host "$($wifi.Name) is identified as NON-public: $($wifi.NetworkCategory). Need fixing"
                    exit 1
                }
            }
         }
        Default {}
    }

}

$ssid = "wifiguest"
$ret = netsh wlan show profiles name="$($ssid)" | select-string "Connection mode"
if ($null -ne $ret) {
    if ($ret -match "Connect manually") {
        #Write-Host "$($ssid) is already set to Manual"
    } else {
        Write-Host "$($ssid) is set to automatic"
        exit 1
    }
} else {
    #Write-Host "No WiFi profiles found with name $($ssid)"
}

#Successfull exit
exit 0

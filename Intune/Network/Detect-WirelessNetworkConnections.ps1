<#PSScriptInfo

.VERSION 1.0

.GUID 

.AUTHOR Mattias Alvbring

.COMPANYNAME DeployWindows.com

.TAGS Windows Intune PowerShell Network Wireless NetworkCategory

.RELEASENOTES
Version 1.0:  Original

#>

<#
.SYNOPSIS
Detection script if network settings is correct

.DESCRIPTION
 This script will check for 
 WIFI1         - Will set this network as Private if not already identified as DomainAuthenticated already
 WIFIGuest      - Will set this network as Public and manual connect


.EXAMPLE

#>

$output = ""
foreach ($wifi in $(Get-NetConnectionProfile -InterfaceAlias Wi-Fi*)) {
    $output += "Found WiFi: $($wifi.Name) with index $($wifi.InterfaceIndex)."

    switch ($wifi.Name) {
        "wifi1" {
            #if network is not identified as DomainAuthenticated set as private
            switch ((Get-NetConnectionProfile -InterfaceIndex $wifi.InterfaceIndex).NetworkCategory) {
                "Public" {
                    $output += "$($wifi.Name) is identified as public: $($wifi.NetworkCategory) - Need fixing."
                    Write-Output $output
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
                    $output += "$($wifi.Name) is identified as NON-public: $($wifi.NetworkCategory) - Need fixing."
                    Write-Output $output
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
        $output += "$($ssid) is set to automatic."
        Write-Output $output
        exit 1
    }
} else {
    $output += "No WiFi profiles found with name $($ssid)."
}

#Successfull exit
Write-Output $output
exit 0

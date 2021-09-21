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
Automatically sets networks to correct network category; private/public

.DESCRIPTION
 This script will configure wireless network settings
 WIFI1         - Will set this network as Private if not already identified as DomainAuthenticated already
 WIFIGuest      - Will set this network as Public and manual connect


.EXAMPLE

#>

$output = ""
foreach ($wifi in $(Get-NetConnectionProfile -InterfaceAlias Wi-Fi*)) {
    $output += "$($wifi.Name) with index $($wifi.InterfaceIndex)."

    switch ($wifi.Name) {
        "wifi1" {
            #if network is not identified as DomainAuthenticated set as private
            switch ((Get-NetConnectionProfile -InterfaceIndex $wifi.InterfaceIndex).NetworkCategory) {
                "DomainAuthenticated" {
                    $output += "$($wifi.Name) identified as DomainAuthenticated - Do nothing."
                 }
                "Public" {
                    $output += "$($wifi.Name) identified as Public, set as Private."
                    Set-NetConnectionProfile -InterfaceIndex $wifi.InterfaceIndex -NetworkCategory Private
                 }
                Default {}
            }
         }
        "wifiguest" { 
            #if network is not identified something else than Public set as Public
            switch ((Get-NetConnectionProfile -InterfaceIndex $wifi.InterfaceIndex).NetworkCategory) {
                "Public" {
                    $output += "$($wifi.Name) identified as Public, do nothing."
                 }
                Default {
                    $output += "$($wifi.Name) identified as NON-Public, set as Public."
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
        $output += "$($ssid) is already set to Manual."
    } else {
        $output += "$($ssid) is set to automatic."

        #alternative way
        #$retProcess = Start-Process -FilePath "netsh.exe" -ArgumentList "wlan set profileparameter name=`"$($ssid)`" ConnectionMode=manual" -PassThru -Wait -WindowStyle Hidden
        #$output += "Setting netsh wlan set profileparameter name=$($ssid) ConnectionMode=manual exit with code: $($retProcess.ExitCode)"

        #Set SSID to connect manual not auto
        $retAction = netsh wlan set profileparameter name=`"$($ssid)`" ConnectionMode=manual
        if ($null -ne $retAction) {
            $output += "Setting netsh wlan set profileparameter name=$($ssid) ConnectionMode=manual exit with code: $($retAction.ExitCode)`n$($retAction)."
        }

        $retPostAction = netsh wlan show profiles name="$($ssid)" | select-string "Connection mode"
        $output += "Now ConnectionMode is set to $($retPostAction)."
    }
} else {
    $output += "No WiFi profiles found with name $($ssid)."
}

Write-Output $output
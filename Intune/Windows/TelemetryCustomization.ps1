##############################
#.SYNOPSIS
# This script will enable to share Device name in Telemetry and disable notification
# This script is used since Policy CSP does not work
#
#Version
# 1.0  First release
#
##############################

##############################
#Author
#@MattiasFors
#https://deploywindows.com
#https://github.com/DeployWindowsCom/DeployWindows-Scripts
##############################

$TelemetryReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"

if((Test-Path -Path $TelemetryReg) -eq $false) {
    New-Item -Path $TelemetryReg -ItemType Key
}


New-ItemProperty -Path $TelemetryReg -Name AllowDeviceNameInTelemetry -PropertyType DWord -Value 1 -Force -ErrorAction Continue
New-ItemProperty -Path $TelemetryReg -Name DisableTelemetryOptInChangeNotification -PropertyType DWord -Value 1 -Force -ErrorAction Continue

Exit 0

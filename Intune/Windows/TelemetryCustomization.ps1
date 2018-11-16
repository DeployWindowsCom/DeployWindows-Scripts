##############################
#.SYNOPSIS
# This script will enable to share Device name in Telemetry and disable notification
# This script is used since Policy CSP does not work
#
#Version
# 1.0  First release
# 1.1 Updated for 64-bit system
#
##############################

##############################
#Author
#@MattiasFors
#https://deploywindows.com
#https://github.com/DeployWindowsCom/DeployWindows-Scripts
##############################

#region Restart into 64-bit
$Is64Bit = [System.Environment]::Is64BitProcess;
$Is64OS = $false; if (($env:PROCESSOR_ARCHITEW6432 -like "AMD64") -or ($env:PROCESSOR_ARCHITECTURE -like "AMD64")) { $Is64OS = $true; }

if (($Is64OS) -and (-not $Is64Bit)) {
    # Running AMD64 but no AMD64 Process, Restart script
    Write-Host "Running AMD64 OS and x86 environment, restart script"
    $Invocation = $PSCommandPath
    if ($Invocation -eq $null) { return }
    $SysNativePath = $PSHOME.ToLower().Replace("syswow64", "sysnative")
    $Ret = Start-Process "$SysNativePath\powershell.exe" -ArgumentList "-ex ByPass -file `"$Invocation`" " -WindowStyle normal -PassThru -Wait
    return $Ret.ExitCode;
} elseif ((-not $Is64OS) -and (-not $Is64Bit)) {
    #Running x86 and no AMD64 Process, Do not bother restarting
    Write-Host "Running x86 OS and x86 environment, continue"
}
#endregion

#region Your content goes here

Write-Host "64-Bit Environment: $($Is64Bit) on 64-Bit Windows: $($Is64OS)"

$TelemetryReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"

if((Test-Path -Path $TelemetryReg) -eq $false) {
    New-Item -Path $TelemetryReg -ItemType Key
}


New-ItemProperty -Path $TelemetryReg -Name AllowDeviceNameInTelemetry -PropertyType DWord -Value 1 -Force -ErrorAction Continue
New-ItemProperty -Path $TelemetryReg -Name DisableTelemetryOptInChangeNotification -PropertyType DWord -Value 1 -Force -ErrorAction Continue

Exit 0

#endregion
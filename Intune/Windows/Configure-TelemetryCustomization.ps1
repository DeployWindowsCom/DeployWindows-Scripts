##############################
#.SYNOPSIS
# This script will enable to share Device name in Telemetry and disable notification
# This script is used since Policy CSP does not work
#
#Version
# 1.0  First release
# 1.1  Added DoNotShowFeedbackNotification
# 1.2  Minior logging updates
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
    $Invocation = $PSCommandPath
    if ($null -eq $Invocation) { return }
    $SysNativePath = $PSHOME.ToLower().Replace("syswow64", "sysnative")
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "$SysNativePath\powershell.exe"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.WindowStyle = "hidden"
    $pinfo.Arguments = "-ex ByPass -file `"$Invocation`" "
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $pinfo
    $proc.Start() | Out-Null
    $proc.WaitForExit()
    $StdErr = $proc.StandardError.ReadToEnd()
    $StdOut = $proc.StandardOutput.ReadToEnd()
    $ExitCode = $proc.ExitCode
    if ($StdErr) { Write-Error -Message "$($StdErr)" }
    Write-Host $ExitCode
    Exit $ExitCode
} elseif ((-not $Is64OS) -and (-not $Is64Bit)) {
    #Running x86 and no AMD64 Process, Do not bother restarting
}
#endregion

#region Your content goes here
$ScriptName = $PSCommandPath.Split("\")[$PSCommandPath.Split("\").Count -1];
Start-Transcript -Path "$($env:TEMP)\$($ScriptName).log" -Force

$TelemetryReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"

if((Test-Path -Path $TelemetryReg) -eq $false) {
    New-Item -Path $TelemetryReg -ItemType Key
}

$ErrorActionPreference = 'Stop';
try {
    New-ItemProperty -Path $TelemetryReg -Name AllowDeviceNameInTelemetry -PropertyType DWord -Value 1 -Force -ErrorAction Stop
    New-ItemProperty -Path $TelemetryReg -Name DisableTelemetryOptInChangeNotification -PropertyType DWord -Value 1 -Force -ErrorAction Stop
    New-ItemProperty -Path $TelemetryReg -Name DoNotShowFeedbackNotifications -PropertyType DWord -Value 1 -Force -ErrorAction Stop
} catch {
    $Err = $_.Exception
    Write-Error -Message "`n$($Err.GetType()) `n$($Err.Message)" -Category OperationStopped
}

Stop-Transcript
#endregion
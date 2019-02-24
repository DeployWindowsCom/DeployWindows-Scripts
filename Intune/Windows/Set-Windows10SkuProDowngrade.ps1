##############################
#.SYNOPSIS
# This script will downgrade your currect installation to Windows 10 Pro
# This script will also install your currect MAK key, if entered
# For more info:
# https://docs.microsoft.com/en-us/windows/deployment/upgrade/windows-10-edition-upgrades#supported-windows-10-downgrade-paths
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

$ErrorActionPreference = 'Stop';
try {

	# Uninstall current key
	$ret = Start-Process -FilePath "cscript.exe" -ArgumentList "$($env:SystemRoot)\System32\slmgr.vbs /upk" -wait -PassThru
	Write-Host "Exit with code $($ret.ExitCode)"

	# This install Windows 10 Pro KMS Key from https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/jj612867(v=ws.11)#windows-10
	$ret = Start-Process -FilePath "cscript.exe" -ArgumentList "$($env:SystemRoot)\System32\slmgr.vbs /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX" -wait -PassThru
	Write-Host "Exit with code $($ret.ExitCode)"

	$MAK = "YOUR-MAK-KEY-GOES-HERE"
	$ret = Start-Process -FilePath "cscript.exe" -ArgumentList "$($env:SystemRoot)\System32\slmgr.vbs /ipk $($MAK)" -wait -PassThru
	Write-Host "Exit with code $($ret.ExitCode)"

	# Activate it using the following command: 
	$ret = Start-Process -FilePath "cscript.exe" -ArgumentList "$($env:SystemRoot)\System32\slmgr.vbs /ato" -wait -PassThru
	Write-Host "Exit with code $($ret.ExitCode)"

} catch {
    $Err = $_.Exception
    Write-Error -Message "`n$($Err.GetType()) `n$($Err.Message)" -Category OperationStopped
}

Stop-Transcript
#endregion
﻿##############################
#.SYNOPSIS
#This will restart your PowerShell script in 64-bit environment, on 64-bit OS only
#Just paste this script at the top of your script
#.EXAMPLE
#N/A
#
#.NOTES
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
    if ($Invocation -eq $null) { return }
    $SysNativePath = $PSHOME.ToLower().Replace("syswow64", "sysnative")
    $Ret = Start-Process "$SysNativePath\powershell.exe" -ArgumentList "-ex ByPass -file `"$Invocation`" " -WindowStyle normal -PassThru -Wait
    return $Ret.ExitCode;
} elseif ((-not $Is64OS) -and (-not $Is64Bit)) {
    #Running x86 and no AMD64 Process, Do not bother restarting
}
#endregion

#region Your content goes here

Start-Transcript -Path "$($env:TEMP)\log.log" -Append -Force

#put your content here

Stop-Transcript

#endregion


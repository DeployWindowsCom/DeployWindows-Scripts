##############################
#.SYNOPSIS
# This script will set screensave timeout
# This script is used since Policy CSP does not work or does not exists
#
#Version
# 1.0  First release
# 1.1  Update for all users, and setting ScreenSaverIsSecure
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

$SetHKU = $false    # This will configure the timeout when the user is logged out, logon screen
$SetHKCU = $true    # This will configure the timeout when the user is logged in, group policy style

$HKUReg = "HKU:\.DEFAULT\Control Panel\Desktop"                                # This will configure the timeout when the user is logged out, logon screen
$HKCURegBase = "\Software\Policies\Microsoft\Windows\Control Panel\Desktop"    # This will configure the timeout when the user is logged in, group policy style

$TimeoutInSeconds = 15*60   # This is the timeout value in seconds
$ScreenSaverIsSecure = 1    # 1 = enable password after timeout, 0 disable require password

$ErrorActionPreference = 'Stop';
try {
    if ($SetHKU -eq $true) { 
        if ((Test-Path -Path $HKUReg) -eq $false) { New-Item -Path $HKUReg -ItemType Key -Force -ErrorAction Stop }
        New-ItemProperty -Path $HKUReg -Name ScreenSaveTimeOut -PropertyType String -Value $TimeoutInSeconds -Force -ErrorAction Stop
    }

    if ($SetHKCU -eq $true) {
        $AllUsers = Get-ChildItem "Registry::\HKEY_USERS\" -ErrorAction SilentlyContinue| Where-Object { (($_.Name).Split("-").Count -ge 6) -and ($_.Name -notmatch "_Classes") }

        foreach ($user in $AllUsers) {
            $HKCUReg = "Registry::$($user.Name)$($HKCURegBase)"
            Write-Host $HKCUReg
            if ((Test-Path -Path $HKCUReg) -eq $false) { New-Item -Path $HKCUReg -ItemType Key -Force -ErrorAction Stop }
            New-ItemProperty -Path $HKCUReg -Name ScreenSaveTimeOut -PropertyType String -Value $TimeoutInSeconds -Force -ErrorAction Stop
            New-ItemProperty -Path $HKCUReg -Name ScreenSaverIsSecure -PropertyType String -Value $ScreenSaverIsSecure -Force -ErrorAction Stop
        }
    }
    # May require to run c:\windows\System32\RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters to enforce the setting now, else restart/logoff
} catch {
    $Err = $_.Exception
    Write-Error -Message "`n$($Err.GetType())" -Category OperationStopped
}

Stop-Transcript
#endregion
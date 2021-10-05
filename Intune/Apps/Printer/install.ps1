
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

#region Main script
$ScriptName = $PSCommandPath.Split("\")[$PSCommandPath.Split("\").Count -1];
Start-Transcript -Path "$($env:TEMP)\$($ScriptName).log" -Force


$Printer = "\\server.domain.com\printer01"
$PrintDriverName = "RICOH PCL6 UniversalDriver V4.10"


# Add print driver to DriverStore
Write-Progress -Activity "Installing printer" -Status "Adding driver to driver store" -PercentComplete 0
&"$($env:windir)\System32\PNPUtil.exe" /Add-Driver "RICOH-PCL6UniversalDriver-V4.10\oemsetup.inf" | Out-Null

# Adding print driver, from DriverStore
Write-Progress -Activity "Installing printer" -Status "Adding print driver" -PercentComplete 25
Add-PrinterDriver -Name $PrintDriverName

# Checking if print server is possible to reach
if ((Test-NetConnection -ComputerName $printer.split('\')[2]).PingSucceeded -eq $true) { 
	Write-Host "Successfull connection to print server $($printer.split('\')[2])"
} else { 
	Write-Host "Failed connection to print server $($printer.split('\')[2])"
	Exit 1
}

# Adding printer
Write-Progress -Activity "Installing printer" -Status "Adding printer" -PercentComplete 50
Add-Printer -ConnectionName $Printer

Write-Progress -Activity "Installing printer" -Status "Printer installed" -PercentComplete 100
Exit 0


Stop-Transcript
#endregion Main script

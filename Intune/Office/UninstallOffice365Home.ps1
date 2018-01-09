
#region User defined variables
$UninstallRegistryFilter = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\O365HomePremPlus*"
$LogFile = "UninstallOffice365Home.log"
$ScriptFolder = "DeployWindows"
$ScriptFolderFullPath = "$($Env:ProgramData)\$($ScriptFolder)"
#endregion

Param([switch]$Is64Bit = $false)
 
Function Restart-As64BitProcess {
    If ([System.Environment]::Is64BitProcess) { return }
    $Invocation = $($MyInvocation.PSCommandPath)
    if ($Invocation -eq $null) { return }
    $sysNativePath = $psHome.ToLower().Replace("syswow64", "sysnative")
    Start-Process "$sysNativePath\powershell.exe" -ArgumentList "-ex bypass -file `"$Invocation`" -Is64Bit" -WindowStyle Hidden -Wait
}
 
 
if (!$Is64Bit) { 
    Restart-As64BitProcess 
} else {

    #region Script require running in 64-bit environment
    Start-Transcript "$($ScriptFolderFullPath)\$($LogFile)"

    $Programs = @(Get-Item -Path $UninstallRegistryFilter)
    Write-Host "Found $($Programs.Count) Programs from $($Programs[0].PSPath) with the filter $($UninstallRegistryFilter)"

    foreach ($Program in $Programs) {
        $UninstallString = $empty
        $UninstallString = $(Get-ItemPropertyValue -Path $Program.PSPath -Name "UninstallString" -ErrorAction SilentlyContinue)
        if ($UninstallString -eq $empty) {
            Write-Host "Missing uninstall command"
        } else {
            $cmd = $UninstallString.Substring(0,$UninstallString.IndexOf(".exe") + 5).Trim()
            $args = $UninstallString.Substring($UninstallString.IndexOf(".exe") + 5).TrimStart()
            Write-Host "Execute command: $($cmd)"
            Write-Host "Parameters $($args)"

            $ps = new-object System.Diagnostics.Process
            $ps.StartInfo.Filename = $cmd
            $ps.StartInfo.Arguments = $args
            $ps.StartInfo.RedirectStandardOutput = $True
            $ps.StartInfo.UseShellExecute = $false
            $ps.start()
            $ps.WaitForExit()
        }

        break;

        #endregion
    }

    Stop-Transcript
}

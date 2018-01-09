<#
.Synopsis
  When deploying Office 365 ProPlus to a Windows 10 signature edition there is a Home Premium version installed
  and therefore Office 365 PP cannot be installed.
  This script will execute the uninstall command for all Office 365 HomePremRetail version and languages installed on the computer
.DESCRIPTION
  This script restart in 64-bit environment
  Look in the Uninstall key for all installed Office 365 Home Prem Retail versions/languages
  For 

  To configure the script define the variables
  Only change other settings if you know what you are doing
.EXAMPLE
  Upload the script to Microsoft Intune, run in system context and apply to all users
.AUTHOR
  Reach the author
  https://deploywindows.com
  @MattiasFors
#>

Param([switch]$Is64Bit = $false)

#region User defined variables
$UninstallRegistryFilter = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\O365HomePremRetail*"
$LogFile = "UninstallOffice365Home.log"
$ScriptFolder = "DeployWindows"
$ScriptFolderFullPath = "$($Env:ProgramData)\$($ScriptFolder)"
#endregion
 
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

    $Programs = @(Get-Item -Path $UninstallRegistryFilter)
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
    }
    Stop-Transcript

    #endregion
}


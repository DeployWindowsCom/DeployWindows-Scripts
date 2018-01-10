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

#region User defined variables
$UninstallRegistryFilter = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\O365HomePremRetail*"
$LogFile = "UninstallOffice365Home.log"
$ScriptFolder = "DeployWindows"
$ScriptFolderFullPath = "$($Env:ProgramData)\$($ScriptFolder)"
#endregion

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

function ShowToast {
    param(
      [parameter(Mandatory=$true,Position=2)]
      [string] $ToastTitle,
      [parameter(Mandatory=$true,Position=3)]
      [string] $ToastText,
      [parameter(Position=1)]
      [string] $Image = $null,
      [parameter()]
      [ValidateSet('long','short')]
      [string] $ToastDuration = "long"
    )
  
    # Toast overview: https://msdn.microsoft.com/en-us/library/windows/apps/hh779727.aspx
    # Toasts templates: https://msdn.microsoft.com/en-us/library/windows/apps/hh761494.aspx
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
  
    # Define Toast template, w/wo image
    $ToastTemplate = [Windows.UI.Notifications.ToastTemplateType]::ToastImageAndText02
    if ($Image.Length -le 0) {
      $ToastTemplate = [Windows.UI.Notifications.ToastTemplateType]::ToastText02
    }
  
  #region Download or define a local image file://c:/image.png
    # Toast images must have dimensions =< 1024x1024 size =< 200 KB
    if ($Image -match "http*") {
      [System.Reflection.Assembly]::LoadWithPartialName("System.web") | Out-Null
      $Image = [System.Web.HttpUtility]::UrlEncode($Image)
      $imglocal = "$($env:TEMP)\ToastImage.png"
      Start-BitsTransfer -Destination $imglocal -Source $([System.Web.HttpUtility]::UrlDecode($Image)) -ErrorAction Continue
    } else {
      $imglocal = $Image
    }
  #endregion
  
  # Define the toast template and create variable for XML manipuration
  # Customize the toast title, text, image and duration
  $toastXml = [xml] $([Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(`
    $ToastTemplate)).GetXml()
  $toastXml.GetElementsByTagName("text")[0].AppendChild($toastXml.CreateTextNode($ToastTitle)) | Out-Null
  $toastXml.GetElementsByTagName("text")[1].AppendChild($toastXml.CreateTextNode($ToastText)) | Out-Null
  if ($Image.Length -ge 1) { $toastXml.GetElementsByTagName("image")[0].SetAttribute("src", $imglocal) }
  $toastXml.toast.SetAttribute("duration", $ToastDuration)

  # Convert back to WinRT type
  $xml = New-Object Windows.Data.Xml.Dom.XmlDocument; $xml.LoadXml($toastXml.OuterXml);
  $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)

  # Get an unique AppId from start, and enable notification in registry
  if ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value.ToString() -eq "S-1-5-18") {
    # Popup alternative when running as system
    # https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx
    $wshell = New-Object -ComObject Wscript.Shell
    if ($ToastDuration -eq "long") {
      $return = $wshell.Popup($ToastText,10,$ToastTitle,0x100)
    } else {
      $return = $wshell.Popup($ToastText,4,$ToastTitle,0x100)
    }
  } else {
    $AppID = ((Get-StartApps -Name 'Windows Powershell') | Select -First 1).AppId
    New-Item "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\$AppID" -Force | Out-Null
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\$AppID" `
      -Name "ShowInActionCenter" -Type Dword -Value "1" -Force | Out-Null
    # Create and show the toast, dont forget AppId
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppID).Show($Toast)
  }
}


#region Require running in 64-bit environment

Start-Transcript "$($ScriptFolderFullPath)\$($LogFile)"

$Programs = @(Get-Item -Path $UninstallRegistryFilter)
Write-Host "Found $($Programs.Count) Programs from $($Programs[0].PSPath) with the filter $($UninstallRegistryFilter)"
ShowToast -ToastTitle "Uninstalling applications" `
  -ToastText "Found $($Programs.Count) Programs with filter $($UninstallRegistryFilter)" -ToastDuration short;

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

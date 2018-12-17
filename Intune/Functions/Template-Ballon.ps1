##############################
#.SYNOPSIS
#Show Windows Toast/ballon for a logged on user
#
#.PARAMETER ToastTitle
#Parameter Title of the toast
#
#.PARAMETER ToastText
#Parameter Text for the toast
#
#.PARAMETER Image
#Parameter Define image either http://, https:// or file://
#
#.PARAMETER ToastDuration
#Parameter Define how long the toast should stay, long or short, 10 or 4 seconds for alternative popup
#
#.EXAMPLE
# ShowToast -Image "https://picsum.photos/150/150?image=1060" 
#   -ToastTitle "Headline" -ToastText "Text" -ToastDuration short
# ShowToast -ToastTitle "Headline" -ToastText "Text" -ToastDuration short
#
#.NOTES
#It will modify the registry value ShowInActionCenter to 1 for PowerShell
# Location HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\$AppID
#
#Version
# 1.0  First release
# 1.1 Fix for 64-bit OS
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
  if ($Image.Length -le 0) { $ToastTemplate = [Windows.UI.Notifications.ToastTemplateType]::ToastText02 }

  # Download or define a local image. Toast images must have dimensions =< 1024x1024 size =< 200 KB
  if ($Image -match "http*") {
    [System.Reflection.Assembly]::LoadWithPartialName("System.web") | Out-Null
    $Image = [System.Web.HttpUtility]::UrlEncode($Image)
    $imglocal = "$($env:TEMP)\ToastImage.png"
    Start-BitsTransfer -Destination $imglocal -Source $([System.Web.HttpUtility]::UrlDecode($Image)) -ErrorAction Continue
  } else { $imglocal = $Image }

  # Define the toast template and create variable for XML manipulation
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
    # Popup alternative when running as system. https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx
    $wshell = New-Object -ComObject Wscript.Shell
    if ($ToastDuration -eq "long") { $return = $wshell.Popup($ToastText,10,$ToastTitle,0x100) }
    else { $return = $wshell.Popup($ToastText,4,$ToastTitle,0x100) }
  } else {
    $AppID = ((Get-StartApps -Name 'Windows Powershell') | Select -First 1).AppId
    New-Item "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\$AppID" -Force | Out-Null
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\$AppID" `
      -Name "ShowInActionCenter" -Type Dword -Value "1" -Force | Out-Null
    # Create and show the toast, dont forget AppId
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppID).Show($Toast)
  }
}
  
# Example images from https://picsum.photos/
ShowToast -Image "https://picsum.photos/150/150?image=1060" -ToastTitle "Windows tweaked!" `
  -ToastText "IT Support has deployed new settings for you! Please logout when possible" -ToastDuration short;

ShowToast -ToastTitle "Windows tweaked!" `
  -ToastText "IT Support has deployed new settings for you! Please logout when possible" -ToastDuration long;

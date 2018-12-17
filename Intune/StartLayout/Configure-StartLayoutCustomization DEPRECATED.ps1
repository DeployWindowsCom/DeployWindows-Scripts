﻿##############################
#.SYNOPSIS
#When using Windows 10 and Microsoft Intune a partial locked Start Layout will all default icons to show  
#This script will run once on each computer directly after enrollment and remove the last used profile
#and the Start Layout will be nice and clean
#.EXAMPLE
#Upload the script to Microsoft Intune, run in system context and apply to all users
#.NOTES
#This script will remove the last used profile on the computer with a scheduled task, and notify the user when the script has run
#To configure the script define the variables
#Only change other settings if you know what you are doing
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


#region User defined variables
$ScriptFolder = "DeployWindows"
$ScheduledScriptName = "ConfigureStartLayoutCustomization.ps1"
$ScheduledTaskName = "ConfigureStartLayoutCustomization"
$ScriptFolderFullPath = "$($Env:ProgramData)\$($ScriptFolder)"
$ScriptRegistryPath = "HKLM:\SOFTWARE\$($ScriptFolder)"
$ScriptRegistryResultName = "$($ScheduledTaskName)Result"
$ForceRestart = $true
$ForceRestartTimeout = 10
$ResetIntuneManagementExtensionPolicies = $false
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

$ScheduledScript = 'Start-Transcript -Path "' + $ScriptFolderFullPath + '\' + $ScheduledScriptName + '.log" -Append
  #Remove the last used profile
  $Error.Clear()
  $UserProfile = Get-WmiObject -Class Win32_UserProfile -ComputerName Localhost -Filter "LocalPath like ''c:\\Users%''" | Sort LastUseTime -Descending  | select -First 1
  $UserProfile.Delete()
  if ($Error.Count -eq 0) { Unregister-ScheduledTask -TaskName "' + $ScheduledTaskName + '" -Confirm:$false -ErrorAction Continue }
Stop-Transcript'

$ScheduledTask = [xml]('<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2018-01-08T08:00:00.0000000</Date>
    <Author>Administrator</Author>
    <Description>Last Used Profile Remover for Microsoft Intune. This is used to clean user start layout</Description>
    <URI>\Create Start</URI>
  </RegistrationInfo>
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>ConsoleDisconnect</StateChange>
    </SessionStateChangeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy ByPass "' + $ScriptFolderFullPath + '\' + $ScheduledScriptName + '"</Arguments>
    </Exec>
  </Actions>
</Task>')

$ScriptAlreadyExecuted = Get-ItemProperty -Path $ScriptRegistryPath -Name $ScriptRegistryResultName -ErrorAction SilentlyContinue
if ($ScriptAlreadyExecuted -eq $empty) {
  # Script has never run, continue
} else {
  Write-Output "Stopping script: The script has already run"
  break 0
}

New-Item -ItemType Directory -Path $ScriptFolderFullPath -Force -ErrorAction SilentlyContinue | Out-Null
$ScheduledScript | Out-File -FilePath "$($ScriptFolderFullPath)\$($ScheduledScriptName)" -Force
Register-ScheduledTask -Xml $ScheduledTask.OuterXml  -TaskName $ScheduledTaskName

# Create a registy value to ensure not rerun by mistake
New-Item -ItemType Directory -Path $ScriptRegistryPath -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $ScriptRegistryPath -Name $ScriptRegistryResultName -Value 1 -PropertyType DWORD -Force -ErrorAction SilentlyContinue  | Out-Null

if ($ResetIntuneManagementExtensionPolicies) {
  #This will make sure all Intune Management Extension Policies that already have run, will rerun after user logon
  $IMEPolicyRegistryPath = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Policies"
  Remove-Item -Path $IMEPolicyRegistryPath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
  New-Item -ItemType Directory -Path $IMEPolicyRegistryPath -Force -ErrorAction SilentlyContinue | Out-Null
}

if ($ForceRestart) {
  ShowToast -ToastTitle "$($ScheduledTaskName) installed" -ToastText "Computer will restart within: $($ForceRestartTimeout)" -ToastDuration long
  Start-Sleep -Seconds $ForceRestartTimeout
  Restart-Computer -Force
} else {
  ShowToast -ToastTitle "$($ScheduledTaskName) installed" -ToastText "Please restart computer as soon as possible!" -ToastDuration long
}

#Always return true
0
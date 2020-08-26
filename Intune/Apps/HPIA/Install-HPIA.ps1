##############################
#.SYNOPSIS
#  This will install HPIA from the current folder and creates a shortcut on the start menu
#   Download HPIA and place the file in the same folder
#   https://ftp.hp.com/pub/caps-softpaq/cmit/HPIA.html
#   https://ftp.hp.com/pub/softpaq/sp107001-107500/sp107374.exe
#
#.EXAMPLE
#
#.NOTES
#
#Version
# 1.0 First release
#
##############################
#Author
#@MattiasFors
#https://deploywindows.com
#https://github.com/DeployWindowsCom/DeployWindows-Scripts
##############################

#Init variables
$TargetDir = "$($env:WinDir)\Temp\HPIA"

#Extract the files
$exe = "sp107374.exe"
$exeParams = "/s /e /f `"$($TargetDir)\App`""
Start-Process -FilePath $exe -ArgumentList $exeParams -Wait -WindowStyle Hidden

# Create the Shortcut 
$TargetFile = "$($TargetDir)\App\HPImageAssistant.exe"
$ShortcutFile = "$($env:ALLUSERSPROFILE)\Microsoft\Windows\Start Menu\Programs\HP Image Assistant.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$shortcut.Arguments = "/SoftPaqDownloadFolder:$($TargetDir)\SoftPaq /ReportFolder:$($TargetDir)"
$shortcut.RelativePath = $($TargetDir)
$Shortcut.Save()

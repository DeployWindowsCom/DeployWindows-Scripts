##############################
#.SYNOPSIS
#  This will uninstall HPIA from the specified folder and removes the shortcut on the start menu
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
$ShortcutFile = "$($env:ALLUSERSPROFILE)\Microsoft\Windows\Start Menu\Programs\HP Image Assistant.lnk"

Remove-Item -Recurse -Path $TargetDir
Remove-Item -Path $ShortcutFile

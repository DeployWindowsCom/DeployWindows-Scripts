##############################
#.SYNOPSIS
#  This will put all Microsoft*Copy*.lnk shortcuts on the desktop 
#    in the recycle bin
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

Add-Type -AssemblyName Microsoft.VisualBasic

#Get desktop path
$DesktopPath = [Environment]::GetFolderPath("Desktop")

#Searching on desktop for all Microsoft * Copy shortcuts, 
# such as Microsoft Teams - Copy.lnk
$files = Get-ChildItem -Path $DesktopPath -Filter Microsoft*Copy*.lnk

foreach ($item in $files)
{
    Write-Host "Found: $($item.FullName)"
    if (Test-Path -Path $item.FullName -PathType Container)
    {
    ##    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($fullpath,'OnlyErrorDialogs','SendToRecycleBin')
    }
    else
    {
        Write-Host "Put the file in recycle bin"
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($item.FullName,'OnlyErrorDialogs','SendToRecycleBin')
    }
}

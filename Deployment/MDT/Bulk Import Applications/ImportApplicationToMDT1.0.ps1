<#
#########################################################################################
#   This Sample Code is provided for the purpose of illustration only and is not 
#   intended to be used in a production environment.
#
#   WARNING:
#   YOU SHOULD NEVER RUN A SCRIPT IN PRODUCTION IF YOU AREN’T 100% CERTAIN OF WHAT IT 
#   WILL DO.  ALL SCRIPTS SHOULD BE THOROUGHLY UNDERSTOOD AND TESTED IN A NON-PRODUCTION
#   ENVIRONMENT PRIOR TO BEING USED IN PRODUCTION.  THIS HELPS ENSURE THAT PRODUCTION 
#   PROBLEMS DO NOT OCCUR AS A RESULT OF RUNNING SCRIPTS THAT HAVE NOT BEEN TESTED AND 
#   VALIDATED BEFOREHAND.
#
#   THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY 
#   OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED 
#   WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#########################################################################################

 ##################################################################################
 #  Script name:    ImportApplicationToMDT.ps1
 #  Created:		2017-09-12
 #  Author:         Mattias Fors
 #                  @MattiasFors
 #                  http://www.deploywindows.com
 # History:
 #  1.0             Created first version
 ##################################################################################

#>

$MDT_Install_Dir = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Deployment 4\" -Name "Install_Dir" -ErrorAction SilentlyContinue
if ($MDT_Install_Dir -eq $null ) {
    Write-Host "Do you have MDT installed?"
    break
}

if (@($(Get-Module -Name "MicrosoftDeploymentToolkit")).Count -ge 1) {
    Write-Host "Module already loaded"
} else {
    Import-Module "$($MDT_Install_Dir)\bin\MicrosoftDeploymentToolkit.psd1"
}

if (@($(Get-MDTPersistentDrive)).Count -ne 1){
    Write-Host "Do not have support for more than one deployment share ATM...";
    break;
}
# Get deployment share information and mount drive
$MDT_DeployShare_Name = (Get-MDTPersistentDrive).Name
$MDT_DeployShare_Path = (Get-MDTPersistentDrive).Path
if (@($(Get-PSDrive -PSProvider MDTProvider -Name $MDT_DeployShare_Name -ErrorAction SilentlyContinue).Count -ge 1)) {
    Remove-PSDrive -Name $MDT_DeployShare_Name -PSProvider MDTProvider
}
New-PSDrive -Name $MDT_DeployShare_Name -PSProvider MDTProvider -Root $MDT_DeployShare_Path | Out-Null

#Get-ChildItem -Path "DS001:\"
#Get-Item "DS001:\Task Sequences\Test\Test 01"
#Import-MDTApplication -Path "DS001:\Applications\Microsoft Visual C++" -enable "True" -Name "Microsoft Visual C++ 2005 x64" -ShortName "VS2005" -Version "1" -Publisher "Microsoft" -CommandLine "vcredist_x64.exe /qb /norestart" -WorkingDirectory ".\Applications\VS2005" -ApplicationSourcePath "C:\Downloads\VS2005" -DestinationFolder "VS2005" –Verbose
#Import-MDTApplication -Path "DS001:\Applications\Microsoft Visual C++" -enable "True" -Name "Microsoft Visual C++ 2005 x86" -ShortName "VS2005" -Version "1" -Publisher "Microsoft" -CommandLine "vcredist_x86.exe" -WorkingDirectory ".\Applications\VS2005" -NoSource -Verbose

$MDT_Applications_Path = "$($MDT_DeployShare_Name):\Applications"
$Download_Path = "$($PSScriptRoot)\Downloads"
$Download_File = "$($PSScriptRoot)\Download.xml"

# Read download file, download necessary files and import applications in MDT
[xml]$Data = Get-Content -Path $Download_File
ForEach($DataRecord in $Data.Download.DownloadItem)
{
    Write-Host "Download and import MDT application: $($DataRecord.FullName)"

    # Create folder in Applications node if needed
    if ($DataRecord.MDTFolderName -like $null) {
        $MDTFolderName = "$($MDT_Applications_Path)"
    } else {
        $MDTFolderName = "$($MDT_Applications_Path)\$($DataRecord.MDTFolderName)"
        New-Item -path "$($MDT_Applications_Path)" -enable "True" `
            -Name "$($DataRecord.MDTFolderName)" -Comments "" -ItemType "folder" `
            -ErrorAction SilentlyContinue
    }

    if ($DataRecord.Source -notlike $null) {
        # Application with source

        # Download the source files from HTTP/HTTPS
        New-Item -Path "$($Download_Path)\$($DataRecord.DestinationFolder)" `
            -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        if ($DataRecord.Source -like "http*") {
            # If you need to encode an source use this command
            # [System.Web.HttpUtility]::UrlEncode("https://server/file?a=b&c=d")
            Start-BitsTransfer -Destination "$($Download_Path)\$($DataRecord.DestinationFolder)\$($DataRecord.DestinationFile)" `
                -Source "$([System.Web.HttpUtility]::UrlDecode($DataRecord.Source))" -Description "Download $($DataRecord.FullName)" `
                -ErrorAction Continue
            if ($DataRecord.CommandAfterDownload -notlike $null) {
                # If the downloaded file requires to be extracted before import, run these commands
                # https://social.technet.microsoft.com/wiki/contents/articles/7703.powershell-running-executables.aspx#Invoke-Command_ICM
                $exe = "$($Download_Path)\$($DataRecord.DestinationFolder)\$($DataRecord.CommandAfterDownload)"
                $CommandLineSwitchesAfterDownload = $DataRecord.CommandLineSwitchesAfterDownload
                Start-Process -FilePath $exe -ArgumentList $CommandLineSwitchesAfterDownload `
                    -WorkingDirectory "$($Download_Path)\$($DataRecord.DestinationFolder)" `
                    -Wait -WindowStyle Normal
            }
        } elseif ((($DataRecord.Source).Substring(0,3) -in @((Get-PSDrive -PSProvider FileSystem).Root)) -or ($DataRecord.Source -like "\\*")) {
            # Local source
            if (Test-Path $DataRecord-Source) {
                Write-Host "This is not implemented yet" -ForegroundColor Yellow
            } else {
                Write-Host "Something wrong with the folder!" -ForegroundColor Red
            }
        }

        Import-MDTApplication -Path $MDTFolderName -Enable "True" -Name $DataRecord.FullName `
            -ShortName $DataRecord.ShortName -Publisher $DataRecord.Publisher `
            -CommandLine "$($DataRecord.Command) $($DataRecord.CommandLineSwitches)" `
            -WorkingDirectory ".\Applications\$($DataRecord.DestinationFolder)" `
            -ApplicationSourcePath "$($Download_Path)\$($DataRecord.DestinationFolder)" `
            -Version $DataRecord.Version `
            -DestinationFolder $DataRecord.DestinationFolder;
    } else {
        # Application without source
        Import-MDTApplication -enable "True" -path $MDTFolderName -Name $DataRecord.FullName `
            -ShortName $DataRecord.ShortName -Version $DataRecord.Version -Publisher $DataRecord.Publisher `
            -Language "" -CommandLine "$($DataRecord.Command) $($DataRecord.CommandLineSwitches)" `
            -WorkingDirectory "$($DataRecord.DestinationFolder)" -NoSource;
    }

}

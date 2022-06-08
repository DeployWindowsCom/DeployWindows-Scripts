#region Restart into 64-bit
$Is64Bit = [System.Environment]::Is64BitProcess;
$Is64OS = $false; if (($env:PROCESSOR_ARCHITEW6432 -like "AMD64") -or ($env:PROCESSOR_ARCHITECTURE -like "AMD64")) { $Is64OS = $true; }

if (($Is64OS) -and (-not $Is64Bit)) {
    # Running AMD64 but no AMD64 Process, Restart script
    $Invocation = $PSCommandPath
    if ($null -eq $Invocation) { return }
    $SysNativePath = $PSHOME.ToLower().Replace("syswow64", "sysnative")
    $Ret = Start-Process "$SysNativePath\powershell.exe" -ArgumentList "-ex ByPass -file `"$Invocation`" " -WindowStyle normal -PassThru -Wait
    $Ret.WaitForExit()
    Write-Error -Message "Exit with errors"
    Exit $Ret.ExitCode;
} elseif ((-not $Is64OS) -and (-not $Is64Bit)) {
    #Running x86 and no AMD64 Process, Do not bother restarting
}
#endregion

###############################################
# Main script starts here
###############################################


#Set to TRUE to test the settings and what should have been changed
# False will perform all changes
$script:WhatIf = $false

$installFolder = "$(Split-Path $($MyInvocation.MyCommand.Path) -Parent)\"
$logfile = Join-Path -Path $env:TEMP -ChildPath "Log-AutopilotBranding.log"
Add-Content -Path $logfile -Value "$(Get-Date): Script starting up"

#Get all local user profiles
$UserProfile = Get-ChildItem 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\ProfileList' | ForEach-Object { $_.GetValue('ProfileImagePath') }

#region Initialize: Load the Config.xml
Add-Content -Path $logfile -Value "$(Get-Date): Install path: $($installFolder)"
Add-Content -Path $logfile -Value "$(Get-Date): Loading configuration from file: $($installFolder)Configuration.xml"
try {
    [Xml]$config = Get-Content "$($installFolder)Configuration.xml"    
}
catch {
    Add-Content -Path $logfile -Value "$(Get-Date): configuration file cannot be loaded"
}
#endregion Initialize: Load the Config.xml

#region Only run during OS setup
if (($UserProfile -like '*defaultuser*') ){

    #region Activity 1: Set time zone (if specified)
    if ($config.Branding.TimeZone) {
        if ($config.Branding.TimeZone.Id) {
            Add-Content -Path $logfile -Value "$(Get-Date): Set time zone: $($config.Branding.TimeZone.OuterXml)"
            if (-not $script:WhatIf) { Set-Timezone -Id $config.Branding.TimeZone.Id }
        }
        if ($config.Branding.TimeZone.SynchronizeTimeService) {
            if (($config.Branding.TimeZone.SynchronizeTimeService) -eq "true") {
                Add-Content -Path $logfile -Value "$(Get-Date): SynchronizeTimeService: $($config.Branding.TimeZone.SynchronizeTimeService)"
                if (-not $script:WhatIf) { 
                    Start-Service w32time
                    Start-Process -FilePath "w32tm.exe" -ArgumentList @("/resync","/force") -NoNewWindow -Wait -PassThru
                 }
            } else {
                Add-Content -Path $logfile -Value "$(Get-Date): SynchronizeTimeService: $($config.Branding.TimeZone.SynchronizeTimeService)"
            }
        }
    }
    #endregion Activity 1: Set time zone (if specified)

    #region Activity 2: Remove provisioned apps if exists
    if ($config.Branding.RemoveApps) {
        $apps = Get-AppxProvisionedPackage -online
        $config.Branding.RemoveApps.App | % {
            $current = $_
            $apps | ? {$_.DisplayName -eq $current} | % {
                Add-Content -Path $logfile -Value "$(Get-Date): Remove provisioned app: $current"
                if (-not $script:WhatIf) { $_ | Remove-AppxProvisionedPackage -Online | Out-Null }
            }
        }
    }
    #endregion Activity 2: Remove provisioned apps if exists

    #region Activity 3: Add features
    if ($config.Branding.AddFeatures) {
        $config.Branding.AddFeatures.Feature | % {
            Add-Content -Path $logfile -Value "$(Get-Date): Add feature: $_"
            if (-not $script:WhatIf) { Add-WindowsCapability -Online -Name $_ }
        }
    }
    #endregion Activity 3: Add features

    #region Activity 4: Add registry hacks
    if ($config.Branding.AddRegistry) {
        foreach ($item in $config.Branding.AddRegistry.Item) {
            Add-Content -Path $logfile -Value "$(Get-Date): Add Registry: $($item.Description)"
            if (-not (Test-Path $item.RegistryPath -PathType Container)) { 
                Add-Content -Path $logfile -Value "$(Get-Date): Add Registry: Create Path $($item.RegistryPath)"
                if (-not $script:WhatIf) { New-Item -Path $item.RegistryPath -Force | Out-Null }
            }
            $propertyType = $null
            switch ($item.RegistryType) {
                "REG_DWORD" { $propertyType = "DWORD" }
                "DWORD" { $propertyType = "DWORD" }
                "REG_SZ" { $propertyType = "String" }
                "String" { $propertyType = "String" }
                "REG_EXPAND_SZ" { $propertyType = "ExpandString" }
                "ExpandString" { $propertyType = "ExpandString" }
                "REG_BINARY" { $propertyType = "Binary" }
                "BINARY" { $propertyType = "String" }
                "REG_QWORD" { $propertyType = "Qword" }
                "QWORD" { $propertyType = "Qword" }
                "REG_MULTI_SZ" { $propertyType = "MultiString" }
                "MultiString" { $propertyType = "MultiString" }
                Default { Add-Content -Path $logfile -Value "$(Get-Date): Add Registry: Unknown registry type $($item.RegistryType)" }
            }
            if ($propertyType) {
                Add-Content -Path $logfile -Value "$(Get-Date): Add Registry: Creating registry item ($($item.RegistryPath)\$($item.RegistryName)[$($propertyType)]=$($item.RegistryData))"
                if (-not $script:WhatIf) { New-ItemProperty -Path $item.RegistryPath -Name $item.RegistryName -Value $item.RegistryData -PropertyType $propertyType -Force | Out-Null }
            }
        }
    }
    #endregion Activity 4: Add registry hacks

    #region Activity 5: Add default associations
    # Export associations Dism.exe /online /export-defaultappassociations:C:\temp\CustomFileAssoc.xml
    # https://techcommunity.microsoft.com/t5/ask-the-performance-team/how-to-configure-file-associations-for-it-pros/ba-p/1313151
    if ($config.Branding.DefaultApps) {
        Add-Content -Path $logfile -Value "$(Get-Date): Set DefaultApps: Associations file $($config.Branding.DefaultApps.File)"
        if (-not $script:WhatIf) { 	& Dism.exe /Online /Import-DefaultAppAssociations:`"$($installFolder)$($config.Branding.DefaultApps.File)`" }
    }
    #endregion Activity 5: Add features

    #region Activity 6: Upgrade OneDrive and change to pre-system installation
    # if the installed version is less than downloaded version, it will initialize an upgrade
    # Release info https://support.office.com/en-us/article/onedrive-release-notes-845dcf18-f921-435e-bf28-4e24b95e5fc0
    if ($config.Branding.OneDriveSetup) {
        switch ($config.Branding.OneDriveSetup.Install)
        {
            "production" { $DownloadPath = $config.Branding.OneDriveSetup.Production }
            "deferred" { $DownloadPath = $config.Branding.OneDriveSetup.Deferred }
            Default { $DownloadPath = $config.Branding.OneDriveSetup.Production }
        }
        Add-Content -Path $logfile -Value "$(Get-Date): OneDrive setup: Starting download latest OneDrive client $($DownloadPath)"
        Invoke-WebRequest -Uri $($DownloadPath) -OutFile (Join-Path "$($env:TEMP)" "OneDriveSetup.exe")
        $OneDriveSetup = (Join-Path "$($env:TEMP)" "OneDriveSetup.exe")
        Add-Content -Path $logfile -Value "$(Get-Date): OneDrive setup: Time to upgrade OneDrive $($OneDriveSetup) /allusers"
        if (-not $script:WhatIf) {
            $proc = Start-Process -FilePath $OneDriveSetup -ArgumentList "/allusers" -NoNewWindow -Wait -PassThru
            do { Start-Sleep -Seconds 2 } until ( $proc.HasExited )
            Add-Content -Path $logfile -Value "$(Get-Date): OneDrive setup Exit code: $($proc.ExitCode)"
        }
    }
    #endregion Activity 6: Add features

}
#endregion Only run during OS setup

    #region Post script: Tag Branding version in registry
    if ($config.Branding.BrandingVersion) {
        Add-Content -Path $logfile -Value "$(Get-Date): Post script: Tattoo version in registry $($config.Branding.BrandingPath)\$($config.Branding.BrandingName)=$($config.Branding.BrandingVersion)"
        if (-not (Test-Path $config.Branding.BrandingPath -PathType Container)) { 
            Add-Content -Path $logfile -Value "$(Get-Date): Post script: Create Path $($config.Branding.BrandingPath)"
            if (-not $script:WhatIf) { New-Item -Path $config.Branding.BrandingPath -Force | Out-Null }
        }
        Add-Content -Path $logfile -Value "$(Get-Date): Post script: Creating registry item"
        if (-not $script:WhatIf) { New-ItemProperty -Path $config.Branding.BrandingPath -Name $config.Branding.BrandingName -Value $config.Branding.BrandingVersion -PropertyType "string" -Force | Out-Null }
    }
    #endregion Post script: Tag Branding version in registry


Write-Host "Script ending.."
exit 0

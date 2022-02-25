
#Set to TRUE to test the settings and what should have been changed
# False will perform all changes
$script:WhatIf = $true

$installFolder = "$(Split-Path $($MyInvocation.MyCommand.Path) -Parent)\"
$installFolder = "C:\repo\DeployWindows-Scripts\Intune\Autopilot\Branding kit\"

#Get all local user profiles
$UserProfile = Get-ChildItem 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\ProfileList' | ForEach-Object { $_.GetValue('ProfileImagePath') }

#region Initialize: Load the Config.xml
Write-Host "Install path: $($installFolder)"
Write-Host "Loading configuration from file: $($installFolder)Configuration.xml"
[Xml]$config = Get-Content "$($installFolder)Configuration.xml"
#endregion Initialize: Load the Config.xml

#region Pre script: Check brand version
If (Test-Path -Path $($config.Branding.BrandingPath)) {
    if (Get-ItemProperty -Path $config.Branding.BrandingPath -Name $config.Branding.BrandingName -ErrorAction Ignore) {
        $version = Get-ItemPropertyValue -Path $config.Branding.BrandingPath -Name $config.Branding.BrandingName -ErrorAction Ignore
        if ($version -ge $config.Branding.BrandingVersion) {
            Write-Host "Pre script: Do NOT run script, version higher"
            Exit 1
        } else {
            Write-Host "Pre script: Run script, Version too low"
        }
    } else {
        Write-Host "Pre script: Run script, Version does not exist"
    }
} else {
    Write-Host "Pre script: Run script, no version installed"
}
#endregion Pre script: Check brand version

#region Only run during OS setup
if (($UserProfile -like '*defaultuser*') ){

    #region Activity 1: Set time zone (if specified)
    if ($config.Branding.TimeZone) {
        Write-Host "Set time zone: $($config.Branding.TimeZone.OuterXml)"
        if (-not $script:WhatIf) { Set-Timezone -Id $config.Branding.TimeZone.Id }
    }
    #endregion Activity 1: Set time zone (if specified)

    #region Activity 2: Remove provisioned apps if exists
    if ($config.Branding.RemoveApps) {
        $apps = Get-AppxProvisionedPackage -online
        $config.Branding.RemoveApps.App | % {
            $current = $_
            $apps | ? {$_.DisplayName -eq $current} | % {
                Write-Host "Remove provisioned app: $current"
                if (-not $script:WhatIf) { $_ | Remove-AppxProvisionedPackage -Online | Out-Null }
            }
        }
    }
    #endregion Activity 2: Remove provisioned apps if exists

    #region Activity 3: Add features
    if ($config.Branding.AddFeatures) {
        $config.Branding.AddFeatures.Feature | % {
            Write-Host "Add feature: $_"
            if (-not $script:WhatIf) { Add-WindowsCapability -Online -Name $_ }
        }
    }
    #endregion Activity 3: Add features

    #region Activity 4: Add registry hacks
    if ($config.Branding.AddRegistry) {
        foreach ($item in $config.Branding.AddRegistry.Item) {
            Write-Host "Add Registry: $($item.Description)"
            if (-not (Test-Path $item.RegistryPath -PathType Container)) { 
                Write-Host "Add Registry: Create Path $($item.RegistryPath)"
                if (-not $script:WhatIf) { New-Item -Path $item.RegistryPath -ItemType Registry -Force | Out-Null }
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
                Default { Write-Host "Add Registry: Unknown registry type $($item.RegistryType)" }
            }
            if ($propertyType) {
                Write-Host "Add Registry: Creating registry item ($($item.RegistryPath)\$($item.RegistryName)[$($propertyType)]=$($item.RegistryData))"
                if (-not $script:WhatIf) { New-ItemProperty -Path $item.RegistryPath -Name $item.RegistryName -Value $item.RegistryValue -PropertyType $propertyType -Force | Out-Null }
            }
        }
    }
    #endregion Activity 4: Add registry hacks

    #region Activity 5: Add default associations
    # Export associations Dism.exe /online /export-defaultappassociations:C:\temp\CustomFileAssoc.xml
    # https://techcommunity.microsoft.com/t5/ask-the-performance-team/how-to-configure-file-associations-for-it-pros/ba-p/1313151
    if ($config.Branding.DefaultApps) {
        Write-Host "Set DefaultApps: Associations file $($config.Branding.DefaultApps.File)"
        if (-not $script:WhatIf) { 	& Dism.exe /Online /Import-DefaultAppAssociations:`"$($installFolder)$($config.Branding.DefaultApps.File)`" }
    }
    #endregion Activity 5: Add features

    #region Activity 5: Upgrade OneDrive and change to pre-system installation
    # if the installed version is less than downloaded version, it will initialize an upgrade
    # Release info https://support.office.com/en-us/article/onedrive-release-notes-845dcf18-f921-435e-bf28-4e24b95e5fc0
    if ($config.Branding.OneDriveSetup) {
        switch ($config.Branding.OneDriveSetup.Install)
        {
            "production" { $DownloadPath = $config.Branding.OneDriveSetup.Production }
            "deferred" { $DownloadPath = $config.Branding.OneDriveSetup.Deferred }
            Default { $DownloadPath = $config.Branding.OneDriveSetup.Production }
        }
        Write-Host "OneDrive setup: Starting download latest OneDrive client $($DownloadPath)"
        Invoke-WebRequest -Uri $($DownloadPath) -OutFile (Join-Path "$($env:TEMP)" "OneDriveSetup.exe")
        $OneDriveSetup = (Join-Path "$($env:TEMP)" "OneDriveSetup.exe")
        Write-Host "OneDrive setup: Time to upgrade OneDrive $($OneDriveSetup) /allusers"
        if (-not $script:WhatIf) {
            $proc = Start-Process -FilePath $OneDriveSetup -ArgumentList "/allusers" -WindowStyle Hidden -PassThru
            $proc.WaitForExit()
            Write-Host "OneDrive setup: Exit code: $($proc.ExitCode)"
        }
    }
    #endregion Activity 5: Add features

}
#endregion Only run during OS setup

    #region Post script: Tag Branding version in registry
    if ($config.Branding.BrandingVersion) {
        Write-Host "Post script: Tattoo version in registry $($config.Branding.BrandingPath)\$($config.Branding.BrandingName)=$($config.Branding.BrandingVersion)"
        if (-not (Test-Path $config.Branding.BrandingPath -PathType Container)) { 
            Write-Host "Post script: Create Path $($config.Branding.BrandingPath)"
            if (-not $script:WhatIf) { New-Item -Path $config.Branding.BrandingPath -ItemType Registry -Force | Out-Null }
        }
        Write-Host "Post script: Creating registry item"
        if (-not $script:WhatIf) { New-ItemProperty -Path $config.Branding.BrandingPath -Name $config.Branding.BrandingName -Value $config.Branding.BrandingVersion -PropertyType "string" -Force | Out-Null }
    }
    #endregion Post script: Tag Branding version in registry



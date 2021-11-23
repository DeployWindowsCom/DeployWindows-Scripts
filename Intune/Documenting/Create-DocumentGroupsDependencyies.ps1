$filterStartswith = "mdm-","mfa-"

#Init Word doc
$FilePath = "$($Env:TEMP)\AzureAD-Groups.docx"
Import-Module PSWriteWord
$doc = New-WordDocument $FilePath 

#init Visio doc
$visio = $true
if ($visio) {
    Import-Module Visio
    $visioApp = New-VisioApplication
    $visioDoc = New-VisioDocument
    #$shapesAzureIdentity =Open-VisioDocument -Filename "C:\Program Files\Microsoft Office\root\Office16\Visio Content\1033\AZUREIDENTITY_M.VSSX"
    $shapesAzureIntune =Open-VisioDocument -Filename "C:\Program Files\Microsoft Office\root\Office16\Visio Content\1033\AZUREINTUNE_M.VSSX"
    #$aadGroup = Get-VisioMaster -Document $shapesAzureIdentity -Name "Groups"
    $intuneGroup = Get-VisioMaster -Document $shapesAzureIntune -Name "Groups"
    $intuneUserGroup = Get-VisioMaster -Document $shapesAzureIntune -Name "User Group"
    $intuneMAM = Get-VisioMaster -Document $shapesAzureIntune -Name "Intune Mobile Application Management"
    $intunePolicy = Get-VisioMaster -Document $shapesAzureIntune -Name "Policy"
    $intuneCompliance = Get-VisioMaster -Document $shapesAzureIntune -Name "Protection"
    $intuneCA = Get-VisioMaster -Document $shapesAzureIntune -Name "Terms and Conditions"
    $intuneApps = Get-VisioMaster -Document $shapesAzureIntune -Name "Apps"
    $posIntuneGroup = [VisioAutomation.Geometry.Point]::new(1,1)
    $posIntuneCompliance = [VisioAutomation.Geometry.Point]::new($posIntuneGroup.X - 3, $posIntuneGroup.Y)
    $posIntuneConfiguration = [VisioAutomation.Geometry.Point]::new($posIntuneGroup.X - 6, $posIntuneGroup.Y)
    $posIntuneMAM = [VisioAutomation.Geometry.Point]::new($posIntuneGroup.X - 9, $posIntuneGroup.Y)
    $posIntuneCA = [VisioAutomation.Geometry.Point]::new($posIntuneGroup.X - 12, $posIntuneGroup.Y)
}

Connect-Graph -Scopes "group.read.all","user.read.all","device.read.all","DeviceManagementConfiguration.Read.All","Policy.Read.All","DeviceManagementApps.Read.All," -ForceRefresh

# Get assignments for all compliance policies
Write-Host "Looking up assignment for compliance policies..."
$deviceCompliancePolicies = (Invoke-GraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies/")
$deviceComplianceAssignments = @()
foreach ($deviceCompliancePolicy in $deviceCompliancePolicies.value) {
    $deviceComplianceAssignments += (Invoke-GraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies/$($deviceCompliancePolicy.id)/assignments").value `
        | Add-Member -Name "displayName" -Value $deviceCompliancePolicy.displayName -MemberType NoteProperty -PassThru
}

# Get assignments for all Device configuration policies
Write-Host "Looking up assignment for device configuration policies..."
$deviceConfigurationPolicies = (Invoke-GraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/")
$deviceConfigurationAssignments = @()
foreach ($deviceConfigurationPolicy in $deviceConfigurationPolicies.value) {
    $deviceConfigurationAssignments += (Invoke-GraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$($deviceConfigurationPolicy.id)/assignments").value `
        | Add-Member -Name "displayName" -Value $deviceConfigurationPolicy.displayName -MemberType NoteProperty -PassThru
}

# Get Assignment for all Application Protection Polices, MAM/APP
Write-Host "Looking up assignment for app protection policies..."
$appProtectionPolicies = (Invoke-GraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/managedAppPolicies/")
$appProtectionAssignments = @()
foreach ($appProtectionPolicy in $appProtectionPolicies.value) {
    # Ref: https://docs.microsoft.com/en-us/graph/api/intune-mam-targetedmanagedapppolicyassignment-list?view=graph-rest-1.0
    switch ($appProtectionPolicy.'@odata.type') {
        '#microsoft.graph.iosManagedAppProtection' {  
            $appProtectionAssignments += (Invoke-GraphRequest -Uri "https://graph.microsoft.com/beta/deviceAppManagement/iosManagedAppProtections/$($appProtectionPolicy.id)/assignments").value `
                | Add-Member -Name "displayName" -Value $appProtectionPolicy.displayName -MemberType NoteProperty -PassThru
            $appProtectionAssignments[$appProtectionAssignments.Count-1].sourceId = $appProtectionPolicy.id
        }
        '#microsoft.graph.androidManagedAppProtection' {  
            $appProtectionAssignments += (Invoke-GraphRequest -Uri "https://graph.microsoft.com/beta/deviceAppManagement/androidManagedAppProtections/$($appProtectionPolicy.id)/assignments").value `
                | Add-Member -Name "displayName" -Value $appProtectionPolicy.displayName -MemberType NoteProperty -PassThru
            $appProtectionAssignments[$appProtectionAssignments.Count-1].sourceId = $appProtectionPolicy.id
        }
    }
}

# Get assignments for all  Conditional Access policies
Write-Host "Looking up assignment for conditional access policies..."
$conditionalAccessPolices = (Invoke-GraphRequest -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies/").value

#Add-WordTOC -WordDocument $doc -MaxIncludeLevel 1 -HeaderStyle Heading1 | Out-Null
#Add-WordPageBreak -WordDocument $doc | Out-Null

foreach ($filter in $filterStartswith) {
    Write-Host "Searching for $($filter).."
    $groups = (Invoke-GraphRequest -Uri "https://graph.microsoft.com/v1.0/groups/?filter=startswith(displayName,'$($filter)')").value

    foreach ($group in $groups) {
        Write-Host "Documenting $($group.DisplayName)"

        #Word
        Add-WordText -WordDocument $doc -Text $group.DisplayName -HeadingType Heading1 | Out-Null
        Add-WordText -WordDocument $doc -Text "$($group.Description)`n"  | Out-Null

        if ($visio) {
            if (-not (Get-VisioShape -Name $group.id)) {
                if ($posIntuneGroup.Y -gt 11) { $posIntuneGroup = [VisioAutomation.Geometry.Point]::new($posIntuneGroup.X + 2, 1) }

                $shape = New-VisioShape -Master $intuneGroup -Position $posIntuneGroup
                $shape.NameU = $group.id
                $shape.Text = $group.displayName
                $posIntuneGroup = [VisioAutomation.Geometry.Point]::new($posIntuneGroup.X, $posIntuneGroup.Y + 1)
            }
        } 

        # Adding compliance
        if ($group.id -in $deviceComplianceAssignments.target.groupid) {
            Add-WordText -WordDocument $doc -Text "Compliance policy assignments" -HeadingType Heading2 | Out-Null
            Add-WordText -WordDocument $doc -Text "Found dependencies to the follwing compliance policies"  | Out-Null
            ($deviceComplianceAssignments | Where-Object { $_.target.groupid -eq $group.id }) | ForEach-Object { 
                Add-WordText -WordDocument $doc -Text $_.DisplayName 

                if ($visio) { 
                    if (-not (Get-VisioShape -Name $_.sourceId)) {
                        $shape = New-VisioShape -Master $intuneCompliance -Position $posIntuneCompliance
                        $shape.NameU = $_.sourceId
                        $shape.Text = $_.displayName
                        $posIntuneCompliance = [VisioAutomation.Geometry.Point]::new($posIntuneCompliance.X, $posIntuneCompliance.Y + 1)
                    }
                    (Get-VisioShape -Name $group.id).AutoConnect((Get-VisioShape -Name $_.sourceId), [Microsoft.Office.Interop.Visio.VisAutoConnectDir]::visAutoConnectDirNone, $null)
                }
            }  | Out-Null
        }

        # Adding device configurations
        if ($group.id -in $deviceConfigurationAssignments.target.groupid) {
            Add-WordText -WordDocument $doc -Text "Device configuration policy assignments" -HeadingType Heading2 | Out-Null
            Add-WordText -WordDocument $doc -Text "Found dependencies to the follwing device configurations"  | Out-Null
            ($deviceConfigurationAssignments | Where-Object { $_.target.groupid -eq $group.id }) | ForEach-Object { 
                Add-WordText -WordDocument $doc -Text $_.DisplayName 
            
                if ($visio) { 
                    if (-not (Get-VisioShape -Name $_.sourceId)) {
                        $shape = New-VisioShape -Master $intunePolicy -Position $posIntuneConfiguration
                        $shape.NameU = $_.sourceId
                        $shape.Text = $_.displayName
                        $posIntuneConfiguration = [VisioAutomation.Geometry.Point]::new($posIntuneConfiguration.X, $posIntuneConfiguration.Y + 1)
                    }
                    (Get-VisioShape -Name $group.id).AutoConnect((Get-VisioShape -Name $_.sourceId), [Microsoft.Office.Interop.Visio.VisAutoConnectDir]::visAutoConnectDirNone, $null)
                }
            }  | Out-Null
        }

        # Adding app protection MAM/APP
        if ($group.id -in $appProtectionAssignments.target.groupid) {
            Add-WordText -WordDocument $doc -Text "App protection policy assignments" -HeadingType Heading2 | Out-Null
            Add-WordText -WordDocument $doc -Text "Found dependencies to the follwing app protections"  | Out-Null
            ($appProtectionAssignments | Where-Object { $_.target.groupid -eq $group.id }) | ForEach-Object { 
                Add-WordText -WordDocument $doc -Text $_.DisplayName 

                if ($visio) { 
                    if (-not (Get-VisioShape -Name $_.sourceId)) {
                        $shape = New-VisioShape -Master $intuneMAM -Position $posIntuneMAM
                        $shape.NameU = $_.sourceId
                        $shape.Text = $_.displayName
                        $posIntuneMAM = [VisioAutomation.Geometry.Point]::new($posIntuneMAM.X, $posIntuneMAM.Y + 1)
                    }
                    (Get-VisioShape -Name $group.id).AutoConnect((Get-VisioShape -Name $_.sourceId), [Microsoft.Office.Interop.Visio.VisAutoConnectDir]::visAutoConnectDirNone, $null)
                }
            }  | Out-Null
        }

        # Adding conditional access polices
        if (($group.id -in $conditionalAccessPolices.conditions.users.includeGroups) -or 
            ($group.id -in $conditionalAccessPolices.conditions.users.excludeGroups)) {
            Add-WordText -WordDocument $doc -Text "Conditional access assignments" -HeadingType Heading2 | Out-Null
            Add-WordText -WordDocument $doc -Text "Found dependencies to the following conditional access policies"  | Out-Null
            if ($group.id -in $conditionalAccessPolices.conditions.users.includeGroups) {
                Add-WordText -WordDocument $doc -Text "Includes" -HeadingType Heading3 | Out-Null
                ($conditionalAccessPolices | Where-Object { $_.conditions.users.includeGroups -eq $group.id }) | ForEach-Object { 
                    Add-WordText -WordDocument $doc -Text $_.DisplayName 

                    if ($visio) { 
                        if (-not (Get-VisioShape -Name $_.id)) {
                            $shape = New-VisioShape -Master $intuneCA -Position $posIntuneCA
                            $shape.NameU = $_.id
                            $shape.Text = $_.displayName
                            $posIntuneCA = [VisioAutomation.Geometry.Point]::new($posIntuneCA.X, $posIntuneCA.Y + 1)
                        }
                        (Get-VisioShape -Name $group.id).AutoConnect((Get-VisioShape -Name $_.id), [Microsoft.Office.Interop.Visio.VisAutoConnectDir]::visAutoConnectDirNone, $null)
                    }
                }  | Out-Null
            }
            if ($group.id -in $conditionalAccessPolices.conditions.users.excludeGroups) {
                Add-WordText -WordDocument $doc -Text "Excludes" -HeadingType Heading3 | Out-Null
                ($conditionalAccessPolices | Where-Object { $_.conditions.users.excludeGroups -eq $group.id }) | ForEach-Object { 
                    Add-WordText -WordDocument $doc -Text $_.DisplayName 

                    if ($visio) { 
                        if (-not (Get-VisioShape -Name $_.id)) {
                            $shape = New-VisioShape -Master $intuneCA -Position $posIntuneCA
                            $shape.NameU = $_.id
                            $shape.Text = $_.displayName
                            $posIntuneCA = [VisioAutomation.Geometry.Point]::new($posIntuneCA.X, $posIntuneCA.Y + 1)
                        }
                        (Get-VisioShape -Name $group.id).AutoConnect((Get-VisioShape -Name $_.id), [Microsoft.Office.Interop.Visio.VisAutoConnectDir]::visAutoConnectDirNone, $null)
                    }
                }  | Out-Null
            }
        }

        $members = (Invoke-GraphRequest -Uri "https://graph.microsoft.com/v1.0/groups/$($group.id)/members").value
        $memberOf = (Invoke-GraphRequest -Uri "https://graph.microsoft.com/v1.0/groups/$($group.id)/memberOf").value

        Add-WordText -WordDocument $doc -Text "Member Of" -HeadingType Heading2 | Out-Null
        Add-WordText -WordDocument $doc -Text "Groups: $(@($memberOf | Where-Object {$_.'@odata.type' -eq "#microsoft.graph.group"} ).Count)" | Out-Null
        if (@($memberOf | Where-Object {$_.'@odata.type' -eq "#microsoft.graph.group"}).Count -gt 0) {
            Add-WordText -WordDocument $doc -Text "Groups" -HeadingType Heading3 | Out-Null
            foreach ($item in @($memberOf | Where-Object {$_.'@odata.type' -eq "#microsoft.graph.group"}) ) {
                if ($item.DisplayName -in $members.DisplayName) {
                    Add-WordText -WordDocument $doc -Text $item.DisplayName -Color Red| Out-Null
                } else {
                    Add-WordText -WordDocument $doc -Text $item.DisplayName | Out-Null
                }

                if ($visio) {
                    if (-not (Get-VisioShape -Name $item.id)) {
                        if ($posIntuneGroup.Y -gt 11) { $posIntuneGroup = [VisioAutomation.Geometry.Point]::new($posIntuneGroup.X + 2, 1) }
                        $shape = New-VisioShape -Master $intuneGroup -Position $posIntuneGroup
                        $shape.NameU = $item.id
                        $shape.Text = $item.displayName
                        $posIntuneGroup = [VisioAutomation.Geometry.Point]::new($posIntuneGroup.X, $posIntuneGroup.Y + 1)
                    }
                    (Get-VisioShape -Name $group.id).AutoConnect((Get-VisioShape -Name $item.id), [Microsoft.Office.Interop.Visio.VisAutoConnectDir]::visAutoConnectDirNone, $null)
                }
            }
        }

        Add-WordText -WordDocument $doc -Text "Members" -HeadingType Heading2 | Out-Null
        Add-WordText -WordDocument $doc -Text "Users: $(@($members | Where-Object {$_.'@odata.type' -eq "#microsoft.graph.user"} ).Count)" | Out-Null
        Add-WordText -WordDocument $doc -Text "Groups: $(@($members | Where-Object {$_.'@odata.type' -eq "#microsoft.graph.group"} ).Count)" | Out-Null
        Add-WordText -WordDocument $doc -Text "Devices: $(@($members | Where-Object {$_.'@odata.type' -eq "#microsoft.graph.device"} ).Count)" | Out-Null
        if (@($members | Where-Object {$_.'@odata.type' -eq "#microsoft.graph.group"}).Count -gt 0) {
            Add-WordText -WordDocument $doc -Text "Member groups" -HeadingType Heading3 | Out-Null
            foreach ($item in @($members | Where-Object {$_.'@odata.type' -eq "#microsoft.graph.group"}) ) {
                if ($item.DisplayName -in $memberOf.DisplayName) {
                    Add-WordText -WordDocument $doc -Text $item.DisplayName -Color Red | Out-Null
                } else {
                    Add-WordText -WordDocument $doc -Text $item.DisplayName | Out-Null
                }

                if ($visio) {
                    if (-not (Get-VisioShape -Name $item.id)) {
                        if ($posIntuneGroup.Y -gt 11) { $posIntuneGroup = [VisioAutomation.Geometry.Point]::new($posIntuneGroup.X + 2, 1) }
                        $shape = New-VisioShape -Master $intuneGroup -Position $posIntuneGroup
                        $shape.NameU = $item.id
                        $shape.Text = $item.displayName
                        $posIntuneGroup = [VisioAutomation.Geometry.Point]::new($posIntuneGroup.X, $posIntuneGroup.Y + 1)
                    }
                    (Get-VisioShape -Name $group.id).AutoConnect((Get-VisioShape -Name $item.id), [Microsoft.Office.Interop.Visio.VisAutoConnectDir]::visAutoConnectDirNone, $null)
                }
            }
        }
    }
}

if ($visio) {
    $pageUnused = New-VisioPage -Name "Unused objects"
    $x = $y = 1
    ((Get-VisioShape -Name * -Page (Get-VisioPage -Name "Page-1")) | where { ($_.Type -eq 2) -and ($_.FromConnects.Count -eq 0) }) | foreach { 
        if ($y -gt 11) { $y = 1; $x = $x + 3; }
        $pageUnused.Drop($_, $x, $y) 
        $y = $y + 2
        (Get-VisioShape -name $_.Name -Page (Get-VisioPage -Name "Page-1")).Delete()
    } | Out-Null
    Select-VisioPage -Page (Get-VisioPage -Name "Page-1")
    $pageLayout = [VisioAutomation.Models.LayoutStyles.HierarchyLayoutStyle]::new()
    $pagelayout.LayoutDirection = [VisioAutomation.Models.LayoutStyles.LayoutDirection]::TopToBottom
    $pageLayout.AvenueSizey = 0.5
    $pageLayout.AvenueSizeX = 2
    Format-VisioPage -LayoutStyle $pageLayout -Page (Get-VisioPage "Page-1")
}

Write-Host "Visio drawing done, make sure to save the file manually to a safe place."
Write-Host "Saving word file.. Make sure to move it to a safe place"
Save-WordDocument $doc -Language 'en-US'

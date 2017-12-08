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
 <#
 .SYNOPSIS
        This PowerShell script will update settings in Internet Explorer.
 .DESCRIPTION
        Support for
        * Zone mapped sites, i.e Trusted Sites
        * Clean trusted sites
        * Automatically do not require HTTPS URL if HTTP URL is in zone map
        * Start page
 .EXAMPLE
 .NOTES
        Tested on: Windows 10 1703

        Source:
            http://DeployWindows.info
            Twitter: @MattiasFors

        Version:
            1.0.0   Created

 #>

 # Do all configuration here
$CleanTrustedSites = $false     # True if clean zone list
$HTTPSTrustedSites = "microsoft.com","deploywindows.info"
$HTTPTrustedSites = ""

$HomePageOverride = $true       # Configure homepage even if already set
$HomePageUrl = "https://www.deploywindows.info"

$SetFirstRunWizardHomePage = $true  # True to set first run wizard to Home page


# Initialize key variables. Do not change if you know what you are doing
$UserZoneMapPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"
$DWord = 2      # Zone mapping: (1) Intranet zone, (2) Trusted Sites zone, (3) Internet zone, and (4) Restricted Sites zone
$UserZoneSettingsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones"
$UserMainPath = "HKCU:\Software\Microsoft\Internet Explorer\Main"

#region Functions
Function CreateKeyReg
{
    Param
    (
        [String]$KeyPath,
        [String]$Name
    )

    If(Test-Path -Path $KeyPath)
    {
        Write-Verbose "Creating a new key '$Name' under $KeyPath."
        New-Item -Path "$KeyPath" -ItemType File -Name "$Name" `
        -ErrorAction SilentlyContinue | Out-Null
    }
    Else
    {
        Write-Warning "The path '$KeyPath' not found."
    }
}

Function SetRegValue
{
    Param
    (
        [Boolean]$blnHTTP=$false,
        [String]$RegPath
    )

    Try
    {
        If($blnHTTP)
        {
            Write-Verbose "Creating a Dword value named 'HTTP' and set the value to 2."
            Set-ItemProperty -Path $RegPath -Name "http" -Value $DWord -ErrorAction SilentlyContinue | Out-Null

            # If there is a HTTP URL, disable require HTTPS URLs (Hex 43 or Decimal 67)
            Write-Verbose "Disable Require server verification (https:) for all sites in this zone for the Zone."
            Set-ItemProperty -Path "$($UserZoneSettingsPath)\$($DWord)" -Name "Flags" -Value 67 -ErrorAction SilentlyContinue | Out-Null
        }
        Else
        {
            Write-Verbose "Creating a Dword value named 'HTTPS' and set the value to 2."
            Set-ItemProperty -Path $RegPath -Name "https" -Value $DWord `
            -ErrorAction SilentlyContinue | Out-Null
        }
    }
    Catch
    {
        Write-Host "Failed to add trusted sites in Internet Explorer." -BackgroundColor Red
    }

}

Function AddHomePage
{
    Param
    (
        [Boolean]$Override=$false,
        [String]$URL
    )

    if ($URL.Length -le 1)
    {
        Write-Verbose "Start Page seems invalid"
    }
    Else
    {
        If ($Override)
        {
            Set-ItemProperty -Path $UserMainPath -Name "Start Page" -Value $URL -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Verbose "Start Page set to $($URL)."
        }
        Else
        {
            Write-Verbose "Do NOT override Start Page."
        }
    }
}

Function DisableFirstRunWizard
{
    Param
    (
        [Boolean]$Homepage=$true
    )

    If ($Homepage)
    {
        Set-ItemProperty -Path $UserMainPath -Name "DisableFirstRunCustomize" -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Verbose "DisableFirstRunWizard set to 1, Start page."
    }
    Else
    {
        Set-ItemProperty -Path $UserMainPath -Name "DisableFirstRunCustomize" -Value 2 -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Verbose "DisableFirstRunWizard set to 2, Welcome IE Page."
    }
}


Function AddTrustedSites
{
    Param
    (
        [Boolean]$HTTP=$false,
        [String[]]$TrustedSites
    )

    If($TrustedSites)
    {
        #Adding trusted sites in the registry
        Foreach($TrustedSite in $TrustedSites)
        {
            If ($TrustedSite.Split(".").Count -eq 2)
            {
                #Settings the primary domain only
                If($HTTP)
                {
                    CreateKeyReg -KeyPath $UserZoneMapPath -Name $TrustedSite 
                    SetRegValue -RegPath "$UserZoneMapPath\$TrustedSite" -blnHTTP $true -DWord $DWord
                    Write-Host "Successfully added '$TrustedSite' domain to trusted Sites in Internet Explorer."
                }
                Else
                {
                    CreateKeyReg -KeyPath $UserZoneMapPath -Name $TrustedSite 
                    SetRegValue -RegPath "$UserZoneMapPath\$TrustedSite" -blnHTTP $false -DWord $DWord
                    Write-Host "Successfully added '$TrustedSite' domain to to trusted Sites in Internet Explorer."
                }
            }
            ElseIf ($TrustedSite.Split(".").Count -gt 2)
            {
                    $PrimaryDomain = "$($TrustedSite.Split(".")[($TrustedSite.Split(".").Count-2)]).$($TrustedSite.Split(".")[($TrustedSite.Split(".").Count-1)])"
                    Write-Host $TrustedSite  $PrimaryDomain
                    $SubDomain = $TrustedSite.Replace(".$($PrimaryDomain)","")
                    #Settings with sub-domain
                    If($HTTP)
                    {
                        CreateKeyReg -KeyPath $UserZoneMapPath -Name $PrimaryDomain
                        CreateKeyReg -KeyPath "$UserZoneMapPath\$PrimaryDomain" -Name $SubDomain
                        SetRegValue -RegPath "$UserZoneMapPath\$PrimaryDomain\$SubDomain" -blnHTTP $true -DWord $DWord
                        Write-Host "Successfully added $SubDomain.$PrimaryDomain' domain to trusted Sites in Internet Explorer."
                    }
                    Else
                    {
                        CreateKeyReg -KeyPath $UserZoneMapPath -Name $PrimaryDomain
                        CreateKeyReg -KeyPath "$UserZoneMapPath\$PrimaryDomain" -Name $SubDomain
                        SetRegValue -RegPath "$UserZoneMapPath\$PrimaryDomain\$SubDomain" -blnHTTP $false -DWord $DWord
                        Write-Host "Successfully added '$SubDomain.$PrimaryDomain' domain to trusted Sites in Internet Explorer."
                    }
            }
        }
    }
}
#endregion Functions

#region Main
if ($CleanTrustedSites)
{
    foreach ($Domain in Get-ChildItem "hkcu:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains") 
    {
        Remove-Item -Path $Domain.PSPath -Recurse -Force
        Write-Host "Successfully cleaned $Domain.Name"
    }
    Write-Host "Zone cleaned."
}

AddTrustedSites -HTTP $false -TrustedSites $HTTPSTrustedSites
AddTrustedSites -HTTP $true -TrustedSites $HTTPTrustedSites

AddHomePage -URL $HomePageUrl -Override $HomePageOverride

DisableFirstRunWizard -Homepage $SetFirstRunWizardHomePage
#endregion Main
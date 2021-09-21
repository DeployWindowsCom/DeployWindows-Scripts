<#PSScriptInfo

.VERSION 1.0

.GUID 

.AUTHOR Mattias Alvbring

.COMPANYNAME DeployWindows.com

.TAGS Windows Intune PowerShell BitLocker Pin

.RELEASENOTES
Version 1.0:  Original

#>

<#
.SYNOPSIS
Prompts user to set a BitLocker PIN if not exists

.DESCRIPTION
 Should be used with serviceui.exe from MDT
 Use with a Win32 app in Intune
 With detection script that checks if a pin is already set
  if (@($(Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where { $_.KeyProtectorType -eq 'TpmPin' }).Count -ge 1) { 
   Write-Output "BitLocker pin exists"; Exit 0; } else { 
   Write-Output "BitLocker pin does not exist" Exit 1: }

.EXAMPLE

#>

############### START DESIGN ###############
$XmlDesign = [XML] '<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Warning dialog" 
        Height="500" Width="600" 
        WindowStartupLocation="CenterScreen"
        ShowInTaskbar="False" 
        ResizeMode="NoResize"
        Topmost="True" 
        WindowStyle="None" >
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="70" />
            <RowDefinition Height="*" />
            <RowDefinition Height="100" />
        </Grid.RowDefinitions>

        <Grid HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Grid.Row="0">
            <StackPanel Orientation="Horizontal">
                <Label Name="txt_Header" Content="Secure BitLocker with a PIN!" 
                HorizontalAlignment="Left" Margin="10" FontSize="24" />

            </StackPanel>
        </Grid>

        <Grid HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Grid.Row="1">
            <StackPanel>
                <TextBlock Name="txt_Content" TextWrapping="WrapWithOverflow" HorizontalAlignment="Left" Margin="10" FontSize="18">
                    You are enforced to secure your computer with a BitLocker startup PIN
                </TextBlock>
                <Label FontSize="12">
                    <StackPanel Orientation="vertical">
                        <Label Content="Pin requirements:" />
                        <Label Content="Minimum 6 digits" />
                        <Label Content="Maximum 20 digits" />
                        <Label Content=" " />
                    </StackPanel>
                </Label>

                <Label Name="txt_Signature" Content="Best regards IT Securty department" />

                <TextBox Name="txt_Pin" AcceptsReturn="False" MaxLength="20" FontSize="36" Margin="30" Width="410" HorizontalAlignment="Left"/>

                <Label Name="txt_ErrorCode" Visibility="Hidden" Content="The pin code does not fullfill the requirements" FontWeight="Bold" Background="Red" Foreground="White" HorizontalAlignment="Center" />

            </StackPanel>
        </Grid>

        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="250" />
            </Grid.ColumnDefinitions>

                <Button Content="Set Pin code" Name="btn_Close" HorizontalAlignment="Center" 
                    Margin="5" Padding="10" VerticalAlignment="Center" Width="150"
                    Grid.Column="0"/>
                <!--Button Content="Skjut fram" Name="btn_Postpone" HorizontalAlignment="Center" 
                    Margin="5" Padding="10" VerticalAlignment="Center" Width="150"
                    Grid.Column="1"/-->
                <!--Image Source="https://www.pressmachine.se/obj.php?obj=107203"
                    Grid.Column="2"/-->
        </Grid>

    </Grid>
</Window>'
###############  END DESIGN  ###############


if ($null -ne $SCRIPT:MyInvocation.MyCommand.Path) { 
    $Script:ScriptPath = Split-Path $SCRIPT:MyInvocation.MyCommand.Path -parent
    $Script:FullScriptPath = $SCRIPT:MyInvocation.MyCommand.Path
}
else {
    $Script:ScriptPath = $null
}
$Script:RegistryBase = "HKCU:\Software\BitLockerPin"

# Initialize the Windows Presentation Framework
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms #[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

# Create an object for the XML content
$xamlReader = New-Object System.Xml.XmlNodeReader $XmlDesign

# Load the content so we can start to work with it
$mainform = [Windows.Markup.XamlReader]::Load($xamlReader)

$btn_Close = $mainform.FindName('btn_Close')

$txt_Pin = $mainform.FindName('txt_Pin')
$txt_ErrorCode = $mainform.FindName('txt_ErrorCode')


#region  Here goes all functions
function Write-Log {
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
 
        [string] $Text
    )

    Write-Host $Text
}

function PLACEHOLDER-Start-PostPoneAction {

    # add a dialog box in the future by adding scheduled task
    #$nextPrompt = (Get-Date).AddSeconds(30)
    #$taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden $($Script:FullScriptPath)" -WorkingDirectory $Script:ScriptPath
    #$taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -DisallowDemandStart -DisallowHardTerminate -DontStopIfGoingOnBatteries -StartWhenAvailable:$true
    #$taskTrigger = New-ScheduledTaskTrigger -Once -At $nextPrompt
    #Register-ScheduledTask -TaskName "CUSTOMER - NAME" -Description "Created by CUSTOMER. DESCRIPTION" -Trigger $taskTrigger -Settings $taskSettings -Action $taskAction -Force

    $mainform.Close()
}

#endregion

#region  Here goes all the events
$btn_Close.Add_Click( { 
        $btn_Close.IsEnabled = $false
        $mainform.Close()
        $btn_Close.IsEnabled = $true
    })

$mainform.Add_Closing( {
        [CmdletBinding()]
        Param(
            [Parameter()] $Window,
            [Parameter()] $CancelEventArgs
        )

        [Int32]$OutNumber = $null
        #Does pin fullfill the requirements
        Write-Log "Check requirements length between 6-20 and only digits"      
        if ($null -ne $txt_Pin.Text) {
            if ($txt_Pin.Text.Length -ge 6) {
                if ($txt_pin.Text.Length -le 20) {
                    if ([Int32]::TryParse($txt_pin.Text,[ref]$OutNumber)){
                        Write-Host "Valid Number"
                        $txt_ErrorCode.Visibility = "Hidden"
                    } else {
                        Write-Host "Invalid Number, contains non-digits!"
                        $txt_ErrorCode.Visibility = "Visible"
                        $_.Cancel = $true
                        return;
                    }                
                } else {
                    $txt_ErrorCode.Visibility = "Visible"
                    $_.Cancel = $true
                    return;
                }
            } else {
                $txt_ErrorCode.Visibility = "Visible"
                $_.Cancel = $true
                return;
            }
        } else {
            $txt_ErrorCode.Visibility = "Visible"
            $_.Cancel = $true
            return;
        }


        # User pressed Close button
        $output = [System.Windows.Forms.MessageBox]::Show("Do not forget your pin!", "Configure BitLocker pin",
            [System.Windows.Forms.MessageBoxButtons]::OKCancel,
            [System.Windows.Forms.MessageBoxIcon]::Warning)

        Write-Log "INFO: Closing dialog, you pressed $($output)"
        if (($output.ToString() -eq "Cancel") -or ($output.ToString() -eq "No")) {
            Write-Log "INFO: Interrupt closing"
            $_.Cancel = $true
        }
        else {
            $SecureString = ConvertTo-SecureString $OutNumber -AsPlainText -Force 
            Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -Pin $SecureString -TPMandPinProtector
            Write-Log "INFO: Thanks for setting pin..."
        }
    })

$mainform.Add_Loaded( {
        Write-Log "DEBUG: Loading application.."


        #region  Here goes the main program

        Write-Log "INFO: woop woop.."

        $txt_Pin.Focus()

        #$mainform.Close()    

        #endregion

    })

$mainform.Add_Initialized( {
        Write-Log "INFO: Initialized.."
    })
#endregion

# Show the form, this should be in the end to show up nicely
$mainform.ShowDialog() | Out-Null

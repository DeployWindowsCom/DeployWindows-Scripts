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
                <Label Name="txt_Header" Content="Omstart krävs!" 
                HorizontalAlignment="Left" Margin="10" FontSize="24" />

            </StackPanel>
        </Grid>

        <Grid HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Grid.Row="1">
            <StackPanel>
                <TextBlock Name="txt_Content" TextWrapping="WrapWithOverflow" HorizontalAlignment="Left" Margin="10" FontSize="18">
                    Din dator har under längre tid inte startats om. För att bibehålla en stabil och snabb dator krävs det att datorn startas om varje månad när uppdateringar sker
                </TextBlock>
                <Label FontSize="18">
                    <StackPanel Orientation="Horizontal">
                        <Label Content="Du måste starta om innan " />
                        <Label Name="txt_EndDate" Content="x" />
                        <Label Content=" " />
                    </StackPanel>
                </Label>

                <Label Name="txt_Signature" Content="Vänliga hälsningar SEF IT" />
            </StackPanel>
        </Grid>

        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="250" />
            </Grid.ColumnDefinitions>

                <Button Content="Starta om*" Name="btn_Close" HorizontalAlignment="Center" 
                    Margin="5" Padding="10" VerticalAlignment="Center" Width="150"
                    Grid.Column="0"/>
                <Button Content="Skjut fram" Name="btn_Postpone" HorizontalAlignment="Center" 
                    Margin="5" Padding="10" VerticalAlignment="Center" Width="150"
                    Grid.Column="1"/>
                <Image Source="https://www.pressmachine.se/obj.php?obj=107203"
                    Grid.Column="2"/>
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
$Script:RegistryBase = "HKCU:\Software\DeployWindows\RebootCheck"

$Script:TotalTime = 48 * 60                 # Hur många minuter som notifieringarna skall visas innan användaren bara får alternativet att starta om, utan att skjuta upp
$Script:FirstNotificationDelay = 2 * 60     # hur många minuter det går mellan notifieringar för användaren
$Script:SecondNotificationAfter = 24 * 60   # hur många minuter tills man skall gå över till SecondNotificationDelay för att visa dialog rutor
$Script:SecondNotificationDelay = 1 * 60    # hur många minuter det går mellan de sista notifieringarna för användaren

# Initialize the Windows Presentation Framework
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms #[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

# Create an object for the XML content
$xamlReader = New-Object System.Xml.XmlNodeReader $XmlDesign

# Load the content so we can start to work with it
$mainform = [Windows.Markup.XamlReader]::Load($xamlReader)

$btn_Close = $mainform.FindName('btn_Close')
$btn_Postpone = $mainform.FindName('btn_Postpone')
$txt_EndDate = $mainform.FindName('txt_EndDate')

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

function Get-PendingReboot {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
 
        [string[]] $ComputerName = $env:COMPUTERNAME
    )

    BEGIN {}
 
    PROCESS {
        Foreach ($Computer in $ComputerName) {
            Try {
                $PendingReboot = $false

                $HKLM = [UInt32] "0x80000002"
                $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"

                if ($WMI_Reg) {
                    Write-Log "INFO: Windows registry found checking for pending reboots"

                    #checking native Windows pending reboots places
                    if (($WMI_Reg.EnumValues($HKLM, "SYSTEM\CurrentControlSet\Control\Session Manager\")).sNames -contains "PendingFileRenameOperations") {
                        $PendingReboot = $true
                        Write-Log "INFO: Pending reboot found: SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations"
                    }
                    if (($WMI_Reg.EnumKey($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")).sNames -contains 'RebootPending') {
                        $PendingReboot = $true 
                        Write-Log "INFO: Pending reboot found: SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
                    }
                    if (($WMI_Reg.EnumKey($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")).sNames -contains 'RebootRequired') {
                        $PendingReboot = $true 
                        Write-Log "INFO: Pending reboot found: SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
                    }

                    #Checking for SCCM namespace
                    $SCCM_Namespace = Get-WmiObject -Namespace ROOT\CCM\ClientSDK -List -ComputerName $Computer -ErrorAction Ignore
                    if ($SCCM_Namespace) {
                        if (([WmiClass]"\\$Computer\ROOT\CCM\ClientSDK:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending -eq $true) { 
                            $PendingReboot = $true 
                            Write-Log "INFO: Pending reboot found in Configuration Manager agent.."
                        }
                    }

                    if ($PendingReboot -eq $true) {
                        [PSCustomObject]@{
                            ComputerName  = $Computer.ToUpper()
                            PendingReboot = $true
                        }
                    }
                    else {
                        [PSCustomObject]@{
                            ComputerName  = $Computer.ToUpper()
                            PendingReboot = $false
                        }
                    }
                } else {
                    #Registry is not found, log error
                    Write-Log "ERROR: Windows registry not found. Assume reboot is needed"
                    [PSCustomObject]@{
                        ComputerName  = $Computer.ToUpper()
                        PendingReboot = $true
                    }
                }
            }
            catch {
                #Unknown error, log
                Write-Log "ERROR: Unknown error happend $($_.Exception.Message). Assume reboot is needed"
                [PSCustomObject]@{
                    ComputerName  = $Computer.ToUpper()
                    PendingReboot = $true
                }
            }
            finally {
                #Clearing Variables
                $WMI_Reg = $null
                $SCCM_Namespace = $null
            }
        }
    }

    END {}
}

function Start-PostPoneAction {
    #Increase postpone count by 1
    if ($Script:PostponeCount) {
        try {
            $count = [int]::Parse($Script:PostponeCount.PostponeCount) + 1
            Write-Log "INFO: Increase PostponeCount to $($count)"
            Set-ItemProperty -Path $Script:RegistryBase -Name PostponeCount -Value $count -Force
        } catch {
            Set-ItemProperty -Path $Script:RegistryBase -Name PostponeCount -Value 1 -Force
        }
    } else {
        #create registry key
        New-ItemProperty -Path $Script:RegistryBase -Name PostponeCount -Value 1 -PropertyType String -Force
        Write-Log "INFO: Adding registry Postponecount"
    }

    # add a dialog box in the future by adding scheduled task
    $nextPrompt = (Get-Date).AddSeconds(30)
    $taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden $($Script:FullScriptPath)" -WorkingDirectory $Script:ScriptPath
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -DisallowDemandStart -DisallowHardTerminate -DontStopIfGoingOnBatteries -StartWhenAvailable:$true
    $taskTrigger = New-ScheduledTaskTrigger -Once -At $nextPrompt
    Register-ScheduledTask -TaskName "Deploywindows - Forced restart" -Description "Created by CUSTOMER to force users about pending restart." -Trigger $taskTrigger -Settings $taskSettings -Action $taskAction -Force
    #Start-ScheduledTask -InputObject $a

    $mainform.Close()
}

function Get-EndDateTime {
    (Get-Date -Date ($Script:FirstrunTime.FirstrunTime)).AddMinutes($Script:TotalTime)
}

function Initialize-Registry {
    if (Get-Item -Path $Script:RegistryBase -ErrorAction SilentlyContinue) {
        Write-Log "INFO: Registry exists"
    } else {
        Write-Log "INFO: Creating registry key for application"
        New-Item $Script:RegistryBase -Force
    }

    $Script:PostponeCount  = Get-ItemProperty -Path $Script:RegistryBase -Name PostponeCount -ErrorAction SilentlyContinue
    if ($Script:PostponeCount) {
        Write-Log "INFO: Postpone count: $($Script:PostponeCount.PostponeCount)"
    } else {
        #create registry key
        Write-Log "INFO: Adding registry entry Postponecount"
        New-ItemProperty -Path $Script:RegistryBase -Name PostponeCount -Value 0 -PropertyType String -Force
        $Script:PostponeCount = Get-ItemProperty -Path $Script:RegistryBase -Name PostponeCount -ErrorAction SilentlyContinue
    }

    $Script:LastrunTime  = Get-ItemProperty -Path $Script:RegistryBase -Name LastrunTime -ErrorAction SilentlyContinue
    if ($Script:LastrunTime) {
        Write-Log "INFO: App last ran: $($Script:LastrunTime.LastrunTime)"
        #Update with current time and date
        Set-ItemProperty -Path $Script:RegistryBase -Name LastrunTime -Value (Get-Date -format G) -Force
    } else {
        #create registry key
        Write-Log "INFO: Adding registry entry LastrunTime"
        $now = Get-Date -format G
        #Get-Date -format G -Date $now
        New-ItemProperty -Path $Script:RegistryBase -Name LastrunTime -Value $now -PropertyType String -Force
    }

    $Script:FirstrunTime  = Get-ItemProperty -Path $Script:RegistryBase -Name FirstrunTime -ErrorAction SilentlyContinue
    if ($Script:FirstrunTime) {
        $endTime = Get-EndDateTime
        $now = Get-Date

        Write-Log "DEBUG: FirstrunTime: $((Get-Date -Date ($Script:FirstrunTime.FirstrunTime))). End time: $($endTime). Now: $($now). Checking you are allowed to postpone.."
        Write-Log "DEBUG: You have $($endTime.Subtract($now).TotalHours) hours left.."

        if ($endTime.Subtract($now) -gt 0) {
            Write-Log "INFO: You are allowed to postpone until $($endTime)"
        } else {
            Write-Log "WARNING: You are not allowed to postpost anymore, disabling button. Endtime was $($endTime)"
            $btn_Postpone.IsEnabled = $false
        }
    } else {
        #create registry key
        Write-Log "INFO: Adding registry entry FirstrunTime"
        $now = Get-Date -format G
        New-ItemProperty -Path $Script:RegistryBase -Name FirstrunTime -Value $now -PropertyType String -Force
        $Script:FirstrunTime  = Get-ItemProperty -Path $Script:RegistryBase -Name FirstrunTime -ErrorAction SilentlyContinue
    }

}
#endregion

#region  Here goes all the events
$btn_Close.Add_Click( { 
        $btn_Close.IsEnabled = $false
        $mainform.Close()
        $btn_Close.IsEnabled = $true
    })

$btn_Postpone.Add_Click( { 
        # Postpone click
        $btn_Postpone.IsEnabled = $false
        Start-PostPoneAction
        $btn_Postpone.IsEnabled = $true
    })

$mainform.Add_Closing( {
        [CmdletBinding()]
        Param(
            [Parameter()] $Window,
            [Parameter()] $CancelEventArgs
        )

        if ($btn_Postpone.IsEnabled -eq $false) {
            # User pressed Postpone button
            Write-Log "INFO: Thanks for now.."
        } else {
            # User pressed Close button
            $output = [System.Windows.Forms.MessageBox]::Show("Glöm inte spara din information, icke sparad information kan gå förlorad. Tryck på OK för att starta om datorn.", "Starta om",
            [System.Windows.Forms.MessageBoxButtons]::OKCancel,
            [System.Windows.Forms.MessageBoxIcon]::Warning)

            Write-Log "INFO: Closing dialog, you pressed $($output)"
            if (($output.ToString() -eq "Cancel") -or ($output.ToString() -eq "No")) {
                Write-Log "INFO: Interrupt closing"
                $_.Cancel = $true
            }
            else {
                Write-Log "INFO: Thanks for restarting..."
            }
        }
    })

$mainform.Add_Loaded( {
    Write-Log "DEBUG: Loading application.."

    $btn_Postpone.Content = "Skjut fram 2 timmar"

    Initialize-Registry
    #region  Here goes the main program

        Write-Log "INFO: You have postponed $($script:PostponeCount.PostponeCount) times already.."
        $txt_EndDate.Content = Get-Date -format G -Date (Get-EndDateTime)

        Write-Log "DEBUG: If there is no pending reboots we will not show user any prompt. Pending Reboot = $((Get-PendingReboot).PendingReboot)"
        if ($false -eq (Get-PendingReboot).PendingReboot) {
            Write-Log "INFO: Exit script without any dialog since there is no pending reboots"
            $btn_Postpone.IsEnabled = $false
            $mainform.Close()    
        } else {
            #there are pending reboots and dialog with show - do nothing
        }


    #endregion

    })

$mainform.Add_Initialized( {
        Write-Log "INFO: Initialized.."
    })
#endregion

# Show the form, this should be in the end to show up nicely
$mainform.ShowDialog() | Out-Null

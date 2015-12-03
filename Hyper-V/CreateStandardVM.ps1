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
# // ***************************************************************************
# // ***** Script Header *****
# //
# // Purpose: Create Virtual Machine in Hyper-V with predefined settings
# //
# // Prerequsits: Tested on Windows 10
# //
# // Source/References:
# //   http://DeployWindows.info
# //   @MattiasFors
# //   mattias@deploywindows.info
# //
# // History:
# //	1.0		Created 
# //    1.1     Updated VHD Path to .\Virtual Hard Disks to follow standard
# //    1.2     Updated with dropboxes instead of textboxes for CPU and VMSwitch
# //
# // ***** End Header *****
# // ***************************************************************************


$global:VMName = $null
$VMPath = "D:\Hyper-V"
$VMBootDVD = "F:\Deploy\Boot\LiteTouchPE_x64.iso"
$VMMemory = 2GB
$VMVHDXSize = 50GB
$VMProcessorCount = 2
$VMGeneration = 2
#$VMBootDevice = "IDE, NetworkAdapter, CD"
$VMNet1 = "Internal 2"
$VMNet2 = "Internal 1"


function Check-IsAdmin()
{
#reference: http://www.interact-sw.co.uk/iangblog/2007/02/09/pshdetectelevation
#reference: http://www.leastprivilege.com/AdminTitleBarForPowerShell.aspx

  # Get the Current User's Security Token
  $windowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
  $principal=new-object System.Security.Principal.WindowsPrincipal($windowsID)
  
  # Check if it has the Administrator access enabled
  return [bool]$principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

}

function Return-Close {

	$Form.Close()
}

function Return-CreateVM {

	$global:VMName = $TextBox.Text.ToString().ToUpper()

    $global:VMPath = $TextBox1.Text.ToString().ToUpper()
    $global:VMBootDVD = $TextBox2.Text.ToString().ToUpper()
    $global:VMMemory = [int64]($TextBox3.Text.ToString().ToUpper().Replace('GB','')) * ([int64](1GB))
    $global:VMVHDXSize = [int64]($TextBox4.Text.ToString().ToUpper().Replace('GB','')) * ([int64](1GB))
    $global:VMProcessorCount = $VMCPU.Items[$VMCPU.SelectedIndex]
    $global:VMGeneration = $TextBox6.Text
    $global:VMNet1 = $VMNet1Name.Items[$VMNet1Name.SelectedIndex]
    $global:VMNet2 = $VMNet2Name.Items[$VMNet2Name.SelectedIndex]

	$Form.Close()
	Write-Host $global:VMName

}

function ShowDialogBox()
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")


    $Form = New-Object System.Windows.Forms.Form

    $Form.Width = 320
    $Form.Height = 400
    $Form.Text = "Create a VM"
    
    $DropDownLabel = New-Object System.Windows.Forms.Label
    $DropDownLabel.Location = New-Object System.Drawing.Size(10,10) 
    $DropDownLabel.Size = New-Object System.Drawing.Size(140,20) 
    $DropDownLabel.Text = "Virtual Machine Name"
    $Form.Controls.Add($DropDownLabel)


    $TextBox = New-Object System.Windows.Forms.TextBox
    $TextBox.Location = New-Object System.Drawing.Size(150,10) 
    $TextBox.Size = New-Object System.Drawing.Size(140,20) 
    $TextBox.Text = "LAB1-SRV-"
    $Form.Controls.Add($TextBox)

    $Button = New-Object System.Windows.Forms.Button
    $Button.Location = New-Object System.Drawing.Size(100,40)
    $Button.Size = New-Object System.Drawing.Size(100,20)
    $Button.Text = "Create VM"
    $Button.Add_Click({Return-CreateVM})
    $Form.Controls.Add($Button)

    #############################
    # Extra settings
    # VM Path
    $DropDownLabel = New-Object System.Windows.Forms.Label
    $DropDownLabel.Location = New-Object System.Drawing.Size(10,90) 
    $DropDownLabel.Size = New-Object System.Drawing.Size(140,20) 
    $DropDownLabel.Text = "VM Path"
    $Form.Controls.Add($DropDownLabel)
    $TextBox1 = New-Object System.Windows.Forms.TextBox
    $TextBox1.Location = New-Object System.Drawing.Size(150,90) 
    $TextBox1.Size = New-Object System.Drawing.Size(100,20) 
    $TextBox1.Text = $VMPath
    $Form.Controls.Add($TextBox1)

    #VMBoot DVD
    $DropDownLabel = New-Object System.Windows.Forms.Label
    $DropDownLabel.Location = New-Object System.Drawing.Size(10,120) 
    $DropDownLabel.Size = New-Object System.Drawing.Size(140,20) 
    $DropDownLabel.Text = "VM Boot DVD"
    $Form.Controls.Add($DropDownLabel)
    $TextBox2 = New-Object System.Windows.Forms.TextBox
    $TextBox2.Location = New-Object System.Drawing.Size(150,120) 
    $TextBox2.Size = New-Object System.Drawing.Size(140,20) 
    $TextBox2.Text = $VMBootDVD
    $Form.Controls.Add($TextBox2)
    
    #VMMemory
    $DropDownLabel = New-Object System.Windows.Forms.Label
    $DropDownLabel.Location = New-Object System.Drawing.Size(10,150) 
    $DropDownLabel.Size = New-Object System.Drawing.Size(140,20) 
    $DropDownLabel.Text = "VM Memory (Ex 2GB)"
    $Form.Controls.Add($DropDownLabel)
    $TextBox3 = New-Object System.Windows.Forms.TextBox
    $TextBox3.Location = New-Object System.Drawing.Size(150,150) 
    $TextBox3.Size = New-Object System.Drawing.Size(100,20) 
    $TextBox3.Text = ($VMMemory / 1GB) 
    $TextBox3.Text += "GB"
    $Form.Controls.Add($TextBox3)

    #VMVHDXSize
    $DropDownLabel = New-Object System.Windows.Forms.Label
    $DropDownLabel.Location = New-Object System.Drawing.Size(10,180) 
    $DropDownLabel.Size = New-Object System.Drawing.Size(140,20) 
    $DropDownLabel.Text = "VM VHDX Size (Ex 50GB)"
    $Form.Controls.Add($DropDownLabel)
    $TextBox4 = New-Object System.Windows.Forms.TextBox
    $TextBox4.Location = New-Object System.Drawing.Size(150,180) 
    $TextBox4.Size = New-Object System.Drawing.Size(100,20) 
    $TextBox4.Text = ($VMVHDXSize / 1GB) 
    $TextBox4.Text += "GB"
    $Form.Controls.Add($TextBox4)

    #VMProcessorCount
    $DropDownLabel = New-Object System.Windows.Forms.Label
    $DropDownLabel.Location = New-Object System.Drawing.Size(10,210) 
    $DropDownLabel.Size = New-Object System.Drawing.Size(140,20) 
    $DropDownLabel.Text = "VM CPU Count"
    $Form.Controls.Add($DropDownLabel)
    $VMCPU = New-Object System.Windows.Forms.ComboBox
    $VMCPU.Location = New-Object System.Drawing.Size(150,210)
    $VMCPU.Size = New-Object System.Drawing.Size(140,20) 
    $VMCPU.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $VMCPU.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VMCPU.Sorted = $true
    $VMCPU.AutoCompleteMode = [System.Windows.Forms.AutoCompleteMode]::None
    $VMCPU.Items.AddRange(1..(Get-VMHost).LogicalProcessorCount)
    $VMCPU.SelectedIndex = $i = 0
    foreach ($item in $VMCPU.Items.GetEnumerator()) {
        if ($item.ToString() -like $VMProcessorCount) { $VMCPU.SelectedIndex = $i }
        $i++
    }
    $Form.Controls.Add($VMCPU)

    # VMGeneration
    $DropDownLabel = New-Object System.Windows.Forms.Label
    $DropDownLabel.Location = New-Object System.Drawing.Size(10,240) 
    $DropDownLabel.Size = New-Object System.Drawing.Size(140,20) 
    $DropDownLabel.Text = "VM Generation"
    $Form.Controls.Add($DropDownLabel)
    $TextBox6 = New-Object System.Windows.Forms.TextBox
    $TextBox6.Location = New-Object System.Drawing.Size(150,240) 
    $TextBox6.Size = New-Object System.Drawing.Size(100,20) 
    $TextBox6.Text = $VMGeneration
    $Form.Controls.Add($TextBox6)
    
    # VMNet1 Virtual Network Switch 1
    $DropDownLabel = New-Object System.Windows.Forms.Label
    $DropDownLabel.Location = New-Object System.Drawing.Size(10,270) 
    $DropDownLabel.Size = New-Object System.Drawing.Size(140,20) 
    $DropDownLabel.Text = "VM Network 1"
    $Form.Controls.Add($DropDownLabel)
    $VMNet1Name = New-Object System.Windows.Forms.ComboBox
    $VMNet1Name.Location = New-Object System.Drawing.Size(150,270)
    $VMNet1Name.Size = New-Object System.Drawing.Size(140,20) 
    $VMNet1Name.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $VMNet1Name.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VMNet1Name.Sorted = $true
    $VMNet1Name.AutoCompleteMode = [System.Windows.Forms.AutoCompleteMode]::None
    $VMNet1Name.Items.AddRange((Get-VMSwitch).Name)
    $VMNet1Name.SelectedIndex = $i = 0
    foreach ($item in $VMNet1Name.Items.GetEnumerator()) {
        if ($item.ToString() -like $VMNet1) { $VMNet1Name.SelectedIndex = $i }
        $i++
    }
    $Form.Controls.Add($VMNet1Name)
    
    # VMNet2 Virtual Network Switch 2
    $DropDownLabel = New-Object System.Windows.Forms.Label
    $DropDownLabel.Location = New-Object System.Drawing.Size(10,300) 
    $DropDownLabel.Size = New-Object System.Drawing.Size(140,20) 
    $DropDownLabel.Text = "VM Network 2"
    $Form.Controls.Add($DropDownLabel)
    $VMNet2Name = New-Object System.Windows.Forms.ComboBox
    $VMNet2Name.Location = New-Object System.Drawing.Size(150,300)
    $VMNet2Name.Size = New-Object System.Drawing.Size(140,20) 
    $VMNet2Name.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $VMNet2Name.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VMNet2Name.Sorted = $true
    $VMNet2Name.AutoCompleteMode = [System.Windows.Forms.AutoCompleteMode]::None
    $VMNet2Name.Items.AddRange((Get-VMSwitch).Name)
    $VMNet2Name.SelectedIndex = $i = 0
    foreach ($item in $VMNet2Name.Items.GetEnumerator()) {
        if ($item.ToString() -like $VMNet2) { $VMNet2Name.SelectedIndex = $i }
        $i++
    }
    $Form.Controls.Add($VMNet2Name)

    $Form.Add_Shown({$Form.Activate()})
    $Form.ShowDialog()

}


# Activate Elevated privilege if not already done
if ( (check-isadmin).Equals($false) )
{
    Write-Host -ForegroundColor Red -BackgroundColor Black "ERROR: Script must run elevated"
    Write-Host

    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")


    $Form = New-Object System.Windows.Forms.Form

    $Form.Width = 300
    $Form.Height = 120
    $Form.Text = "Error"

    $DropDownLabel = New-Object System.Windows.Forms.Label
    $DropDownLabel.Location = New-Object System.Drawing.Size(10,10) 
    $DropDownLabel.Size = New-Object System.Drawing.Size(280,20) 
    $DropDownLabel.Text = "Your need to start this as elevated"
    $Form.Controls.Add($DropDownLabel)

    $Button = New-Object System.Windows.Forms.Button
    $Button.Location = New-Object System.Drawing.Size(100,40)
    $Button.Size = New-Object System.Drawing.Size(100,20)
    $Button.Text = "Close"
    $Button.Add_Click({Return-Close})
    $Form.Controls.Add($Button)

    $Form.Add_Shown({$Form.Activate()})
    $Form.ShowDialog()

    #$host.SetShouldExit(0)
}
else
{
    $DiaglogBoxReturn = ShowDialogBox
    $VMName = $global:VMName

    $VMPath = $global:VMPath
    $VMBootDVD = $global:VMBootDVD
    $VMMemory = $global:VMMemory
    $VMVHDXSize = $global:VMVHDXSize
    $VMProcessorCount = $global:VMProcessorCount
    $VMGeneration = $global:VMGeneration
    $VMNet1 = $global:VMNet1
    $VMNet2 = $global:VMNet2

    if (($VMName -ne $null) -and ($VMName.Length -gt 1))
    {
        Write-Host "Creating Hyper-V Virtual Machine with name: $VMName"
    
        #Create VM
        #$VMVHDXPath = "$VMPath\$VMName\VHD\$VMName-1.vhdx"
        $VMVHDXPath = Join-Path -Path (Join-Path -Path $VMPath -ChildPath "$($VMName)\Virtual Hard Disks") -ChildPath "$($VMName)-1.vhdx"
        #$VMPath = "$VMPath\$VMName" # this will set the Virtual Machine config files in a sub subfolder

#        New-VM -Name $VMName -MemoryStartupBytes $VMMemory -NewVHDPath $VMVHDXPath -NewVHDSizeBytes $VMVHDXSize -Path $VMPath -BootDevice $VMBootDevice -Generation $VMGeneration
        New-VM -Name $VMName -MemoryStartupBytes $VMMemory -NewVHDPath $VMVHDXPath -NewVHDSizeBytes $VMVHDXSize -Path $VMPath -Generation $VMGeneration
        Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes ($VMMemory/4) -MaximumBytes $VMMemory
        Rename-VMNetworkAdapter -NewName "VMNet0" -VMName $VMName
        $VMBootNet0 = Get-VMNetworkAdapter -VMName $VMName -Name "VMNet0"
        $VMHardDiskDrive1 = Get-VMHardDiskDrive $VMName

        #Add a default Boot.iso
        Add-VMDvdDrive -VMName $VMName -Path $VMBootDVD
        $VMDvdDrive = Get-VMDvdDrive -VMName $VMName -ControllerNumber 0 -ControllerLocation 1

        # Set processors
        Set-VM -Name $VMName -ProcessorCount $VMProcessorCount

        # Add extra NICs
        if ($VMNet1.Length -gt 0) {
            Add-VMNetworkAdapter -VMName $VMName -SwitchName $VMNet1 -Name "VMNet1" -IsLegacy $false 
        }
        else {
            Add-VMNetworkAdapter -VMName $VMName -Name "VMNet1" -IsLegacy $false 
        }
        if ($VMNet1.Length -gt 0) {
            Add-VMNetworkAdapter -VMName $VMName -SwitchName $VMNet2 -Name "VMNet2" -IsLegacy $false
        }
        else {
            Add-VMNetworkAdapter -VMName $VMName -Name "VMNet2" -IsLegacy $false
        }

        $VMBootNet1 = Get-VMNetworkAdapter -VMName $VMName -Name "VMNet1"
        $VMBootNet2 = Get-VMNetworkAdapter -VMName $VMName -Name "VMNet2"
        
        #Add Boot to DVD, Harddisk and one of the NICs
        Set-VMFirmware -VMName $VMName -EnableSecureBoot On -PreferredNetworkBootProtocol IPv4 -BootOrder $VMDvdDrive, $VMHardDiskDrive1, $VMBootNet0, $VMBootNet1, $VMBootNet2


        #Set-VMNetworkAdapter -VMName $VMName
    }
    else
    {
        Write-Host "Error or you cancelled"

    }
}

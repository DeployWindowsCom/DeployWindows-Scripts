#
#This script will show different ways of uninstall applikations
#Even uninstallation wizards that requires keystrokes
#
#@MattiasFors
#https://deploywindows.com
#https://github.com/DeployWindowsCom/DeployWindows-Scripts
##############################



#region Restart into 64-bit
$Is64Bit = [System.Environment]::Is64BitProcess;
$Is64OS = $false; if (($env:PROCESSOR_ARCHITEW6432 -like "AMD64") -or ($env:PROCESSOR_ARCHITECTURE -like "AMD64")) { $Is64OS = $true; }

if (($Is64OS) -and (-not $Is64Bit)) {
    # Running AMD64 but no AMD64 Process, Restart script
    Write-Host "Running AMD64 OS and x86 environment, restart script"
    $Invocation = $PSCommandPath
    if ($Invocation -eq $null) { return }
    $SysNativePath = $PSHOME.ToLower().Replace("syswow64", "sysnative")
    $Ret = Start-Process "$SysNativePath\powershell.exe" -ArgumentList "-ex ByPass -file `"$Invocation`" " -WindowStyle normal -PassThru -Wait
    return $Ret.ExitCode;
} elseif ((-not $Is64OS) -and (-not $Is64Bit)) {
    #Running x86 and no AMD64 Process, Do not bother restarting
    Write-Host "Running x86 OS and x86 environment, continue"
}
#endregion

#region Your content goes here
Write-Host "64-Bit Environment: $($Is64Bit) on 64-Bit Windows: $($Is64OS)"

#Load assembly
Add-Type -AssemblyName System.Windows.Forms

function uninstallApp {
    param (
        [string] $path
    )
    Write-Host $path

    if (Test-Path $path) {
        #Start process
        $ret = Start-process $path -PassThru -WindowStyle Normal;

        #Create a new object
        $wshell = New-Object -ComObject WScript.Shell;
        Start-Sleep -Seconds 2;

        #Send key strokes to the application
        Write-Host "Sending keystrokes to process $($ret.Name)/$($ret.Id)";
        $null = $wshell.AppActivate($ret.Id);
        #https://msdn.microsoft.com/en-us/library/office/aa202943%28v=office.10%29.aspx
        [System.windows.Forms.SendKeys]::SendWait("~");
        Start-Sleep -Seconds 10;
        $null = $wshell.AppActivate($ret.Id);
        [System.windows.Forms.SendKeys]::SendWait("~");

        if ($ret.ExitCode) {
        	Write-Host "Process exitcode $($ret.ExitCode)";
	} else {
            while (Wait-Process -Id $ret.Id) {
                Start-Sleep -Seconds 1;
            }
        }

    } else {
        Write-Host "File not found $($path)"
    }
}

# HP Classroom Manager
Write-Host "Uninstall HP Classroom manager"
$ret = Start-Process -FilePath MsiExec.exe -ArgumentList "/X{BD092778-74B2-447D-A547-8C34DC14A02F} /qn /norestart" -wait -PassThru
Write-Host "Exit with code $($ret.ExitCode)"

#HP ePrint SW
Write-Host "Uninstall HP ePrint SW"
$ret = Start-Process -FilePath MsiExec.exe -ArgumentList "/X{20185BDA-D396-4C93-95C7-ECD0FB397FF7} /qn /norestart" -wait -PassThru
Write-Host "Exit with code $($ret.ExitCode)"

#REM HP Jumpstart
Write-Host "Uninstall HP Jumpstart"
$ret = Start-Process -FilePath MsiExec.exe -ArgumentList "/X{81CA40FD-E11B-4DC1-AE33-A71EB044B8B7} /qn /norestart" -wait -PassThru
Write-Host "Exit with code $($ret.ExitCode)"

Write-Host "Uninstall HP Jumpstart"
$ret = Start-Process -FilePath MsiExec.exe -ArgumentList "/X{D95E43DC-3E04-4AF0-853E-46D832A473FE} /qn /norestart" -wait -PassThru
Write-Host "Exit with code $($ret.ExitCode)"

#HP Documentation
Write-Host "Uninstall HP Documentation"
$path = "C:\Program Files\HP\Documentation\Doc_Uninstall.cmd"
if (Test-Path $path) {
    $ret = Start-Process -FilePath "$($env:comspec)" -ArgumentList "/C $($path)" -Wait  -PassThru
    Write-Host "Exit with code $($ret.ExitCode)"
}

#HP HP School Pack Installer
Write-Host "Uninstall HP School Pack Installer"
uninstallApp -path "C:\Program Files (x86)\HP\HPSI\uninstall.exe"

#HP Software setup
Write-Host "Uninstall HP Software setup"
$ret = Start-Process -FilePath MsiExec.exe -ArgumentList "/X{C968E860-054F-490F-95C6-C9A29601459E} /qn /norestart" -Wait -PassThru
Write-Host "Exit with code $($ret.ExitCode)"

#HP Sure connect
Write-Host "Uninstall HP Sure Connect"
$path = "C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe"
if (Test-Path $path) {
	$ret = Start-Process -FilePath $path -ArgumentList "-runfromtemp -l0x0409 -uninst" -wait -PassThru
    Write-Host "Exit with code $($ret.ExitCode)"
}


#endregion

#
#This script will show different ways of uninstall applikations
#Even uninstallation wizards that requires keystrokes
#


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



#HP Documentation
Write-Host "Uninstall HP Documentation"
$path = "C:\Program Files\HP\Documentation\Doc_Uninstall.cmd"
if (test-Path $path) {
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


Download HPIA
 https://ftp.hp.com/pub/softpaq/sp107001-107500/sp107374.exe
Save the file in the same folder
Repackage the application as Intune Win32 app

Use these install commands
powershell.exe -NoLogo -ExecutionPolicy Bypass -File .\Install-HPIA.ps1
powershell.exe -NoLogo -ExecutionPolicy Bypass -File .\Uninstall-HPIA.ps1
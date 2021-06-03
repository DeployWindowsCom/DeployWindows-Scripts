Add the resulting Win32 app (.intunewin) to Intune. The installation command line should be:

powershell.exe -noprofile -executionpolicy bypass -file .\Update-OneDrive.ps1


Description
Updates and installes OneDrive per-machine
Log: Windows\Temp\OneDrive.log
Detection fil: %ProgramData%\Microsoft OneDrive\setup\Update-OneDrive.ps1.tag


The uninstall command line should be (there is no uninstallation, potentially you could delete the tag file)

cmd.exe /c


The detection rule should look for the existence of this file:

File or folder exists
%ProgramData%\Microsoft OneDrive\setup\Update-OneDrive.ps1.tag

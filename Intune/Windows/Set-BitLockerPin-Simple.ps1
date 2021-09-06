
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
$title = "Time to set a PIN code!"
$msg   = "You are required to set a Bitlocker startup PIN code."
do {
    $result = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)
} while ($result -eq "")
$SecureString = ConvertTo-SecureString $result -AsPlainText -Force 

Add-BitLockerKeyProtector -MountPoint "C:" -Pin $SecureString -TPMandPinProtector

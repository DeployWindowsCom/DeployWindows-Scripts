Add-Type -AssemblyName System.Windows.Forms
$global:toast = New-Object System.Windows.Forms.NotifyIcon
$path = (Get-Process -id $pid).Path
$toast.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
$toast.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
$toast.BalloonTipText = "This is the pop-up message text for the user"
$toast.BalloonTipTitle = "Hello mr $($Env:USERNAME)"
$toast.Visible = $true
$toast.ShowBalloonTip(10000)
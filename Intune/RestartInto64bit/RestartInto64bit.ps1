
Param([switch]$Is64Bit = $false)
 
Function Restart-As64BitProcess {
    If ([System.Environment]::Is64BitProcess) { return }
    $Invocation = $($MyInvocation.PSCommandPath)
    if ($Invocation -eq $null) { return }
    $sysNativePath = $psHome.ToLower().Replace("syswow64", "sysnative")
    Start-Process "$sysNativePath\powershell.exe" -ArgumentList "-ex bypass -file `"$Invocation`" -Is64Bit" -WindowStyle Hidden -Wait
}
 
 
if (!$Is64Bit) { 
    Restart-As64BitProcess 
} else {

    # Place your content here


}

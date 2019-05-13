

function Focus-Windows([string]$proc, [bool]$maximize)
{
    #Credits to https://stackoverflow.com/questions/42566799/how-to-bring-focus-to-window-by-process-name

    [string] $adm

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class WinAp {
      [DllImport("user32.dll")]
      [return: MarshalAs(UnmanagedType.Bool)]
      public static extern bool SetForegroundWindow(IntPtr hWnd);

      [DllImport("user32.dll")]
      [return: MarshalAs(UnmanagedType.Bool)]
      public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@
$p = Get-Process | Where {$_.mainWindowTitle} |
    Where {$_.Name -like "$proc"}
if (($p -eq $null) -and ($adm -ne "")) {
    Start-Process "$proc" -Verb runAs
} elseif (($p -eq $null) -and ($adm -eq "")) {
    Start-Process "$proc"
} else {
    $h = $p.MainWindowHandle
    [void] [WinAp]::SetForegroundWindow($h)
    if ($maximize)
    {
        [void] [WinAp]::ShowWindow($h, 3)
    } else {
        [void] [WinAp]::ShowWindow($h, 1)
    }
}

}

Focus-Windows "notepad" $false
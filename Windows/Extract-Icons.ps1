# Extract the default icon from files (dll, exe..) and create system icons such as exclamation marks


$path = "c:\windows\System32\moricons.dll"
$outputpath = "C:\temp"


#region This will extract the default associated icon
$format = "png"
switch ($format)
{
    'png' { $imageformat = [System.Drawing.Imaging.ImageFormat]::Png }
    'gif' { $imageformat = [System.Drawing.Imaging.ImageFormat]::Gif }
    'jpg' { $imageformat = [System.Drawing.Imaging.ImageFormat]::Jpeg }
    'ico' { $imageformat = [System.Drawing.Imaging.ImageFormat]::Icon}
    Default { $format = "jpg"; $imageformat = [System.Drawing.Imaging.ImageFormat]::Jpeg; }
}
Add-Type -AssemblyName System.Drawing
$icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
$icon.ToBitmap().save("$($outputpath)\icon.$($format)", $imageformat)
#endregion


#region This will create an icon from system icons
$icon = [System.Drawing.SystemIcons]::Exclamation
$icon.ToBitmap().save("$($outputpath)\Exclamation.$($format)", $imageformat)
#endregion


#region This will create a specificed icon from a file. Dont forget to change the number
#copy from https://social.technet.microsoft.com/Forums/windowsserver/en-US/16444c7a-ad61-44a7-8c6f-b8d619381a27/using-icons-in-powershell-scripts?forum=winserverpowershell
$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

namespace System
{
    public class IconExtractor {
        public static Icon Extract(string file, int number, bool largeIcon) {
            IntPtr large;
            IntPtr small;
            ExtractIconEx(file, number, out large, out small, 1);
            try {
                return Icon.FromHandle(largeIcon ? large : small);
            } catch {
                return null;
            }

        }
        [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
        private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);
    }
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing
#NOTE! change number 42 to the number of image you want!
$icon = [System.IconExtractor]::Extract($path, 42, $true)
$icon.ToBitmap().save("$($outputpath)\icons.$($format)", $imageformat)
#endregion

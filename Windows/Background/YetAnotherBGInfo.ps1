

Function New-BGinfo {
    Param(  [Parameter(Mandatory)]
            [string] $Text,
 
            [Parameter()]
            [string] $OutFile= "$($env:temp)\BGInfo.bmp",
 
            [Parameter()]
            [ValidateSet("Left","Center")]
            [string]$Align="Center",
 
 
            [Parameter()]
            [ValidateSet("Blue","Grey","Black")]
            [string]$Theme="Blue",
 
            [Parameter()]
            [string]$FontName="Arial",
 
            [Parameter()]
            [ValidateRange(9,45)]
            [int32]$FontSize = 12,
 
            [Parameter()]
            [switch]$UseCurrentWallpaperAsSource
    )
Begin {
 
    Switch ($Theme) {
        Blue {
            $BG = @(58,110,165)
            $FC1 = @(254,253,254)
            $FC2 = @(185,190,188)
            $FS1 = $FontSize+1
            $FS2 = $FontSize-2
            break
        }
        Grey {
            $BG = @(77,77,77)
            $FC1 = $FC2 = @(255,255,255)
            $FS1=$FS2=$FontSize
            break
        }
        Black {
            $BG = @(0,0,0)
            $FC1 = $FC2 = @(255,255,255)
            $FS1=$FS2=$FontSize
        }
    }
    Try {
        [system.reflection.assembly]::loadWithPartialName('system.drawing.imaging') | out-null
        [system.reflection.assembly]::loadWithPartialName('system.windows.forms') | out-null
 
        # Draw string > alignement
        $sFormat = new-object System.Drawing.StringFormat
 
        Switch ($Align) {
            Center {
                $sFormat.Alignment = [system.drawing.StringAlignment]::Center
                $sFormat.LineAlignment = [system.drawing.StringAlignment]::Center
                break
            }
            Left {
                $sFormat.Alignment = [system.drawing.StringAlignment]::Near
                $sFormat.LineAlignment = [system.drawing.StringAlignment]::Near
            }
        }
 
 
        if ($UseCurrentWallpaperAsSource) {
            $wpath = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper -ErrorAction Stop).WallPaper
            if (Test-Path -Path $wpath -PathType Leaf) {
                $bmp = new-object System.Drawing.Bitmap -ArgumentList $wpath
                $image = [System.Drawing.Graphics]::FromImage($bmp)
                $SR = $bmp | Select Width,Height
            } else {
                Write-Warning -Message "Failed cannot find the current wallpaper $($wpath)"
                break
            }
        } else {
            $SR = [System.Windows.Forms.Screen]::AllScreens | Where Primary | 
            Select -ExpandProperty Bounds | Select Width,Height
 
            Write-Verbose -Message "Screen resolution is set to $($SR.Width)x$($SR.Height)" -Verbose
 
            # Create Bitmap
            $bmp = new-object system.drawing.bitmap($SR.Width,$SR.Height)
            $image = [System.Drawing.Graphics]::FromImage($bmp)
     
            $image.FillRectangle(
                (New-Object Drawing.SolidBrush (
                    [System.Drawing.Color]::FromArgb($BG[0],$BG[1],$BG[2])
                )),
                (new-object system.drawing.rectanglef(0,0,($SR.Width),($SR.Height)))
            )
 
        }
    } Catch {
        Write-Warning -Message "Failed to $($_.Exception.Message)"
        break
    }
}
Process {
 
    # Split our string as it can be multiline
    $artext = ($text -split "\r\n")
     
    $i = 1
    Try {
        for ($i ; $i -le $artext.Count ; $i++) {
            if ($i -eq 1) {
                $font1 = New-Object System.Drawing.Font($FontName,$FS1,[System.Drawing.FontStyle]::Bold)
                $Brush1 = New-Object Drawing.SolidBrush (
                    [System.Drawing.Color]::FromArgb($FC1[0],$FC1[1],$FC1[2])
                )
                $sz1 = [system.windows.forms.textrenderer]::MeasureText($artext[$i-1], $font1)
                $rect1 = New-Object System.Drawing.RectangleF (0,($sz1.Height),$SR.Width,$SR.Height)
                $image.DrawString($artext[$i-1], $font1, $brush1, $rect1, $sFormat) 
            } else {
                $font2 = New-Object System.Drawing.Font($FontName,$FS2,[System.Drawing.FontStyle]::Bold)
                $Brush2 = New-Object Drawing.SolidBrush (
                    [System.Drawing.Color]::FromArgb($FC2[0],$FC2[1],$FC2[2])
                )
                $sz2 = [system.windows.forms.textrenderer]::MeasureText($artext[$i-1], $font2)
                $rect2 = New-Object System.Drawing.RectangleF (0,($i*$FontSize*2 + $sz2.Height),$SR.Width,$SR.Height)
                $image.DrawString($artext[$i-1], $font2, $brush2, $rect2, $sFormat)
            }
        }
    } Catch {
        Write-Warning -Message "Failed to $($_.Exception.Message)"
        break
    }
}
End {   
    Try { 
        # Close Graphics
        $image.Dispose();
 
        # Save and close Bitmap
        $bmp.Save($OutFile, [system.drawing.imaging.imageformat]::Bmp);
        $bmp.Dispose();
 
        # Output our file
        Get-Item -Path $OutFile
    } Catch {
        Write-Warning -Message "Failed to $($_.Exception.Message)"
        break
    }
}
 
} # endof function

Function Set-Wallpaper {
    Param(
        [Parameter(Mandatory=$true)]
        $Path,
         
        [ValidateSet('Center','Stretch','Fill','Tile','Fit')]
        $Style = 'Stretch'
    )
    Try {
        if (-not ([System.Management.Automation.PSTypeName]'Wallpaper.Setter').Type) {
            Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            using Microsoft.Win32;
            namespace Wallpaper {
                public enum Style : int {
                Center, Stretch, Fill, Fit, Tile
                }
                public class Setter {
                    public const int SetDesktopWallpaper = 20;
                    public const int UpdateIniFile = 0x01;
                    public const int SendWinIniChange = 0x02;
                    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
                    private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
                    public static void SetWallpaper ( string path, Wallpaper.Style style ) {
                        SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
                        RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
                        switch( style ) {
                            case Style.Tile :
                                key.SetValue(@"WallpaperStyle", "0") ; 
                                key.SetValue(@"TileWallpaper", "1") ; 
                                break;
                            case Style.Center :
                                key.SetValue(@"WallpaperStyle", "0") ; 
                                key.SetValue(@"TileWallpaper", "0") ; 
                                break;
                            case Style.Stretch :
                                key.SetValue(@"WallpaperStyle", "2") ; 
                                key.SetValue(@"TileWallpaper", "0") ;
                                break;
                            case Style.Fill :
                                key.SetValue(@"WallpaperStyle", "10") ; 
                                key.SetValue(@"TileWallpaper", "0") ; 
                                break;
                            case Style.Fit :
                                key.SetValue(@"WallpaperStyle", "6") ; 
                                key.SetValue(@"TileWallpaper", "0") ; 
                                break;
}
                        key.Close();
                    }
                }
            }
"@ -ErrorAction Stop 
            } else {
                Write-Verbose -Message "Type already loaded" -Verbose
            }
        # } Catch TYPE_ALREADY_EXISTS
        } Catch {
            Write-Warning -Message "Failed because $($_.Exception.Message)"
        }
    [Wallpaper.Setter]::SetWallpaper( $Path, $Style )
}


$os = Get-CimInstance Win32_OperatingSystem
($o = [pscustomobject]@{
    HostName =  $env:COMPUTERNAME
    UserName = '{0}\{1}' -f  $env:USERDOMAIN,$env:USERNAME
    'Operating System' = '{0} Service Pack {1} (build {2})' -f  $os.Caption,
    $os.ServicePackMajorVersion,$os.BuildNumber
}) | ft -AutoSize
$BootTime = (New-TimeSpan -Start $os.LastBootUpTime -End (Get-Date)).ToString()
 
# $t is the multiline text defined as here-string
$t = @"
Welcome to your computer 
$($o.HostName)
Logged on user: $($o.UserName)
$($o.'Operating System')
Uptime: $BootTime
"@

#Alt 1 - Grey background
#$WallPaper = New-BGinfo -text $t -Theme Grey
#Set-Wallpaper -Path $WallPaper.FullName -Style Fill 

#Alt 2 - Current wallpaper settings
$BGHT = @{
    Text  = $t ;
    Theme = "Black" ;
    FontName = "Verdana" ;
    UseCurrentWallpaperAsSource = $true ;
   }
$WallPaper = New-BGinfo @BGHT
Set-Wallpaper -Path $WallPaper.FullName -Style Fill

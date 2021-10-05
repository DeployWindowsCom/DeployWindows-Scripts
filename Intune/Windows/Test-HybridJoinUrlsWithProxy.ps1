# Test proxy
$logpath = "\\SERVER\ClientLog$\$($env:computername)?ProxyTest.log"

Start-Transcript -Path $logpath -Force

$urls = @(
    "https://enterpriseregistration.windows.net/EnrollmentServer/device/",
    "https://login.microsoftonline.com",
    "https://device.login.microsoftonline.com"
    "https://autologon.microsoftazuread-sso.com/domain.local/winauth/sso" #This is used for SSO
)

$proxy = "http://10.10.10.10:8080"

$ret = 0
foreach ($url in $urls)
   {
        Write-Host
        Write-Host "Connecting to $($url)...."
        try
        {
            $a = Invoke-WebRequest $url -Proxy $proxy -Method Post -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            if (!($a).Content.Contains("look for a text"))
            {
                Write-Host "Successful connection" -BackgroundColor Green
                $ret++
            } else {
                Write-Host "Failed connection - was caught by proxy" -BackgroundColor Red
            }
        }
        catch [System.Net.WebException]
        {
            $err = $_.Exception
            switch ($err.Status)
            {
                'NameResolutionFailure' {
                    Write-Host "Failed to connect ($($err.Status): $($err.Message))"  -BackgroundColor Red
                }
                'ProtocolError' {
                    #$err.Response
                    if (($err.Message.Contains("400")) -and ($err.Response.ContentLength -ge 1) -and ($err.Response.StatusCode -eq "BadRequest")) {
                        Write-Host "Guessing a Successful connection to the webservice with the response $($err.Status): $($err.Message)" -BackgroundColor DarkYellow
                        $ret++
                    } else {
                        Write-Host "Guessing your connection is NOT successful to the webservice with the response $($err.Status): $($err.Message)" -BackgroundColor Red
                    }
                }
                Default {
                    Write-Host "Failed to connect ($($err.Status): $($err.InnerException))"  -BackgroundColor Red
                }
            }
            #$_.Exception | gm
            #$_.InvocationInfo
        }
        catch [System.Exception]
        {
            Write-Host "Unrepairable error with Exception: $($_.Exception.Message)"  -BackgroundColor Red
        }
        catch {
            write-host "What happend? $($_.Exception.Message)"
        }
        finally
        { }

   }

   Write-Host "$($ret) out of $($urls.Count) seems to be successful"

Stop-Transcript 
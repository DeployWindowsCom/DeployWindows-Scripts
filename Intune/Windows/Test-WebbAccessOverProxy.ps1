
# a couple of public services that should be accessable for your service
$urls = @(
"https://test.blob.core.windows.net",
"https://adds.aadconnecthealth.azure.com/",
#"servicebus.windows.net",
"https://s1.adhybridhealth.azure.com",
"https://management.azure.com",
"https://policykeyservice.dc.ad.msft.net/",
"https://login.windows.net",
"https://login.microsoftonline.com",
"https://secure.aadcdn.microsoftonline-p.com",
"https://www.office.com"
)


$proxy = "http://10.10.10.1:8080" # your proxy server


foreach ($url in $urls)
   {
        Write-Host
        Write-Host "Connecting to $($url)...."
        try
        {
            $a = Invoke-WebRequest $url -Proxy $proxy -Method Post -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            if (!($a).Content.Contains("DS Smith"))
            {
                Write-Host "Successful connection" -BackgroundColor Green
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
        write-host "något hände?"
        }
        finally
        { }

   }

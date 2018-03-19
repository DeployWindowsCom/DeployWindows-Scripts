#Get the current domain
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$domain = "DC=$($domain.Name.Replace('.',',DC='))"
#Get the current username and SID
$CurrentUsername = $env:USERNAME
$CurrentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
#Time to connect to a domain controller and perform a ldap search with either current username or SID
#Only one object will be returned
$Searcher = New-Object DirectoryServices.DirectorySearcher
$Searcher.Filter = "(&(objectCategory=person)(objectSid=$($CurrentUserSid)))"
#$Searcher.Filter = "(&(objectCategory=person)(cn=$($CurrentUsername)))"
$Searcher.SearchRoot = "LDAP://$($domain)"
$User = $Searcher.FindOne()
$CurrentUpn = ([ADSI]$User.Path).userPrincipalName
 
If ($(Test-Path -Path "HKCU:\Software\Microsoft\Office\15.0\Lync") -eq $False) { New-Item "HKCU:\Software\Microsoft\Office\15.0\Lync" }
New-ItemProperty "HKCU:\Software\Microsoft\Office\15.0\Lync" -Name "FirstRun" -Value 1 -PropertyType "DWord" -Force
New-ItemProperty "HKCU:\Software\Microsoft\Office\15.0\Lync" -Name "SavePassword" -Value 1 -PropertyType "DWord" -Force
New-ItemProperty "HKCU:\Software\Microsoft\Office\15.0\Lync" -Name "ServerSipUri" -Value $CurrentUpn -PropertyType "String" -Force
New-ItemProperty "HKCU:\Software\Microsoft\Office\15.0\Lync" -Name "ServerUsername" -Value $CurrentUpn -PropertyType "String" -Force
New-ItemProperty "HKCU:\Software\Microsoft\Office\15.0\Lync" -Name "IsBasicTutorialSeenByUser" -Value 1 -PropertyType "DWord" -Force
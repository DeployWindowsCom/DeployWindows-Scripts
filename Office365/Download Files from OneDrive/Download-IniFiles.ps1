Param(
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [string]
    $Inputfile
)

$scriptpath = $MyInvocation.MyCommand.Definition.Replace($MyInvocation.MyCommand.Name, "")

if (-not (Test-Path -Path $inputfile -ErrorAction SilentlyContinue)) {
    Write-Host "Input file does not exist $($inputfile)" -BackgroundColor Red
    break
}
$ResultFile = Join-Path -Path $scriptpath -ChildPath "Result - Download INI.csv"

#Static variables
$StaticFolderUrl = "Documents/Personal"
$StaticFileName = "Business Cards.docx"
$TargetFolder = Join-Path -Path $scriptpath -ChildPath "DownloadedFiles"

if (-not (Test-Path -Path $TargetFolder -ErrorAction SilentlyContinue)) {
    Write-Host "You need to create this folder: $($TargetFolder)" -BackgroundColor Red
    break
}

#Importing the CSV file
$csv = Import-Csv -Path $inputfile

# Result file header
if (Test-Path $ResultFile) { Remove-Item -Path $ResultFile -Force }
"onedrive,samaccountname,serverurl,downloadpath,onedriveconnect,listfolder,filedownloaded" | Add-Content -Path $ResultFile -Encoding UTF8 -Force

Foreach ($user in $csv) {
    $UserOneDrive = $user.onedrive
    $SamAccountName = $user.username

    $result = New-Object PSObject
    Add-Member -InputObject $result -MemberType NoteProperty -Name "Onedrive" -Value $UserOneDrive
    Add-Member -InputObject $result -MemberType NoteProperty -Name "SamAccountName" -Value $SamAccountName
    Add-Member -InputObject $result -MemberType NoteProperty -Name "ServerUrl" -Value ""
    Add-Member -InputObject $result -MemberType NoteProperty -Name "DownloadPath" -Value ""
    Add-Member -InputObject $result -MemberType NoteProperty -Name "OneDriveConnect" -Value "failed"
    Add-Member -InputObject $result -MemberType NoteProperty -Name "ListFolder" -Value "failed"
    Add-Member -InputObject $result -MemberType NoteProperty -Name "FileDownloaded" -Value "notfound"

    Write-Host "Connecting to user's OneDrive: $($UserOneDrive)"
    try {
        Connect-pnponline -url $UserOneDrive -Interactive -ErrorAction Stop
        $result.OneDriveConnect = "success"
    } catch {
        Write-Host "Error connecting user's OneDrive" -ForegroundColor Red
        $result.OneDriveConnect = "error"
    }

    $FileFound = $false
    $file = $null
    try {
        $file = Get-PnPFolderItem -FolderSiteRelativeUrl $StaticFolderUrl -ItemName $StaticFileName -ItemType File -ErrorAction Stop
        $FileFound = $true
        $result.ListFolder = "success"
    } catch {
        Write-Host "Error enumerate file: $($StaticFileName)" -ForegroundColor Red
        $result.ListFolder = "error"
    }

    if (($FileFound) -and ($null -ne $file )) {
        try {
            $SubFolderName = $SamAccountName
            $DownloadFolder = Join-Path -Path $TargetFolder -ChildPath $SubFolderName
            if (-not (Test-Path -Path $DownloadFolder)) {
                New-Item -Path $TargetFolder -Name $SubFolderName -ItemType Directory | Out-Null
            }
            $result.ServerUrl = $file.ServerRelativeUrl
            $result.DownloadPath = $DownloadFolder
            Get-PnPFile -Url $file.ServerRelativeUrl -Path $DownloadFolder -Filename $StaticFileName -AsFile -Force -ErrorAction Stop
            Write-Host "File downloaded" -ForegroundColor Green
            $result.FileDownloaded = "success"
        } catch {
            Write-Host "Error downloading file" -ForegroundColor Red
            $result.FileDownloaded = "error"
        }
    }

    $result | Export-Csv -Path $ResultFile -Append -NoClobber -NoTypeInformation -Force
}

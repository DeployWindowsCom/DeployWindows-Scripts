###########################################################################
#
# This script will sync the time with a preconfigured internet source
#
############################################################################


$SyncTask = @(Get-ScheduledTask -TaskName "ForceSynchronizeTime" -TaskPath "\Microsoft\Windows\Time Synchronization\")

if ($SyncTask.Count -ge 1) 
{
    Write-Host "Start ForceSynchronizeTime"
    Start-ScheduledTask -TaskName "ForceSynchronizeTime" -TaskPath "\Microsoft\Windows\Time Synchronization\"
} 
else 
{
    $SyncTask = @(Get-ScheduledTask -TaskName "SynchronizeTime" -TaskPath "\Microsoft\Windows\Time Synchronization\")
    if ($SyncTask.Count -ge 1) 
    {
        #This may not start due to not using AC
        Write-Host "Start SynchronizeTime"
        Start-ScheduledTask -TaskName "SynchronizeTime" -TaskPath "\Microsoft\Windows\Time Synchronization\"
    }
    else
    {
        #This will run the Scheuled task command directly
        Write-Host "Start SC Taskstarted"
        $Cmd = "$($env:windir)\system32\sc.exe"
        $CmdArg = "start w32time task_started"
        $Ret = Start-Process $Cmd -ArgumentList $CmdArg -WindowStyle Hidden -PassThru -Wait
        #$Ret.ExitCode;
    }
}

Return $Null;

Import-Module WebAdministration
#$apppool = Get-ChildItem -Path IIS:\Apppools -Name
param ([string] $apppool = 0)
$idx = 1
write-host "{"
write-host " `"data`":[`n"
foreach ($currentapppool in $apppool)
{
    $AppPoolPID = (gwmi -NS 'root\WebAdministration' -class 'WorkerProcess' | Where-Object -Property AppPoolName -eq "$currentapppool").ProcessId    
    if ($idx -lt $apppool.count)
    {
     
        $line= "{ `"{#PID}`" : `"" + $AppPoolPID + "`" },"
        write-host $line
    }
    elseif ($idx -ge $apppool.count)
    {
    $line= "{ `"{#PID}`" : `"" + $AppPoolPID + "`" }"
    write-host $line
    }
    $idx++;
}
write-host
write-host " ]"
write-host "}"




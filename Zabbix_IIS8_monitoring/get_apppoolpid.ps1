param ([string] $name = 0)
Import-Module WebAdministration
$AppPoolPID = (gwmi -NS 'root\WebAdministration' -class 'WorkerProcess' | Where-Object -Property AppPoolName -eq "$name").ProcessId
Write-Output ($AppPoolPID)
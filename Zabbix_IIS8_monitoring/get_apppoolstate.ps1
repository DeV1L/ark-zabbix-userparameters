param ([string] $name = 0)
Import-Module WebAdministration
$apppoolState = Get-WebAppPoolState -name "$name"
    if ($apppoolState.value -eq "Started"){
        Write-Output "1"
        }
    else {
        Write-Output "0"
        }
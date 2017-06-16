$certLocation = "\\rackspace\certstore"
Import-Module WebAdministration
$apppool = Get-ChildItem -Path IIS:\Apppools -Name
$certs = gci $certLocation -Filter "*.pfx"
$idx = 1
write-host "{"
write-host " `"data`":[`n"
foreach ($cert in $certs)
{
    if ($idx -lt $certs.count)
    {
     
        $line= "{ `"{#CERT}`" : `"" + $cert + "`" },"
        write-host $line
    }
    elseif ($idx -ge $certs.count)
    {
    $line= "{ `"{#CERT}`" : `"" + $cert + "`" }"
    write-host $line
    }
    $idx++;
}
write-host
write-host " ]"
write-host "}"

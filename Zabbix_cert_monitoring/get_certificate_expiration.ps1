param ([string] $name = 0)
$certLocation = "\\rackspace\certstore"
$certPass = "Arkadium"
$certKeySet = "DefaultKeySet"
$currentDate = (Get-Date).Date
$PFXCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$PFXCert.Import($certLocation+"\"+$name, $certPass, $certKeySet)
$certExpirationDate = $PFXCert.NotAfter.Date
$certWillExpire = ($certExpirationDate - $currentDate).Days
Write-Output ($certWillExpire)
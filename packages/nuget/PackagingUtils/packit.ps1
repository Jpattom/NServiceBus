if(Test-Path ./RunOnce.ps1)
{
	./RunOnce.ps1
	Write-Host "Please restart and execute me a again"
}
else
{
	import-module ./packit.psm1
	Write-Output "Loding the moduele for packing.............."
	$packit.push_to_nuget = $true 
	invoke-packit "NServiceBus.Host" "" @{NServiceBus="<version>"}
	remove-module packit
}
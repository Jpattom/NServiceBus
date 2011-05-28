if(Test-Path ./RunOnce.ps1)
{
	./RunOnce.ps1
	Write-Host "Please restart and execute me a again"
	
}
$nugetAvailable = Get-Command Nuget 
if($nugetAvailable -eq $null)
{
	Write-Host "Nuget Not Available......."
	Write-Host "Please Copy the nuget.exe to any folder in [env]path and execute me again"
	
}
else
{
	import-module ./packit.psm1
	invoke-packit "NServiceBus.Host" "" @{NServiceBus="<version>"}
	remove-module packit
}
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
	
	#region packing NserviceBus
	$packit.package_description = "The most popular open-source service bus for .net"
	invoke-packit "NServiceBus" "" @{log4net="1.2.10"} "NServiceBus.dll", "NServiceBus.Core.dll"
	#endregion
	
	#region packing NServiceBus.Host
	$packit.package_description = "The hosting template for the nservicebus, The most popular open-source service bus for .net"
	invoke-packit "NServiceBus.Host" "" @{NServiceBus="<version>"} "NServiceBus.Host.exe" 
	#endregion
	
	remove-module packit
}
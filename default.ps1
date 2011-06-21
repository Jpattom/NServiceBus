task default -depends CreatePackage

task CreatePackage -depends  BuildOnNet35, BuildOnNet40  {

	cd .\packages\nuget\PackagingUtils
	import-module ./packit.psm1
	Write-Output "Loding the moduele for packing.............."
	$packit.push_to_nuget = $false 
	
	#region packing NserviceBus
	$packit.package_description = "The most popular open-source service bus for .net"
	invoke-packit "NServiceBus" "" @{log4net="1.2.10"} "NServiceBus.dll", "NServiceBus.Core.dll"
	#endregion
	
	#region packing NServiceBus.Host
	$packit.package_description = "The hosting template for the nservicebus, The most popular open-source service bus for .net"
	invoke-packit "NServiceBus.Host" "" @{NServiceBus="<version>"} "NServiceBus.Host.exe" 
	#endregion
	
	#region NServiceBus.Testing
	$packit.package_description = "The testing for the nservicebus, The most popular open-source service bus for .net"
	invoke-packit "NServiceBus.Testing" "" @{NServiceBus="<version>"} "NServiceBus.Testing.dll"
	#endregion
	
	remove-module packit
	cd ..\..\..\
 }
 
 
 task BuildOnNet35 {
 	.\tools\nant\nant.exe -D:targetframework=net-3.5
	XCopy  binaries\* build\lib\net35\ /S /Y
 }
 
 task BuildOnNet40 {
 	.\tools\nant\nant.exe -D:targetframework=net-4.0
	XCopy  binaries\* build\lib\net40\ /S /Y
 }
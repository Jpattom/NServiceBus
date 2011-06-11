task default -depends CreatePackage

task CreatePackage -depends  BuildOnNet35, BuildOnNet40  {
	cd .\packages\nuget\PackagingUtils
	.\packit.ps1
	 cd ..\..\..\
 }
 
 
 task BuildOnNet35 {
 	.\tools\nant\nant.exe -D:targetframework=net-3.5
	XCopy  binaries\* build\lib\net35\ /S /Y
 
 }
 
 task BuildOnNet40 {
 	echo "Building Nservice Bus On .net framework 4.0"
 	.\tools\nant\nant.exe -D:targetframework=net-4.0
	XCopy  binaries\* build\lib\net40\ /S /Y
 }
 
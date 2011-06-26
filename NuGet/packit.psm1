#region Public Module Variables  
$script:packit = @{}
$script:packit.push_to_nuget = $false      # Set the variable to true to push the package to NuGet galary.

$script:packit.default_package = "NServiceBus"
$script:packit.package_owners = "Udi Dahan, Andreas Ohlund, Matt Burton, Jonathan Oliver et al"
$script:packit.package_authors = "Udi Dahan, Andreas Ohlund, Matt Burton, Jonathan Oliver et al"
$script:packit.package_description = "The most popular open-source service bus for .net"
$script:packit.package_language = "en-US"
$script:packit.package_licenseUrl = "http://nservicebus.com/license.aspx"
$script:packit.package_projectUrl = "http://nservicebus.com/"
$script:packit.package_requireLicenseAcceptance = $true;
$script:packit.package_tags = "nservicebus servicebus msmq cqrs publish subscribe"
$script:packit.package_version = "2.5"
$script:packit.package_iconUrl = "http://a2.twimg.com/profile_images/1203939022/nServiceBus_Twitter_Logo_reasonably_small.png"
$script:packit.binaries_Location = ".\binaries"
$script:packit.framework_Isolated_Binaries_Loc = ".\build\lib"
$script:packit.targeted_Frameworks = "net35","net40"
$script:packit.versionAssemblyName = $script:packit.binaries_Location + "\NServiceBus.dll"
$script:packit.packageOutPutDir = ".\packages"
$script:packit.PackagingArtefactsRoot = ".\NuGet\PackagingArtefacts"
$script:packit.nugetCommand = ".\tools\Nuget\NuGet.exe"
$script:packit.nugetKey =     ".\tools\Nuget\NuGetKey.txt"

Export-ModuleMember -Variable "packit"
#endregion

$VesionPlaceHolder = "<version>"

function PushPackage($packageName)
{
	$keyfile = resolve-path $script:packit.nugetKey
	$packagespath = resolve-path $script:packit.packageOutPutDir
	$nugetExcec =  resolve-path $script:packit.nugetCommand
	if(-not (test-path $keyfile)) 
	{
  		throw "Could not find the NuGet access key at $keyfile."
	}
  	pushd $packagespath
 
  	# get our secret key.
  	$key = get-content $keyfile
	$key = $key.Trim()
 
  	# Find all the packages and display them for confirmation
  	$packages = dir $packageName
  	write-host "Packages to upload:"
  	$packages | % { write-host $_.Name }
 
    $packages | % { 
        $package = $_.Name
        write-host "Uploading $package"
        #&$nugetExcec  push -source "http://packages.nuget.org/v1/" $package $key
        write-host ""    
  	}
  popd
}

Export-ModuleMember -Function "PushPackage"

function Invoke-Packit
{

[CmdletBinding(
    SupportsShouldProcess=$False,
    SupportsTransactions=$False,
    ConfirmImpact="None",
    DefaultParameterSetName="")]
	
	param(
    		 [Parameter(Position=0,Mandatory=0)]
    		 [string]$packageName = $script:packit.default_package,
			 [Parameter(Position=1,Mandatory=0)]
    		 [string]$packageVersion = "",
			 [Parameter(Position=2,Mandatory=0)]
    		 [System.Collections.Hashtable]$dependencies = @{},
			 [Parameter(Position=3, Mandatory=0)]
			 [System.Collections.ArrayList]$assemblyNames  
  		)
		
	begin
	{
	
	}
	process
	{
	
    	[string]$version = $packageVersion
		if($version -eq "")
		{
			try
			{
				$versionAssemblyLocation = Resolve-Path -Path $script:packit.versionAssemblyName
				[System.Reflection.Assembly]$versionAssembly = [System.Reflection.Assembly]::Loadfile($versionAssemblyLocation)
				if($versionAssembly -ne $null)
				{
					$assmName = $versionAssembly.GetName();
					if($assmName -ne $null){
						$version = $assmName.version
					}
				}
			}
			catch
			{
			  "Unable to Find the Version from assembly due to the Error:- `n $_"
		      $version = $script:packit.package_version
			}
		}
		 
		 if((Test-Path -Path $script:packit.packageOutPutDir) -ne $true)
		 {
		 	mkdir $script:packit.packageOutPutDir
		 }
		 
		$packageDir = $script:packit.PackagingArtefactsRoot + "\" + $packageName
		if((Test-Path -Path $script:packit.PackagingArtefactsRoot) -ne $true)
		{
			mkdir $script:packit.PackagingArtefactsRoot
		}
		
		if((Test-Path -Path $packageDir) -ne $true)
		{
			mkdir $packageDir
		}
		
		
		$packagePath = $packageDir + "\" + $packageName
		&$script:packit.nugetCommand  spec $packagePath -Force
		$nuGetSpecFile = $packagePath + ".nuspec"
		[xml] $nuGetSpecContent= Get-Content $nuGetSpecFile
		$nuGetSpecContent.package.metadata.Id = $packageName
		$nuGetSpecContent.package.metadata.version = $version
		$nuGetSpecContent.package.metadata.authors = $script:packit.package_authors
		$nuGetSpecContent.package.metadata.owners = $script:packit.package_owners
		$nuGetSpecContent.package.metadata.licenseUrl = $script:packit.package_licenseUrl
		$nuGetSpecContent.package.metadata.projectUrl = $script:packit.package_projectUrl
		$nuGetSpecContent.package.metadata.requireLicenseAcceptance = "true"
		$nuGetSpecContent.package.metadata.description = $script:packit.package_description
		$nuGetSpecContent.package.metadata.tags = $script:packit.package_tags
		$nuGetSpecContent.package.metadata.iconUrl = $script:packit.package_iconUrl;
		$dependencyInnerXml = ""
		if($dependencies.Count -gt 0)
		{
		   $dependencies |  Foreach-Object {
 		   $p = $_
    		@($p.GetEnumerator()) | Where-Object {            
        	($_.Value | Out-String) 
    		} | Foreach-Object {
			 $dependencyPackage = $_.Key
			 $dependencyPackageVersion = $_.Value
			 if($dependencyPackageVersion -eq $VesionPlaceHolder)
			 {
			 	$dependencyPackageVersion = $version
			 }
			 $dependencyInnerXml = "{0}<dependency id=""{1}"" version=""{2}"" />" -f 
        	 $dependencyInnerXml,$dependencyPackage,$dependencyPackageVersion
    		}
			}
	       $nuGetSpecContent.package.metadata.dependencies.set_InnerXML($dependencyInnerXml)
		}				 
		$writerSettings = new-object System.Xml.XmlWriterSettings
  		$writerSettings.OmitXmlDeclaration = $true
  		$writerSettings.NewLineOnAttributes = $true
 		$writerSettings.Indent = $true
		$nuGetSpecFilePath = Resolve-Path -Path $nuGetSpecFile
  		$writer = [System.Xml.XmlWriter]::Create($nuGetSpecFilePath, $writerSettings)

  		$nuGetSpecContent.WriteTo($writer)
 		$writer.Flush()
  		$writer.Close()
		 if($assemblyNames.Count -gt 0)
		 {
			 $libPath = $packageDir + "\lib"
			 mkdir $libPath
		 	 foreach ($assemblyName in $assemblyNames)
			 {
				 foreach($framework in $script:packit.targeted_Frameworks)
				 {
				 	$source = $script:packit.framework_Isolated_Binaries_Loc + "\" + $framework + "\" + $assemblyName
					$destination =  $libPath + "\" + $framework +"\"
					$directoryName  = [system.io.Path]::GetDirectoryName($assemblyName)
					if($directoryName -ne "")
					{
						$destination +=  $directoryName + "\"
						
					}
					#Using Xcopy to copy everything including directory structure
				 	XCopy $source $destination /S /Y 
				 }			 
			}			 
		 }
		 $packageContentPath = ".\Content" + $packageName
		 if(Test-Path $packageContentPath)
		 {
			 $contentPath = $packageDir + "\Content"
			 mkdir $contentPath
			 $packageContentPath += "\*.*"
			 copy $packageContentPath $contentPath
		 }
		 $packageToolsPath = ".\Tools" + $packageName
		 if(Test-Path $packageToolsPath)
		 {
			 $toolsPath = $packageDir + "\tools"
			 mkdir $toolsPath
			 $packageToolsPath += "\*.*"
			 copy $packageToolsPath $toolsPath
		 }		 
		 
		 &$script:packit.nugetCommand  pack $nuGetSpecFile -OutputDirectory $script:packit.packageOutPutDir -Verbose
		 
		 if($script:packit.push_to_nuget){ PushPackage($packName) }
	}
	end
	{
	
	}	
}

Export-ModuleMember -Function "Invoke-Packit"


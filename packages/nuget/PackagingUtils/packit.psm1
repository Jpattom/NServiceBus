#-- Public Module Variables -- 
$script:packit = @{}
$script:packit.push_to_nuget = $false      # Set the variable to true to push the package to NuGet galary.
$script:packit.default_package = "NServiceBus"
$script:packit.package_owners = "Udi Dahan, Andreas Ohlund, Matt Burton, Jonathan Oliver et al"
$script:packit.package_authors = "Udi Dahan, Andreas Ohlund, Matt Burton, Jonathan Oliver et al"
$script:packit.package_description = "The hosting template for the nservicebusThe most popular open-source service bus for .net"
$script:packit.package_language = "en-US"
$script:packit.package_licenseUrl = "http://nservicebus.com/license.aspx"
$script:packit.package_projectUrl = "http://nservicebus.com/"
$script:packit.package_requireLicenseAcceptance = $true;
$script:packit.package_tags = "nservicebus servicebus msmq cqrs publish subscribe"
$script:packit.package_version = "2.5"
$script:packit.package_iconUrl = "http://images.nservicebus.com/nServiceBus_Logo.png"
$script:packit.build_Location = "..\..\..\Build"
$script:packit.versionAssemblyName = $script:packit.build_Location + "\nservicebus\NServiceBus.dll"
$script:packit.packageOutPutDir = ".\packages"

Export-ModuleMember -Variable "packit"

$VesionPlaceHolder = "<version>"

function PuchPackage($packageName)
{
$keyfile = ""
$packagespath = resolve-path $script:packit.packageOutPutDir
 
#if(-not (test-path $keyfile)) {
#  throw "Could not find the NuGet access key at $keyfile. If you're not Jeremy, you shouldn't be running this script!"
#}
#else {
  pushd $packagespath
 
  # get our secret key.
#  $key = get-content $keyfile
 
  # Find all the packages and display them for confirmation
  $packages = dir $packageName
  write-host "Packages to upload:"
  $packages | % { write-host $_.Name }
 
  # Ensure we haven't run this by accident.
  $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Uploads the packages."
  $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Does not upload the packages."
  $options = [System.Management.Automation.Host.ChoiceDescription[]]($no, $yes)
 
  $result = $host.ui.PromptForChoice("Upload packages", "Do you want to upload the NuGet packages to the NuGet server?", $options, 0) 
 
  # Cancelled
  if($result -eq 0) {
    "Upload aborted"
  }
  # upload
  elseif($result -eq 1) {
    $packages | % { 
        $package = $_.Name
        write-host "Uploading $package"
#        NuGet push -source "http://packages.nuget.org/v1/" $package $key
        write-host ""
    }
  }
  popd
}
#}

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
			 [System.Collections.ArrayList]$assemblyNames = @{}
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
		$packageDir = "..\" + $packageName
		if(Test-Path $packageDir)
		{
			Remove-Item $packageDir -Recurse
		}
		mkdir $packageDir 
		$packagePath = $packageDir + "\" + $packageName
		NuGet spec $packagePath
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
#		if($nuGetSpecContent.package.metadata.language -eq $null)
#		{
#			$refNode = $nuGetSpecContent.package.metadata | Select-Object -Property "description"
#			$parentNode = $nuGetSpecContent.package | Select-Object -Property "metadata"
#			$languageNode = $parentNode.CreateElement("language");
#			$parentNode.insertAfter($languageNode, $refNode)
#			#$nuGetSpecContent.package.metadata.CreateElement("language");
#			
#		}
#		$nuGetSpecContent.package.metadata.language = $script:packit.package_language
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
		Set-Content $nuGetSpecFile $nuGetSpecContent.get_OuterXML()				
		 if($assemblyNames.Count -gt 0)
		 {
			 $libPath = $packageDir + "\lib"
			 mkdir $libPath
			 <#	 Logic Copy the assemblies to lib to support both 4.0 and 3.5 framework#>
			 
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
		 if(Test-Path $packageContentPath)
		 {
			 $toolsPath = $packageDir + "\tools"
			 mkdir $toolsPath
			 $packageToolsPath += "\*.*"
			 copy $packageToolsPath $toolsPath
		 }		 
		 NuGet pack $nuGetSpecFile 
		 
		 if((Test-Path -Path $script:packit.packageOutPutDir) -ne $true)
		 {
		 	mkdir $script:packit.packageOutPutDir
		 }
		 $packName = "{0}.{1}.nupkg" -f
		 $packageName, $version 
		 
#		 $relativePath = $script:packit.packageOutPutDir + "\" + $packageName
#		 if(Test-Path $relativePath)
#		 {
#		 	Remove-Item $relativePath
#		 }
		 Move-Item $packName $script:packit.packageOutPutDir -Force
		 PuchPackage($packName)
		 
	}
	end
	{
	
	}	
}

Export-ModuleMember -Function "Invoke-Packit"


param($installPath, $toolsPath, $package, $project)
 
if ($host.Version.Major -eq 1 -and $host.Version.Minor -lt 1) 
{ 
    "NOTICE: This package only works with NuGet 1.1 or above. Please update your NuGet install at http://nuget.codeplex.com. Sorry, but you're now in a weird state. Please 'uninstall-package AddMvc3ToWebForms' now."
}
else
{
	$userConfig = $project.FullName + ".user"
	if(Test-Path $userConfig)
	{
	    [xml] $userConfigContent = Get-Content $userConfig
	}
	else
	{
		
		 [xml] $userConfigContent = new-object System.Xml.XmlDocument
		 $userConfigContentXml = "<?xml version=""1.0"" encoding=""utf-8""?><Project ToolsVersion=""4.0"" xmlns=""http://schemas.microsoft.com/developer/msbuild/2003""><PropertyGroup Condition=""'`$(Configuration)|`$(Platform)' == 'Debug|x86'""><StartAction>Program</StartAction><StartProgram>{0}\{1}</StartProgram></PropertyGroup></Project>" -f
		 "`$(outdir)", "NServiceBus.Host.exe"
		 
		 $userConfigContent.LoadXml($userConfigContentXml )
		 
		 $writerSettings = new-object System.Xml.XmlWriterSettings
		 $writerSettings.OmitXmlDeclaration = $true
		 $writerSettings.NewLineOnAttributes = $true
		 $writerSettings.Indent = $true

		 $writer = [System.Xml.XmlWriter]::Create($userConfig, $writerSettings)
    	 $userConfigContent.WriteTo($writer)
		 $writer.Flush()
		 $writer.Close()
	}
	$project.ProjectItems.Item("NServiceBus.Host.exe.config").Properties.Item("CopyToOutputDirectory").Value = 1
	
}
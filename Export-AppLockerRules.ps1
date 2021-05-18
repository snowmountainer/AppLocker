function Export-AppLockerRules
{
<#
.SYNOPSIS
	Export Applocker Rules
.DESCRIPTION
	Export Applocker Rules
.PARAMETER OutPath
	Specifies the path to output xml file.
.PARAMETER RoulesSource
	Specifies the AppLocker Source of rules. Default 'Effective' for effective working rules.
	Values: Effective, Local
    Default Value: Effective
.PARAMETER Filter
	Specifies the output filtertype. Default 'All' for all rules.
	Values: All, Prefix, ExceptPrefix
    Default Value: All
.PARAMETER Prefix
	Specifies the output filter by prefix. Not available for filter 'All'.
.EXAMPLE
	Export-AppLockerRules -OutPath "c:\test\Effective.xml" -Verbose
.EXAMPLE
	Export-AppLockerRules -OutPath "c:\test\Effective.xml" -RoulesSource Effective -Filter All -Verbose
.EXAMPLE
	Export-AppLockerRules -OutPath "c:\test\ExceptPrefix.xml" -RoulesSource Effective -Filter ExceptPrefix -Prefix "SAMPLE" -Verbose
.EXAMPLE
	Export-AppLockerRules -OutPath "c:\test\Prefix.xml" -RoulesSource Effective -Filter Prefix -Prefix "SAMPLE" -Verbose
.NOTES
	Copyright (C) 2021 Martin Schneeberger
	
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
	
	v1.0.1
.LINK
	https://github.com/snowmountainer/AppLocker
#>
	[CmdletBinding()]
	Param
	(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$OutPath,
        [ValidateSet("Effective", "Local")]
        [string]$RoulesSource = "Effective",
        [ValidateSet("All", "Prefix", "ExceptPrefix")]
        [string]$Filter = "All",
        [ValidateScript({$Filter -ne "All"})]
        [string]$Prefix
	)
	Begin
	{
	}
	Process
	{
		switch ($RoulesSource)
		{
			"Local" {[xml]$xml = Get-AppLockerPolicy -Local –Xml; Write-Verbose "Exporting rules from Local policy"}
			"Effective" {[xml]$xml = Get-AppLockerPolicy -Effective –Xml; Write-Verbose "Exporting rules from Effective policy"}
		}
        
		switch ($Filter)
		{
			"ExceptPrefix" {
				Write-Verbose "Exporting rules without prefix `"${Prefix}`:`""
				$xml.AppLockerPolicy.RuleCollection | ForEach-Object {$_.EnforcementMode = "NotConfigured"}
				$nodesToRemove = $xml.SelectNodes("//FilePublisherRule[(starts-with(@Name,'${Prefix}:'))] | //FilePathRule[(starts-with(@Name,'${Prefix}:'))] | //FileHashRule[(starts-with(@Name,'${Prefix}:'))]")
				$nodesToRemove | ForEach-Object {
					[void]($_.ParentNode.RemoveChild($_))
				}
			}
			"Prefix" {
				Write-Verbose "Exporting rules with prefix `"${Prefix}`:`""
				$xml.AppLockerPolicy.RuleCollection | ForEach-Object {$_.EnforcementMode = "NotConfigured"}
				$nodesToRemove = $xml.SelectNodes("//FilePublisherRule[not(starts-with(@Name,'${Prefix}:'))] | //FilePathRule[not(starts-with(@Name,'${Prefix}:'))] | //FileHashRule[not(starts-with(@Name,'${Prefix}:'))]")
				$nodesToRemove | ForEach-Object {
					[void]($_.ParentNode.RemoveChild($_))
				}
			}
			"All" {
				Write-Verbose "Exporting ALL rules"
			}
		}
		if(!(Test-Path -Path "$(Split-Path -Path $OutPath)" -PathType Container)){
			New-Item -Path "$(Split-Path -Path $OutPath)" -ItemType Directory -Force | Out-Null
			Write-Verbose -Message "Directory '$(Split-Path -Path $OutPath)' created"
		}
		$xml.Save("$OutPath")
	}
	End
	{
	}
}


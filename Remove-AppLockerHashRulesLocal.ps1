function Remove-AppLockerLocalHashRules
{
<#
.SYNOPSIS
	Remove-AppLockerLocalHashRules
.DESCRIPTION
	Remove locale AppLocker Hash Rules by a prefix.
.PARAMETER Prefix
	Prefix for marking and recognizing the local hash rules
.PARAMETER ClearLocalRules
	Switch to clear all local hash rules
.EXAMPLE
	Remove-AppLockerLocalHashRules -Prefix "SAMPLEFOLDER2" -Verbose
.EXAMPLE
	Remove-AppLockerLocalHashRules -ClearLocalRules -Verbose
.NOTES
	Copyright (C) 2021 Martin Schneeberger
	
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
	
	v1.0
.LINK
	https://github.com/snowmountainer/AppLocker
#>
	[CmdletBinding()]
	Param
	(
		[string]$Prefix,
		[switch]$ClearLocalRules = $false
	)
	Begin
	{
	}
	Process
	{
		# Clear all local rule if true
		$null = Get-AppLockerPolicy -Local -ErrorAction SilentlyContinue

		if($ClearLocalRules){
			$null = Get-AppLockerPolicy -Local -ErrorAction SilentlyContinue
			[Microsoft.Security.ApplicationId.PolicyManagement.PolicyModel.AppLockerPolicy]::FromXml(
@'
<AppLockerPolicy Version="1" />
'@
			) | Set-AppLockerPolicy -ErrorAction Stop
			Write-Verbose -Message 'Successfully cleared local Applocker policy'
		} else {

			# Get local rules
			[xml]$LocalRules = Get-AppLockerPolicy -Local -Xml

			# Filter out prefix
			Write-Verbose "Filter out rules with prefix `"${Prefix}`:`""
			$LocalRules.AppLockerPolicy.RuleCollection | ForEach-Object {$_.EnforcementMode = "NotConfigured"}
					$nodesToRemove = $LocalRules.SelectNodes("//FilePublisherRule[(starts-with(@Name,'${Prefix}:'))] | //FilePathRule[(starts-with(@Name,'${Prefix}:'))] | //FileHashRule[(starts-with(@Name,'${Prefix}:'))]")
			$nodesToRemove | ForEach-Object {
				[void]($_.ParentNode.RemoveChild($_))
			}

			# Save and set
			$LocalRules.Save("$($env:TEMP)\AppLNR.xml")
			Set-AppLockerPolicy -XmlPolicy "$($env:TEMP)\AppLNR.xml"
			Write-Verbose -Message "Local rules without prefix `"${Prefix}`:`" set"
		}
	}
	End
	{
		if(Test-Path "$($env:TEMP)\AppLNR.xml"){Remove-Item -Path "$($env:TEMP)\AppLNR.xml" -Force} # New local without prefix
	}
}


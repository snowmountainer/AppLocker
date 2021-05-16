function Add-AppLockerLocalHashRules
{
<#
.SYNOPSIS
	Add-AppLockerLocalHashRules
.DESCRIPTION
	Add merge to locale AppLocker Hash Rules by file or folder. Mark with a prefix for future management. Optional output to xml file. 
.PARAMETER Path
	Path to file or folder, for wich local hash rules are created
	Mandatory
.PARAMETER Prefix
	Prefix for marking and recognizing the local hash rules
	Mandatory
.PARAMETER OutXML
	Complete path for exporting the XML file
	Optional
.PARAMETER MergeAndSet
	Switch for activating and merging the local hash rules
	Default Value: False
.EXAMPLE
	Add-AppLockerLocalHashRules -Path "C:\TEST\procexp64.exe" -Prefix "SAMPLEFILE" -Verbose
.EXAMPLE
	Add-AppLockerLocalHashRules -Path "\\sccm\sccm$\Fiddler2\Fiddler" -Prefix "SAMPLEFOLDER" -Verbose
.EXAMPLE
	Add-AppLockerLocalHashRules -Path "\\sccm\sccm$\Fiddler2\Fiddler" -Prefix "SAMPLEFOLDER" -OutXML "C:\test\test\YeahhhFOLDER.xml" -Verbose
.EXAMPLE
	Add-AppLockerLocalHashRules -Path "\\sccm\sccm$\Fiddler2\Fiddler" -Prefix "SAMPLEFOLDER" -MergeAndSet -Verbose 
.EXAMPLE
	Add-AppLockerLocalHashRules -Path "C:\test\Fiddler.exe" -Prefix "SAMPLEFILE" -OutXML "C:\test\test\YeahhhFILE.xml" -MergeAndSet -Verbose
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
		[Parameter(Mandatory=$true,
			ValueFromPipelineByPropertyName=$true,
			Position=0)]
		[string]$Path,
		[Parameter(Mandatory=$true)]
		[string]$Prefix,
		[string]$OutXML,
		[switch]$MergeAndSet = $false
	)
	Begin
	{
        #region Functions
        Function Format-XMLIndent
        {
	        [Cmdletbinding()]
	        [Alias("IndentXML")]
	        param
	        (
		        [xml]$Content,
		        [int]$Indent
	        )

	        # String Writer and XML Writer objects to write XML to string
	        $StringWriter = New-Object System.IO.StringWriter 
	        $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 

	        # Default = None, change Formatting to Indented
	        $xmlWriter.Formatting = "indented" 

	        # Gets or sets how many IndentChars to write for each level in 
	        # the hierarchy when Formatting is set to Formatting.Indented
	        $xmlWriter.Indentation = $Indent
    
	        $Content.WriteContentTo($XmlWriter) 
	        $XmlWriter.Flush();$StringWriter.Flush() 
	        $StringWriter.ToString()
        }
        #endregion Functions
	}
	Process
	{
		# Test if Path is file or folder
		if(Test-Path -Path $($Path) -PathType Leaf){
			$NewRules = Get-AppLockerFileInformation -Path $Path
			Write-Verbose -Message "File Information: $($NewRules.Count) Rule"
		} else {
			$NewRules += Get-AppLockerFileInformation -Directory $Path -FileType Dll -Recurse
			$NewRules += Get-AppLockerFileInformation -Directory $Path -FileType Exe -Recurse
			$NewRules += Get-AppLockerFileInformation -Directory $Path -FileType Script -Recurse
			$NewRules += Get-AppLockerFileInformation -Directory $Path -FileType WindowsInstaller -Recurse
			Write-Verbose -Message "Files from Folder Information: $($NewRules.Count) Rules"
		}

		### Get Rules by prefix an export as xml file
		if($OutXML){
			$PrefixRules = ($NewRules | New-AppLockerPolicy -RuleType Hash -RuleNamePrefix $Prefix -Optimize -User S-1-1-0)
			$ProperPrefix = $PrefixRules.ToXml()
			if(!(Test-Path -Path "$(Split-Path -Path $OutXML)" -PathType Container)){
				New-Item -Path "$(Split-Path -Path $OutXML)" -ItemType Directory -Force | Out-Null
				Write-Verbose -Message "Directory '$(Split-Path -Path $OutXML)' created"
			}
			Format-XMLIndent -Content $ProperPrefix -Indent 2  | Out-File -Encoding utf8 -FilePath $OutXML -Force
			Write-Verbose -Message "Rules, exported to:'$($OutXML)'"
		}

		### Merge prefix and set new local rules
		if($MergeAndSet){
			# Get local rules
			$LocalRules = Get-AppLockerPolicy -Local
			$LocalRules.Merge(($NewRules | New-AppLockerPolicy -RuleType Hash -RuleNamePrefix $Prefix -Optimize -User S-1-1-0))
			$ProperNew = $LocalRules.ToXml()
			Format-XMLIndent -Content $ProperNew -Indent 2  | Out-File -Encoding utf8 -FilePath "$($env:TEMP)\AppLNR.xml" -Force
			Set-AppLockerPolicy -XmlPolicy "$($env:TEMP)\AppLNR.xml"
			Write-Verbose -Message "Local rules with new rules prefix '$($Prefix)' merged and set"
		}
	}
	End
	{
		if(Test-Path "$($env:TEMP)\AppLNR.xml"){Remove-Item -Path "$($env:TEMP)\AppLNR.xml" -Force} # New local with prefix
	}
}


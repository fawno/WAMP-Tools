function Get-ClassesRoot {
	param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string] $Path,
		[string] $Name = "",
		[string] $DefaultValue = $null,
		[ValidateSet("None", "DoNotExpandEnvironmentNames")] [string] $Options = "None"
	)

	$SubKey = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($Path, $true)
	if (!$SubKey) {
		return $DefaultValue
	}
	$SubKey.GetValue($Name, $DefaultValue, $Options)
}

function Set-ClassesRoot {
	Param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string] $Path,
		[string] $Name = "",
		[String] $Value = $null,
		[ValidateSet("Binary", "DWord", "ExpandString", "MultiString", "None", "QWord", "String", "Unknown")] [String] $valueKind = "String"
	)

	$SubKey = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($Path, $true)
	if (!$SubKey) {
		$SubKey = [Microsoft.Win32.Registry]::ClassesRoot.CreateSubKey($Path)
	}
	$SubKey.SetValue($Name, $Value, $valueKind)
}

function Remove-ClassesRoot {
	param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string] $Path,
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string] $Name,
		[bool] $throwOnMissingValue = $false
	)

	([Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($Path, $true)).DeleteValue($Name, $throwOnMissingValue)
}

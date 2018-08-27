function Get-Environment {
	param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Name,
		[String] $DefaultValue = $null,
		[ValidateSet("None", "DoNotExpandEnvironmentNames")] [String] $Options = "None"
	)

	([Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment", $true)).GetValue($Name, $DefaultValue, $Options)
}

function Set-Environment {
	Param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Name,
		[String] $Value = $null,
		[ValidateSet("Binary", "DWord", "ExpandString", "MultiString", "None", "QWord", "String", "Unknown")] [String] $valueKind = "String"
	)

	([Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment", $true)).SetValue($Name, $Value, $valueKind)
}

function Remove-Environment {
	param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [String] $Name,
		[bool] $throwOnMissingValue = $false
	)

	([Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment", $true)).DeleteValue($Name, $throwOnMissingValue)
}
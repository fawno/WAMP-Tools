function Show-NetshFirewallRule {
	param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string] $DisplayName
	)

	netsh advfirewall firewall show rule name="$DisplayName" verbose
}

function Remove-NetshFirewallRule {
	param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string] $DisplayName
	)

	[void] (netsh advfirewall firewall del rule name="$DisplayName")
}

function Set-NetshFirewallProgramRule {
	param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string] $DisplayName,
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string] $Program
	)

	[void] (netsh advfirewall firewall set rule name="$DisplayName" new program="$Program")
}

function New-NetshFirewallProgramRule {
	param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string] $DisplayName,
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string] $Program
	)

	[void] (netsh advfirewall firewall add rule name="$DisplayName" dir=in action=allow program="$Program" enable=yes profile=any edge=yes)
}


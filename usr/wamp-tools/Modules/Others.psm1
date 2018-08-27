function Test-ItemPropertyValue {
	param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Path,
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Name
	)

	if (Test-Path $Path) {
		try {
			Get-ItemPropertyValue $Path $Name
		} catch {
			return $null
		}
	} else {
		return $null
	}
}

function Test-VCInstalled {
	param (
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Version,
		[parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Arch
	)

	$Arch = $Arch.ToLower()
	$Version = New-Object -TypeName System.Version($Version)
	$VMajor = $Version.Major
	$VMinor = $Version.Minor

	$VCRegPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\$VMajor.$VMinor\VC\Runtimes\$Arch"
	$VCInstalled = Test-ItemPropertyValue $VCRegPath Installed
	$VCVersion = Test-ItemPropertyValue $VCRegPath Version
	if (($VCInstalled -eq 1) -and $VCVersion) {
		$VCVersion = $VCVersion.replace("v", "")
		$VCVersion = New-Object -TypeName System.Version($VCVersion)
		return ($VCVersion -ge $Version)
	}

	$VCRegPath = "HKLM:\SOFTWARE\Microsoft\VisualStudio\$VMajor.$VMinor\VC\Runtimes\$Arch"
	$VCInstalled = Test-ItemPropertyValue $VCRegPath Installed
	$VCVersion = Test-ItemPropertyValue $VCRegPath Version
	if (($VCInstalled -eq 1) -and $VCVersion) {
		$VCVersion = $VCVersion.replace("v", "")
		$VCVersion = New-Object -TypeName System.Version($VCVersion)
		return ($VCVersion -ge $Version)
	}

	return $false
}

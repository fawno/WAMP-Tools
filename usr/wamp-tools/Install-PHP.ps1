<#
	.SYNOPSIS
	PowerShell script to install PHP

	.PARAMETER Version
	Branch or specific version:
	 -For branch: x.x (example: 7.2)
	 -For specific version: x.x.x (example: 7.2.9)

	Default: last stable release

	.PARAMETER QAVersion
	Version of QA release: alpha, beta, RC, RC1...

	Default: no QA Version

	.PARAMETER Arch
	Architecture: x86 or x64

	Default:
	 -Arch x64

	.PARAMETER ThreadSafe
	Thread safe or not thread safe version.

	Default:
	 -ThreadSafe 1

	.PARAMETER UsrPath
	Path that php-x.x.x path be created.

	Default:
	 -UsrPath ..

	.EXAMPLE
	./Install-PHP.ps1

	Install last stable release of PHP x64 ThreadSafe

	.EXAMPLE
	./Install-PHP.ps1 7.2

	Install last stable release of PHP-7.2 branch x64 ThreadSafe

	.EXAMPLE
	./Install-PHP.ps1 -Arch x86 -ThreadSafe 0

	Install last stable release of PHP x86 NoThreadSafe

	.LINK
	https://github.com/fawno/WAMP-Tools

	.LINK
	https://lab.fawno.com
#>

	Param (
		[string] $Version,
		[string] $QAVersion,
		[string] $Arch = "x64",
		[bool] $ThreadSafe = $True,
		[string] $UsrPath = ".."
	)

	$Arch = $Arch.ToUpper()
	if ($Arch -notin @("X86", "X64")) {
		throw "The arch value must be x86 or x64. Got: $Arch"
	}

	if ($Version) {
		$Version = New-Object -TypeName System.Version($Version)
	}

	if (!(Test-Path -Path $UsrPath)) {
		throw "The usrpath must be a valid path and exist"
	}
	$UsrPath = [string](Get-Item $UsrPath).FullName
	$VarPath = [string](Get-Item "$UsrPath\..").FullName + "\var"

	$VC = @{
		"VC14_X86" = "https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x86.exe"
		"VC14_X64" = "https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe"
		"VC15_X86" = "https://download.microsoft.com/download/6/A/A/6AA4EDFF-645B-48C5-81CC-ED5963AEAD48/vc_redist.x86.exe"
		"VC15_X64" = "https://download.microsoft.com/download/6/A/A/6AA4EDFF-645B-48C5-81CC-ED5963AEAD48/vc_redist.x64.exe"
	}

	Import-Module .\Modules\NativeMethods
	Import-Module .\Modules\Environment
	Import-Module .\Modules\Others
	Import-Module .\Modules\Register-ClassesRoot

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	Add-Type -assembly "System.IO.Compression.FileSystem"

	Write-Output "Checking for downloadable PHP versions..."
	$Releases = @()

	$ReleasesUris = @("https://windows.php.net/downloads/releases/", "https://windows.php.net/downloads/releases/archives/")
	if ($QAVersion) {
		$ReleasesUris += "https://windows.php.net/downloads/qa/"
	}

	foreach ($ReleasesUri in $ReleasesUris) {
		$ReleasesPage = Invoke-WebRequest -Uri $ReleasesUri
		$ReleasesPage.Links | Where-Object { $_.innerText -match "^php-([\d\.]+)([A-Za-z]+\d+)?-(nts-)?.*(VC\d+)-(x\d+).zip" } | ForEach-Object {
			$Release = @{}
			$Release['Version'] = New-Object -TypeName System.Version($Matches[1])
			$Release['QAVersion'] = $Matches[2]
			$Release['ThreadSafe'] = ![bool]$Matches[3]
			$Release['VCVersion'] = ($Matches[4] + '_' + $Matches[5]).ToUpper()
			$Release['Architecture'] = $Matches[5].ToUpper()
			$Release['DownloadUrl'] = [Uri]::new([Uri]$ReleasesUri, $_.href).AbsoluteUri

			$Releases += $Release
		}
	}

	$Release = $false

	$Filtered = $Releases | Where-Object { [string]$_.Version -ge $Version -and [string]$_.QAVersion -ge $QAVersion -and [string]$_.ThreadSafe -eq $ThreadSafe -and $_.Architecture -eq $Arch }
	if ($Version) {
		$Release = $Filtered | Where-Object { [string]$_.Version -match [string]$Version } | Sort-Object -Descending { $_.Version } | Select-Object -First 1
	} else {
		$Release = $Filtered | Sort-Object -Descending { $_.Version } | Select-Object -First 1
	}

	if (!$Release) {
		throw "Unable to find an installable version of $Arch PHP $Version. Check that the version specified is correct."
	}

	$ReleasePath =  "$UsrPath\php-" + $Release.Version + $Release.QAVersion

	$PhpDownloadUri = $Release.DownloadUrl
	$PhpFileName = [Uri]::new([Uri]$PhpDownloadUri).Segments[-1]
	$PhpDownloadFile = "$ReleasePath\$PhpFileName"

	$VcDownloadUri = $VC[$Release.VCVersion]
	$VcFileName = [Uri]::new([Uri]$VcDownloadUri).Segments[-1]
	$VcDownloadFile = "$ReleasePath\$VcFileName"

	if (!(Test-Path -Path $ReleasePath )) {
		New-Item -ItemType Directory -Force -Path $ReleasePath | Out-Null

		Write-Output ("Downloading PHP " + $Release.Version + " ($PhpFileName)...")
		try {
			Start-BitsTransfer -Source $PhpDownloadUri -Destination $PhpDownloadFile
		} catch {
			throw "Unable to download PHP from: $PhpDownloadUri"
		}

		Write-Output ("Downloading " + $release.VCVersion + " redistributable...")
		try {
			Start-BitsTransfer -Source $VcDownloadUri -Destination $VcDownloadFile
		} catch {
			throw "Unable to download PHP from: $VcDownloadUri"
		}
		$VcVersionInfo = Get-ItemPropertyValue -Path $VcDownloadFile -Name VersionInfo

		Write-Output "Checking installed version of VC redistributable..."
		if (!(Test-VCInstalled -Version $VcVersionInfo.FileVersion -Arch $Arch)) {
			Write-Output ("Installing " + $release.VCVersion + " redistributable...")
			&$VcDownloadFile /q /norestart | Out-Null
			if (-not $?) {
				throw ("Unable to install " + $release.VCVersion + " redistributable")
			}
			Start-Sleep -s 2
		}

		Remove-Item $VcDownloadFile -Force -ErrorAction SilentlyContinue | Out-Null

		Write-Output ("Extracting PHP " + $release.Version + " ($PhpFileName) to: $ReleasePath")
		try {
			[IO.Compression.ZipFile]::ExtractToDirectory($PhpDownloadFile, $ReleasePath)
		} catch {
			throw "Unable to extract PHP from ZIP"
		}
		Remove-Item $PhpDownloadFile -Force -ErrorAction SilentlyContinue | Out-Null

		Copy-Item "$ReleasePath\php.ini-development" -Destination "$ReleasePath\php.ini" -ErrorAction Stop
	}

	$ActivePath = "$UsrPath\php"
	$Release = Get-Item $ReleasePath

	if (Test-Path -Path $ActivePath) {
		$Active = Get-Item $ActivePath
		if (!($Active.Target -eq $Release.FullName)) {
			[System.IO.Directory]::Delete($ActivePath, $true)
		}
	}

	if (!(Test-Path -Path $ActivePath)) {
		Write-Output ("Changing the active PHP version to " + $Release.Name)
		$Active = New-Item -Type SymbolicLink -Target $Release.FullName -Path $ActivePath
	}

	$PHPCliFirewallRule = Test-NetFirewallRule -DisplayName PHP-CLI
	if (!($PHPCliFirewallRule)) {
		Write-Output "Creating PHP-CLI firewall rule"
		$PHPCliFirewallRule = New-NetFirewallRule -DisplayName PHP-CLI -Enabled 1 -Profile Any -Direction Inbound -Action Allow -EdgeTraversalPolicy Allow
	}
	$PHPCliFirewallApplication = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $PHPCliFirewallRule
	if ($PHPCliFirewallApplication.Program -ne ($Release.FullName + "\php.exe")) {
		Write-Output ("Setting PHP-CLI firewall rule program " + $Release.FullName + "\php.exe")
		Set-NetFirewallApplicationFilter -InputObject $PHPCliFirewallApplication -Program ($Release.FullName + "\php.exe")
	}

	$PHPWinFirewallRule = Test-NetFirewallRule -DisplayName PHP-WIN
	if (!($PHPWinFirewallRule)) {
		Write-Output "Creating PHP-WIN firewall rule"
		$PHPWinFirewallRule = New-NetFirewallRule -DisplayName PHP-WIN -Enabled 1 -Profile Any -Direction Inbound -Action Allow -EdgeTraversalPolicy Allow
	}
	$PHPWinFirewallApplication = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $PHPWinFirewallRule
	if ($PHPWinFirewallApplication.Program -ne ($Release.FullName + "\php-win.exe")) {
		Write-Output ("Setting PHP-WIN firewall rule program " + $Release.FullName + "\php-win.exe")
		Set-NetFirewallApplicationFilter -InputObject $PHPWinFirewallApplication -Program ($Release.FullName + "\php-win.exe")
	}

	if (!(Test-Path -Path "$UsrPath\bin\composer.phar")) {
		if (!(Test-Path -Path "$UsrPath\bin")) {
			Write-Output ("Creating the \usr\bin directory...")
			New-Item -ItemType Directory -Force -Path "$UsrPath\bin" | Out-Null
		}

		Write-Output ("Downloading composer...")
		try {
			Start-BitsTransfer -Source "https://getcomposer.org/composer.phar" -Destination "$UsrPath\bin\composer.phar"
		} catch {
			throw "Unable to download composer"
		}
	}

	if (!(Test-Path -Path "$UsrPath\pear")) {
		Write-Output ("Creating the PHP_PEAR_SYSCONF_DIR directory...")
		New-Item -ItemType Directory -Force -Path "$UsrPath\pear" | Out-Null
	}

	if (!(Test-Path -Path "$VarPath\log")) {
		New-Item -ItemType Directory -Force -Path "$VarPath\log" | Out-Null
	}

	if (!(Test-Path -Path "$VarPath\tmp")) {
		New-Item -ItemType Directory -Force -Path "$VarPath\tmp" | Out-Null
	}

	if (!(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Templates\template.php")) {
		[System.IO.File]::WriteAllLines("C:\ProgramData\Microsoft\Windows\Templates\template.php", "<?php", (New-Object System.Text.UTF8Encoding $False))
	}

	if (!(Test-Path -Path "$UsrPath\etc\php\php.ini")) {
		if (!(Test-Path -Path "template-php.ini")) {
			throw "The template-php.ini file is missing"
		}

		Write-Output ("Creating the PHP_INI_SCAN_DIR directory...")
		if (!(Test-Path -Path "$UsrPath\etc\php")) {
			New-Item -ItemType Directory -Force -Path "$UsrPath\etc\php" | Out-Null
		}

		Write-Output ("Creating php.ini into PHP_INI_SCAN_DIR directory")
		$IniContent = Get-Content "template-php.ini"
		$IniContent = $IniContent.Replace('${USR_PATH}', $UsrPath)
		$IniContent = $IniContent.Replace('${VAR_PATH}', $VarPath)
		Set-Content -Path "$UsrPath\etc\php\php.ini" -Value $IniContent
	}

	$EnvironmentUpdated = $false

	if ((Get-Environment PHP_INI_SCAN_DIR $null) -ne "$UsrPath\etc\php") {
		Write-Output ("Setting environment variable PHP_INI_SCAN_DIR=$UsrPath\etc\php")
		Set-Environment PHP_INI_SCAN_DIR "$UsrPath\etc\php"
		$EnvironmentUpdated = $true
	} else {
		Write-Output ("OK PHP_INI_SCAN_DIR=" + (Get-Environment PHP_INI_SCAN_DIR))
	}

	if ((Get-Environment PHP_PEAR_SYSCONF_DIR $null) -ne "$UsrPath\pear") {
		Write-Output ("Setting environment variable PHP_PEAR_SYSCONF_DIR=$UsrPath\pear")
		Set-Environment PHP_PEAR_SYSCONF_DIR "$UsrPath\pear"
		$EnvironmentUpdated = $true
	} else {
		Write-Output ("OK PHP_PEAR_SYSCONF_DIR=" + (Get-Environment PHP_PEAR_SYSCONF_DIR))
	}

	if ((Get-Environment MIBDIRS $null) -ne "$UsrPath\share\mibs") {
		Write-Output ("Setting environment variable MIBDIRS=$UsrPath\share\mibs")
		Set-Environment MIBDIRS "$UsrPath\share\mibs"
		$EnvironmentUpdated = $true
	} else {
		Write-Output ("OK MIBDIRS=" + (Get-Environment MIBDIRS))
	}

	$PathAddings = @()
	$PathAddings += "$UsrPath\bin"
	$PathAddings += "$UsrPath\php"
	$PathAddings += "$UsrPath\php\ext"
	$PathAddings += "$UsrPath\pear"

	$OldPath = Get-Environment Path $null DoNotExpandEnvironmentNames
	$NewPath = (";" + $OldPath + ";").Replace(";;", ";")
	foreach ($PathAdding in $PathAddings) {
		if (!($NewPath -match (";" + $PathAdding.Replace("\", "\\") + ";"))) {
			Write-Output "Adding $PathAdding to the Path"
			$NewPath += "$PathAdding;"
		} else {
			Write-Output "OK $PathAdding in the Path"
		}
	}
  $NewPath = ($NewPath -replace "^;") -replace ";$"

	if ($NewPath -ne $OldPath) {
		Set-Environment Path $NewPath ExpandString
		$EnvironmentUpdated = $true
	}

	$PathEXTAddings = @()
	$PathEXTAddings += ".PHP"
	$PathEXTAddings += ".PHAR"
	$PathEXTAddings += ".PHPW"

	$OldPathEXT = Get-Environment PATHEXT $null
	$NewPathEXT = ";" + $OldPathEXT + ";"
	foreach ($PathEXTAdding in $PathEXTAddings) {
		if (!($NewPathEXT -match ";$PathEXTAdding;")) {
			Write-Output "Adding $PathEXTAdding to the PATHEXT"
			$NewPathEXT += "$PathEXTAdding;"
		} else {
			Write-Output "OK $PathEXTAdding in the PATHEXT"
		}
	}
	$NewPathEXT = ($NewPathEXT -replace "^;") -replace ";$"

	if ($NewPathEXT -ne $OldPathEXT) {
		Set-Environment PATHEXT $NewPathEXT
		$EnvironmentUpdated = $true
	}

<########################### Registering PHAR Script ##########################>
	if ((Get-ClassesRoot ".phar") -ne "pharfile") {
		Write-Output "Setting HKCR\.phar: pharfile"
		Set-ClassesRoot ".phar" -Value "pharfile"
		$EnvironmentUpdated = $true
	}
	if ((Get-ClassesRoot "pharfile") -ne "PHAR Script") {
		Write-Output "Setting HKCR\pharfile: PHAR Script"
		Set-ClassesRoot "pharfile" -Value "PHAR Script"
		$EnvironmentUpdated = $true
	}
	if ((Get-ClassesRoot "pharfile\DefaultIcon") -ne "$UsrPath\share\php_xpstyle.ico") {
		Write-Output "Setting HKCR\pharfile\DefaultIcon: $UsrPath\share\php_xpstyle.ico"
		Set-ClassesRoot "pharfile\DefaultIcon" -Value "$UsrPath\share\php_xpstyle.ico"
		$EnvironmentUpdated = $true
	}
	if ((Get-ClassesRoot "pharfile\shell\open\command") -ne "`"$UsrPath\php\php.exe`" `"%1`" %*") {
		Write-Output "Setting HKCR\pharfile\shell\open\command: `"$UsrPath\php\php.exe`" `"%1`" %*"
		Set-ClassesRoot "pharfile\shell\open\command" -Value "`"$UsrPath\php\php.exe`" `"%1`" %*"
		$EnvironmentUpdated = $true
	}

<########################### Registering PHP Script ###########################>
	if ((Get-ClassesRoot ".php") -ne "phpfile") {
		Write-Output "Setting HKCR\.php: phpfile"
		Set-ClassesRoot ".php" -Value "phpfile"
		$EnvironmentUpdated = $true
	}
	if ((Get-ClassesRoot ".php\ShellNew" "FileName") -ne "template.php") {
		Write-Output "Setting HKCR\.php\ShellNew: FileName = template.php"
		Set-ClassesRoot ".php\ShellNew" "FileName" -Value "template.php"
		$EnvironmentUpdated = $true
	}
	if ((Get-ClassesRoot "phpfile") -ne "PHP Script") {
		Write-Output "Setting HKCR\phpfile: PHP Script"
		Set-ClassesRoot "phpfile" -Value "PHP Script"
		$EnvironmentUpdated = $true
	}
	if ((Get-ClassesRoot "phpfile\DefaultIcon") -ne "$UsrPath\share\php_xpstyle.ico") {
		Write-Output "Setting HKCR\phpfile\DefaultIcon: $UsrPath\share\php_xpstyle.ico"
		Set-ClassesRoot "phpfile\DefaultIcon" -Value "$UsrPath\share\php_xpstyle.ico"
		$EnvironmentUpdated = $true
	}
	if ((Get-ClassesRoot "phpfile\shell\open\command") -ne "`"$UsrPath\php\php.exe`" `"%1`" %*") {
		Write-Output "Setting HKCR\phpfile\shell\open\command: `"$UsrPath\php\php.exe`" `"%1`" %*"
		Set-ClassesRoot "phpfile\shell\open\command" -Value "`"$UsrPath\php\php.exe`" `"%1`" %*"
		$EnvironmentUpdated = $true
	}

<########################### Registering PHPW Script ##########################>
	if ((Get-ClassesRoot ".phpw") -ne "phpwfile") {
		Write-Output "Setting HKCR\.phpw: phpwfile"
		Set-ClassesRoot ".phpw" -Value "phpwfile"
		$EnvironmentUpdated = $true
	}
	if ((Get-ClassesRoot ".phpw\ShellNew" "FileName") -ne "template.php") {
		Write-Output "Setting HKCR\.phpw\ShellNew: FileName = template.php"
		Set-ClassesRoot ".phpw\ShellNew" "FileName" -Value "template.php"
		$EnvironmentUpdated = $true
	}
	if ((Get-ClassesRoot "phpwfile") -ne "PHP-Win Script") {
		Write-Output "Setting HKCR\phpwfile: PHP-Win Script"
		Set-ClassesRoot "phpwfile" -Value "PHP-Win Script"
		$EnvironmentUpdated = $true
	}
	if ((Get-ClassesRoot "phpwfile\DefaultIcon") -ne "$UsrPath\share\php_xpstyle.ico") {
		Write-Output "Setting HKCR\phpwfile\DefaultIcon: $UsrPath\share\php_xpstyle.ico"
		Set-ClassesRoot "phpwfile\DefaultIcon" -Value "$UsrPath\share\php_xpstyle.ico"
		$EnvironmentUpdated = $true
	}
	if ((Get-ClassesRoot "phpwfile\shell\open\command") -ne "`"$UsrPath\php\php-win.exe`" `"%1`" %*") {
		Write-Output "Setting HKCR\phpwfile\shell\open\command: `"$UsrPath\php\php-win.exe`" `"%1`" %*"
		Set-ClassesRoot "phpwfile\shell\open\command" -Value "`"$UsrPath\php\php-win.exe`" `"%1`" %*"
		$EnvironmentUpdated = $true
	}

<##################### Send WM_SETTINGCHANGE if necessary #####################>
	if ($EnvironmentUpdated) {
		Send-SettingChange
	}

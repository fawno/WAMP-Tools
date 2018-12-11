<#
	.SYNOPSIS
	PowerShell script to install Apache

	.LINK
	https://github.com/fawno/WAMP-Tools/tree/PowerShell

	.LINK
	https://lab.fawno.com
#>

	Param (
		[ValidateSet("x86", "x64", "X86", "X64")] [string] $Arch = "x64",
		[string] $UsrPath = ".."
	)

	$Arch = $Arch.ToLower()

	if (!(Test-Path -Path $UsrPath)) {
		throw "The UsrPath must be a valid path and exist"
	}

	$UsrPath = (Get-Item $UsrPath).FullName
	$VarPath = $(Get-Item "$UsrPath\..\var").Fullname

	if (!(Test-Path -Path "$VarPath\log\httpd")) {
		New-Item -Path "$VarPath\log\httpd" -Type Directory | Out-Null
	}

	if (!(Test-Path -Path "$VarPath\www\html")) {
		New-Item -Path "$VarPath\www\html" -Type Directory | Out-Null
	}

	if (!(Test-Path -Path "$VarPath\www\html\.htaccess")) {
		Write-Output ("Creating $VarPath\www\html\.htaccess")
		$htaccess = "Allow from localhost`n"
		$htaccess += "Allow from 127.0.0.1`n"
		$htaccess += "Allow from hostname`n"
		$htaccess += "Satisfy Any"
		Set-Content -Path "$VarPath\www\html\.htaccess" -Value $htaccess
	}

	if (!(Test-Path -Path "$VarPath\www\html\index.php")) {
		Write-Output ("Creating $VarPath\www\html\index.php")
		[System.IO.File]::WriteAllLines("$VarPath\www\html\index.php", "<?php phpinof();", (New-Object System.Text.UTF8Encoding $False))
	}

	Import-Module .\Modules\NativeMethods
	Import-Module .\Modules\Environment
	Import-Module .\Modules\Others
	Import-Module .\Modules\NetshFirewall
	Import-Module .\Modules\Register-ClassesRoot

	$ApacheLounge = "https://www.apachelounge.com/download/"

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	Add-Type -assembly "System.IO.Compression.FileSystem"

	Write-Output "Checking for downloadable Apache versions..."

	$Releases = @()

	$DownloadsPage = Invoke-WebRequest $ApacheLounge -UserAgent ""
	$DownloadsPage.Links | Where-Object { $_.innerText -match "^httpd-([\d\.]+)-(win\d+)-(VC\d+).zip$" } | ForEach-Object {
		$Matches[2] = $Matches[2].ToLower().Replace("win32", "x86").Replace("win64", "x64")
		$Releases += @{
			DownloadFile = $Matches[0];
			Version = New-Object -TypeName System.Version($Matches[1]);
			VC = $Matches[3];
			VCVersion = "$($Matches[3])_$($Matches[2])";
			Architecture = $Matches[2];
			DownloadUrl = $_.href;
		}
	}


	$Release = $Releases | Where-Object { $_.Architecture -eq $Arch } | Sort-Object -Descending { $_.Version } | Select-Object -First 1

	if (!$Release) {
		throw "Unable to find an installable version of $Arch Apache $Version. Check that the version specified is correct."
	}

	$ReleasePath =  "$UsrPath\httpd-$($Release.Version)-$($Release.Architecture)-$($Release.VC)"

	$ApacheDownloadUri = $Release.DownloadUrl
	$ApacheFileName = [Uri]::new([Uri]$ApacheDownloadUri).Segments[-1]
	$ApacheDownloadFile = "$ReleasePath\$ApacheFileName"

	if (!(Test-Path -Path "$ReleasePath\bin\httpd.exe" )) {
		if (!(Test-Path -Path "$ReleasePath" )) {
			New-Item -ItemType Directory -Force -Path $ReleasePath | Out-Null
		}

		if (!(Test-Path -Path $ApacheDownloadFile )) {
			Write-Output "Downloading Apache $($Release.Version) ($ApacheFileName)..."
			try {
				Start-BitsTransfer -Source $ApacheDownloadUri -Destination $ApacheDownloadFile
			} catch {
				throw "Unable to download Apache from: $ApacheDownloadUri"
			}
		}

		if ((Test-Path -Path $ApacheDownloadFile )) {
			try {
				Write-Output "Extracting Apache $($Release.Version) ($ApacheFileName) to: $ReleasePath"
				#Expand-Archive -LiteralPath $ApacheDownloadFile -DestinationPath $ReleasePath -ErrorAction Stop
				$ZipFile = [IO.Compression.ZipFile]::OpenRead($ApacheDownloadFile)
				$ZipFile.Entries | Where-Object { $_.FullName -match "^[^/]+/((bin|conf|error|icons|modules)/.*[^/])$" } | ForEach-Object {
					$DestinationFileName = "$ReleasePath\$($Matches[1])".Replace("\conf/", "/conf.original/")

					$DestinationPath = Split-Path -Parent $DestinationFileName
					if (!(Test-Path -LiteralPath $DestinationPath)) {
						New-Item -Path $DestinationPath -Type Directory | Out-Null
					}

					try {
						[IO.Compression.ZipFileExtensions]::ExtractToFile($_, $DestinationFileName, $true)
					} catch {
						throw "Unable to extract Apache from ZIP"
					}
				}
				$ZipFile.Dispose()
			} catch {
				throw "Unable to extract Apache from ZIP"
			}
			Remove-Item $ApacheDownloadFile -Force -ErrorAction SilentlyContinue | Out-Null
		}
	}

	if (!(Test-Path -Path "$ReleasePath\conf")) {
		if (Test-Path -Path "$UsrPath\etc\httpd") {
			Write-Output "Linking $UsrPath\etc\httpd as $ReleasePath\conf"
			New-Item -Type SymbolicLink -Target "$UsrPath\etc\httpd" -Path "$ReleasePath\conf" | Out-Null
		}
	}

	if (!(Test-Path -Path "$ReleasePath\logs")) {
		Write-Output "Linking $VarPath\log\httpd as $ReleasePath\logs"
		New-Item -Type SymbolicLink -Target "$VarPath\log\httpd" -Path "$ReleasePath\logs" | Out-Null
	}

	if (!(Test-Path -Path "$ReleasePath\htdocs")) {
		Write-Output "Linking $VarPath\log\httpd as $ReleasePath\htdocs"
		New-Item -Type SymbolicLink -Target "$VarPath\www\html" -Path "$ReleasePath\htdocs" | Out-Null
	}

	$ActivePath = "$UsrPath\httpd"
	$Release = Get-Item $ReleasePath

	if (Test-Path -Path $ActivePath) {
		$Active = Get-Item $ActivePath
		if (!($Active.Target -eq $Release.FullName)) {
			[System.IO.Directory]::Delete($ActivePath, $true)
		}
	}

	if (!(Test-Path -Path $ActivePath)) {
		Write-Output "Changing the active Apache version to $($Release.Name)"
		$Active = New-Item -Type SymbolicLink -Target $Release.FullName -Path $ActivePath
	}

	if ((Test-Path -Path "$UsrPath\etc\httpd\httpd.conf")) {
		$httpdconf = Get-Content "$UsrPath\etc\httpd\httpd.conf"
		$updated = $false
		if (!($httpdconf -match "^Define USRROOT `"$($UsrPath.Replace('\', '\\'))`"$")) {
			Write-Output "$UsrPath"
			$httpdconf = $httpdconf -replace "^Define USRROOT .*$", "Define USRROOT `"$UsrPath`""
			$updated = $true
		}
		if (!($httpdconf -match "^Define VARROOT `"$($VarPath.Replace('\', '\\'))`"$")) {
			Write-Output "$VarPath"
			$httpdconf = $httpdconf -replace "^Define VARROOT .*$", "Define VARROOT `"$VarPath`""
			$updated = $true
		}
		if ($updated) {
			Set-Content -Path "$UsrPath\etc\httpd\httpd.conf" -Value $httpdconf
		}
	}

	if (Get-Module NetSecurity -List) {
		$ApacheFirewallRule = Test-NetFirewallRule -DisplayName "Apache HTTP Server"
		if (!($ApacheFirewallRule)) {
			Write-Output "Creating Apache HTTP Server firewall rule"
			$ApacheFirewallRule = New-NetFirewallRule -DisplayName "Apache HTTP Server" -Description "Apache HTTP Server" -Enabled 1 -Profile Any -Direction Inbound -Action Allow -EdgeTraversalPolicy Allow
		}
		$ApacheFirewallPort = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $ApacheFirewallRule
		if ($ApacheFirewallPort.Protocol -ne "TCP") {
			Write-Output "Setting Apache HTTP Server firewall rule port TCP 80,443"
			Set-NetFirewallPortFilter -Protocol TCP -LocalPort 80,443 -InputObject $ApacheFirewallPort
		}
	} else {
		$ApacheFirewallRule = Show-NetshFirewallRule "Apache HTTP Server"
		if ($ApacheFirewallRule -match "Apache HTTP Server") {
			if (!($ApacheFirewallRule -match "TCP")) {
				Write-Output "Setting Apache HTTP Server firewall rule port TCP 80,443"
				Set-NetshFirewallPortRule "Apache HTTP Server" "TCP" "80,443"
			}
		} else {
			Write-Output "Creating Apache HTTP Server firewall rule port TCP 80,443"
			New-NetshFirewallPortRule "Apache HTTP Server" "TCP" "80,443"
		}
	}

	if ((Test-Path -Path "$UsrPath\httpd\bin\httpd.exe")) {
		if (!(Get-Service | Where-Object { $_.Name -eq "Apache2.4" })) {
			#&"$UsrPath\httpd\bin\httpd.exe" -k install
			New-Service -Name "Apache2.4" -DisplayName "Apache2.4" -BinaryPathName "`"$UsrPath\httpd\bin\httpd.exe`" -k runservice"
		}
	}

@echo off
setlocal enableextensions enabledelayedexpansion
	cd /d %~dp0

	netsh advfirewall firewall del rule name="PHP-CLI"
	netsh advfirewall firewall del rule name="PHP-WIN"

	pause
endlocal
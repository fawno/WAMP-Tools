@echo off
setlocal enableextensions enabledelayedexpansion
	cd /d %~dp0

	set USR_PATH=%~dp0..
	set PHP_INI_SCAN_DIR=%USR_PATH%\etc\php
	set MIBDIRS=%USR_PATH%\share\mibs

	if not exist "%USR_PATH%\etc\php\php.ini" (
		..\php\php -n php_reset_ini.php
	)

	..\php\php apache_1_create_ca.php
	..\php\php apache_2_create_intermediate.php
	..\php\php apache_3_create_cert.php %1

	pause
endlocal
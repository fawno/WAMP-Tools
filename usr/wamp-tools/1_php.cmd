@echo off
setlocal enableextensions enabledelayedexpansion
	cd /d %~dp0

	set path=%~dp0..\bin;%path%
	set USR_PATH=%~dp0..
	set VAR_PATH=%~dp0..\..\var
	set WGETRC=%USR_PATH%\etc\wgetrc

	set PHP_BRANCH=7.2

	junction -nobanner -accepteula -q > nul

	if not exist "%VAR_PATH%\wamp\." (
		mkdir %VAR_PATH%\wamp
	)

	for /f "usebackq" %%d in (`wget -qO - https://windows.php.net/downloads/releases/ ^| grep -Po "php-%PHP_BRANCH%.\d+-Win32-VC15-x64.zip" ^| grep -Pom 1 "php-[\d\.]+"`) do (

		if not exist "%USR_PATH%\%%d\." (
			if not exist "%VAR_PATH%\wamp\%%d-Win32-VC15-x64.zip" (
				wget -qN --show-progress -P %VAR_PATH%\wamp\ https://windows.php.net/downloads/releases/%%d-Win32-VC15-x64.zip
			)
			unzip %VAR_PATH%\wamp\%%d-Win32-VC15-x64.zip -d %USR_PATH%\%%d
		)

		if exist "%USR_PATH%\%%d\." (
			if not exist "%USR_PATH%\%%d\php.ini" (
				echo copy %USR_PATH%\%%d\php.ini-production %USR_PATH%\%%d\php.ini
				copy %USR_PATH%\%%d\php.ini-production %USR_PATH%\%%d\php.ini
			)

			if exist "%USR_PATH%\php\." (
				for /f "usebackq" %%i in (`junction -nobanner %USR_PATH%\php ^| grep -Pom 1 "php-[\d\.]+"`) do (
					if not "%%d"=="%%i" (
						junction -nobanner -d %USR_PATH%\php
					)
				)
			)

			if not exist "%USR_PATH%\php\." (
				junction -nobanner %USR_PATH%\php %USR_PATH%\%%d
			)
		)
	)

	if not exist "%USR_PATH%\etc\php\php.ini" (
		..\php\php -n php_reset_ini.php
	)

	pause
endlocal
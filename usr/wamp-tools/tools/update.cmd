@echo off
setlocal enableextensions enabledelayedexpansion
	if exist c:\usr\%1\php.exe (
		php -v
		echo.

		if exist c:\usr\ImageMagick\. (
			if exist c:\usr\%2\convert.exe (
				junction -d c:\usr\ImageMagick
				junction c:\usr\ImageMagick c:\usr\%2
			)
		)

		sc query | grep "NOMBRE_SERVICIO" | grep -Po "Apache.*|agen2sql|agen2web|InkSaver_inputSpooler|Ria_inputSpooler|php-fcgi|Archivo_inputSpooler|W3SVC|CakeFotosSpool|CakePresstSpool|CakeSuscripcionesSpool|ImpoMaq_inputSpooler" > update.services

		for /f "usebackq" %%s in (update.services) do (
			net stop "%%s"
		)
		echo.

		junction -d c:\usr\php
		junction c:\usr\php "c:\usr\%1"
		echo.

		for /f "usebackq" %%s in (update.services) do (
			net start "%%s"
		)
		echo.

		for /f "delims=" %%r in ('netsh advfirewall firewall show rule name^=all ^| grep -Po "PHP-CLI"') do (
			netsh advfirewall firewall set rule name="PHP-CLI" new program=c:\usr\%1\php.exe
		)

		for /f "delims=" %%r in ('netsh advfirewall firewall show rule name^=all ^| grep -Po "PHP-WIN"') do (
			netsh advfirewall firewall set rule name="PHP-WIN" new program=c:\usr\%1\php-win.exe
		)

		php -v
	) else (
		dir /b c:\usr\php-*
	)
	pause
endlocal
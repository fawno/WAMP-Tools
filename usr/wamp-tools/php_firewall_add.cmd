@echo off
setlocal enableextensions enabledelayedexpansion
	cd /d %~dp0

	if exist "..\php\." (
		for /f "usebackq" %%p in (`junction -nobanner ..\php ^| grep -Pom 1 "[a-z]\:\\.*php-[\d\.]+"`) do (
			for /f "delims=" %%r in ('netsh advfirewall firewall show rule name^="PHP-CLI" ^| grep -Po "PHP-CLI"') do (
				echo Actualizando regla "PHP-CLI"...
				netsh advfirewall firewall set rule name="PHP-CLI" new program=%%p\php.exe
			)

			for /f "delims=" %%r in ('netsh advfirewall firewall show rule name^=PHP-CLI ^| grep -Po "Ninguna regla coincide con los criterios especificados."') do (
				echo Creando regla "PHP-CLI"...
				netsh advfirewall firewall add rule name="PHP-CLI" dir=in action=allow program=%%p\php.exe enable=yes profile=any edge=yes
			)

			for /f "delims=" %%r in ('netsh advfirewall firewall show rule name^="PHP-WIN" ^| grep -Po "PHP-WIN"') do (
				echo Actualizando regla "PHP-WIN"...
				netsh advfirewall firewall set rule name="PHP-WIN" new program=%%p\php-win.exe
			)

			for /f "delims=" %%r in ('netsh advfirewall firewall show rule name^=PHP-WIN ^| grep -Po "Ninguna regla coincide con los criterios especificados."') do (
				echo Creando regla "PHP-WIN"...
				netsh advfirewall firewall add rule name="PHP-WIN" dir=in action=allow program=%%p\php-win.exe enable=yes profile=any edge=yes
			)
		)
	)

	pause
endlocal
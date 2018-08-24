@echo off
setlocal enableextensions enabledelayedexpansion
	cd /d %~dp0

	set path=%~dp0..\bin;%path%
	set USR_PATH=%~dp0..
	set VAR_PATH=%~dp0..\..\var
	set WGETRC=%USR_PATH%\etc\wgetrc

	junction -nobanner -accepteula -q > nul

	if not exist "%VAR_PATH%\wamp\." (
		mkdir %VAR_PATH%\wamp
	)

	if not exist "%VAR_PATH%\mysql\tmp\." (
		mkdir %VAR_PATH%\mysql\tmp
	)

	rem https://dev.mysql.com/downloads/mysql/
	rem https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.12-winx64.zip
	rem https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.23-win32.zip
	for /f "usebackq" %%d in (`wget -qO - https://dev.mysql.com/downloads/mysql/ ^| grep -Poim 1 "mysql-[\d\.]+"`) do (
		if not exist "%USR_PATH%\%%d\bin\." (
      if not exist "%VAR_PATH%\wamp\%%d-winx64.zip" (
				for /f "usebackq" %%v in (`echo. %%d ^| grep -Po "\d+\.\d+"`) do (
					wget -qN --show-progress -P %VAR_PATH%\wamp https://dev.mysql.com/get/Downloads/MySQL-%%v/%%d-winx64.zip
				)
			)

			if exist "%VAR_PATH%\wamp\%%d-winx64.zip" (
				unzip %VAR_PATH%\wamp\%%d-winx64.zip -x "%%d-winx64\bin\mysqld.pdb" -d %USR_PATH%
				move %USR_PATH%\%%d-* %USR_PATH%\%%d
			)

			if exist "%USR_PATH%\mysql\bin\my.ini" (
				copy %USR_PATH%\mysql\bin\my.ini %USR_PATH%\%%d\bin\my.ini
			)
		)

		if exist "%USR_PATH%\%%d\bin\." (
			if exist "%USR_PATH%\mysql\." (
				for /f "usebackq" %%i in (`junction -nobanner %USR_PATH%\mysql ^| grep -Pom 1 "mysql-[\d\.]+"`) do (
					if not "%%d"=="%%i" (
						junction -nobanner -d %USR_PATH%\mysql
					)
				)
			)

			if not exist "%USR_PATH%\mysql\." (
				junction -nobanner %USR_PATH%\mysql %USR_PATH%\%%d
			)
		)

		if not exist "%USR_PATH%\mysql\bin\my.ini" (
			..\php\php -n mysql_reset_ini.php
		)
	)

	if not exist "%VAR_PATH%\mysql\data\." (
		%USR_PATH%\mysql\bin\mysqld --defaults-file=%USR_PATH%\mysql\bin\my.ini --initialize-insecure
	)

	if exist "..\mysql\." (
		for /f "usebackq" %%p in (`junction -nobanner ..\mysql ^| grep -Piom 1 "[a-z]\:\\.*mysql-[\d\.]+"`) do (
			if exist "%%p\bin\mysqld.exe" (
				for /f "delims=" %%r in ('netsh advfirewall firewall show rule name^="MySQL Server" verbose ^| grep -Piom 1 "[a-z]\:\\.*mysql-[\d\.]+"') do (
					set fwrule=1
					if not "%%p"=="%%r" (
						echo Actualizando regla "MySQL Server"...
						netsh advfirewall firewall set rule name="MySQL Server" new program=%%p\bin\mysqld.exe
					)
				)

				if "!fwrule!"=="" (
					echo Creando regla "MySQL Server"...
					netsh advfirewall firewall add rule name="MySQL Server" dir=in action=allow program=%%p\bin\mysqld.exe enable=yes profile=any edge=yes
				)

				for %%b in (..\mysql\bin\mysqld.exe) do (
					for /f "delims=" %%r in ('sc qc MySQL ^| grep -Po "ERROR 1060"') do (
						echo Registrando servicio "MySQL"...
						%%~fb --install MySQL --defaults-file=%%~dpbmy.ini
					)
				)
			)
		)
	)

	pause
endlocal
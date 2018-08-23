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

	if not exist "%USR_PATH%\etc\httpd\." (
		if exist "httpd-conf.zip" (
			unzip httpd-conf.zip -d %USR_PATH%\
		)
	)

	if not exist "%VAR_PATH%\log\httpd\." (
		mkdir %VAR_PATH%\log\httpd
	)

	if not exist "%VAR_PATH%\www\html\." (
		mkdir %VAR_PATH%\www\html;
	)

	if not exist "%VAR_PATH%\www\html\.htaccess" (
		echo Allow from localhost> %VAR_PATH%\www\html\.htaccess
		echo Allow from atom>> %VAR_PATH%\www\html\.htaccess
		echo Satisfy Any>> %VAR_PATH%\www\html\.htaccess
	)

	if not exist "%VAR_PATH%\www\html\index.php" (
		echo ^<?php phpinfo^(^)^;> %VAR_PATH%\www\html\index.php
	)


	for /f "usebackq" %%d in (`wget -q -O - -U "" https://www.apachelounge.com/download/ ^| grep -Po "httpd-[\d\.]+-win64-VC15.zip" ^| grep -Pom 1 "httpd-[\d\.]+"`) do (
		if not exist "%USR_PATH%\%%d\bin\." (
      if not exist "%VAR_PATH%\wamp\%%d-win64-VC15.zip" (
				wget -q -O - -U "" https://www.apachelounge.com/download/ | grep -Po "\x22[^\x22]+%%d-win64-VC15.zip\x22"|grep -Po "[^\x22]*"|wget -qN --show-progress -U "" -P %VAR_PATH%\wamp -i -
      )

      if exist "%VAR_PATH%\wamp\%%d-win64-VC15.zip" (
				mkdir %USR_PATH%\%%d
				mkdir %USR_PATH%\%%d\conf.original
				junction -nobanner %USR_PATH%\%%d\Apache24 %USR_PATH%\%%d
				junction -nobanner %USR_PATH%\%%d\conf %USR_PATH%\%%d\conf.original
				unzip %VAR_PATH%\wamp\%%d-win64-VC15.zip Apache24\bin\* Apache24\conf\* Apache24\error\* Apache24\icons\* Apache24\modules\* -d %USR_PATH%\%%d\
				junction -nobanner -d %USR_PATH%\%%d\Apache24
				junction -nobanner -d %USR_PATH%\%%d\conf

				if not exist "%USR_PATH%\etc\httpd\." (
					xcopy /e %USR_PATH%\%%d\conf.original %USR_PATH%\etc\httpd\
				)

				junction -nobanner %USR_PATH%\%%d\conf %USR_PATH%\etc\httpd
				junction -nobanner %USR_PATH%\%%d\logs %VAR_PATH%\log\httpd
				junction -nobanner %USR_PATH%\%%d\htdocs %VAR_PATH%\www\html
			)
		)

		if exist "%USR_PATH%\%%d\bin\." (
			if exist "%USR_PATH%\httpd\." (
				for /f "usebackq" %%i in (`junction -nobanner %USR_PATH%\httpd ^| grep -Pom 1 "httpd-[\d\.]+"`) do (
					if not "%%d"=="%%i" (
						junction -nobanner -d %USR_PATH%\httpd
					)
				)
			)

			if not exist "%USR_PATH%\httpd\." (
				junction -nobanner %USR_PATH%\httpd %USR_PATH%\%%d
			)
		)
	)

	if exist "%USR_PATH%\xampp-control\." (
		if not exist "%USR_PATH%\xampp-control\apache" (
			if exist "%USR_PATH%\httpd\." (
				junction -nobanner %USR_PATH%\xampp-control\apache %USR_PATH%\httpd
			)
		)
	)

:end
endlocal
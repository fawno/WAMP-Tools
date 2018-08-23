@echo off
setlocal enableextensions enabledelayedexpansion
	cd /d %~dp0

	..\php\php -n %~n0.php

	pause
endlocal
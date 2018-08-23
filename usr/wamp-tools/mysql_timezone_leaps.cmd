@echo off
setlocal enableextensions enabledelayedexpansion
	cd /d %~dp0

	..\mysql\bin\mysql --user=root mysql < timezone_2018e_leaps.sql

	pause
endlocal
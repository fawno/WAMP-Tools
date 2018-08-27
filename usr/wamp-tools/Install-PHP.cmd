@echo off
setlocal enableextensions enabledelayedexpansion
	cd /d %~dp0

	for %%p in (%*) do (
		if "%%p"=="-h" goto _help_
		if "%%p"=="-help" goto _help_
		if "%%p"=="--help" goto _help_
		if "%%p"=="help" goto _help_
		if "%%p"=="/?" goto _help_
		if "%%p"=="/h" goto _help_
	)

	PowerShell -ExecutionPolicy RemoteSigned .\Install-PHP.ps1 %*
goto _end_

:_help_
	for %%p in (%*) do (
		if "%%p"=="-examples" (
			PowerShell -ExecutionPolicy RemoteSigned Get-Help .\Install-PHP.ps1 -examples
			goto _end_
		)

		if "%%p"=="-detailed" (
			PowerShell -ExecutionPolicy RemoteSigned Get-Help .\Install-PHP.ps1 -detailed
			goto _end_
		)

		if "%%p"=="-full" (
			PowerShell -ExecutionPolicy RemoteSigned Get-Help .\Install-PHP.ps1 -full
			goto _end_
		)

		if "%%p"=="-online" (
			PowerShell -ExecutionPolicy RemoteSigned Get-Help .\Install-PHP.ps1 -online
			goto _end_
		)
	)
	PowerShell -ExecutionPolicy RemoteSigned Get-Help .\Install-PHP.ps1

:_end_
	pause
endlocal
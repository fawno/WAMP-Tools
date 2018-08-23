<?php
	$usr_path = dirname(__DIR__);

	$ini_scan = dirname(__DIR__) . '\\etc\\php';
	if (!is_dir($ini_scan)) {
		mkdir($ini_scan, 0777, true);
	}

	$pear_sys = dirname(__DIR__) . '\\pear';
	if (!is_dir($pear_sys)) {
		mkdir($pear_sys, 0777, true);
	}

	$var_path = dirname(dirname(__DIR__)) . '\\var';
	if (!is_dir($var_path . '\\log')) {
		mkdir($var_path . '\\log', 0777, true);
	}

	if (!is_dir($var_path . '\\tmp')) {
		mkdir($var_path . '\\tmp', 0777, true);
	}

	$ini = file_get_contents('template-php.ini');
	$replaces['${VAR_PATH}'] = $var_path;
	$replaces['${USR_PATH}'] = $usr_path;
	$ini = str_replace(array_keys($replaces), array_values($replaces), $ini);
	file_put_contents($ini_scan . '\\php.ini', $ini);

	echo 'Añade al path de windows las siguientes rutas:', PHP_EOL;
	echo $usr_path . '\\bin', PHP_EOL;
	echo $usr_path . '\\php', PHP_EOL;
	echo $usr_path . '\\php\ext', PHP_EOL;
	echo PHP_EOL;
	echo 'Añade las siguientes variables de entorno:', PHP_EOL;
	echo 'PHP_INI_SCAN_DIR=', $ini_scan, PHP_EOL;
	echo 'PHP_PEAR_SYSCONF_DIR=', $pear_sys, PHP_EOL;
	echo 'set MIBDIRS=', $user_path . '\\share\\mibs', PHP_EOL;


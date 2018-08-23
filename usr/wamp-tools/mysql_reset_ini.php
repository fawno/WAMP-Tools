<?php
	$usr_path = dirname(__DIR__);
	$var_path = dirname(dirname(__DIR__)) . '\\var';
	if (!is_dir($var_path . '\\mysql\\tmp')) {
		mkdir($var_path . '\\mysql\\tmp', 0777, true);
	}


	$ini = file_get_contents('template-my.ini');
	$replaces['${VAR_PATH}'] = $var_path;
	$replaces['${USR_PATH}'] = $usr_path;
	$ini = str_replace(array_keys($replaces), array_values($replaces), $ini);
	file_put_contents($usr_path . '\\mysql\\bin\my.ini', str_replace('\\', '/', $ini));

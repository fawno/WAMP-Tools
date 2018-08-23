<?php
	$usr_path = dirname(__DIR__);
	$var_path = dirname(dirname(__DIR__)) . '\\var';

	$httpd_conf = $usr_path . '/httpd/conf/httpd.conf';
	$conf = file_get_contents($httpd_conf);

	$replaces['~Define USRROOT .*~'] = 'Define USRROOT "' . $usr_path . '"';
	$replaces['~Define VARROOT .*~'] = 'Define VARROOT "' . $var_path . '"';
	$conf = preg_replace(array_keys($replaces), array_values($replaces), $conf);
	file_put_contents($httpd_conf, $conf);
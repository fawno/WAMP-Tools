<?php
	$usr_path = dirname(__DIR__);
	$var_path = dirname(dirname(__DIR__)) . '\\var';

	$organizationName = 'Localhost';
	$commonName = 'hostname';
	$subjectAltName = [$commonName, 'localhost', '*.hostdomain'];

	$openssl_ca = $var_path . '\\wamp\\openssl.' . strtolower($organizationName) . '.ca.cnf';
	$openssl_int = $var_path . '\\wamp\\openssl.' . strtolower($organizationName) . '.intermediate.cnf';
	$openssl_cert = $var_path . '\\wamp\\openssl.' . strtolower($organizationName) . '.host.' . $commonName . '.cnf';

	$SSLCACertificateFile = $usr_path . '/etc/httpd/ssl.crt/ca.' . strtolower($organizationName) . '.crt';
	$SSLCertificateChainFile = $usr_path . '/etc/httpd/server-ca.crt';
	$SSLCertificateFile = $usr_path . '/etc/httpd/server.crt';
	$SSLCertificateKeyFile = $usr_path . '/etc/httpd/server.key';

	$dn_ca = [
		'countryName' => 'ES',
		//'stateOrProvinceName' => '',
		//'localityName' => '',
		'organizationName' => $organizationName,
		'organizationalUnitName' => $organizationName . ' Certificate Authority',
		'commonName' => $organizationName . ' Root CA',
		//'emailAddress' => '',
	];

	$dn_intermediate = [
		'countryName' => 'ES',
		//'stateOrProvinceName' => '',
		//'localityName' => '',
		'organizationName' => $organizationName,
		'organizationalUnitName' => $organizationName . ' Certificate Authority',
		'commonName' => $organizationName . ' Intermediate CA',
		//'emailAddress' => '',
	];

	$dn_host = [
		'countryName' => 'ES',
		//'stateOrProvinceName' => '',
		//'localityName' => '',
		'organizationName' => $organizationName,
		'organizationalUnitName' => $organizationName . ' Web Services',
		'commonName' => $commonName,
		//'emailAddress' => '',
	];

	if (!is_dir(dirname($openssl_ca))) {
		mkdir(dirname($openssl_ca), 0777, true);
	}

	if (!is_dir(dirname($openssl_int))) {
		mkdir(dirname($openssl_int), 0777, true);
	}

	if (!is_dir(dirname($openssl_cert))) {
		mkdir(dirname($openssl_cert), 0777, true);
	}

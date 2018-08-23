<?php
	require 'openssl_conf.php';

	$opt['u'] = 'update';
	$options = getopt(implode('', array_keys($opt)), $opt);
	$update = (bool) (isset($options['u']) or isset($options['update']));

	$cert_template = file_get_contents('template.cert.cnf');

	$subjectAltName = 'DNS:' . implode(',DNS:', $subjectAltName);
	file_put_contents($openssl_cert, str_replace('$subjectAltName', $subjectAltName, $cert_template));

	$config_ca = parse_ini_file($openssl_ca, true, INI_SCANNER_TYPED);
	$config_int = parse_ini_file($openssl_int, true, INI_SCANNER_TYPED);

	$www_private_key = $config_int['CA_default']['private'] . '/' . $commonName . '.key.pem';
	$www_certificate = $config_int['CA_default']['certs'] . '/' . $commonName . '.cert.pem';

	$config = [
	 'digest_alg' => 'aes256',
	 'private_key_bits' => 2048,
	 'private_key_type' => OPENSSL_KEYTYPE_RSA,
	 'config' => $openssl_int,
	];

	if (!is_file($config_int['CA_default']['serial'])) {
		$serial_int = 0x1000;
	} else {
		$serial_int = file_get_contents($config_int['CA_default']['serial']);
		$serial_int = hexdec($serial_int);
	}

	if ($update) {
		if (is_file($www_private_key)) {
			unlink($www_private_key);
		}

		if (is_file($www_certificate)) {
			unlink($www_certificate);
		}
	}


	if (is_file($www_private_key)) {
		$privkey = openssl_pkey_get_private(file_get_contents($www_private_key));
	} else {
		$privkey = openssl_pkey_new($config);
		openssl_pkey_export_to_file($privkey, $www_private_key);
	}

	if (!is_file($www_certificate)) {
		$csr_args['digest_alg'] = 'sha256';
		$csr_args['config'] = $openssl_int;
		$csr = openssl_csr_new($dn_host, $privkey, $csr_args);

		$cacert = 'file://' . $config_int['CA_default']['certificate'];
		$cakey = 'file://' . $config_int['CA_default']['private_key'];
		$csr_args['config'] = $openssl_cert;
		$csr_args['x509_extensions'] = 'server_cert';
		$x509 = openssl_csr_sign($csr, $cacert, $cakey, $days = 7300, $csr_args, $serial_int++);
		openssl_x509_export_to_file($x509, $www_certificate);
		file_put_contents($config_int['CA_default']['serial'], dechex($serial_int));
	} else {
		$x509 = openssl_x509_read(file_get_contents($www_certificate));
	}

	if (is_file($www_certificate)) {
		if (!is_dir(dirname($SSLCertificateFile))) {
			mkdir(dirname($SSLCertificateFile), 0777, true);
		}
		copy($www_certificate, $SSLCertificateFile);
	}

	if (is_file($www_private_key)) {
		if (!is_dir(dirname($SSLCertificateKeyFile))) {
			mkdir(dirname($SSLCertificateKeyFile), 0777, true);
		}
		copy($www_private_key, $SSLCertificateKeyFile);
	}

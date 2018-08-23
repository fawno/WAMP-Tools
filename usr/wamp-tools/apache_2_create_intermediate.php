<?php
	require 'openssl_conf.php';

	$opt['u'] = 'update';
	$options = getopt(implode('', array_keys($opt)), $opt);
	$update = (bool) (isset($options['u']) or isset($options['update']));

	$config_ca = parse_ini_file($openssl_ca, true, INI_SCANNER_TYPED);
	$config_int = parse_ini_file($openssl_int, true, INI_SCANNER_TYPED);

	$paths = ['dir', 'certs', 'crl_dir', 'new_certs_dir', 'private'];
	foreach ($paths as $path) {
		if (!is_dir($config_int['CA_default'][$path])) {
			mkdir($config_int['CA_default'][$path], 0777, true);
		}
	}

	if (!is_file($config_int['CA_default']['database'])) {
		touch($config_int['CA_default']['database']);
	}

	if (!is_file($config_ca['CA_default']['serial'])) {
		$serial_ca = 0x1000;
	} else {
		$serial_ca = file_get_contents($config_ca['CA_default']['serial']);
		$serial_ca = hexdec($serial_ca);
	}

	if ($update) {
		if (is_file($config_int['CA_default']['private_key'])) {
			unlink($config_int['CA_default']['private_key']);
		}

		if (is_file($config_int['CA_default']['certificate'])) {
			unlink($config_int['CA_default']['certificate']);
		}

		if (is_file($config_int['CA_default']['certs'] . '/ca-chain.cert.pem')) {
			unlink($config_int['CA_default']['certs'] . '/ca-chain.cert.pem');
		}
	}


	$config = [
	 'digest_alg' => 'aes256',
	 'private_key_bits' => 4096,
	 'private_key_type' => OPENSSL_KEYTYPE_RSA,
	 'config' => $openssl_int,
	];

	if (is_file($config_int['CA_default']['private_key'])) {
		$privkey = openssl_pkey_get_private(file_get_contents($config_int['CA_default']['private_key']));
	} else {
		$privkey = openssl_pkey_new($config);
		openssl_pkey_export_to_file($privkey, $config_int['CA_default']['private_key']);
	}

	if (!is_file($config_int['CA_default']['certificate'])) {
		$csr = openssl_csr_new($dn_intermediate, $privkey, ['digest_alg' => 'sha256', 'config' => $openssl_int]);
		$cacert = 'file://' . $config_ca['CA_default']['certificate'];
		$cakey = 'file://' . $config_ca['CA_default']['private_key'];
		$x509 = openssl_csr_sign($csr, $cacert, $cakey, $days = 7300, ['digest_alg' => 'sha256', 'x509_extensions' => 'v3_intermediate_ca', 'config' => $openssl_ca], $serial_ca++);
		openssl_x509_export_to_file($x509, $config_int['CA_default']['certificate']);
		file_put_contents($config_ca['CA_default']['serial'], dechex($serial_ca));
	} else {
		$x509 = openssl_x509_read(file_get_contents($config_int['CA_default']['certificate']));
	}

	if (!is_file($config_int['CA_default']['certs'] . '/ca-chain.cert.pem')) {
		$ca_chain = null;
		$ca_chain .= file_get_contents($config_int['CA_default']['certificate']);
		$ca_chain .= file_get_contents($config_ca['CA_default']['certificate']);
		file_put_contents($config_int['CA_default']['certs'] . '/ca-chain.cert.pem', $ca_chain);
	}

	if (is_file($config_int['CA_default']['certs'] . '/ca-chain.cert.pem')) {
		if (!is_dir(dirname($SSLCertificateChainFile))) {
			mkdir(dirname($SSLCertificateChainFile), 0777, true);
		}
		copy($config_int['CA_default']['certs'] . '/ca-chain.cert.pem', $SSLCertificateChainFile);
	}

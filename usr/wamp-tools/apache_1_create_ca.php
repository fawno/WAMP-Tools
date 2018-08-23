<?php
	require 'openssl_conf.php';

	$openssl_template = file_get_contents('template.openssl.cnf');

	$dir = $usr_path . '/root/ca.' . strtolower($organizationName);
	file_put_contents($openssl_ca, str_replace(['$dir', '$type', '$policy'], [$dir, 'ca', 'policy_strict'], $openssl_template));

	$dir = $usr_path . '/root/ca.' . strtolower($organizationName) . '/intermediate';
	file_put_contents($openssl_int, str_replace(['$dir', '$type', '$policy'], [$dir, 'intermediate', 'policy_loose'], $openssl_template));

	$config_ca = parse_ini_file($openssl_ca, true, INI_SCANNER_TYPED);

	$paths = ['dir', 'certs', 'crl_dir', 'new_certs_dir', 'private'];
	foreach ($paths as $path) {
		if (!is_dir($config_ca['CA_default'][$path])) {
			mkdir($config_ca['CA_default'][$path], 0777, true);
		}
	}

	if (!is_file($config_ca['CA_default']['database'])) {
		touch($config_ca['CA_default']['database']);
	}

	if (!is_file($config_ca['CA_default']['serial'])) {
		file_put_contents($config_ca['CA_default']['serial'], '1000');
	} else {
		$serial_ca = file_get_contents($config_ca['CA_default']['serial']);
	}

	$config = [
	 'digest_alg' => 'aes256',
	 'private_key_bits' => 4096,
	 'private_key_type' => OPENSSL_KEYTYPE_RSA,
	 'config' => $openssl_ca,
	];

	if (is_file($config_ca['CA_default']['private_key'])) {
		$privkey = openssl_pkey_get_private(file_get_contents($config_ca['CA_default']['private_key']));
	} else {
		$privkey = openssl_pkey_new($config);
		openssl_pkey_export_to_file($privkey, $config_ca['CA_default']['private_key']);
	}

	if (!is_file($config_ca['CA_default']['certificate'])) {
		$csr = openssl_csr_new($dn_ca, $privkey, ['digest_alg' => 'sha256', 'x509_extensions' => 'v3_ca', 'config' => $openssl_ca]);
		$x509 = openssl_csr_sign($csr, null, $privkey, $days = 7300, ['digest_alg' => 'sha256', 'config' => $openssl_ca]);
		openssl_x509_export_to_file($x509, $config_ca['CA_default']['certificate']);
	} else {
		$x509 = openssl_x509_read(file_get_contents($config_ca['CA_default']['certificate']));
	}

	if (is_file($config_ca['CA_default']['certificate'])) {
		if (!is_dir(dirname($SSLCACertificateFile))) {
			mkdir(dirname($SSLCACertificateFile), 0777, true);
		}
		copy($config_ca['CA_default']['certificate'], $SSLCACertificateFile);
	}

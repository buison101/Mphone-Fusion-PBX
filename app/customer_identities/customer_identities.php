<?php

	require_once dirname(__DIR__, 2) . '/resources/require.php';
	require_once 'resources/check_auth.php';

	if (!permission_exists('customer_identity_view')) {
		echo 'access denied';
		exit;
	}

	//Provisioning is intentionally surfaced on the FusionPBX Users list.
	//Email and Extension assignments remain sourced from FusionPBX.
	header('Location: ' . PROJECT_PATH . '/core/users/users.php');
	exit;

?>

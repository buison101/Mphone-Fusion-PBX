<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/identity_session.php';

	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');
	header('X-Content-Type-Options: nosniff');

	if (!portal_identity_validate_session(true) || !portal_identity_is_active()) {
		http_response_code(401);
		echo json_encode(['error' => 'unauthorized']);
		exit;
	}
	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
		http_response_code(405);
		echo json_encode(['error' => 'method_not_allowed']);
		exit;
	}

	$result = portal_identity_api_request('GET', 'billing', null,
		(string) ($_SESSION['portal_identity']['access_token'] ?? ''));
	if ($result['status'] !== 200) {
		http_response_code($result['status'] === 403 ? 403 : 503);
		echo json_encode(['error' => $result['status'] === 403 ? 'forbidden' : 'service_unavailable']);
		exit;
	}

	$billing_config = is_readable('/etc/mphone/billing.env')
		? (parse_ini_file('/etc/mphone/billing.env', false, INI_SCANNER_RAW) ?: []) : [];
	$bank = [
		'name' => 'Techcombank',
		'account' => (string) ($billing_config['MPHONE_BILLING_BANK_ACCOUNT'] ?? '662888'),
		'account_name' => (string) ($billing_config['MPHONE_BILLING_BANK_NAME'] ?? 'MPHONE'),
	];
	echo json_encode(array_merge($result['payload'], ['bank' => $bank]));

<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/identity_session.php';
	require_once dirname(__DIR__, 2) . '/customer_identities/resources/customer_platform.php';

	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');
	header('X-Content-Type-Options: nosniff');

	if (!portal_identity_validate_session(true) || empty($_SESSION['authorized'])) {
		http_response_code(401);
		echo json_encode(['error' => 'unauthorized']);
		exit;
	}
	if (portal_identity_is_active() || !if_group('superadmin')) {
		http_response_code(403);
		echo json_encode(['error' => 'forbidden']);
		exit;
	}

	$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
	$input = $method === 'POST' ? json_decode(file_get_contents('php://input'), true) : $_GET;
	$input = is_array($input) ? $input : [];
	if ($method === 'POST') {
		$provided_csrf = trim((string) ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ''));
		$expected_csrf = (string) ($_SESSION['portal']['csrf'] ?? '');
		if ($provided_csrf === '' || $expected_csrf === '' || !hash_equals($expected_csrf, $provided_csrf)) {
			http_response_code(403);
			echo json_encode(['error' => 'invalid_csrf']);
			exit;
		}
	}
	elseif ($method !== 'GET') {
		http_response_code(405);
		echo json_encode(['error' => 'method_not_allowed']);
		exit;
	}

	$action = trim((string) ($input['action'] ?? 'list'));
	$action_map = [
		'list' => 'customer_manage_list',
		'detail' => 'customer_manage_detail',
		'create' => 'customer_manage_create',
		'update' => 'customer_manage_update',
		'status' => 'customer_manage_status',
		'sync_retry' => 'customer_manage_sync_retry',
	];
	if (!isset($action_map[$action])) {
		http_response_code(400);
		echo json_encode(['error' => 'invalid_request']);
		exit;
	}
	$result = customer_platform_request(array_merge($input, [
		'action' => $action_map[$action],
		'actor_superadmin' => true,
	]));
	http_response_code(in_array($result['status'], [200, 400, 401, 403, 404, 409], true) ? $result['status'] : 503);
	echo json_encode($result['payload'], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

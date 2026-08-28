<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/identity_session.php';
	require_once dirname(__DIR__, 2) . '/customer_identities/resources/customer_platform.php';

	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');
	header('X-Content-Type-Options: nosniff');

	if (!portal_identity_validate_session(true) || !portal_identity_has_workspace()) {
		http_response_code(401);
		echo json_encode(['error' => 'unauthorized']);
		exit;
	}
	$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
	if (!in_array($method, ['GET', 'POST'], true)) {
		http_response_code(405);
		echo json_encode(['error' => 'method_not_allowed']);
		exit;
	}
	if ($method === 'POST') {
		$provided_csrf = trim((string) ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ''));
		$expected_csrf = (string) ($_SESSION['portal']['csrf'] ?? '');
		if ($provided_csrf === '' || $expected_csrf === '' || !hash_equals($expected_csrf, $provided_csrf)) {
			http_response_code(403);
			echo json_encode(['error' => 'invalid_csrf']);
			exit;
		}
	}

	$input = $method === 'POST' ? json_decode(file_get_contents('php://input'), true) : $_GET;
	$input = is_array($input) ? $input : [];
	$resource = trim((string) ($input['resource'] ?? 'profile'));
	$action_map = [
		'profile' => 'portal_customer_profile',
		'profile_update' => 'portal_customer_profile_update',
		'profile_change_submit' => 'portal_customer_profile_change_submit',
		'profile_change_cancel' => 'portal_customer_profile_change_cancel',
		'security' => 'portal_customer_security',
		'subscription' => 'portal_subscription_view',
		'subscription_change_submit' => 'portal_subscription_change_submit',
	];
	if (!isset($action_map[$resource])) {
		http_response_code(400);
		echo json_encode(['error' => 'invalid_request']);
		exit;
	}

	$payload = array_merge($input, [
		'action' => $action_map[$resource],
		'customer_uuid' => (string) $_SESSION['portal_identity']['customer_uuid'],
		'actor_identity_uuid' => (string) $_SESSION['portal_identity']['identity_uuid'],
		'actor_session_uuid' => (string) ($_SESSION['portal_identity']['session_id'] ?? ''),
		'request_fingerprint' => hash('sha256', (string) ($_SERVER['REMOTE_ADDR'] ?? '') . '|' .
			(string) ($_SERVER['HTTP_USER_AGENT'] ?? '')),
	]);
	$result = customer_platform_request($payload);
	http_response_code(in_array($result['status'], [200, 400, 401, 403, 404, 409], true) ? $result['status'] : 503);
	echo json_encode($result['payload'], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

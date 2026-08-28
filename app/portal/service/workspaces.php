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

	$access_token = (string) ($_SESSION['portal_identity']['access_token'] ?? '');
	$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
	if ($method === 'GET') {
		$result = portal_identity_api_request('GET', 'memberships', null, $access_token);
		if ($result['status'] !== 200) {
			http_response_code($result['status'] === 403 ? 403 : 503);
			echo json_encode(['error' => $result['payload']['error'] ?? 'service_unavailable']);
			exit;
		}
		echo json_encode([
			'identity' => $result['payload']['identity'] ?? [],
			'memberships' => $result['payload']['memberships'] ?? [],
			'active_customer_uuid' => $_SESSION['portal_identity']['customer_uuid'] ?? null,
		], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
		exit;
	}

	if ($method !== 'POST') {
		http_response_code(405);
		echo json_encode(['error' => 'method_not_allowed']);
		exit;
	}
	$provided_csrf = trim((string) ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ''));
	$expected_csrf = (string) ($_SESSION['portal']['csrf'] ?? '');
	if ($provided_csrf === '' || $expected_csrf === '' || !hash_equals($expected_csrf, $provided_csrf)) {
		http_response_code(403);
		echo json_encode(['error' => 'invalid_csrf']);
		exit;
	}
	$input = json_decode(file_get_contents('php://input'), true);
	$customer_uuid = trim((string) (($input['customer_uuid'] ?? '')));
	if (!is_uuid($customer_uuid)) {
		http_response_code(400);
		echo json_encode(['error' => 'invalid_request']);
		exit;
	}
	$result = portal_identity_api_request('POST', 'switch-workspace', ['customer_uuid' => $customer_uuid], $access_token);
	if ($result['status'] !== 200) {
		http_response_code(in_array($result['status'], [400, 401, 403, 404], true) ? $result['status'] : 503);
		echo json_encode(['error' => $result['payload']['error'] ?? 'service_unavailable']);
		exit;
	}
	$_SESSION['portal_identity']['access_token'] = $result['payload']['access_token'];
	$_SESSION['portal_identity']['expires_at'] = time() + (int) ($result['payload']['expires_in'] ?? 900);
	$_SESSION['portal_identity']['customer_uuid'] = $result['payload']['customer']['customer_uuid'];
	$_SESSION['portal_identity']['membership_uuid'] = $result['payload']['membership']['membership_uuid'];
	$_SESSION['portal_identity']['customer'] = $result['payload']['customer'];
	$_SESSION['portal_identity']['membership'] = $result['payload']['membership'];
	$_SESSION['portal_identity']['validated_at'] = 0;
	if (!portal_identity_validate_session(true)) {
		http_response_code(401);
		echo json_encode(['error' => 'invalid_session']);
		exit;
	}
	echo json_encode(['switched' => true, 'customer' => $_SESSION['portal_identity']['customer'],
		'membership' => $_SESSION['portal_identity']['membership']], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

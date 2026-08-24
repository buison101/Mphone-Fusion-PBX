<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/identity_session.php';

	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');
	header('X-Content-Type-Options: nosniff');
	header('Referrer-Policy: no-referrer');

	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
		http_response_code(405);
		echo json_encode(['error' => 'method_not_allowed']);
		exit;
	}

	$input = json_decode(file_get_contents('php://input'), true);
	$input = is_array($input) ? $input : [];
	$action = trim((string) ($input['action'] ?? ''));
	$public_actions = [
		'request_recovery' => 'request-recovery',
		'confirm_recovery' => 'confirm-recovery',
		'request_verification' => 'request-verification',
		'confirm_verification' => 'confirm-verification',
		'confirm_email_change' => 'confirm-email-change',
	];
	$authenticated_actions = [
		'change_password' => 'change-password',
		'request_email_change' => 'request-email-change',
	];

	$is_authenticated_action = isset($authenticated_actions[$action]);
	if (!isset($public_actions[$action]) && !$is_authenticated_action) {
		http_response_code(400);
		echo json_encode(['error' => 'invalid_request']);
		exit;
	}

	if ($is_authenticated_action) {
		if (!portal_identity_validate_session(true) || !portal_identity_is_active()) {
			http_response_code(401);
			echo json_encode(['error' => 'unauthorized']);
			exit;
		}
		$expected_csrf = (string) ($_SESSION['portal']['csrf'] ?? '');
	} else {
		$expected_csrf = portal_identity_login_csrf();
	}
	$provided_csrf = trim((string) ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ''));
	if ($provided_csrf === '' || $expected_csrf === '' || !hash_equals($expected_csrf, $provided_csrf)) {
		http_response_code(403);
		echo json_encode(['error' => 'invalid_csrf']);
		exit;
	}

	$body = [];
	foreach (['email', 'token', 'password', 'current_password', 'new_password', 'new_email'] as $field) {
		if (isset($input[$field]) && is_string($input[$field])) {
			$body[$field] = $input[$field];
		}
	}
	$endpoint = $is_authenticated_action ? $authenticated_actions[$action] : $public_actions[$action];
	$access_token = $is_authenticated_action
		? (string) ($_SESSION['portal_identity']['access_token'] ?? '')
		: '';
	$result = portal_identity_api_request('POST', $endpoint, $body, $access_token, 'mphone-identity-email');
	$status = (int) ($result['status'] ?? 0);
	if ($status < 200 || $status >= 300) {
		$allowed = [400, 401, 403, 409, 429];
		http_response_code(in_array($status, $allowed, true) ? $status : 503);
		echo json_encode(['error' => $result['payload']['error'] ?? 'service_unavailable']);
		exit;
	}

	http_response_code($status);
	echo json_encode($result['payload']);

?>

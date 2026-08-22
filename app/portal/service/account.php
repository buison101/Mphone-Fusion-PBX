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
		$requests = [
			'me' => portal_identity_api_request('GET', 'me', null, $access_token),
			'extensions' => portal_identity_api_request('GET', 'extensions', null, $access_token),
			'devices' => portal_identity_api_request('GET', 'devices', null, $access_token),
		];
		foreach ($requests as $result) {
			if ($result['status'] !== 200) {
				http_response_code($result['status'] === 403 ? 403 : 503);
				echo json_encode(['error' => $result['status'] === 403 ? 'forbidden' : 'service_unavailable']);
				exit;
			}
		}
		$extensions = array_map(static function ($extension) {
			return [
				'extension_uuid' => $extension['extension_uuid'] ?? '',
				'extension' => $extension['extension'] ?? '',
				'display_name' => $extension['display_name'] ?? '',
				'can_use' => !empty($extension['can_use']),
				'can_manage' => !empty($extension['can_manage']),
			];
		}, $requests['extensions']['payload']['extensions'] ?? []);
		echo json_encode([
			'identity' => $requests['me']['payload']['identity'] ?? [],
			'customer' => $_SESSION['portal_identity']['customer'] ?? [],
			'membership' => $_SESSION['portal_identity']['membership'] ?? [],
			'extensions' => $extensions,
			'devices' => $requests['devices']['payload']['devices'] ?? [],
		]);
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
	$input = is_array($input) ? $input : [];
	$action = trim((string) ($input['action'] ?? ''));
	if ($action === 'revoke_device') {
		$session_id = trim((string) ($input['session_id'] ?? ''));
		if (!is_uuid($session_id)) {
			http_response_code(400);
			echo json_encode(['error' => 'invalid_request']);
			exit;
		}
		$result = portal_identity_api_request('POST', 'revoke-device', ['session_id' => $session_id], $access_token);
		if ($result['status'] !== 200) {
			http_response_code(in_array($result['status'], [403, 404], true) ? $result['status'] : 503);
			echo json_encode(['error' => $result['payload']['error'] ?? 'service_unavailable']);
			exit;
		}
		if (!empty($result['payload']['current'])) {
			portal_identity_clear_local_session();
			session_regenerate_id(true);
		}
		echo json_encode(['revoked' => true, 'current' => !empty($result['payload']['current'])]);
		exit;
	}

	if (in_array($action, ['logout_others', 'logout_all'], true)) {
		$result = portal_identity_api_request('POST', 'logout-all', [], $access_token);
		if ($result['status'] !== 200) {
			http_response_code(in_array($result['status'], [401, 403, 429], true) ? $result['status'] : 503);
			echo json_encode(['error' => $result['payload']['error'] ?? 'service_unavailable']);
			exit;
		}
		echo json_encode(['revoked' => true]);
		exit;
	}

	http_response_code(400);
	echo json_encode(['error' => 'invalid_request']);

?>

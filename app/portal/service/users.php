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

	$identity_actor = portal_identity_is_active();
	$membership_role = (string) ($_SESSION['portal_identity']['membership']['role'] ?? '');
	$fusion_manager = !$identity_actor && (if_group('superadmin') || if_group('admin'));
	if (($identity_actor && !in_array($membership_role, ['owner', 'customer_admin'], true)) || (!$identity_actor && !$fusion_manager)) {
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

	$customer_uuid = $identity_actor
		? (string) ($_SESSION['portal_identity']['customer_uuid'] ?? '')
		: trim((string) ($input['customer_uuid'] ?? ''));
	$action = $method === 'GET' ? trim((string) ($input['action'] ?? 'list')) : trim((string) ($input['action'] ?? ''));
	if ($action === 'customers' && $fusion_manager) {
		$payload = [
			'action' => 'portal_customers_list',
			'actor_superadmin' => if_group('superadmin'),
			'actor_admin' => if_group('admin'),
		];
	}
	elseif ($action === 'list' && $fusion_manager && !is_uuid($customer_uuid)) {
		$payload = [
			'action' => 'portal_users_all',
			'actor_superadmin' => if_group('superadmin'),
			'actor_admin' => if_group('admin'),
		];
	}
	elseif (in_array($action, ['merge_preview', 'merge_execute'], true) && !$identity_actor && if_group('superadmin')) {
		$payload = array_merge($input, [
			'action' => $action === 'merge_preview' ? 'customer_merge_preview' : 'customer_merge_execute',
			'actor_superadmin' => true,
		]);
	}
	else {
		if (!is_uuid($customer_uuid)) {
			http_response_code(400);
			echo json_encode(['error' => 'customer_required']);
			exit;
		}
		$action_map = [
			'list' => 'portal_users_list',
			'invite' => 'portal_user_invite',
			'update' => 'portal_user_update',
			'resend' => 'portal_user_resend',
		];
		if (!isset($action_map[$action])) {
			http_response_code(400);
			echo json_encode(['error' => 'invalid_request']);
			exit;
		}
		$payload = array_merge($input, ['action' => $action_map[$action], 'customer_uuid' => $customer_uuid]);
		if ($identity_actor) {
			$payload['actor_identity_uuid'] = $_SESSION['portal_identity']['identity_uuid'];
		}
		else {
			$payload['actor_superadmin'] = if_group('superadmin');
			$payload['actor_admin'] = if_group('admin');
		}
	}

	$result = customer_platform_request($payload);
	http_response_code(in_array($result['status'], [200, 400, 401, 403, 404, 409], true) ? $result['status'] : 503);
	echo json_encode($result['payload'], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/identity_session.php';

	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');
	header('X-Content-Type-Options: nosniff');
	header('Referrer-Policy: no-referrer');

	$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
	if ($method === 'GET') {
		echo json_encode([
			'authenticated' => portal_identity_validate_session(),
			'login_csrf' => portal_identity_login_csrf(),
		]);
		exit;
	}
	if ($method !== 'POST') {
		http_response_code(405);
		echo json_encode(['error' => 'method_not_allowed']);
		exit;
	}

	$provided_csrf = trim((string) ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ''));
	$expected_csrf = portal_identity_is_active()
		? (string) ($_SESSION['portal']['csrf'] ?? '')
		: portal_identity_login_csrf();
	if ($provided_csrf === '' || $expected_csrf === '' || !hash_equals($expected_csrf, $provided_csrf)) {
		http_response_code(403);
		echo json_encode(['error' => 'invalid_csrf']);
		exit;
	}

	$input = json_decode(file_get_contents('php://input'), true);
	$input = is_array($input) ? $input : [];
	$action = trim((string) ($input['action'] ?? ''));

	if ($action === 'logout') {
		if (portal_identity_is_active()) {
			portal_identity_api_request(
				'POST',
				'logout',
				[],
				(string) ($_SESSION['portal_identity']['access_token'] ?? '')
			);
		}
		portal_identity_clear_local_session();
		session_regenerate_id(true);
		$_SESSION['portal_login_csrf'] = bin2hex(random_bytes(32));
		echo json_encode(['logged_out' => true, 'login_csrf' => $_SESSION['portal_login_csrf']]);
		exit;
	}

	if ($action !== 'login' && $action !== 'google_complete') {
		http_response_code(400);
		echo json_encode(['error' => 'invalid_request']);
		exit;
	}

	$email = '';
	$request = [];
	if ($action === 'login') {
		$email = strtolower(trim((string) ($input['email'] ?? '')));
		$password = (string) ($input['password'] ?? '');
		if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($password) < 1 || strlen($password) > 1024) {
			http_response_code(400);
			echo json_encode(['error' => 'invalid_request']);
			exit;
		}
		$request = ['login_mode' => 'account', 'login' => $email, 'password' => $password];
	}
	else {
		$id_token = (string) ($_SESSION['mphone_google_id_token'] ?? '');
		$id_token_expires_at = (int) ($_SESSION['mphone_google_id_token_expires_at'] ?? 0);
		unset($_SESSION['mphone_google_id_token'], $_SESSION['mphone_google_id_token_expires_at']);
		if ($id_token === '' || $id_token_expires_at < time()) {
			http_response_code(400);
			echo json_encode(['error' => 'invalid_google_token']);
			exit;
		}
		$request = ['login_mode' => 'google', 'id_token' => $id_token];
	}

	$installation_id = portal_identity_installation_id();
	$result = portal_identity_api_request('POST', 'login', array_merge($request, [
		'tenant' => 'shared',
		'installation_id' => $installation_id,
		'device' => portal_identity_device_metadata(),
	]));
	$payload = $result['payload'];
	if ($result['status'] !== 200 || ($payload['subject_kind'] ?? '') !== 'customer_identity') {
		http_response_code(in_array($result['status'], [429, 503], true) ? $result['status'] : 401);
		$google_errors = ['google_not_linked', 'invalid_google_token', 'google_disabled'];
		$error = $action === 'google_complete' && in_array($payload['error'] ?? '', $google_errors, true)
			? $payload['error'] : (in_array($result['status'], [429, 503], true)
				? ($payload['error'] ?? 'service_unavailable') : 'invalid_credentials');
		echo json_encode(['error' => $error]);
		exit;
	}

	$user_uuid = trim((string) ($payload['user']['user_uuid'] ?? ''));
	$domain_uuid = trim((string) ($payload['domain_uuid'] ?? ''));
	if (!is_uuid($user_uuid) || !is_uuid($domain_uuid)
		|| !is_uuid($payload['identity_uuid'] ?? '')
		|| (!empty($payload['customer_uuid']) && !is_uuid($payload['customer_uuid']))
		|| (!empty($payload['membership_uuid']) && !is_uuid($payload['membership_uuid']))) {
		http_response_code(503);
		echo json_encode(['error' => 'invalid_identity_mapping']);
		exit;
	}

	$sql = "select u.username, u.user_email, u.contact_uuid, d.domain_name ";
	$sql .= "from v_users u join v_domains d on d.domain_uuid = u.domain_uuid ";
	$sql .= "where u.user_uuid = :user_uuid and u.domain_uuid = :domain_uuid ";
	$sql .= "and u.user_enabled = 'true' and d.domain_enabled = 'true' limit 1";
	$row = $database->select($sql, ['user_uuid' => $user_uuid, 'domain_uuid' => $domain_uuid], 'row');
	if (!is_array($row) || empty($row['username']) || empty($row['domain_name'])) {
		http_response_code(503);
		echo json_encode(['error' => 'invalid_identity_mapping']);
		exit;
	}

	$_SESSION = [];
	session_regenerate_id(true);
	$user_settings = new settings(['database' => $database, 'domain_uuid' => $domain_uuid, 'user_uuid' => $user_uuid]);
	authentication::create_user_session([
		'domain_uuid' => $domain_uuid,
		'domain_name' => $row['domain_name'],
		'user_uuid' => $user_uuid,
		'username' => $row['username'],
		'contact_uuid' => $row['contact_uuid'] ?? null,
	], $user_settings);
	$_SESSION['authorized'] = true;
	portal_identity_set_extensions($payload['extensions'] ?? []);
	portal_identity_strip_domain_permissions();
	$_SESSION['portal_identity'] = [
		'identity_uuid' => $payload['identity_uuid'],
		'customer_uuid' => $payload['customer_uuid'] ?? null,
		'membership_uuid' => $payload['membership_uuid'] ?? null,
		'session_id' => $payload['session_id'],
		'installation_id' => $installation_id,
		'access_token' => $payload['access_token'],
		'refresh_token' => $payload['refresh_token'],
		'expires_at' => time() + (int) ($payload['expires_in'] ?? 900),
		'validated_at' => time(),
		'primary_email' => (string) ($payload['identity']['primary_email'] ?? $email),
		'customer' => $payload['customer'] ?? [],
		'membership' => $payload['membership'] ?? [],
	];
	$_SESSION['portal']['csrf'] = bin2hex(random_bytes(32));

	if (!permission_exists('portal_view')) {
		portal_identity_api_request('POST', 'logout', [], (string) $payload['access_token']);
		portal_identity_clear_local_session();
		http_response_code(403);
		echo json_encode(['error' => 'forbidden']);
		exit;
	}

	echo json_encode(['authenticated' => true]);

?>

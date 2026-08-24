<?php

	function portal_identity_api_url(): string {
		$value = getenv('MPHONE_PORTAL_AUTH_URL');
		return rtrim(!empty($value) ? $value : 'http://127.0.0.1:8000', '/');
	}

	function portal_identity_api_request(string $method, string $action, ?array $body = null, string $access_token = '', string $service = 'mphone-auth-v2'): array {
		if (!preg_match('/^[a-z0-9-]+$/', $service)) {
			return ['status' => 0, 'payload' => [], 'error' => 'invalid_service'];
		}
		$url = portal_identity_api_url() . '/functions/v1/' . $service . '/' . ltrim($action, '/');
		$headers = ['Accept: application/json', 'Content-Type: application/json'];
		if ($access_token !== '') {
			$headers[] = 'Authorization: Bearer ' . $access_token;
		}
		$handle = curl_init($url);
		curl_setopt_array($handle, [
			CURLOPT_CUSTOMREQUEST => strtoupper($method),
			CURLOPT_HTTPHEADER => $headers,
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_CONNECTTIMEOUT => 3,
			CURLOPT_TIMEOUT => 8,
		]);
		if ($body !== null) {
			curl_setopt($handle, CURLOPT_POSTFIELDS, json_encode($body, JSON_UNESCAPED_SLASHES));
		}
		$response_body = curl_exec($handle);
		$status = (int) curl_getinfo($handle, CURLINFO_RESPONSE_CODE);
		$error = curl_error($handle);
		curl_close($handle);
		$payload = is_string($response_body) ? json_decode($response_body, true) : null;
		return [
			'status' => $status,
			'payload' => is_array($payload) ? $payload : [],
			'error' => $error,
		];
	}

	function portal_identity_is_active(): bool {
		return !empty($_SESSION['portal_identity']['identity_uuid'])
			&& !empty($_SESSION['portal_identity']['customer_uuid'])
			&& !empty($_SESSION['portal_identity']['session_id']);
	}

	function portal_identity_login_csrf(): string {
		if (empty($_SESSION['portal_login_csrf'])) {
			$_SESSION['portal_login_csrf'] = bin2hex(random_bytes(32));
		}
		return $_SESSION['portal_login_csrf'];
	}

	function portal_identity_installation_id(): string {
		$cookie_name = 'mphone_portal_device';
		$value = trim((string) ($_COOKIE[$cookie_name] ?? ''));
		if (!preg_match('/^portal-[a-f0-9]{48}$/', $value)) {
			$value = 'portal-' . bin2hex(random_bytes(24));
			setcookie($cookie_name, $value, [
				'expires' => time() + 31536000,
				'path' => '/',
				'secure' => true,
				'httponly' => true,
				'samesite' => 'Lax',
			]);
			$_COOKIE[$cookie_name] = $value;
		}
		return $value;
	}

	function portal_identity_device_metadata(): array {
		$user_agent = strtolower((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''));
		$platform = str_contains($user_agent, 'windows') ? 'Windows'
			: (str_contains($user_agent, 'android') ? 'Android'
			: (str_contains($user_agent, 'iphone') || str_contains($user_agent, 'ipad') ? 'iOS'
			: (str_contains($user_agent, 'mac os') ? 'macOS'
			: (str_contains($user_agent, 'linux') ? 'Linux' : ''))));
		$browser = str_contains($user_agent, 'edg/') ? 'Microsoft Edge'
			: (str_contains($user_agent, 'firefox/') ? 'Firefox'
			: (str_contains($user_agent, 'chrome/') ? 'Chrome'
			: (str_contains($user_agent, 'safari/') ? 'Safari' : 'Web browser')));
		return [
			'client_type' => 'web',
			'device_name' => $platform !== '' ? $browser . ' · ' . $platform : $browser,
			'platform' => $platform,
			'app_version' => 'portal',
		];
	}

	function portal_identity_strip_domain_permissions(): void {
		$blocked = [
			'call_active_all',
			'call_active_domain',
			'xml_cdr_domain',
			'contact_domain_view',
		];
		if (!if_group('superadmin')) {
			$blocked[] = 'portal_call_tag_edit';
		}
		foreach ($blocked as $permission) {
			unset($_SESSION['permissions'][$permission]);
			unset($_SESSION['user']['permissions'][$permission]);
		}
		unset($permission);
	}

	function portal_identity_set_extensions(array $extensions): void {
		$_SESSION['user']['extension'] = [];
		foreach ($extensions as $row) {
			$extension_uuid = trim((string) ($row['extension_uuid'] ?? ''));
			$extension = trim((string) ($row['extension'] ?? ''));
			if (!is_uuid($extension_uuid) || $extension === '') {
				continue;
			}
			$_SESSION['user']['extension'][] = [
				'user' => $extension,
				'number_alias' => '',
				'destination' => $extension,
				'extension_uuid' => $extension_uuid,
				'outbound_caller_id_name' => '',
				'outbound_caller_id_number' => '',
				'user_context' => $_SESSION['domain_name'] ?? '',
				'description' => trim((string) ($row['display_name'] ?? '')),
			];
		}
	}

	function portal_identity_clear_local_session(): void {
		$websocket_token_name = $_SESSION['portal']['ws_token_name'] ?? '';
		if ($websocket_token_name !== '' && class_exists('subscriber')) {
			$websocket_token_file = subscriber::get_token_file($websocket_token_name);
			if (is_file($websocket_token_file)) {
				unlink($websocket_token_file);
			}
		}
		unset(
			$_SESSION['portal_identity'],
			$_SESSION['portal'],
			$_SESSION['authorized'],
			$_SESSION['username'],
			$_SESSION['user_uuid'],
			$_SESSION['user'],
			$_SESSION['permissions'],
			$_SESSION['groups'],
			$_SESSION['authentication']
		);
		$_SESSION['authorized'] = false;
	}

	function portal_identity_refresh_session(): bool {
		$identity = $_SESSION['portal_identity'] ?? [];
		if (empty($identity['refresh_token']) || empty($identity['installation_id'])) {
			return false;
		}
		$result = portal_identity_api_request('POST', 'refresh', [
			'refresh_token' => $identity['refresh_token'],
			'installation_id' => $identity['installation_id'],
		]);
		if ($result['status'] !== 200 || empty($result['payload']['access_token']) || empty($result['payload']['refresh_token'])) {
			return false;
		}
		$_SESSION['portal_identity']['access_token'] = $result['payload']['access_token'];
		$_SESSION['portal_identity']['refresh_token'] = $result['payload']['refresh_token'];
		$_SESSION['portal_identity']['expires_at'] = time() + (int) ($result['payload']['expires_in'] ?? 900);
		return true;
	}

	function portal_identity_validate_session(bool $force = false): bool {
		if (!portal_identity_is_active()) {
			return !empty($_SESSION['authorized']) && !empty($_SESSION['user_uuid']);
		}
		if ((int) ($_SESSION['portal_identity']['expires_at'] ?? 0) <= time() + 60) {
			if (!portal_identity_refresh_session()) {
				portal_identity_clear_local_session();
				return false;
			}
		}
		$last_validated = (int) ($_SESSION['portal_identity']['validated_at'] ?? 0);
		if (!$force && time() - $last_validated < 60) {
			return true;
		}
		$access_token = (string) ($_SESSION['portal_identity']['access_token'] ?? '');
		$session_result = portal_identity_api_request('GET', 'session', null, $access_token);
		$principal = $session_result['payload']['principal'] ?? [];
		if ($session_result['status'] !== 200
			|| ($principal['subjectKind'] ?? '') !== 'customer_identity'
			|| ($principal['identityUuid'] ?? '') !== ($_SESSION['portal_identity']['identity_uuid'] ?? '')
			|| ($principal['customerUuid'] ?? '') !== ($_SESSION['portal_identity']['customer_uuid'] ?? '')) {
			portal_identity_clear_local_session();
			return false;
		}
		$extensions_result = portal_identity_api_request('GET', 'extensions', null, $access_token);
		if ($extensions_result['status'] !== 200 || !isset($extensions_result['payload']['extensions'])) {
			portal_identity_clear_local_session();
			return false;
		}
		portal_identity_set_extensions($extensions_result['payload']['extensions']);
		portal_identity_strip_domain_permissions();
		$_SESSION['portal_identity']['validated_at'] = time();
		return true;
	}

	function portal_identity_has_domain_scope(): bool {
		return !portal_identity_is_active() && permission_exists('xml_cdr_domain');
	}

?>

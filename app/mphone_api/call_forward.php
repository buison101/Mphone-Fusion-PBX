<?php
/*
	FusionPBX
	Copyright (C) 2026

	Internal API used by the Mphone Supabase gateway.
*/

	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');

	require_once dirname(__DIR__, 2) . '/resources/require.php';

	function api_response(int $status, array $payload): void {
		http_response_code($status);
		echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
		exit;
	}

	function request_header(string $name): string {
		$key = 'HTTP_' . strtoupper(str_replace('-', '_', $name));
		return trim($_SERVER[$key] ?? '');
	}

	function boolean_value(mixed $value): ?bool {
		if (is_bool($value)) {
			return $value;
		}
		if ($value === 1 || $value === '1' || $value === 'true') {
			return true;
		}
		if ($value === 0 || $value === '0' || $value === 'false') {
			return false;
		}
		return null;
	}

	function base64url_decode(string $value): string|false {
		$padding = strlen($value) % 4;
		if ($padding > 0) {
			$value .= str_repeat('=', 4 - $padding);
		}
		return base64_decode(strtr($value, '-_', '+/'), true);
	}

	function supabase_jwt_secret(): string {
		$secret = getenv('SUPABASE_JWT_SECRET') ?: '';
		if ($secret !== '') {
			return $secret;
		}
		$environment_file = '/opt/supabase/supabase-project/.env';
		if (!is_readable($environment_file)) {
			return '';
		}
		$content = file_get_contents($environment_file);
		if ($content !== false && preg_match('/^JWT_SECRET=(.+)$/m', $content, $matches)) {
			return trim($matches[1], " \t\n\r\0\x0B\"'");
		}
		return '';
	}

	function session_user_uuid(string $token): string {
		$parts = explode('.', $token);
		if (count($parts) !== 3) {
			return '';
		}
		[$encoded_header, $encoded_payload, $encoded_signature] = $parts;
		$header_json = base64url_decode($encoded_header);
		$payload_json = base64url_decode($encoded_payload);
		$signature = base64url_decode($encoded_signature);
		$secret = supabase_jwt_secret();
		if ($header_json === false || $payload_json === false || $signature === false || $secret === '') {
			return '';
		}
		$header = json_decode($header_json, true);
		$payload = json_decode($payload_json, true);
		if (!is_array($header) || !is_array($payload) || ($header['alg'] ?? '') !== 'HS256') {
			return '';
		}
		$expected_signature = hash_hmac('sha256', $encoded_header . '.' . $encoded_payload, $secret, true);
		if (!hash_equals($expected_signature, $signature)) {
			return '';
		}
		if (($payload['iss'] ?? '') !== 'mphone-fusionpbx' || ($payload['aud'] ?? '') !== 'authenticated') {
			return '';
		}
		if (!isset($payload['exp']) || (int) $payload['exp'] < time()) {
			return '';
		}
		$user_uuid = trim((string) ($payload['user_uuid'] ?? ''));
		return is_uuid($user_uuid) ? $user_uuid : '';
	}

	function forward_payload(array $row): array {
		return [
			'extension_uuid' => $row['extension_uuid'],
			'extension' => $row['extension'],
			'domain' => $row['domain_name'],
			'forward_all' => [
				'enabled' => filter_var($row['forward_all_enabled'], FILTER_VALIDATE_BOOLEAN),
				'destination' => $row['forward_all_destination'] ?? '',
			],
			'forward_busy' => [
				'enabled' => filter_var($row['forward_busy_enabled'], FILTER_VALIDATE_BOOLEAN),
				'destination' => $row['forward_busy_destination'] ?? '',
			],
			'forward_no_answer' => [
				'enabled' => filter_var($row['forward_no_answer_enabled'], FILTER_VALIDATE_BOOLEAN),
				'destination' => $row['forward_no_answer_destination'] ?? '',
			],
			'forward_not_registered' => [
				'enabled' => filter_var($row['forward_user_not_registered_enabled'], FILTER_VALIDATE_BOOLEAN),
				'destination' => $row['forward_user_not_registered_destination'] ?? '',
			],
		];
	}

	$service_secret = getenv('MPHONE_API_SECRET') ?: '';
	$provided_secret = request_header('X-Mphone-Api-Key');
	$session_user_uuid = session_user_uuid(request_header('X-Mphone-Session'));
	$valid_service_secret = $service_secret !== '' && $provided_secret !== '' && hash_equals($service_secret, $provided_secret);
	if (!$valid_service_secret && $session_user_uuid === '') {
		api_response(401, ['error' => 'Unauthorized']);
	}

	$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
	if (!in_array($method, ['GET', 'PUT'], true)) {
		header('Allow: GET, PUT');
		api_response(405, ['error' => 'Method not allowed']);
	}

	$input = [];
	if ($method === 'PUT') {
		$decoded = json_decode(file_get_contents('php://input'), true);
		if (!is_array($decoded)) {
			api_response(400, ['error' => 'Invalid JSON body']);
		}
		$input = $decoded;
	}

	$user_uuid = $session_user_uuid !== ''
		? $session_user_uuid
		: trim((string) ($_GET['user_uuid'] ?? $input['user_uuid'] ?? ''));
	$extension_uuid = trim((string) ($_GET['extension_uuid'] ?? $input['extension_uuid'] ?? ''));
	if (!is_uuid($user_uuid) || !is_uuid($extension_uuid)) {
		api_response(400, ['error' => 'Invalid user_uuid or extension_uuid']);
	}

	$sql = "select e.extension_uuid, e.domain_uuid, e.extension, e.number_alias, e.call_timeout, ";
	$sql .= "e.do_not_disturb, e.follow_me_uuid, e.follow_me_enabled, ";
	$sql .= "e.forward_all_enabled, e.forward_all_destination, ";
	$sql .= "e.forward_busy_enabled, e.forward_busy_destination, ";
	$sql .= "e.forward_no_answer_enabled, e.forward_no_answer_destination, ";
	$sql .= "e.forward_user_not_registered_enabled, e.forward_user_not_registered_destination, ";
	$sql .= "d.domain_name ";
	$sql .= "from v_extensions e ";
	$sql .= "join v_extension_users eu on eu.extension_uuid = e.extension_uuid ";
	$sql .= "join v_users u on u.user_uuid = eu.user_uuid and u.domain_uuid = e.domain_uuid ";
	$sql .= "join v_domains d on d.domain_uuid = e.domain_uuid ";
	$sql .= "where e.extension_uuid = :extension_uuid and u.user_uuid = :user_uuid ";
	$sql .= "and e.enabled = 'true' and u.user_enabled = 'true' ";
	$parameters = [
		'extension_uuid' => $extension_uuid,
		'user_uuid' => $user_uuid,
	];
	$row = $database->select($sql, $parameters, 'row');
	unset($sql, $parameters);

	if (empty($row)) {
		api_response(404, ['error' => 'Extension not found or not assigned to user']);
	}

	if ($method === 'GET') {
		api_response(200, forward_payload($row));
	}

	$fields = [
		'forward_all' => ['forward_all_enabled', 'forward_all_destination'],
		'forward_busy' => ['forward_busy_enabled', 'forward_busy_destination'],
		'forward_no_answer' => ['forward_no_answer_enabled', 'forward_no_answer_destination'],
		'forward_not_registered' => ['forward_user_not_registered_enabled', 'forward_user_not_registered_destination'],
	];
	$updates = [];
	foreach ($fields as $api_field => [$enabled_field, $destination_field]) {
		if (!isset($input[$api_field]) || !is_array($input[$api_field])) {
			api_response(400, ['error' => "Missing $api_field settings"]);
		}
		$enabled = boolean_value($input[$api_field]['enabled'] ?? null);
		$destination = trim((string) ($input[$api_field]['destination'] ?? ''));
		if ($enabled === null) {
			api_response(400, ['error' => "Invalid $api_field enabled value"]);
		}
		if (strlen($destination) > 255 || ($destination !== '' && !preg_match('/^[*0-9]+$/', $destination))) {
			api_response(400, ['error' => "Invalid $api_field destination"]);
		}
		if ($enabled && $destination === '') {
			api_response(400, ['error' => "$api_field destination is required when enabled"]);
		}
		if ($enabled && ($destination === $row['extension'] || (!empty($row['number_alias']) && $destination === $row['number_alias']))) {
			api_response(400, ['error' => "$api_field cannot forward to the same extension"]);
		}
		$updates[$enabled_field] = $enabled ? 'true' : 'false';
		$updates[$destination_field] = $destination;
	}

	try {
		if ($updates['forward_all_enabled'] === 'true' || $updates['forward_busy_enabled'] === 'true' || $updates['forward_no_answer_enabled'] === 'true') {
			$updates['do_not_disturb'] = 'false';
		}
		if ($updates['forward_all_enabled'] === 'true') {
			$updates['follow_me_enabled'] = 'false';
		}
		$array['extensions'][0] = array_merge([
			'domain_uuid' => $row['domain_uuid'],
			'extension_uuid' => $extension_uuid,
		], $updates);
		if ($updates['forward_all_enabled'] === 'true' && is_uuid($row['follow_me_uuid'] ?? '')) {
			$array['follow_me'][0]['domain_uuid'] = $row['domain_uuid'];
			$array['follow_me'][0]['follow_me_uuid'] = $row['follow_me_uuid'];
			$array['follow_me'][0]['follow_me_enabled'] = 'false';
		}
		$database->save($array);
		unset($array);

		$cache = new cache;
		$cache->delete('directory:' . $row['extension'] . '@' . $row['domain_name']);
		if (!empty($row['number_alias'])) {
			$cache->delete('directory:' . $row['number_alias'] . '@' . $row['domain_name']);
		}

		if ($settings->get('device', 'feature_sync', false)) {
			$notify = new feature_event_notify;
			$notify->domain_name = $row['domain_name'];
			$notify->extension = $row['extension'];
			$notify->ring_count = (int) ceil(((int) $row['call_timeout']) / 6);
			$notify->forward_all_enabled = $updates['forward_all_enabled'] === 'true';
			$notify->forward_all_destination = $updates['forward_all_destination'] ?: '0';
			$notify->forward_busy_enabled = $updates['forward_busy_enabled'] === 'true';
			$notify->forward_busy_destination = $updates['forward_busy_destination'] ?: '0';
			$notify->forward_no_answer_enabled = $updates['forward_no_answer_enabled'] === 'true';
			$notify->forward_no_answer_destination = $updates['forward_no_answer_destination'] ?: '0';
			$notify->send_notify();
		}

		$row = array_merge($row, $updates);
		api_response(200, forward_payload($row));
	}
	catch (Throwable $error) {
		error_log('Mphone call-forward API failed: ' . $error->getMessage());
		api_response(500, ['error' => 'Unable to update call forwarding']);
	}

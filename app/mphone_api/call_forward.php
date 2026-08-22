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

	function mphone_auth_public_key(): string {
		$path = getenv('MPHONE_AUTH_PUBLIC_KEY_FILE') ?: '/etc/mphone/auth-v2-public.pem';
		if (!is_readable($path)) {
			return '';
		}
		$value = file_get_contents($path);
		return $value === false ? '' : trim($value);
	}

	function jwt_es256_der_signature(string $signature): string|false {
		if (strlen($signature) !== 64) {
			return false;
		}
		$encode_integer = static function (string $value): string {
			$value = ltrim($value, "\x00");
			if ($value === '') {
				$value = "\x00";
			}
			if ((ord($value[0]) & 0x80) !== 0) {
				$value = "\x00" . $value;
			}
			return "\x02" . chr(strlen($value)) . $value;
		};
		$r = $encode_integer(substr($signature, 0, 32));
		$s = $encode_integer(substr($signature, 32, 32));
		$sequence = $r . $s;
		return "\x30" . chr(strlen($sequence)) . $sequence;
	}

	function session_principal(string $token): array {
		$parts = explode('.', $token);
		if (count($parts) !== 3) {
			return [];
		}
		[$encoded_header, $encoded_payload, $encoded_signature] = $parts;
		$header_json = base64url_decode($encoded_header);
		$payload_json = base64url_decode($encoded_payload);
		$signature = base64url_decode($encoded_signature);
		if ($header_json === false || $payload_json === false || $signature === false) {
			return [];
		}
		$header = json_decode($header_json, true);
		$payload = json_decode($payload_json, true);
		if (!is_array($header) || !is_array($payload)) {
			return [];
		}
		$algorithm = $header['alg'] ?? '';
		$signing_input = $encoded_header . '.' . $encoded_payload;
		if ($algorithm === 'HS256') {
			$secret = supabase_jwt_secret();
			if ($secret === '') {
				return [];
			}
			$expected_signature = hash_hmac('sha256', $signing_input, $secret, true);
			if (!hash_equals($expected_signature, $signature)) {
				return [];
			}
		}
		elseif ($algorithm === 'ES256') {
			$public_key = mphone_auth_public_key();
			$der_signature = jwt_es256_der_signature($signature);
			if ($public_key === '' || $der_signature === false ||
				openssl_verify($signing_input, $der_signature, $public_key, OPENSSL_ALGO_SHA256) !== 1) {
				return [];
			}
		}
		else {
			return [];
		}
		$is_v2 = ($payload['token_version'] ?? 1) === 2;
		$expected_issuer = $is_v2 ? 'mphone-identity' : 'mphone-fusionpbx';
		$expected_audience = $is_v2 ? 'mphone-api' : 'authenticated';
		if (($payload['iss'] ?? '') !== $expected_issuer || ($payload['aud'] ?? '') !== $expected_audience) {
			return [];
		}
		if (!isset($payload['exp']) || (int) $payload['exp'] < time()) {
			return [];
		}
		$actor_type = ($payload['actor_type'] ?? 'user') === 'extension' ? 'extension' : 'user';
		$user_uuid = trim((string) ($payload['user_uuid'] ?? ($actor_type === 'user' ? ($payload['actor_uuid'] ?? '') : '')));
		$extension_uuid = trim((string) ($payload['extension_uuid'] ?? ''));
		if ($actor_type === 'user' && !is_uuid($user_uuid)) {
			return [];
		}
		if ($actor_type === 'extension' && !is_uuid($extension_uuid)) {
			return [];
		}
		return [
			'actor_type' => $actor_type,
			'user_uuid' => is_uuid($user_uuid) ? $user_uuid : '',
			'extension_uuid' => is_uuid($extension_uuid) ? $extension_uuid : '',
		];
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

	function follow_me_payload(database $database, array $extension): array {
		$follow_me = [];
		$destinations = [];
		if (is_uuid($extension['follow_me_uuid'] ?? '')) {
			$sql = "select cid_name_prefix, cid_number_prefix, follow_me_enabled, follow_me_ignore_busy ";
			$sql .= "from v_follow_me where domain_uuid = :domain_uuid and follow_me_uuid = :follow_me_uuid";
			$follow_me = $database->select($sql, [
				'domain_uuid' => $extension['domain_uuid'],
				'follow_me_uuid' => $extension['follow_me_uuid'],
			], 'row') ?: [];

			$sql = "select follow_me_destination_uuid, follow_me_destination, follow_me_delay, ";
			$sql .= "follow_me_timeout, follow_me_prompt from v_follow_me_destinations ";
			$sql .= "where follow_me_uuid = :follow_me_uuid order by follow_me_order asc";
			$rows = $database->select($sql, ['follow_me_uuid' => $extension['follow_me_uuid']], 'all');
			foreach ($rows as $destination) {
				$destinations[] = [
					'uuid' => $destination['follow_me_destination_uuid'],
					'destination' => $destination['follow_me_destination'],
					'delay' => (int) $destination['follow_me_delay'],
					'timeout' => (int) $destination['follow_me_timeout'],
					'confirm' => !empty($destination['follow_me_prompt']),
				];
			}
		}
		return [
			'extension_uuid' => $extension['extension_uuid'],
			'extension' => $extension['extension'],
			'enabled' => filter_var($follow_me['follow_me_enabled'] ?? $extension['follow_me_enabled'] ?? false, FILTER_VALIDATE_BOOLEAN),
			'ignore_busy' => filter_var($follow_me['follow_me_ignore_busy'] ?? false, FILTER_VALIDATE_BOOLEAN),
			'cid_name_prefix' => $follow_me['cid_name_prefix'] ?? '',
			'cid_number_prefix' => $follow_me['cid_number_prefix'] ?? '',
			'destinations' => $destinations,
		];
	}

	function save_with_api_permissions(database $database, array &$array, bool $include_follow_me = false): bool {
		$permission_names = ['extension_edit'];
		if ($include_follow_me) {
			$permission_names = array_merge($permission_names, [
				'follow_me_edit',
				'follow_me_destination_add',
				'follow_me_destination_edit',
				'follow_me_destination_delete',
			]);
		}

		$temporary_permissions = permissions::new();
		foreach ($permission_names as $permission_name) {
			$temporary_permissions->add($permission_name, 'temp');
		}
		try {
			return $database->save($array) !== false;
		}
		finally {
			foreach ($permission_names as $permission_name) {
				$temporary_permissions->delete($permission_name, 'temp');
			}
		}
	}

	function select_extension(database $database, string $extension_uuid): array {
		$sql = "select e.extension_uuid, e.domain_uuid, e.extension, e.number_alias, e.call_timeout, ";
		$sql .= "e.do_not_disturb, e.follow_me_uuid, e.follow_me_enabled, ";
		$sql .= "e.forward_all_enabled, e.forward_all_destination, ";
		$sql .= "e.forward_busy_enabled, e.forward_busy_destination, ";
		$sql .= "e.forward_no_answer_enabled, e.forward_no_answer_destination, ";
		$sql .= "e.forward_user_not_registered_enabled, e.forward_user_not_registered_destination, ";
		$sql .= "d.domain_name from v_extensions e ";
		$sql .= "join v_domains d on d.domain_uuid = e.domain_uuid ";
		$sql .= "where e.extension_uuid = :extension_uuid and e.enabled = 'true' and d.domain_enabled = 'true'";
		return $database->select($sql, ['extension_uuid' => $extension_uuid], 'row') ?: [];
	}

	$service_secret = getenv('MPHONE_API_SECRET') ?: '';
	$provided_secret = request_header('X-Mphone-Api-Key');
	$session_principal = session_principal(request_header('X-Mphone-Session'));
	$valid_service_secret = $service_secret !== '' && $provided_secret !== '' && hash_equals($service_secret, $provided_secret);
	if (!$valid_service_secret && empty($session_principal)) {
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
	$mode = trim((string) ($_GET['mode'] ?? $input['mode'] ?? 'basic'));

	$user_uuid = ($session_principal['user_uuid'] ?? '') !== ''
		? $session_principal['user_uuid']
		: trim((string) ($_GET['user_uuid'] ?? $input['user_uuid'] ?? ''));
	$extension_uuid = trim((string) ($_GET['extension_uuid'] ?? $input['extension_uuid'] ?? ''));
	if (!is_uuid($extension_uuid)) {
		api_response(400, ['error' => 'Invalid extension_uuid']);
	}
	$is_extension_session = ($session_principal['actor_type'] ?? '') === 'extension';
	if ($is_extension_session && ($session_principal['extension_uuid'] ?? '') !== $extension_uuid) {
		api_response(403, ['error' => 'Extension is outside this session']);
	}
	if (!$is_extension_session && !is_uuid($user_uuid)) {
		api_response(400, ['error' => 'Invalid user_uuid']);
	}

	$sql = "select e.extension_uuid, e.domain_uuid, e.extension, e.number_alias, e.call_timeout, ";
	$sql .= "e.do_not_disturb, e.follow_me_uuid, e.follow_me_enabled, ";
	$sql .= "e.forward_all_enabled, e.forward_all_destination, ";
	$sql .= "e.forward_busy_enabled, e.forward_busy_destination, ";
	$sql .= "e.forward_no_answer_enabled, e.forward_no_answer_destination, ";
	$sql .= "e.forward_user_not_registered_enabled, e.forward_user_not_registered_destination, ";
	$sql .= "d.domain_name ";
	$sql .= "from v_extensions e ";
	$sql .= "join v_domains d on d.domain_uuid = e.domain_uuid ";
	$parameters = ['extension_uuid' => $extension_uuid];
	if ($is_extension_session) {
		$sql .= "where e.extension_uuid = :extension_uuid ";
		$sql .= "and e.enabled = 'true' and d.domain_enabled = 'true' ";
	}
	else {
		$sql .= "join v_extension_users eu on eu.extension_uuid = e.extension_uuid ";
		$sql .= "join v_users u on u.user_uuid = eu.user_uuid and u.domain_uuid = e.domain_uuid ";
		$sql .= "where e.extension_uuid = :extension_uuid and u.user_uuid = :user_uuid ";
		$sql .= "and e.enabled = 'true' and u.user_enabled = 'true' ";
		$parameters['user_uuid'] = $user_uuid;
	}
	$row = $database->select($sql, $parameters, 'row');
	unset($sql, $parameters);

	if (empty($row)) {
		api_response(404, ['error' => 'Extension not found or not available to this session']);
	}

	if ($method === 'GET' && $mode === 'advanced') {
		api_response(200, follow_me_payload($database, $row));
	}

	if ($method === 'PUT' && $mode === 'advanced') {
		$enabled = boolean_value($input['enabled'] ?? null);
		$ignore_busy = boolean_value($input['ignore_busy'] ?? null);
		$cid_name_prefix = trim((string) ($input['cid_name_prefix'] ?? ''));
		$cid_number_prefix = trim((string) ($input['cid_number_prefix'] ?? ''));
		$submitted_destinations = $input['destinations'] ?? null;
		if ($enabled === null || $ignore_busy === null || !is_array($submitted_destinations)) {
			api_response(400, ['error' => 'Invalid advanced forwarding settings']);
		}
		if (count($submitted_destinations) > 5 || strlen($cid_name_prefix) > 255 || strlen($cid_number_prefix) > 255) {
			api_response(400, ['error' => 'Advanced forwarding settings exceed allowed limits']);
		}

		$follow_me_uuid = is_uuid($row['follow_me_uuid'] ?? '') ? $row['follow_me_uuid'] : uuid();
		$destinations = [];
		foreach ($submitted_destinations as $index => $destination) {
			if (!is_array($destination)) {
				api_response(400, ['error' => 'Invalid destination']);
			}
			$number = trim((string) ($destination['destination'] ?? ''));
			if ($number === '') {
				continue;
			}
			$delay = (int) ($destination['delay'] ?? 0);
			$timeout = (int) ($destination['timeout'] ?? 45);
			$confirm = boolean_value($destination['confirm'] ?? false);
			if (!preg_match('/^[*0-9]+$/', $number) || strlen($number) > 255 || $number === $row['extension']) {
				api_response(400, ['error' => 'Invalid advanced forwarding destination']);
			}
			if ($delay < 0 || $delay > 100 || $timeout < 5 || $timeout > 100 || $confirm === null) {
				api_response(400, ['error' => 'Delay and timeout must be between 0 and 100 seconds']);
			}
			$destinations[] = [
				'uuid' => is_uuid($destination['uuid'] ?? '') ? $destination['uuid'] : uuid(),
				'destination' => $number,
				'delay' => $delay,
				'timeout' => $timeout,
				'confirm' => $confirm,
				'order' => count($destinations),
			];
		}
		$enabled = $enabled && count($destinations) > 0;

		try {
			$array['extensions'][0]['domain_uuid'] = $row['domain_uuid'];
			$array['extensions'][0]['extension_uuid'] = $extension_uuid;
			$array['extensions'][0]['follow_me_uuid'] = $follow_me_uuid;
			$array['extensions'][0]['follow_me_enabled'] = $enabled ? 'true' : 'false';
			if ($enabled) {
				$array['extensions'][0]['forward_all_enabled'] = 'false';
				$array['extensions'][0]['do_not_disturb'] = 'false';
			}
			$array['follow_me'][0]['domain_uuid'] = $row['domain_uuid'];
			$array['follow_me'][0]['follow_me_uuid'] = $follow_me_uuid;
			$array['follow_me'][0]['cid_name_prefix'] = $cid_name_prefix;
			$array['follow_me'][0]['cid_number_prefix'] = $cid_number_prefix;
			$array['follow_me'][0]['follow_me_ignore_busy'] = $ignore_busy ? 'true' : 'false';
			$array['follow_me'][0]['follow_me_enabled'] = $enabled ? 'true' : 'false';
			foreach ($destinations as $index => $destination) {
				$array['follow_me'][0]['follow_me_destinations'][$index] = [
					'domain_uuid' => $row['domain_uuid'],
					'follow_me_uuid' => $follow_me_uuid,
					'follow_me_destination_uuid' => $destination['uuid'],
					'follow_me_destination' => $destination['destination'],
					'follow_me_delay' => $destination['delay'],
					'follow_me_timeout' => $destination['timeout'],
					'follow_me_prompt' => $destination['confirm'] ? '1' : '',
					'follow_me_order' => $destination['order'],
				];
			}
			if (!save_with_api_permissions($database, $array, true)) {
				throw new RuntimeException('FusionPBX rejected the advanced forwarding update');
			}
			unset($array);

			$kept_uuids = array_column($destinations, 'uuid');
			$sql = "select follow_me_destination_uuid from v_follow_me_destinations where follow_me_uuid = :follow_me_uuid";
			$existing = $database->select($sql, ['follow_me_uuid' => $follow_me_uuid], 'all');
			foreach ($existing as $existing_destination) {
				if (!in_array($existing_destination['follow_me_destination_uuid'], $kept_uuids, true)) {
					$delete['follow_me_destinations'][]['follow_me_destination_uuid'] = $existing_destination['follow_me_destination_uuid'];
				}
			}
			if (!empty($delete)) {
				$delete_permissions = permissions::new();
				$delete_permissions->add('follow_me_destination_delete', 'temp');
				try {
					if (!$database->delete($delete)) {
						throw new RuntimeException('FusionPBX rejected deleting an advanced forwarding destination');
					}
				}
				finally {
					$delete_permissions->delete('follow_me_destination_delete', 'temp');
				}
			}

			$cache = new cache;
			$cache->delete('directory:' . $row['extension'] . '@' . $row['domain_name']);
			if (!empty($settings->get('switch', 'extensions')) && is_readable($settings->get('switch', 'extensions'))) {
				$extension_config = new extension;
				$extension_config->xml();
			}
			$saved_row = select_extension($database, $extension_uuid);
			if (empty($saved_row) || filter_var($saved_row['follow_me_enabled'], FILTER_VALIDATE_BOOLEAN) !== $enabled) {
				throw new RuntimeException('Advanced forwarding state was not persisted');
			}
			api_response(200, follow_me_payload($database, $saved_row));
		}
		catch (Throwable $error) {
			error_log('Mphone advanced call-forward API failed: ' . $error->getMessage());
			api_response(500, ['error' => 'Unable to update advanced call forwarding']);
		}
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
		if (!save_with_api_permissions($database, $array)) {
			throw new RuntimeException('FusionPBX rejected the call-forward update');
		}
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

		if (!empty($settings->get('switch', 'extensions')) && is_readable($settings->get('switch', 'extensions'))) {
			$extension_config = new extension;
			$extension_config->xml();
		}

		$saved_row = select_extension($database, $extension_uuid);
		if (empty($saved_row)) {
			throw new RuntimeException('Updated extension could not be read back');
		}
		foreach ($updates as $field => $expected_value) {
			$actual_value = $saved_row[$field] ?? null;
			if (str_ends_with($field, '_enabled') || $field === 'do_not_disturb' || is_bool($actual_value)) {
				$actual_value = filter_var($actual_value, FILTER_VALIDATE_BOOLEAN) ? 'true' : 'false';
			}
			else {
				$actual_value = (string) ($actual_value ?? '');
			}
			if ($actual_value !== $expected_value) {
				throw new RuntimeException("Call-forward field $field was not persisted");
			}
		}
		api_response(200, forward_payload($saved_row));
	}
	catch (Throwable $error) {
		error_log('Mphone call-forward API failed: ' . $error->getMessage());
		api_response(500, ['error' => 'Unable to update call forwarding']);
	}

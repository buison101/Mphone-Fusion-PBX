<?php
/*
	FusionPBX
	Copyright (C) 2026

	Receives local call-forward events from FreeSWITCH and relays them to the
	private Supabase Edge Function. This endpoint is intentionally localhost-only.
*/

	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');

	require_once dirname(__DIR__, 2) . '/resources/require.php';

	function push_response(int $status, array $payload): void {
		http_response_code($status);
		echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
		exit;
	}

	$remote_address = $_SERVER['REMOTE_ADDR'] ?? '';
	if (!in_array($remote_address, ['127.0.0.1', '::1'], true)) {
		push_response(403, ['error' => 'Forbidden']);
	}
	if (strtoupper($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
		push_response(405, ['error' => 'Method not allowed']);
	}

	$input = json_decode(file_get_contents('php://input'), true);
	if (!is_array($input)) {
		push_response(400, ['error' => 'Invalid JSON body']);
	}
	$event_id = trim((string) ($input['event_id'] ?? ''));
	$caller_number = trim((string) ($input['caller_number'] ?? ''));
	$dialed_number = trim((string) ($input['dialed_number'] ?? ''));
	$extension = trim((string) ($input['extension'] ?? ''));
	$domain_name = trim((string) ($input['domain_name'] ?? ''));
	if ($event_id === '' || $caller_number === '' || $dialed_number === '' ||
		$extension === '' || $domain_name === '' || strlen($event_id) > 255 ||
		strlen($caller_number) > 255 || strlen($dialed_number) > 255) {
		push_response(400, ['error' => 'Invalid call-forward event']);
	}

	$sql = "select e.extension_uuid, e.extension, e.forward_all_enabled, e.forward_all_destination ";
	$sql .= "from v_extensions e join v_domains d on d.domain_uuid = e.domain_uuid ";
	$sql .= "where e.extension = :extension and d.domain_name = :domain_name and e.enabled = 'true' limit 1";
	$row = $database->select($sql, [
		'extension' => $extension,
		'domain_name' => $domain_name,
	], 'row');
	if (empty($row) || !filter_var($row['forward_all_enabled'], FILTER_VALIDATE_BOOLEAN) ||
		trim((string) $row['forward_all_destination']) === '') {
		push_response(202, ['sent' => false]);
	}

	$secret_file = '/etc/mphone/push-api-secret';
	$secret = is_readable($secret_file) ? trim((string) file_get_contents($secret_file)) : '';
	if ($secret === '') {
		error_log('Mphone push secret is unavailable');
		push_response(503, ['error' => 'Push service unavailable']);
	}
	$payload = json_encode([
		'event_id' => $event_id,
		'extension_uuid' => $row['extension_uuid'],
		'extension' => $row['extension'],
		'caller_number' => $caller_number,
		'dialed_number' => $dialed_number,
		'forward_destination' => trim((string) $row['forward_all_destination']),
	], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
	$context = stream_context_create(['http' => [
		'method' => 'POST',
		'header' => "Content-Type: application/json\r\nX-Mphone-Push-Secret: {$secret}\r\n",
		'content' => $payload,
		'timeout' => 3,
		'ignore_errors' => true,
	]]);
	$response = file_get_contents(
		'http://127.0.0.1:8000/functions/v1/mphone-call-forward-notify',
		false,
		$context
	);
	$status_line = $http_response_header[0] ?? '';
	if ($response === false || !preg_match('/\s2\d\d\s/', $status_line)) {
		error_log('Mphone call-forward push relay failed: ' . $status_line);
		push_response(502, ['error' => 'Unable to relay push event']);
	}
	push_response(200, ['sent' => true]);


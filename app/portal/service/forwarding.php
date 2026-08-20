<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/request.php';

	portal_json_headers();
	if (($_SERVER['REQUEST_METHOD'] ?? 'POST') !== 'PUT') { http_response_code(405); echo json_encode(['error' => 'method_not_allowed']); exit; }
	portal_require_session(['call_forward']);
	portal_require_csrf();
	$input = json_decode(file_get_contents('php://input'), true);
	if (!is_array($input) || !portal_extension_is_assigned($input['extension_uuid'] ?? '')) { http_response_code(403); echo json_encode(['error' => 'extension_forbidden']); exit; }
	$extension_uuid = $input['extension_uuid'];
	$types = ['all' => 'forward_all', 'busy' => 'forward_busy', 'no_answer' => 'forward_no_answer', 'not_registered' => 'forward_user_not_registered'];
	$forwarding = $input['forwarding'] ?? null;
	$call_timeout = (int) ($input['call_timeout'] ?? 30);
	if (!is_array($forwarding) || $call_timeout < 5 || $call_timeout > 120) { http_response_code(400); echo json_encode(['error' => 'invalid_forwarding']); exit; }
	$database = new database;
	$row = $database->select('select extension,number_alias from v_extensions where domain_uuid=:domain_uuid and extension_uuid=:extension_uuid', ['domain_uuid' => $_SESSION['domain_uuid'], 'extension_uuid' => $extension_uuid], 'row');
	if (empty($row)) { http_response_code(404); echo json_encode(['error' => 'not_found']); exit; }
	$array['extensions'][0]['domain_uuid'] = $_SESSION['domain_uuid'];
	$array['extensions'][0]['extension_uuid'] = $extension_uuid;
	$array['extensions'][0]['call_timeout'] = $call_timeout;
	foreach ($types as $key => $field) {
		$enabled = filter_var($forwarding[$key]['enabled'] ?? false, FILTER_VALIDATE_BOOLEAN);
		$destination = preg_replace('/[\s().-]+/', '', trim((string) ($forwarding[$key]['destination'] ?? '')));
		if ($destination !== '' && (!preg_match('/^[+*#0-9]{1,32}$/', $destination) || $destination === $row['extension'])) { http_response_code(400); echo json_encode(['error' => 'invalid_destination', 'field' => $key]); exit; }
		$array['extensions'][0][$field . '_enabled'] = $enabled && $destination !== '' ? 'true' : 'false';
		$array['extensions'][0][$field . '_destination'] = $destination !== '' ? $destination : null;
	}
	$temporary = permissions::new();
	$temporary->add('extension_edit', 'temp');
	try { $saved = $database->save($array) !== false; }
	finally { $temporary->delete('extension_edit', 'temp'); }
	if (!$saved) { http_response_code(500); echo json_encode(['error' => 'save_failed']); exit; }
	$cache = new cache;
	$cache->delete('directory:' . $row['extension'] . '@' . $_SESSION['domain_name']);
	if (!empty($row['number_alias'])) { $cache->delete('directory:' . $row['number_alias'] . '@' . $_SESSION['domain_name']); }
	error_log('portal forwarding updated user=' . $_SESSION['user_uuid'] . ' extension=' . $extension_uuid);
	echo json_encode(['saved' => true]);

?>

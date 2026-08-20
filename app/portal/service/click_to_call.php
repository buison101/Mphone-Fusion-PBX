<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/request.php';

	portal_json_headers();
	if (($_SERVER['REQUEST_METHOD'] ?? 'POST') !== 'POST') { http_response_code(405); echo json_encode(['error' => 'method_not_allowed']); exit; }
	portal_require_session(['click_to_call_view', 'click_to_call_call']);
	portal_require_csrf();
	$input = json_decode(file_get_contents('php://input'), true);
	$extension_uuid = $input['extension_uuid'] ?? '';
	$destination = preg_replace('/[\s().-]+/', '', trim((string) ($input['destination'] ?? '')));
	if (!portal_extension_is_assigned($extension_uuid)) { http_response_code(403); echo json_encode(['error' => 'extension_forbidden']); exit; }
	if (!preg_match('/^[+*#0-9]{1,32}$/', $destination)) { http_response_code(400); echo json_encode(['error' => 'invalid_destination']); exit; }
	$database = new database;
	$row = $database->select('select extension,effective_caller_id_name,effective_caller_id_number from v_extensions where domain_uuid=:domain_uuid and extension_uuid=:extension_uuid and enabled=\'true\'', ['domain_uuid' => $_SESSION['domain_uuid'], 'extension_uuid' => $extension_uuid], 'row');
	if (empty($row) || !preg_match('/^[A-Za-z0-9_.-]{1,32}$/', $row['extension'])) { http_response_code(404); echo json_encode(['error' => 'not_found']); exit; }
	$domain_name = $_SESSION['domain_name'] ?? '';
	if (!preg_match('/^[A-Za-z0-9.-]{1,253}$/', $domain_name)) { http_response_code(400); echo json_encode(['error' => 'invalid_domain']); exit; }
	$caller_name = preg_replace('/[^A-Za-z0-9 _.-]/', '', (string) ($row['effective_caller_id_name'] ?? $row['extension']));
	$caller_number = preg_replace('/[^+0-9]/', '', (string) ($row['effective_caller_id_number'] ?? $row['extension']));
	$command = "bgapi originate {click_to_call=true,origination_caller_id_name='" . $caller_name . "',origination_caller_id_number=" . $caller_number . ',domain_uuid=' . $_SESSION['domain_uuid'] . ',domain_name=' . $domain_name . '}user/' . $row['extension'] . '@' . $domain_name . " &transfer('" . $destination . ' XML ' . $domain_name . "')";
	$esl = event_socket::create();
	if (!$esl->is_connected()) { http_response_code(503); echo json_encode(['error' => 'switch_unavailable']); exit; }
	$result = trim(event_socket::api($command));
	if (stripos($result, '+OK') !== 0) { http_response_code(502); echo json_encode(['error' => 'originate_failed']); exit; }
	error_log('portal click-to-call user=' . $_SESSION['user_uuid'] . ' extension=' . $extension_uuid . ' destination=' . $destination);
	echo json_encode(['accepted' => true]);

?>

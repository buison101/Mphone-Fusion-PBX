<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/request.php';

	portal_json_headers();
	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') { http_response_code(405); echo json_encode(['error' => 'method_not_allowed']); exit; }
	portal_require_session();
	$domain_uuid = $_SESSION['domain_uuid'] ?? '';
	if (!is_uuid($domain_uuid)) { http_response_code(400); echo json_encode(['error' => 'invalid_domain']); exit; }
	$uuids = portal_assigned_extension_uuids();
	if (empty($uuids)) { echo json_encode(['available' => true, 'extensions' => []]); exit; }
	$parameters = ['domain_uuid' => $domain_uuid];
	$placeholders = [];
	foreach ($uuids as $index => $uuid) { $key = 'extension_' . $index; $placeholders[] = ':' . $key; $parameters[$key] = $uuid; }
	$sql = 'select e.extension_uuid,e.extension,e.effective_caller_id_name,e.effective_caller_id_number,e.outbound_caller_id_name,e.outbound_caller_id_number,e.call_timeout,e.user_record,e.do_not_disturb,e.forward_all_enabled,e.forward_all_destination,e.forward_busy_enabled,e.forward_busy_destination,e.forward_no_answer_enabled,e.forward_no_answer_destination,e.forward_user_not_registered_enabled,e.forward_user_not_registered_destination,v.voicemail_enabled,v.voicemail_mail_to,v.voicemail_attach_file from v_extensions e left join v_voicemails v on v.domain_uuid=e.domain_uuid and v.voicemail_id=e.extension where e.domain_uuid=:domain_uuid and e.extension_uuid in (' . implode(',', $placeholders) . ") and e.enabled='true' order by e.extension";
	$database = new database;
	$rows = $database->select($sql, $parameters, 'all') ?: [];
	$registrations = [];
	$esl = event_socket::create();
	if ($esl->is_connected()) {
		$registration_json = event_socket::api('show registrations as json');
		$decoded = json_decode($registration_json, true);
		foreach (($decoded['rows'] ?? []) as $registration) {
			if (($registration['realm'] ?? '') === ($_SESSION['domain_name'] ?? '')) { $registrations[$registration['reg_user']][] = $registration; }
		}
	}
	$extensions = [];
	foreach ($rows as $row) {
		$registered = $registrations[$row['extension']] ?? [];
		$extensions[] = [
			'extension_uuid' => $row['extension_uuid'], 'extension' => $row['extension'],
			'caller_id_name' => $row['effective_caller_id_name'] ?? '', 'caller_id_number' => $row['effective_caller_id_number'] ?? '',
			'outbound_caller_id_name' => $row['outbound_caller_id_name'] ?? '', 'outbound_caller_id_number' => $row['outbound_caller_id_number'] ?? '',
			'registered' => count($registered) > 0, 'registered_devices' => count($registered), 'registration_protocols' => array_values(array_unique(array_column($registered, 'network_proto'))),
			'voicemail' => ['enabled' => filter_var($row['voicemail_enabled'] ?? false, FILTER_VALIDATE_BOOLEAN), 'email' => $row['voicemail_mail_to'] ?? '', 'attach_audio' => filter_var($row['voicemail_attach_file'] ?? false, FILTER_VALIDATE_BOOLEAN)],
			'recording_policy' => $row['user_record'] ?? 'none', 'do_not_disturb' => filter_var($row['do_not_disturb'], FILTER_VALIDATE_BOOLEAN), 'call_timeout' => (int) $row['call_timeout'],
			'forwarding' => [
				'all' => ['enabled' => filter_var($row['forward_all_enabled'], FILTER_VALIDATE_BOOLEAN), 'destination' => $row['forward_all_destination'] ?? ''],
				'busy' => ['enabled' => filter_var($row['forward_busy_enabled'], FILTER_VALIDATE_BOOLEAN), 'destination' => $row['forward_busy_destination'] ?? ''],
				'no_answer' => ['enabled' => filter_var($row['forward_no_answer_enabled'], FILTER_VALIDATE_BOOLEAN), 'destination' => $row['forward_no_answer_destination'] ?? ''],
				'not_registered' => ['enabled' => filter_var($row['forward_user_not_registered_enabled'], FILTER_VALIDATE_BOOLEAN), 'destination' => $row['forward_user_not_registered_destination'] ?? ''],
			],
		];
	}
	echo json_encode(['available' => true, 'extensions' => $extensions, 'capabilities' => ['forwarding_edit' => permission_exists('call_forward'), 'dnd_edit' => permission_exists('do_not_disturb')]], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

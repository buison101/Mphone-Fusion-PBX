<?php

	require_once dirname(__DIR__, 3).'/resources/require.php';
	require_once dirname(__DIR__).'/resources/request.php';
	require_once dirname(__DIR__).'/resources/call_metadata_scope.php';

	portal_json_headers();
	$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
	if (!in_array($method, ['POST', 'PATCH', 'DELETE'], true)) { http_response_code(405); echo json_encode(['error' => 'method_not_allowed']); exit; }
	portal_require_csrf();
	$permission = $method === 'POST' ? 'portal_call_note_add' : ($method === 'PATCH' ? 'portal_call_note_edit' : 'portal_call_note_delete');
	portal_require_session(['xml_cdr_view', 'portal_call_note_view', $permission]);
	$payload = json_decode(file_get_contents('php://input'), true);
	$domain_uuid = $_SESSION['domain_uuid'] ?? '';
	$user_uuid = $_SESSION['user_uuid'] ?? '';
	if (!is_array($payload) || !is_uuid($domain_uuid) || !is_uuid($user_uuid)) { http_response_code(400); echo json_encode(['error' => 'invalid_request']); exit; }
	$database = new database;

	if ($method === 'POST') {
		$call_uuid = $payload['call_uuid'] ?? '';
		$text = trim((string)($payload['text'] ?? ''));
		$offset = ($payload['offset_seconds'] ?? '') === '' || ($payload['offset_seconds'] ?? null) === null ? null : (float)$payload['offset_seconds'];
		$cdr = portal_authorized_cdr($database, $call_uuid, $domain_uuid);
		if (empty($cdr)) { http_response_code(404); echo json_encode(['error' => 'not_found']); exit; }
		if ($text === '' || mb_strlen($text) > 2000 || ($offset !== null && ($offset < 0 || $offset > min(86400, max(0, (float)$cdr['duration']))))) {
			http_response_code(422); echo json_encode(['error' => 'invalid_note']); exit;
		}
		$note_uuid = uuid();
		$database->execute('insert into v_portal_call_notes (note_uuid, domain_uuid, xml_cdr_uuid, user_uuid, note_text, offset_seconds, insert_user) values (:uuid, :domain_uuid, :call_uuid, :user_uuid, :text, :offset, :user_uuid)', ['uuid' => $note_uuid, 'domain_uuid' => $domain_uuid, 'call_uuid' => $call_uuid, 'user_uuid' => $user_uuid, 'text' => $text, 'offset' => $offset]);
		echo json_encode(['status' => 'created', 'note_uuid' => $note_uuid]); exit;
	}

	$note_uuid = $payload['note_uuid'] ?? '';
	$note = is_uuid($note_uuid) ? $database->select('select note_uuid, xml_cdr_uuid, user_uuid from v_portal_call_notes where note_uuid = :uuid and domain_uuid = :domain_uuid', ['uuid' => $note_uuid, 'domain_uuid' => $domain_uuid], 'row') : [];
	if (empty($note) || $note['user_uuid'] !== $user_uuid || empty(portal_authorized_cdr($database, $note['xml_cdr_uuid'], $domain_uuid))) {
		http_response_code(404); echo json_encode(['error' => 'not_found']); exit;
	}
	if ($method === 'PATCH') {
		$text = trim((string)($payload['text'] ?? ''));
		if ($text === '' || mb_strlen($text) > 2000) { http_response_code(422); echo json_encode(['error' => 'invalid_note']); exit; }
		$database->execute('update v_portal_call_notes set note_text = :text, update_date = now(), update_user = :user_uuid where note_uuid = :uuid and domain_uuid = :domain_uuid and user_uuid = :user_uuid', ['text' => $text, 'uuid' => $note_uuid, 'domain_uuid' => $domain_uuid, 'user_uuid' => $user_uuid]);
		echo json_encode(['status' => 'updated']); exit;
	}
	$database->execute('delete from v_portal_call_notes where note_uuid = :uuid and domain_uuid = :domain_uuid and user_uuid = :user_uuid', ['uuid' => $note_uuid, 'domain_uuid' => $domain_uuid, 'user_uuid' => $user_uuid]);
	echo json_encode(['status' => 'deleted']);

?>

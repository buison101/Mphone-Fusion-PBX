<?php

	require_once dirname(__DIR__, 3).'/resources/require.php';
	require_once dirname(__DIR__).'/resources/request.php';
	require_once dirname(__DIR__).'/resources/call_metadata_scope.php';

	portal_json_headers();
	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') { http_response_code(405); echo json_encode(['error' => 'method_not_allowed']); exit; }
	portal_require_csrf();
	portal_require_session(['xml_cdr_view', 'portal_call_tag_view']);

	$payload = json_decode(file_get_contents('php://input'), true);
	$action = is_array($payload) ? ($payload['action'] ?? '') : '';
	$domain_uuid = $_SESSION['domain_uuid'] ?? '';
	$user_uuid = $_SESSION['user_uuid'] ?? '';
	$allowed_colors = ['primary', 'secondary', 'success', 'warning', 'error', 'info'];
	if (!is_uuid($domain_uuid) || !is_uuid($user_uuid)) { http_response_code(400); echo json_encode(['error' => 'invalid_request']); exit; }
	$database = new database;

	if ($action === 'create') {
		if (!permission_exists('portal_call_tag_edit')) { http_response_code(403); echo json_encode(['error' => 'forbidden']); exit; }
		$name = trim(preg_replace('/\s+/u', ' ', (string)($payload['name'] ?? '')));
		$normalized_name = portal_normalize_tag_name($name);
		$color = in_array(($payload['color'] ?? ''), $allowed_colors, true) ? $payload['color'] : 'primary';
		if ($name === '' || mb_strlen($name) > 80 || mb_strlen($normalized_name) > 80) { http_response_code(422); echo json_encode(['error' => 'invalid_tag']); exit; }
		if ((int)$database->select('select count(*) from v_portal_call_tags where domain_uuid = :domain_uuid and normalized_name = :name', ['domain_uuid' => $domain_uuid, 'name' => $normalized_name], 'column') > 0) {
			http_response_code(409); echo json_encode(['error' => 'tag_exists']); exit;
		}
		$tag_uuid = uuid();
		$database->execute(
			'insert into v_portal_call_tags (tag_uuid, domain_uuid, name, normalized_name, color_token, insert_user) values (:uuid, :domain_uuid, :name, :normalized_name, :color, :user_uuid)',
			['uuid' => $tag_uuid, 'domain_uuid' => $domain_uuid, 'name' => $name, 'normalized_name' => $normalized_name, 'color' => $color, 'user_uuid' => $user_uuid]
		);
		echo json_encode(['status' => 'created', 'tag' => ['uuid' => $tag_uuid, 'name' => $name, 'color' => $color]], JSON_UNESCAPED_UNICODE);
		exit;
	}
	if ($action === 'disable') {
		if (!permission_exists('portal_call_tag_edit')) { http_response_code(403); echo json_encode(['error' => 'forbidden']); exit; }
		$tag_uuid = $payload['tag_uuid'] ?? '';
		if (!is_uuid($tag_uuid)) { http_response_code(400); echo json_encode(['error' => 'invalid_request']); exit; }
		$database->execute(
			'update v_portal_call_tags set enabled = false, update_date = now(), update_user = :user_uuid where tag_uuid = :tag_uuid and domain_uuid = :domain_uuid and enabled = true',
			['user_uuid' => $user_uuid, 'tag_uuid' => $tag_uuid, 'domain_uuid' => $domain_uuid]
		);
		echo json_encode(['status' => 'disabled']);
		exit;
	}

	$call_uuid = $payload['call_uuid'] ?? '';
	$tag_uuid = $payload['tag_uuid'] ?? '';
	if (!permission_exists('portal_call_tag_assign')) { http_response_code(403); echo json_encode(['error' => 'forbidden']); exit; }
	if (!is_uuid($call_uuid) || !is_uuid($tag_uuid) || empty(portal_authorized_cdr($database, $call_uuid, $domain_uuid))) {
		http_response_code(404); echo json_encode(['error' => 'not_found']); exit;
	}
	$tag_exists = (int)$database->select('select count(*) from v_portal_call_tags where tag_uuid = :tag_uuid and domain_uuid = :domain_uuid and enabled = true', ['tag_uuid' => $tag_uuid, 'domain_uuid' => $domain_uuid], 'column');
	if ($tag_exists < 1) { http_response_code(404); echo json_encode(['error' => 'not_found']); exit; }

	if ($action === 'assign') {
		$database->execute(
			'insert into v_portal_call_tag_assignments (assignment_uuid, domain_uuid, xml_cdr_uuid, tag_uuid, insert_user) values (:uuid, :domain_uuid, :call_uuid, :tag_uuid, :user_uuid) on conflict (domain_uuid, xml_cdr_uuid, tag_uuid) do nothing',
			['uuid' => uuid(), 'domain_uuid' => $domain_uuid, 'call_uuid' => $call_uuid, 'tag_uuid' => $tag_uuid, 'user_uuid' => $user_uuid]
		);
		echo json_encode(['status' => 'assigned']); exit;
	}
	if ($action === 'unassign') {
		$database->execute('delete from v_portal_call_tag_assignments where domain_uuid = :domain_uuid and xml_cdr_uuid = :call_uuid and tag_uuid = :tag_uuid', ['domain_uuid' => $domain_uuid, 'call_uuid' => $call_uuid, 'tag_uuid' => $tag_uuid]);
		echo json_encode(['status' => 'unassigned']); exit;
	}
	http_response_code(400); echo json_encode(['error' => 'invalid_action']);

?>

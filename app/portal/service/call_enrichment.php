<?php

	require_once dirname(__DIR__, 3).'/resources/require.php';
	require_once dirname(__DIR__).'/resources/request.php';

	portal_json_headers();
	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
		http_response_code(405);
		echo json_encode(['error' => 'method_not_allowed']);
		exit;
	}
	portal_require_session(['xml_cdr_view']);

	$xml_cdr_uuid = $_GET['id'] ?? '';
	$domain_uuid = $_SESSION['domain_uuid'] ?? '';
	if (!is_uuid($xml_cdr_uuid) || !is_uuid($domain_uuid)) {
		http_response_code(400);
		echo json_encode(['error' => 'invalid_request']);
		exit;
	}

	$parameters = ['xml_cdr_uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid];
	$scope_sql = '';
	if (!portal_identity_has_domain_scope()) {
		$extension_uuids = portal_assigned_extension_uuids();
		if (empty($extension_uuids)) {
			http_response_code(404);
			echo json_encode(['error' => 'not_found']);
			exit;
		}
		$placeholders = [];
		foreach ($extension_uuids as $index => $extension_uuid) {
			$key = 'extension_uuid_'.$index;
			$placeholders[] = ':'.$key;
			$parameters[$key] = $extension_uuid;
		}
		$scope_sql = 'and extension_uuid in ('.implode(', ', $placeholders).') ';
	}

	$database = new database;
	$cdr = $database->select(
		'select xml_cdr_uuid from v_xml_cdr where xml_cdr_uuid = :xml_cdr_uuid and domain_uuid = :domain_uuid '.$scope_sql,
		$parameters,
		'row'
	);
	if (empty($cdr)) {
		http_response_code(404);
		echo json_encode(['error' => 'not_found']);
		exit;
	}

	$transcript = permission_exists('xml_cdr_transcript_view') ? $database->select(
		'select transcript_json, transcript_summary, summary_status, summary_model, summary_duration, '.
		'coalesce(summary_attempt_count, 0) as summary_attempt_count, update_date, insert_date from v_xml_cdr_transcripts '.
		'where xml_cdr_uuid = :xml_cdr_uuid and domain_uuid = :domain_uuid limit 1',
		['xml_cdr_uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid],
		'row'
	) : [];
	$state = 'unavailable';
	$segments = [];
	$summary = '';
	$summary_state = 'unavailable';
	$summary_model = null;
	$summary_duration = null;
	$summary_attempt_count = 0;
	$updated_at = null;
	if (!empty($transcript)) {
		$decoded = is_array($transcript['transcript_json'])
			? $transcript['transcript_json']
			: json_decode((string)$transcript['transcript_json'], true);
		foreach (($decoded['segments'] ?? []) as $segment) {
			if (!isset($segment['start'], $segment['end'], $segment['text'])) { continue; }
			$segments[] = [
				'speaker' => (string)($segment['speaker'] ?? $segment['channel'] ?? '0'),
				'start' => max(0, (float)$segment['start']),
				'end' => max(0, (float)$segment['end']),
				'text' => trim((string)$segment['text']),
			];
			if (count($segments) >= 2000) { break; }
		}
		$state = !empty($segments) ? 'completed' : 'failed';
		$summary = trim(strip_tags((string)($transcript['transcript_summary'] ?? '')));
		$summary_state = in_array(($transcript['summary_status'] ?? ''), ['disabled', 'processing', 'completed', 'failed', 'skipped'], true)
			? $transcript['summary_status']
			: ($summary !== '' ? 'completed' : 'unavailable');
		if ($summary_state === 'processing' && !empty($transcript['update_date']) && strtotime($transcript['update_date']) <= time() - 900) {
			$summary_state = 'failed';
		}
		$summary_model = !empty($transcript['summary_model']) ? (string)$transcript['summary_model'] : null;
		$summary_duration = isset($transcript['summary_duration']) ? (float)$transcript['summary_duration'] : null;
		$summary_attempt_count = (int)($transcript['summary_attempt_count'] ?? 0);
		$date = $transcript['update_date'] ?: $transcript['insert_date'];
		$updated_at = !empty($date) ? date('c', strtotime($date)) : null;
	}
	elseif (permission_exists('xml_cdr_transcript_view')) {
		$queue = $database->select(
			'select transcribe_status, update_date from v_transcribe_queue '.
			'where transcribe_queue_uuid = :xml_cdr_uuid and domain_uuid = :domain_uuid limit 1',
			['xml_cdr_uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid],
			'row'
		);
		if (!empty($queue)) {
			$state = in_array($queue['transcribe_status'], ['pending', 'processing', 'completed', 'failed'], true)
				? $queue['transcribe_status']
				: 'unavailable';
			$updated_at = !empty($queue['update_date']) ? date('c', strtotime($queue['update_date'])) : null;
		}
	}

	$tags = [];
	$available_tags = [];
	if (permission_exists('portal_call_tag_view')) {
		$tag_rows = $database->select(
			'select t.tag_uuid, t.name, t.color_token from v_portal_call_tag_assignments a '.
			'join v_portal_call_tags t on t.tag_uuid = a.tag_uuid and t.domain_uuid = a.domain_uuid '.
			'where a.domain_uuid = :domain_uuid and a.xml_cdr_uuid = :xml_cdr_uuid order by t.tag_order, t.name limit 100',
			['xml_cdr_uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid],
			'all'
		) ?: [];
		foreach ($tag_rows as $tag) {
			$item = ['uuid' => $tag['tag_uuid'], 'name' => $tag['name'], 'color' => $tag['color_token']];
			$tags[] = $item;
		}
		$available_rows = $database->select(
			'select tag_uuid, name, color_token from v_portal_call_tags where domain_uuid = :domain_uuid and enabled = true order by tag_order, name limit 100',
			['domain_uuid' => $domain_uuid],
			'all'
		) ?: [];
		foreach ($available_rows as $tag) {
			$available_tags[] = ['uuid' => $tag['tag_uuid'], 'name' => $tag['name'], 'color' => $tag['color_token']];
		}
	}

	$notes = [];
	if (permission_exists('portal_call_note_view')) {
		$note_rows = $database->select(
			'select n.note_uuid, n.user_uuid, n.note_text, n.offset_seconds, n.insert_date, n.update_date, u.username '.
			'from v_portal_call_notes n left join v_users u on u.user_uuid = n.user_uuid and u.domain_uuid = n.domain_uuid '.
			'where n.domain_uuid = :domain_uuid and n.xml_cdr_uuid = :xml_cdr_uuid order by n.insert_date asc limit 500',
			['domain_uuid' => $domain_uuid, 'xml_cdr_uuid' => $xml_cdr_uuid],
			'all'
		) ?: [];
		foreach ($note_rows as $note) {
			$notes[] = [
				'uuid' => $note['note_uuid'],
				'text' => $note['note_text'],
				'offset_seconds' => $note['offset_seconds'] !== null ? (float)$note['offset_seconds'] : null,
				'author' => $note['username'] ?: '',
				'own' => $note['user_uuid'] === ($_SESSION['user_uuid'] ?? ''),
				'created_at' => date('c', strtotime($note['insert_date'])),
				'updated_at' => !empty($note['update_date']) ? date('c', strtotime($note['update_date'])) : null,
			];
		}
	}

	echo json_encode([
		'call_uuid' => $xml_cdr_uuid,
		'tags' => $tags,
		'available_tags' => $available_tags,
		'notes' => $notes,
		'capabilities' => [
			'tag_edit' => permission_exists('portal_call_tag_edit'),
			'tag_assign' => permission_exists('portal_call_tag_assign'),
			'note_add' => permission_exists('portal_call_note_add'),
			'note_edit' => permission_exists('portal_call_note_edit'),
			'note_delete' => permission_exists('portal_call_note_delete'),
		],
		'transcript' => [
			'state' => $state,
			'language' => 'vi',
			'segments' => $segments,
			'summary' => $summary,
			'summary_state' => $summary_state,
			'summary_model' => $summary_model,
			'summary_duration' => $summary_duration,
			'summary_attempt_count' => $summary_attempt_count,
			'engine' => 'local',
			'model' => 'small',
			'updated_at' => $updated_at,
		],
	], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

?>

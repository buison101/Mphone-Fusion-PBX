<?php

	require_once dirname(__DIR__, 3).'/resources/require.php';
	require_once dirname(__DIR__).'/resources/request.php';

	portal_json_headers();
	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
		http_response_code(405);
		echo json_encode(['error' => 'method_not_allowed']);
		exit;
	}
	portal_require_csrf();
	portal_require_session(['xml_cdr_view', 'xml_cdr_transcript_view', 'transcribe_queue_edit']);

	$payload = json_decode(file_get_contents('php://input'), true);
	$xml_cdr_uuid = is_array($payload) ? ($payload['id'] ?? '') : '';
	$domain_uuid = $_SESSION['domain_uuid'] ?? '';
	if (!is_uuid($xml_cdr_uuid) || !is_uuid($domain_uuid)) {
		http_response_code(400);
		echo json_encode(['error' => 'invalid_request']);
		exit;
	}

	$parameters = ['xml_cdr_uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid];
	$scope_sql = '';
	if (!permission_exists('xml_cdr_domain')) {
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

	$transcript = $database->select(
		'select transcript_json, summary_status, summary_duration, update_date, coalesce(summary_attempt_count, 0) as summary_attempt_count '.
		'from v_xml_cdr_transcripts where xml_cdr_uuid = :xml_cdr_uuid and domain_uuid = :domain_uuid limit 1',
		['xml_cdr_uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid],
		'row'
	);
	if (empty($transcript)) {
		http_response_code(409);
		echo json_encode(['error' => 'transcript_unavailable']);
		exit;
	}
	$processing_is_fresh = ($transcript['summary_status'] ?? '') === 'processing'
		&& !empty($transcript['update_date'])
		&& strtotime($transcript['update_date']) > time() - 900;
	if ($processing_is_fresh) {
		http_response_code(409);
		echo json_encode(['error' => 'summary_processing']);
		exit;
	}

	$settings = new settings(['database' => $database, 'domain_uuid' => $domain_uuid]);
	if (!$settings->get('language_model', 'enabled') || !$settings->get('call_recordings', 'summary_enabled')) {
		http_response_code(409);
		echo json_encode(['error' => 'summary_disabled']);
		exit;
	}

	$transcript_json = is_array($transcript['transcript_json'])
		? json_encode($transcript['transcript_json'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
		: (string)$transcript['transcript_json'];
	$transcript_text = trim(strip_tags(transcribe::conversation_format($transcript_json, 'text')));
	$minimum_characters = (int)$settings->get('call_recordings', 'summary_min_characters', 40);
	if (mb_strlen($transcript_text) < $minimum_characters) {
		$database->execute(
			"update v_xml_cdr_transcripts set summary_status = 'skipped', transcript_summary = '', ".
			"summary_last_error = '', update_date = now() where xml_cdr_uuid = :uuid and domain_uuid = :domain_uuid",
			['uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid]
		);
		http_response_code(422);
		echo json_encode(['error' => 'transcript_too_short']);
		exit;
	}

	$attempt_count = (int)$transcript['summary_attempt_count'] + 1;
	$model = $settings->get('call_recordings', 'summary_model_name', 'qwen3-4b');
	$database->execute(
		"update v_xml_cdr_transcripts set summary_status = 'processing', summary_model = :model, ".
		"summary_attempt_count = :attempt_count, summary_last_error = '', update_date = now() ".
		"where xml_cdr_uuid = :uuid and domain_uuid = :domain_uuid",
		['model' => $model, 'attempt_count' => $attempt_count, 'uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid]
	);

	$started = microtime(true);
	try {
		$default_prompt = "Tóm tắt cuộc gọi bằng tiếng Việt theo đúng bốn dòng: Nội dung chính, Kết quả, Việc cần thực hiện, Cảm xúc. Chỉ dùng thông tin có trong hội thoại; ghi 'Không xác định' khi không có dữ liệu. Không suy đoán và không dùng Markdown.";
		$prompt = $settings->get('call_recordings', 'summary_model_prompt', $default_prompt);
		$summary = (new language_model(false, $settings))->request($model, [
			'prompt' => $prompt."```\n".$transcript_text."\n```",
		]);
		$duration = round(microtime(true) - $started, 1);
		$database->execute(
			"update v_xml_cdr_transcripts set transcript_summary = :summary, summary_status = 'completed', ".
			"summary_duration = :duration, summary_last_error = '', update_date = now() ".
			"where xml_cdr_uuid = :uuid and domain_uuid = :domain_uuid",
			['summary' => $summary, 'duration' => $duration, 'uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid]
		);
		echo json_encode(['status' => 'completed', 'duration' => $duration]);
	}
	catch (Throwable $exception) {
		$duration = round(microtime(true) - $started, 1);
		$error = preg_replace('/[\r\n\t]+/', ' ', $exception->getMessage());
		$error = mb_substr($error, 0, 500);
		$database->execute(
			"update v_xml_cdr_transcripts set summary_status = 'failed', summary_duration = :duration, ".
			"summary_last_error = :error, update_date = now() where xml_cdr_uuid = :uuid and domain_uuid = :domain_uuid",
			['duration' => $duration, 'error' => $error, 'uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid]
		);
		error_log('Portal summary retry failed for '.$xml_cdr_uuid.': '.$error);
		http_response_code(502);
		echo json_encode(['error' => 'summary_failed']);
	}

?>

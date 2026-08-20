<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/report_scope.php';

	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');
	header('X-Content-Type-Options: nosniff');
	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') { http_response_code(405); echo json_encode(['error' => 'method_not_allowed']); exit; }
	if (empty($_SESSION['authorized']) || empty($_SESSION['user_uuid'])) { http_response_code(401); echo json_encode(['error' => 'unauthorized']); exit; }
	if (!permission_exists('portal_view') || !permission_exists('xml_cdr_view') || !permission_exists('xml_cdr_recording')) { http_response_code(403); echo json_encode(['error' => 'forbidden']); exit; }

	try { $context = portal_report_context(); }
	catch (InvalidArgumentException $exception) { http_response_code(400); echo json_encode(['error' => $exception->getMessage()]); exit; }

	$page = max(1, (int) ($_GET['page'] ?? 1));
	$page_size = (int) ($_GET['page_size'] ?? 20);
	if (!in_array($page_size, [20, 50, 100], true)) { $page_size = 20; }
	$parameters = $context['parameters'];
	$conditions = "and c.record_name is not null and c.record_name <> '' and c.record_path is not null and c.record_path <> '' ";
	if (!empty($_GET['q'])) {
		$needle = substr(trim((string) $_GET['q']), 0, 64);
		if ($needle !== '') { $conditions .= 'and (c.caller_id_number ilike :needle or c.caller_id_name ilike :needle or c.destination_number ilike :needle) '; $parameters['needle'] = '%' . $needle . '%'; }
	}
	$where = $context['where'] . $conditions;
	$database = new database;
	$total = (int) $database->select('select count(*) from v_xml_cdr c ' . $where, $parameters, 'column');
	$pages = (int) ceil($total / $page_size);
	if ($pages > 0 && $page > $pages) { $page = $pages; }

	$sql = "select date_trunc('day', c.start_stamp) as bucket, count(*) as recordings, coalesce(sum(c.billsec), 0) as duration, count(*) filter(where nullif(c.record_transcription, '') is not null) as transcripts from v_xml_cdr c ";
	$sql .= $where . 'group by bucket order by bucket';
	$daily_rows = $database->select($sql, $parameters, 'all') ?? [];
	$daily = [];
	foreach ($daily_rows as $row) { $daily[] = ['bucket' => date('c', strtotime($row['bucket'])), 'recordings' => (int) $row['recordings'], 'duration' => (int) $row['duration'], 'transcripts' => (int) $row['transcripts']]; }

	$sql = "select case when c.billsec < 60 then 'under_1m' when c.billsec < 180 then '1_3m' when c.billsec < 600 then '3_10m' else 'over_10m' end bucket, count(*) recordings from v_xml_cdr c ";
	$distribution_rows = $database->select($sql . $where . 'group by bucket order by min(c.billsec)', $parameters, 'all') ?? [];
	$duration_distribution = array_map(fn($row) => ['bucket' => $row['bucket'], 'recordings' => (int) $row['recordings']], $distribution_rows);

	$sql = "select coalesce(e.extension, c.extension_uuid::text, '—') as extension, count(*) as recordings, coalesce(sum(c.billsec), 0) as duration from v_xml_cdr c left join v_extensions e on e.extension_uuid = c.extension_uuid and e.domain_uuid = c.domain_uuid ";
	$sql .= $where . 'group by e.extension, c.extension_uuid order by duration desc limit 12';
	$extension_rows = $database->select($sql, $parameters, 'all') ?? [];
	$by_extension = array_map(fn($row) => ['extension' => $row['extension'], 'recordings' => (int) $row['recordings'], 'duration' => (int) $row['duration']], $extension_rows);

	$parameters['page_size'] = $page_size;
	$parameters['page_offset'] = ($page - 1) * $page_size;
	$sql = 'select c.xml_cdr_uuid, c.extension_uuid, e.extension, c.start_stamp, c.direction, c.caller_id_name, c.caller_id_number, c.destination_number, c.billsec, c.record_length, c.record_transcription, c.record_path, c.record_name from v_xml_cdr c left join v_extensions e on e.extension_uuid = c.extension_uuid and e.domain_uuid = c.domain_uuid ';
	$sql .= $where . 'order by c.start_stamp desc limit :page_size offset :page_offset';
	$result = $database->select($sql, $parameters, 'all') ?? [];
	$rows = [];
	$storage_bytes = 0;
	foreach ($result as $row) {
		$directory = realpath($row['record_path']);
		$file = $directory === false ? false : realpath($directory . DIRECTORY_SEPARATOR . basename($row['record_name']));
		$available = $file !== false && strpos($file, $directory . DIRECTORY_SEPARATOR) === 0 && is_readable($file);
		$file_size = $available ? (int) filesize($file) : 0;
		$storage_bytes += $file_size;
		$rows[] = [
			'uuid' => $row['xml_cdr_uuid'], 'extension_uuid' => $row['extension_uuid'], 'extension' => $row['extension'] ?? '',
			'start_stamp' => date('c', strtotime($row['start_stamp'])), 'direction' => $row['direction'] ?? '',
			'remote_party' => $row['direction'] === 'outbound' ? ($row['destination_number'] ?? '') : ($row['caller_id_number'] ?? ''),
			'remote_name' => $row['caller_id_name'] ?? '', 'duration' => (int) $row['billsec'], 'file_size' => $file_size,
			'format' => strtolower(pathinfo($row['record_name'], PATHINFO_EXTENSION)), 'state' => $available ? 'available' : 'missing',
			'transcription' => !empty($row['record_transcription']),
		];
	}

	$duration_total = array_sum(array_column($daily, 'duration'));
	$transcript_total = array_sum(array_column($daily, 'transcripts'));
	$today = date('Y-m-d');
	$today_count = 0;
	foreach ($daily as $row) { if (substr($row['bucket'], 0, 10) === $today) { $today_count = $row['recordings']; } }
	echo json_encode([
		'available' => true, 'scope' => $context['scope'], 'from' => $context['from'], 'to' => $context['to'],
		'totals' => ['recordings' => $total, 'duration' => $duration_total, 'today' => $today_count, 'transcripts' => $transcript_total, 'page_storage_bytes' => $storage_bytes],
		'daily' => $daily, 'by_extension' => $by_extension, 'duration_distribution' => $duration_distribution, 'page' => $page, 'page_size' => $page_size, 'pages' => $pages, 'rows' => $rows,
		'capabilities' => ['play' => permission_exists('xml_cdr_recording_play'), 'download' => permission_exists('xml_cdr_recording_download')],
	], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/request.php';
	require_once dirname(__DIR__) . '/resources/report_scope.php';
	require_once dirname(__DIR__) . '/resources/call_status.php';

	portal_json_headers();
	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') { http_response_code(405); echo json_encode(['error' => 'method_not_allowed']); exit; }
	portal_require_session(['xml_cdr_view']);
	try { $context = portal_report_context(); }
	catch (InvalidArgumentException $exception) { http_response_code(400); echo json_encode(['error' => $exception->getMessage()]); exit; }

	$page = max(1, (int) ($_GET['page'] ?? 1));
	$page_size = (int) ($_GET['page_size'] ?? 20);
	if (!in_array($page_size, [20, 50, 100], true)) { $page_size = 20; }
	$parameters = $context['parameters'];
	$callback_scope = permission_exists('xml_cdr_domain') ? '' : 'and o.extension_uuid in (select extension_uuid from v_extension_users where user_uuid = :portal_user_uuid) ';
	if (!permission_exists('xml_cdr_domain')) { $parameters['portal_user_uuid'] = $_SESSION['user_uuid']; }
	$status_sql = portal_call_status_sql('c');
	$normalized_caller = "regexp_replace(coalesce(c.caller_id_number,''), '[^0-9]+', '', 'g')";
	$normalized_outbound = "regexp_replace(coalesce(o.destination_number,''), '[^0-9]+', '', 'g')";
	$base = "from v_xml_cdr c left join lateral (select o.start_stamp, o.billsec, (" . portal_call_status_sql('o') . ") callback_status from v_xml_cdr o where o.domain_uuid=c.domain_uuid and o.direction='outbound' and o.start_stamp>c.start_stamp and " . $normalized_outbound . '=' . $normalized_caller . ' ' . $callback_scope . 'order by o.start_stamp asc limit 1) callback on true ';
	$where = $context['where'] . "and (" . $status_sql . ")='missed' and " . $normalized_caller . "<>'' ";
	$database = new database;
	$total = (int) $database->select('select count(*) ' . $base . $where, $parameters, 'column');
	$summary_sql = "select count(*) filter(where callback.start_stamp is null) open, count(*) filter(where callback.start_stamp is not null and callback.billsec<30) called_back, count(*) filter(where callback.billsec>=30) resolved, count(*) filter(where callback.start_stamp is null and c.start_stamp<now()-interval '24 hours') overdue, coalesce(avg(extract(epoch from callback.start_stamp-c.start_stamp)) filter(where callback.start_stamp is not null),0) average_callback_seconds ";
	$summary = $database->select($summary_sql . $base . $where, $parameters, 'row') ?: [];
	$chart_parameters = $context['parameters'];
	$daily_rows = $database->select("select date_trunc('day',c.start_stamp) bucket,count(*) calls from v_xml_cdr c " . $where . 'group by bucket order by bucket', $chart_parameters, 'all') ?: [];
	$hour_rows = $database->select("select extract(hour from c.start_stamp)::int hour_of_day,count(*) calls from v_xml_cdr c " . $where . 'group by hour_of_day order by hour_of_day', $chart_parameters, 'all') ?: [];
	$pages = (int) ceil($total / $page_size);
	if ($pages > 0 && $page > $pages) { $page = $pages; }
	$parameters['page_size'] = $page_size;
	$parameters['page_offset'] = ($page - 1) * $page_size;
	$sql = 'select c.xml_cdr_uuid, c.extension_uuid, e.extension, c.start_stamp, c.caller_id_name, c.caller_id_number, c.caller_destination, c.call_center_queue_uuid, q.queue_name, callback.start_stamp callback_stamp, callback.billsec callback_billsec, callback.callback_status, ';
	$sql .= '(select count(*) from v_xml_cdr m where m.domain_uuid=c.domain_uuid and m.start_stamp<=c.start_stamp and regexp_replace(coalesce(m.caller_id_number,\'\'), \'[^0-9]+\', \'\', \'g\')=' . $normalized_caller . " and (" . portal_call_status_sql('m') . ")='missed') missed_attempts ";
	$sql .= $base . 'left join v_extensions e on e.extension_uuid=c.extension_uuid and e.domain_uuid=c.domain_uuid left join v_call_center_queues q on q.call_center_queue_uuid=c.call_center_queue_uuid and q.domain_uuid=c.domain_uuid ';
	$sql .= $where . 'order by c.start_stamp desc limit :page_size offset :page_offset';
	$result = $database->select($sql, $parameters, 'all');
	if (!is_array($result)) { $result = []; }
	$rows = [];
	$kpis = ['open' => (int) ($summary['open'] ?? 0), 'called_back' => (int) ($summary['called_back'] ?? 0), 'resolved' => (int) ($summary['resolved'] ?? 0), 'overdue' => (int) ($summary['overdue'] ?? 0), 'average_callback_seconds' => (int) round((float) ($summary['average_callback_seconds'] ?? 0))];
	foreach ($result as $row) {
		$callback_seconds = !empty($row['callback_stamp']) ? max(0, strtotime($row['callback_stamp']) - strtotime($row['start_stamp'])) : null;
		if (!empty($row['callback_stamp']) && (int) $row['callback_billsec'] >= 30) { $state = 'resolved'; }
		elseif (!empty($row['callback_stamp'])) { $state = 'called_back'; }
		else { $state = 'open'; }
		$overdue = $state === 'open' && strtotime($row['start_stamp']) < time() - 86400;
		$rows[] = ['uuid' => $row['xml_cdr_uuid'], 'extension_uuid' => $row['extension_uuid'], 'extension' => $row['extension'] ?? '', 'start_stamp' => date('c', strtotime($row['start_stamp'])), 'caller_name' => $row['caller_id_name'] ?? '', 'caller_number' => $row['caller_id_number'] ?? '', 'did' => $row['caller_destination'] ?? '', 'queue' => $row['queue_name'] ?? '', 'attempts' => (int) $row['missed_attempts'], 'callback_stamp' => !empty($row['callback_stamp']) ? date('c', strtotime($row['callback_stamp'])) : null, 'callback_seconds' => $callback_seconds, 'callback_result' => $row['callback_status'] ?? '', 'state' => $state, 'overdue' => $overdue];
	}
	$daily = array_map(fn($row) => ['bucket' => date('c', strtotime($row['bucket'])), 'calls' => (int) $row['calls']], $daily_rows);
	$hour_map = [];
	foreach ($hour_rows as $row) { $hour_map[(int) $row['hour_of_day']] = (int) $row['calls']; }
	$hourly = [];
	for ($hour = 0; $hour < 24; $hour++) { $hourly[] = ['hour' => $hour, 'calls' => $hour_map[$hour] ?? 0]; }

	echo json_encode(['available' => true, 'scope' => $context['scope'], 'from' => $context['from'], 'to' => $context['to'], 'definitions' => ['callback' => 'first later outbound call to the normalized caller number', 'resolved' => 'callback billsec >= 30 seconds', 'overdue' => 'open for more than 24 hours'], 'kpis' => $kpis, 'daily' => $daily, 'hourly' => $hourly, 'page' => $page, 'page_size' => $page_size, 'pages' => $pages, 'total' => $total, 'rows' => $rows], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

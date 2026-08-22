<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/call_status.php';
	require_once dirname(__DIR__) . '/resources/report_scope.php';

	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');
	header('X-Content-Type-Options: nosniff');
	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') { http_response_code(405); echo json_encode(['error' => 'method_not_allowed']); exit; }
	portal_identity_validate_session();
	if (empty($_SESSION['authorized']) || empty($_SESSION['user_uuid'])) { http_response_code(401); echo json_encode(['error' => 'unauthorized']); exit; }
	if (!permission_exists('portal_view') || !permission_exists('xml_cdr_view')) { http_response_code(403); echo json_encode(['error' => 'forbidden']); exit; }

	$report = $_GET['report'] ?? 'volume';
	if (!in_array($report, ['volume', 'extensions', 'inbound', 'outbound', 'time', 'dimensions'], true)) { http_response_code(400); echo json_encode(['error' => 'invalid_report']); exit; }
	try { $context = portal_report_context(); }
	catch (InvalidArgumentException $exception) { http_response_code(400); echo json_encode(['error' => $exception->getMessage()]); exit; }

	$database = new database;
	$status_sql = portal_call_status_sql('c');
	$where = $context['where'];
	$parameters = $context['parameters'];
	$data = [];
	$definitions = [];

	if ($report === 'volume') {
		$group = $_GET['group'] ?? 'day';
		if (!in_array($group, ['hour', 'day', 'week', 'month'], true)) { $group = 'day'; }
		$sql = "select date_trunc('" . $group . "', c.start_stamp) bucket, count(*) total, count(*) filter(where c.direction='inbound') inbound, count(*) filter(where c.direction='outbound') outbound, count(*) filter(where (" . $status_sql . ")='answered') answered, count(*) filter(where c.direction='inbound' and (" . $status_sql . ")='answered') answered_inbound, count(*) filter(where (" . $status_sql . ")='missed') missed, coalesce(sum(c.billsec),0) talk_seconds, count(*) filter(where c.billsec>0) talked from v_xml_cdr c ";
		$sql .= $where . 'group by bucket order by bucket';
		$rows = $database->select($sql, $parameters, 'all') ?? [];
		foreach ($rows as $row) {
			$data[] = ['bucket' => date('c', strtotime($row['bucket'])), 'total' => (int) $row['total'], 'inbound' => (int) $row['inbound'], 'outbound' => (int) $row['outbound'], 'answered' => (int) $row['answered'], 'missed' => (int) $row['missed'], 'answer_rate' => (int) $row['inbound'] > 0 ? round(((int) $row['answered_inbound'] / (int) $row['inbound']) * 100, 1) : null, 'average_talk' => (int) $row['talked'] > 0 ? (int) round((int) $row['talk_seconds'] / (int) $row['talked']) : 0];
		}
		$definitions = ['answer_rate' => 'answered / inbound × 100', 'average_talk' => 'total billsec / calls with billsec > 0'];
	}
	elseif ($report === 'extensions') {
		$sql = "select c.extension_uuid, coalesce(e.extension, c.extension_uuid::text, '—') extension, count(*) total, count(*) filter(where c.direction='inbound') inbound, count(*) filter(where c.direction='outbound') outbound, count(*) filter(where (" . $status_sql . ")='answered') answered, count(*) filter(where c.direction='inbound' and (" . $status_sql . ")='answered') answered_inbound, count(*) filter(where (" . $status_sql . ")='missed') missed, coalesce(sum(c.billsec),0) talk_seconds, count(*) filter(where c.billsec>0) talked from v_xml_cdr c left join v_extensions e on e.extension_uuid=c.extension_uuid and e.domain_uuid=c.domain_uuid ";
		$sql .= $where . 'group by c.extension_uuid,e.extension order by total desc limit 100';
		$rows = $database->select($sql, $parameters, 'all') ?? [];
		foreach ($rows as $row) { $data[] = ['extension_uuid' => $row['extension_uuid'], 'extension' => $row['extension'], 'total' => (int) $row['total'], 'inbound' => (int) $row['inbound'], 'outbound' => (int) $row['outbound'], 'answered' => (int) $row['answered'], 'missed' => (int) $row['missed'], 'talk_seconds' => (int) $row['talk_seconds'], 'average_talk' => (int) $row['talked'] > 0 ? (int) round((int) $row['talk_seconds'] / (int) $row['talked']) : 0, 'answer_rate' => (int) $row['inbound'] > 0 ? round(((int) $row['answered_inbound'] / (int) $row['inbound']) * 100, 1) : null]; }
		$definitions = ['extension' => 'FusionPBX extension associated with the CDR leg', 'answer_rate' => 'answered / inbound × 100'];
	}
	elseif ($report === 'inbound') {
		$sla = max(1, min((int) ($_GET['sla'] ?? 20), 300));
		$parameters['sla'] = $sla;
		$sql = "select count(*) total, count(*) filter(where (" . $status_sql . ")='answered') answered, count(*) filter(where (" . $status_sql . ")='missed') missed, coalesce(avg(c.waitsec),0) average_wait, coalesce(max(c.waitsec),0) maximum_wait, count(*) filter(where (" . $status_sql . ")='answered' and c.waitsec<=:sla) within_sla from v_xml_cdr c ";
		$row = $database->select($sql . $where . "and c.direction='inbound'", $parameters, 'row') ?? [];
		$buckets_sql = "select case when c.waitsec<10 then '0-9' when c.waitsec<20 then '10-19' when c.waitsec<40 then '20-39' when c.waitsec<60 then '40-59' else '60+' end bucket, count(*) total, count(*) filter(where (" . $status_sql . ")='answered') answered, count(*) filter(where (" . $status_sql . ")<>'answered') abandoned from v_xml_cdr c ";
		$bucket_parameters = $parameters;
		unset($bucket_parameters['sla']);
		$buckets = $database->select($buckets_sql . $where . "and c.direction='inbound' group by bucket order by min(c.waitsec)", $bucket_parameters, 'all');
		if (!is_array($buckets)) { $buckets = []; }
		$data = ['totals' => ['total' => (int) ($row['total'] ?? 0), 'answered' => (int) ($row['answered'] ?? 0), 'missed' => (int) ($row['missed'] ?? 0), 'answer_rate' => (int) ($row['total'] ?? 0) > 0 ? round(((int) $row['answered'] / (int) $row['total']) * 100, 1) : null, 'average_wait' => (int) round((float) ($row['average_wait'] ?? 0)), 'maximum_wait' => (int) ($row['maximum_wait'] ?? 0), 'within_sla' => (int) ($row['within_sla'] ?? 0), 'sla_seconds' => $sla], 'buckets' => array_map(fn($item) => ['bucket' => $item['bucket'], 'total' => (int) $item['total'], 'answered' => (int) $item['answered'], 'abandoned' => (int) $item['abandoned']], $buckets)];
		$definitions = ['sla' => 'answered inbound calls with waitsec ≤ configured threshold', 'abandoned' => 'inbound status other than answered'];
	}
	elseif ($report === 'outbound') {
		$success = max(1, min((int) ($_GET['success_seconds'] ?? 30), 3600));
		$parameters['success'] = $success;
		$sql = "select count(*) total, count(*) filter(where c.billsec>0) connected, count(*) filter(where c.billsec>=:success) successful, count(distinct c.destination_number) unique_numbers, coalesce(avg(c.billsec) filter(where c.billsec>0),0) average_talk from v_xml_cdr c ";
		$row = $database->select($sql . $where . "and c.direction='outbound'", $parameters, 'row') ?? [];
		$sql = "select c.destination_number number, count(*) calls, count(*) filter(where c.billsec>0) connected, count(*) filter(where c.billsec>=:success) successful, coalesce(sum(c.billsec),0) talk_seconds, max(c.start_stamp) latest from v_xml_cdr c ";
		$rows = $database->select($sql . $where . "and c.direction='outbound' group by c.destination_number order by calls desc limit 100", $parameters, 'all') ?? [];
		$data = ['totals' => ['total' => (int) ($row['total'] ?? 0), 'connected' => (int) ($row['connected'] ?? 0), 'successful' => (int) ($row['successful'] ?? 0), 'success_rate' => (int) ($row['total'] ?? 0) > 0 ? round(((int) $row['successful'] / (int) $row['total']) * 100, 1) : null, 'unique_numbers' => (int) ($row['unique_numbers'] ?? 0), 'average_talk' => (int) round((float) ($row['average_talk'] ?? 0)), 'success_seconds' => $success], 'numbers' => array_map(fn($item) => ['number' => $item['number'], 'calls' => (int) $item['calls'], 'connected' => (int) $item['connected'], 'successful' => (int) $item['successful'], 'talk_seconds' => (int) $item['talk_seconds'], 'latest' => date('c', strtotime($item['latest']))], $rows)];
		$definitions = ['connected' => 'billsec > 0', 'successful' => 'billsec ≥ configured minimum (' . $success . ' seconds)'];
	}
	elseif ($report === 'time') {
		$sql = "select extract(isodow from c.start_stamp)::int weekday, extract(hour from c.start_stamp)::int hour_of_day, count(*) total, count(*) filter(where c.direction='inbound') inbound, count(*) filter(where (" . $status_sql . ")='missed') missed, coalesce(avg(c.waitsec),0) average_wait from v_xml_cdr c ";
		$rows = $database->select($sql . $where . 'group by weekday,hour_of_day order by weekday,hour_of_day', $parameters, 'all') ?? [];
		foreach ($rows as $row) { $data[] = ['weekday' => (int) $row['weekday'], 'hour' => (int) $row['hour_of_day'], 'total' => (int) $row['total'], 'inbound' => (int) $row['inbound'], 'missed' => (int) $row['missed'], 'missed_rate' => (int) $row['total'] > 0 ? round(((int) $row['missed'] / (int) $row['total']) * 100, 1) : 0, 'average_wait' => (int) round((float) $row['average_wait'])]; }
		$definitions = ['weekday' => 'ISO weekday: Monday = 1, Sunday = 7', 'missed_rate' => 'missed / total × 100'];
	}
	else {
		$sql = "select nullif(c.caller_destination,'') did, count(*) total, count(*) filter(where (" . $status_sql . ")='answered') answered, count(*) filter(where (" . $status_sql . ")='missed') missed, coalesce(avg(c.waitsec),0) average_wait, coalesce(sum(c.billsec),0) talk_seconds from v_xml_cdr c ";
		$dids = $database->select($sql . $where . "and c.direction='inbound' and nullif(c.caller_destination,'') is not null group by did order by total desc", $parameters, 'all') ?? [];
		$sql = "select c.call_center_queue_uuid uuid, q.queue_name name, 'queue' kind, count(*) total, count(*) filter(where (" . $status_sql . ")='answered') answered, count(*) filter(where (" . $status_sql . ")<>'answered') missed, coalesce(avg(c.waitsec),0) average_wait, coalesce(max(c.waitsec),0) maximum_wait from v_xml_cdr c join v_call_center_queues q on q.call_center_queue_uuid=c.call_center_queue_uuid and q.domain_uuid=c.domain_uuid ";
		$queues = $database->select($sql . $where . "and c.direction='inbound' group by c.call_center_queue_uuid,q.queue_name order by total desc", $parameters, 'all') ?? [];
		$sql = "select c.ring_group_uuid uuid, r.ring_group_name name, 'ring_group' kind, count(*) total, count(*) filter(where (" . $status_sql . ")='answered') answered, count(*) filter(where (" . $status_sql . ")<>'answered') missed, coalesce(avg(c.waitsec),0) average_wait, coalesce(max(c.waitsec),0) maximum_wait from v_xml_cdr c join v_ring_groups r on r.ring_group_uuid=c.ring_group_uuid and r.domain_uuid=c.domain_uuid ";
		$rings = $database->select($sql . $where . "and c.direction='inbound' group by c.ring_group_uuid,r.ring_group_name order by total desc", $parameters, 'all') ?? [];
		$data = ['dids' => array_map(fn($row) => ['did' => $row['did'], 'total' => (int) $row['total'], 'answered' => (int) $row['answered'], 'missed' => (int) $row['missed'], 'answer_rate' => (int) $row['total'] > 0 ? round(((int) $row['answered'] / (int) $row['total']) * 100, 1) : null, 'average_wait' => (int) round((float) $row['average_wait']), 'talk_seconds' => (int) $row['talk_seconds']], $dids), 'groups' => array_map(fn($row) => ['uuid' => $row['uuid'], 'name' => $row['name'], 'kind' => $row['kind'], 'total' => (int) $row['total'], 'answered' => (int) $row['answered'], 'missed' => (int) $row['missed'], 'answer_rate' => (int) $row['total'] > 0 ? round(((int) $row['answered'] / (int) $row['total']) * 100, 1) : null, 'average_wait' => (int) round((float) $row['average_wait']), 'maximum_wait' => (int) $row['maximum_wait']], array_merge($queues, $rings))];
		$definitions = ['did' => 'caller_destination on inbound CDR', 'group' => 'FusionPBX Queue or Ring Group UUID associated with CDR'];
	}

	echo json_encode(['available' => true, 'report' => $report, 'scope' => $context['scope'], 'from' => $context['from'], 'to' => $context['to'], 'definitions' => $definitions, 'data' => $data], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

<?php
/*
	FusionPBX
	Version: MPL 1.1

	The contents of this file are subject to the Mozilla Public License Version
	1.1 (the "License"); you may not use this file except in compliance with
	the License. You may obtain a copy of the License at
	http://www.mozilla.org/MPL/

	Software distributed under the License is distributed on an "AS IS" basis,
	WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
	for the specific language governing rights and limitations under the
	License.

	The Original Code is FusionPBX

	Paged call history for the customer portal. Read only.

	Scope follows the rule the CDR page uses: without xml_cdr_domain a user sees
	only the extensions assigned to them. Every query is pinned to domain_uuid.
*/

	require_once dirname(__DIR__, 3) . "/resources/require.php";
	require_once dirname(__DIR__) . "/resources/call_status.php";

	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');
	header('X-Content-Type-Options: nosniff');

	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
		http_response_code(405);
		echo json_encode(['error' => 'method_not_allowed']);
		exit;
	}

	if (empty($_SESSION['authorized']) || empty($_SESSION['user_uuid'])) {
		http_response_code(401);
		echo json_encode(['error' => 'unauthorized', 'login_url' => PROJECT_PATH . '/']);
		exit;
	}

	if (!permission_exists('portal_view') || !permission_exists('xml_cdr_view')) {
		http_response_code(403);
		echo json_encode(['error' => 'forbidden']);
		exit;
	}

	$domain_uuid = $_SESSION['domain_uuid'] ?? '';
	if (!is_uuid($domain_uuid)) {
		http_response_code(400);
		echo json_encode(['error' => 'invalid_domain']);
		exit;
	}

//paging, clamped so a crafted request cannot ask for an unbounded page
	$page = (int) ($_GET['page'] ?? 1);
	if ($page < 1) { $page = 1; }
	$page_size = (int) ($_GET['page_size'] ?? 20);
	if (!in_array($page_size, [20, 50, 100], true)) { $page_size = 20; }

	$conditions = [];
	$parameters = ['domain_uuid' => $domain_uuid];

//scope
	$scope = 'domain';
	if (!permission_exists('xml_cdr_domain')) {
		$scope = 'extensions';
		$extension_uuids = [];
		if (!empty($_SESSION['user']['extension']) && is_array($_SESSION['user']['extension'])) {
			foreach ($_SESSION['user']['extension'] as $row) {
				if (!empty($row['extension_uuid']) && is_uuid($row['extension_uuid'])) {
					$extension_uuids[] = $row['extension_uuid'];
				}
			}
			unset($row);
		}

		if (empty($extension_uuids)) {
			echo json_encode([
				'available' => true,
				'scope' => $scope,
				'page' => 1,
				'page_size' => $page_size,
				'total' => 0,
				'pages' => 0,
				'rows' => [],
				'recordings' => false,
				'capabilities' => [
					'recording_play' => false,
					'recording_download' => false,
					'csv_export' => permission_exists('xml_cdr_export_csv'),
				],
			]);
			exit;
		}

		$placeholders = [];
		foreach ($extension_uuids as $index => $uuid) {
			$key = 'extension_uuid_' . $index;
			$placeholders[] = ':' . $key;
			$parameters[$key] = $uuid;
		}
		$conditions[] = "extension_uuid in (" . implode(', ', $placeholders) . ")";
		unset($placeholders, $index, $uuid, $key);
	}

//date range, accepted as plain dates and widened to cover the whole end day
	if (!empty($_GET['from']) && strtotime($_GET['from']) !== false) {
		$conditions[] = "start_stamp >= :from_stamp";
		$parameters['from_stamp'] = date('Y-m-d H:i:sO', strtotime($_GET['from'] . ' 00:00:00'));
	}
	if (!empty($_GET['to']) && strtotime($_GET['to']) !== false) {
		$conditions[] = "start_stamp <= :to_stamp";
		$parameters['to_stamp'] = date('Y-m-d H:i:sO', strtotime($_GET['to'] . ' 23:59:59'));
	}

//direction
	if (!empty($_GET['direction']) && in_array($_GET['direction'], ['inbound', 'outbound', 'local'], true)) {
		$conditions[] = "direction = :direction";
		$parameters['direction'] = $_GET['direction'];
	}

//extension selection is always combined with the domain and user scope above
	if (!empty($_GET['extension_uuid']) && is_uuid($_GET['extension_uuid'])) {
		$conditions[] = "extension_uuid = :selected_extension_uuid";
		$parameters['selected_extension_uuid'] = $_GET['extension_uuid'];
	}

//status, filtered against the same expression the rows are labelled with, so the
//filter and the badge can never disagree
	$status_sql = portal_call_status_sql();
	if (!empty($_GET['status']) && in_array($_GET['status'], portal_call_statuses(), true)) {
		$conditions[] = "(" . $status_sql . ") = :status";
		$parameters['status'] = $_GET['status'];
	}

//free text over the three number fields a customer would search by
	if (!empty($_GET['q'])) {
		$needle = substr(trim((string) $_GET['q']), 0, 64);
		if ($needle !== '') {
			$conditions[] = "(caller_id_number ilike :needle or caller_id_name ilike :needle or destination_number ilike :needle)";
			$parameters['needle'] = '%' . $needle . '%';
		}
	}

//bounded duration filters, expressed in seconds
	foreach (['wait_min' => 'waitsec >=', 'wait_max' => 'waitsec <=', 'talk_min' => 'billsec >=', 'talk_max' => 'billsec <='] as $key => $expression) {
		if (isset($_GET[$key]) && $_GET[$key] !== '' && is_numeric($_GET[$key])) {
			$value = max(0, min((int) $_GET[$key], 86400));
			$conditions[] = $expression . ' :' . $key;
			$parameters[$key] = $value;
		}
	}
	unset($key, $expression, $value);

	if (!empty($_GET['recording']) && in_array($_GET['recording'], ['yes', 'no'], true)) {
		$conditions[] = $_GET['recording'] === 'yes'
			? "(record_name is not null and record_name <> '' and record_path is not null and record_path <> '')"
			: "(record_name is null or record_name = '' or record_path is null or record_path = '')";
	}

	if (!empty($_GET['tag_uuid']) && is_uuid($_GET['tag_uuid']) && permission_exists('portal_call_tag_view')) {
		$conditions[] = 'exists(select 1 from v_portal_call_tag_assignments pta where pta.domain_uuid = :domain_uuid and pta.xml_cdr_uuid = v_xml_cdr.xml_cdr_uuid and pta.tag_uuid = :tag_uuid)';
		$parameters['tag_uuid'] = $_GET['tag_uuid'];
	}
	if (!empty($_GET['has_note']) && in_array($_GET['has_note'], ['yes', 'no'], true) && permission_exists('portal_call_note_view')) {
		$note_exists = 'exists(select 1 from v_portal_call_notes pn where pn.domain_uuid = :domain_uuid and pn.xml_cdr_uuid = v_xml_cdr.xml_cdr_uuid)';
		$conditions[] = $_GET['has_note'] === 'yes' ? $note_exists : 'not '.$note_exists;
	}
	if (!empty($_GET['has_transcript']) && in_array($_GET['has_transcript'], ['yes', 'no'], true) && permission_exists('xml_cdr_transcript_view')) {
		$transcript_exists = 'exists(select 1 from v_xml_cdr_transcripts pt where pt.domain_uuid = :domain_uuid and pt.xml_cdr_uuid = v_xml_cdr.xml_cdr_uuid)';
		$conditions[] = $_GET['has_transcript'] === 'yes' ? $transcript_exists : 'not '.$transcript_exists;
	}
	if (!empty($_GET['has_summary']) && in_array($_GET['has_summary'], ['yes', 'no'], true) && permission_exists('xml_cdr_transcript_view')) {
		$summary_exists = "exists(select 1 from v_xml_cdr_transcripts ps where ps.domain_uuid = :domain_uuid and ps.xml_cdr_uuid = v_xml_cdr.xml_cdr_uuid and nullif(ps.transcript_summary, '') is not null)";
		$conditions[] = $_GET['has_summary'] === 'yes' ? $summary_exists : 'not '.$summary_exists;
	}

	$where = "where domain_uuid = :domain_uuid ";
	if (!empty($conditions)) {
		$where .= "and " . implode(" and ", $conditions) . " ";
	}

	$database = new database;

	$total = (int) $database->select("select count(*) as total from v_xml_cdr " . $where, $parameters, 'column');
	$pages = $page_size > 0 ? (int) ceil($total / $page_size) : 0;
	if ($pages > 0 && $page > $pages) { $page = $pages; }

	$recordings_allowed = permission_exists('xml_cdr_recording')
		&& (permission_exists('xml_cdr_recording_play') || permission_exists('xml_cdr_recording_download'));

	$select = "select xml_cdr_uuid, extension_uuid, direction, caller_id_name, caller_id_number, caller_destination, ";
	$select .= "destination_number, start_stamp, answer_stamp, end_stamp, duration, billsec, waitsec, ";
	$select .= "missed_call, hangup_cause, hangup_cause_q850, sip_hangup_disposition, ";
	$select .= "record_name, record_path, record_length, record_transcription, ";
	$select .= "call_center_queue_uuid, cc_agent_uuid, ring_group_uuid, ivr_menu_uuid, ";
	if (permission_exists('portal_call_tag_view')) {
		$select .= "coalesce((select json_agg(json_build_object('uuid', pt.tag_uuid, 'name', pt.name, 'color', pt.color_token) order by pt.tag_order, pt.name) from v_portal_call_tag_assignments pa join v_portal_call_tags pt on pt.tag_uuid = pa.tag_uuid and pt.domain_uuid = pa.domain_uuid where pa.domain_uuid = v_xml_cdr.domain_uuid and pa.xml_cdr_uuid = v_xml_cdr.xml_cdr_uuid), '[]'::json) as call_tags, ";
	}
	$select .= "(" . $status_sql . ") as call_status ";

//CSV uses the exact same authorized filters as the table and is deliberately capped
	if (($_GET['format'] ?? '') === 'csv') {
		if (!permission_exists('xml_cdr_export_csv')) {
			http_response_code(403);
			echo json_encode(['error' => 'forbidden']);
			exit;
		}
		$export_parameters = $parameters;
		$export_parameters['export_limit'] = 10000;
		$export_rows = $database->select($select . "from v_xml_cdr " . $where . "order by start_stamp desc limit :export_limit", $export_parameters, 'all') ?? [];
		header_remove('Content-Type');
		header('Content-Type: text/csv; charset=utf-8');
		header('Content-Disposition: attachment; filename="calls-' . date('Y-m-d-His') . '.csv"');
		$output = fopen('php://output', 'w');
		fputcsv($output, ['date', 'extension_uuid', 'direction', 'caller_name', 'caller_number', 'destination', 'status', 'wait_seconds', 'talk_seconds', 'duration_seconds', 'hangup_cause', 'sip_disposition', 'recording']);
		foreach ($export_rows as $row) {
			fputcsv($output, [
				$row['start_stamp'], $row['extension_uuid'], $row['direction'], $row['caller_id_name'],
				$row['caller_id_number'], $row['destination_number'], $row['call_status'], (int) $row['waitsec'],
				(int) $row['billsec'], (int) $row['duration'], $row['hangup_cause'], $row['sip_hangup_disposition'],
				(!empty($row['record_name']) && !empty($row['record_path'])) ? 'yes' : 'no',
			]);
		}
		fclose($output);
		exit;
	}

	$rows = [];
	if ($total > 0) {
		$sql = $select . "from v_xml_cdr " . $where;
		$sql .= "order by start_stamp desc ";
		$sql .= "limit :page_size offset :page_offset ";
		$parameters['page_size'] = $page_size;
		$parameters['page_offset'] = ($page - 1) * $page_size;
		$result = $database->select($sql, $parameters, 'all') ?? [];

		foreach ($result as $row) {
			$has_recording = $recordings_allowed && !empty($row['record_name']) && !empty($row['record_path']);
			$call_tags = is_array($row['call_tags'] ?? null) ? $row['call_tags'] : (json_decode($row['call_tags'] ?? '[]', true) ?: []);
			$rows[] = [
				'uuid' => $row['xml_cdr_uuid'],
				'extension_uuid' => $row['extension_uuid'] ?? '',
				'direction' => $row['direction'] ?? '',
				'caller_id_name' => $row['caller_id_name'] ?? '',
				'caller_id_number' => $row['caller_id_number'] ?? '',
				'destination_number' => $row['destination_number'] ?? '',
				'caller_destination' => $row['caller_destination'] ?? '',
				'start_stamp' => !empty($row['start_stamp']) ? date('c', strtotime($row['start_stamp'])) : null,
				'answer_stamp' => !empty($row['answer_stamp']) ? date('c', strtotime($row['answer_stamp'])) : null,
				'end_stamp' => !empty($row['end_stamp']) ? date('c', strtotime($row['end_stamp'])) : null,
				'duration' => (int) ($row['duration'] ?? 0),
				'billsec' => (int) ($row['billsec'] ?? 0),
				'waitsec' => (int) ($row['waitsec'] ?? 0),
				//the single value the interface labels and filters on
				'status' => $row['call_status'] ?? 'no_answer',
				'hangup_cause' => $row['hangup_cause'] ?? '',
				'hangup_cause_q850' => $row['hangup_cause_q850'] ?? '',
				'sip_hangup_disposition' => $row['sip_hangup_disposition'] ?? '',
				'call_center_queue_uuid' => $row['call_center_queue_uuid'] ?? '',
				'cc_agent_uuid' => $row['cc_agent_uuid'] ?? '',
				'ring_group_uuid' => $row['ring_group_uuid'] ?? '',
				'ivr_menu_uuid' => $row['ivr_menu_uuid'] ?? '',
				'record_length' => (int) ($row['record_length'] ?? 0),
				'transcription' => !empty($row['record_transcription']),
				//the file itself is never named to the browser, only whether one exists
				'recording' => $has_recording,
				'tags' => $call_tags,
			];
		}
		unset($result, $row);
	}

	$tag_options = permission_exists('portal_call_tag_view')
		? ($database->select('select tag_uuid as uuid, name, color_token as color from v_portal_call_tags where domain_uuid = :domain_uuid and enabled = true order by tag_order, name limit 100', ['domain_uuid' => $domain_uuid], 'all') ?: [])
		: [];

	echo json_encode([
		'available' => true,
		'scope' => $scope,
		'page' => $page,
		'page_size' => $page_size,
		'total' => $total,
		'pages' => $pages,
		'rows' => $rows,
		'recordings' => $recordings_allowed,
		'tag_options' => $tag_options,
		'capabilities' => [
			'recording_play' => permission_exists('xml_cdr_recording_play'),
			'recording_download' => permission_exists('xml_cdr_recording_download'),
			'csv_export' => permission_exists('xml_cdr_export_csv'),
		],
	], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

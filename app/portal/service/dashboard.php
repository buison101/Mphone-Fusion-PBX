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

	Read only call history for the customer portal dashboard. Live call state
	arrives over the websocket, this endpoint supplies what the switch cannot
	report: what already happened.

	Scope follows the rule the CDR page uses. A user without xml_cdr_domain sees
	only the extensions assigned to them, which is what an end customer gets.
*/

//includes files
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

	if (!permission_exists('portal_view')) {
		http_response_code(403);
		echo json_encode(['error' => 'forbidden']);
		exit;
	}

//the dashboard degrades rather than fails when call history is not permitted,
//so the live widgets keep working for a user who may not read the CDR
	if (!permission_exists('xml_cdr_view')) {
		echo json_encode([
			'available' => false,
			'reason' => 'missing_permission',
			'scope' => null,
			'totals' => null,
			'hourly' => [],
			'recent' => [],
		]);
		exit;
	}

//window, capped so a crafted request cannot ask for an unbounded scan
	$hours = (int) ($_GET['hours'] ?? 24);
	if ($hours < 1) { $hours = 24; }
	if (!in_array($hours, [24, 168, 720, 2160], true)) { $hours = 24; }

	$domain_uuid = $_SESSION['domain_uuid'] ?? '';
	if (!is_uuid($domain_uuid)) {
		http_response_code(400);
		echo json_encode(['error' => 'invalid_domain']);
		exit;
	}

//build the scope. xml_cdr_domain widens it to the whole domain, otherwise the
//query is pinned to the extensions this user owns
	$scope = 'domain';
	$scope_sql = '';
	$parameters = ['domain_uuid' => $domain_uuid];

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

		//a user with no extension and no domain permission has nothing to see,
		//answering with an empty result is safer than an unscoped query
		if (empty($extension_uuids)) {
			echo json_encode([
				'available' => true,
				'scope' => $scope,
					'hours' => $hours,
					'totals' => ['calls' => 0, 'answered' => 0, 'answered_inbound' => 0, 'missed' => 0, 'unconnected' => 0, 'inbound' => 0, 'outbound' => 0, 'local' => 0, 'talk_seconds' => 0, 'average_talk_seconds' => 0, 'average_wait_seconds' => 0, 'answer_rate' => null],
					'previous' => [],
					'statuses' => array_fill_keys(portal_call_statuses(), 0),
				'hourly' => [],
				'recent' => [],
			]);
			exit;
		}

		$placeholders = [];
		foreach ($extension_uuids as $index => $uuid) {
			$key = 'extension_uuid_' . $index;
			$placeholders[] = ':' . $key;
			$parameters[$key] = $uuid;
		}
		$scope_sql = "and extension_uuid in (" . implode(', ', $placeholders) . ") ";
		unset($placeholders, $index, $uuid, $key);
	}

	$parameters['hours'] = $hours;
	$window_sql = "and start_stamp >= (now() - (:hours || ' hours')::interval) ";
	$direction = strtolower(trim((string) ($_GET['direction'] ?? '')));
	$direction_sql = '';
	if (in_array($direction, ['inbound', 'outbound', 'local'], true)) {
		$parameters['direction'] = $direction;
		$direction_sql = "and direction = :direction ";
	}
	else {
		$direction = '';
	}

	$database = new database;

//one pass over the window produces both the totals and the hourly series.
//answered is counted from the status column, never from answer_stamp: the switch
//sets an answer stamp on legs that never connected, so counting those would
//report every cancelled call as answered.
	$status_sql = portal_call_status_sql();

	$sql = "select ";
	$bucket = $hours <= 48 ? 'hour' : 'day';
	$sql .= "date_trunc('" . $bucket . "', start_stamp) as bucket, ";
	$sql .= "count(*) as calls, ";
	$sql .= "count(*) filter (where (" . $status_sql . ") = 'answered') as answered, ";
	$sql .= "count(*) filter (where direction = 'inbound' and (" . $status_sql . ") = 'answered') as answered_inbound, ";
	$sql .= "count(*) filter (where (" . $status_sql . ") = 'missed') as missed, ";
	$sql .= "count(*) filter (where (" . $status_sql . ") in ('cancelled', 'no_answer', 'busy', 'failed')) as unconnected, ";
	$sql .= "count(*) filter (where direction = 'inbound') as inbound, ";
	$sql .= "count(*) filter (where direction = 'outbound') as outbound, ";
	$sql .= "count(*) filter (where direction = 'local') as local, ";
	$sql .= "coalesce(sum(billsec), 0) as talk_seconds, ";
	$sql .= "coalesce(sum(waitsec), 0) as wait_seconds, ";
	$sql .= "count(*) filter (where billsec > 0) as talked_calls, ";
	$sql .= "count(*) filter (where waitsec > 0) as waited_calls ";
	$sql .= "from v_xml_cdr ";
	$sql .= "where domain_uuid = :domain_uuid ";
	$sql .= $scope_sql;
	$sql .= $window_sql;
	$sql .= $direction_sql;
	$sql .= "group by bucket ";
	$sql .= "order by bucket asc ";
	$buckets = $database->select($sql, $parameters, 'all') ?? [];

	$totals = ['calls' => 0, 'answered' => 0, 'answered_inbound' => 0, 'missed' => 0, 'unconnected' => 0, 'inbound' => 0, 'outbound' => 0, 'local' => 0, 'talk_seconds' => 0, 'average_talk_seconds' => 0, 'average_wait_seconds' => 0, 'answer_rate' => null];
	$wait_seconds = 0;
	$talked_calls = 0;
	$waited_calls = 0;
	$hourly = [];
	foreach ($buckets as $row) {
		$totals['calls']        += (int) $row['calls'];
		$totals['answered']     += (int) $row['answered'];
		$totals['answered_inbound'] += (int) $row['answered_inbound'];
		$totals['missed']       += (int) $row['missed'];
		$totals['unconnected']  += (int) $row['unconnected'];
		$totals['inbound']      += (int) $row['inbound'];
		$totals['outbound']     += (int) $row['outbound'];
		$totals['local']        += (int) $row['local'];
		$totals['talk_seconds'] += (int) $row['talk_seconds'];
		$wait_seconds           += (int) $row['wait_seconds'];
		$talked_calls           += (int) $row['talked_calls'];
		$waited_calls           += (int) $row['waited_calls'];

		$hourly[] = [
			'bucket' => date('c', strtotime($row['bucket'])),
			'calls' => (int) $row['calls'],
			'answered' => (int) $row['answered'],
			'missed' => (int) $row['missed'],
			'unconnected' => (int) $row['unconnected'],
		];
	}
	unset($buckets, $row);
	$totals['average_talk_seconds'] = $talked_calls > 0 ? (int) round($totals['talk_seconds'] / $talked_calls) : 0;
	$totals['average_wait_seconds'] = $waited_calls > 0 ? (int) round($wait_seconds / $waited_calls) : 0;
	$totals['answer_rate'] = $totals['inbound'] > 0 ? round(($totals['answered_inbound'] / $totals['inbound']) * 100, 1) : null;

//same scope, immediately preceding period for KPI comparison
	$previous_parameters = $parameters;
	$previous_parameters['hours'] = $hours * 2;
	$sql = "select count(*) as calls, count(*) filter (where (" . $status_sql . ") = 'answered') as answered, ";
	$sql .= "count(*) filter (where (" . $status_sql . ") = 'missed') as missed, coalesce(sum(billsec), 0) as talk_seconds ";
	$sql .= "from v_xml_cdr where domain_uuid = :domain_uuid " . $scope_sql;
	$sql .= "and start_stamp >= (now() - (:hours || ' hours')::interval) and start_stamp < (now() - interval '" . $hours . " hours') ";
	$sql .= $direction_sql;
	$previous_row = $database->select($sql, $previous_parameters, 'row') ?? [];
	$previous = [
		'calls' => (int) ($previous_row['calls'] ?? 0),
		'answered' => (int) ($previous_row['answered'] ?? 0),
		'missed' => (int) ($previous_row['missed'] ?? 0),
		'talk_seconds' => (int) ($previous_row['talk_seconds'] ?? 0),
	];
	unset($previous_parameters, $previous_row);

	$sql = "select (" . $status_sql . ") as call_status, count(*) as calls from v_xml_cdr where domain_uuid = :domain_uuid ";
	$sql .= $scope_sql . $window_sql . $direction_sql . "group by call_status";
	$status_rows = $database->select($sql, $parameters, 'all') ?? [];
	$statuses = array_fill_keys(portal_call_statuses(), 0);
	foreach ($status_rows as $row) {
		if (isset($statuses[$row['call_status']])) { $statuses[$row['call_status']] = (int) $row['calls']; }
	}
	unset($status_rows, $row);

//the most recent calls, same scope
	$sql = "select ";
	$sql .= "xml_cdr_uuid, direction, caller_id_name, caller_id_number, ";
	$sql .= "destination_number, start_stamp, duration, billsec, ";
	$sql .= "(" . $status_sql . ") as call_status ";
	$sql .= "from v_xml_cdr ";
	$sql .= "where domain_uuid = :domain_uuid ";
	$sql .= $scope_sql;
	$sql .= $window_sql;
	$sql .= $direction_sql;
	$sql .= "order by start_stamp desc ";
	$sql .= "limit 10 ";
	$rows = $database->select($sql, $parameters, 'all') ?? [];

	$recent = [];
	foreach ($rows as $row) {
		$recent[] = [
			'uuid' => $row['xml_cdr_uuid'],
			'direction' => $row['direction'] ?? '',
			'caller_id_name' => $row['caller_id_name'] ?? '',
			'caller_id_number' => $row['caller_id_number'] ?? '',
			'destination_number' => $row['destination_number'] ?? '',
			'start_stamp' => !empty($row['start_stamp']) ? date('c', strtotime($row['start_stamp'])) : null,
			'duration' => (int) ($row['duration'] ?? 0),
			'billsec' => (int) ($row['billsec'] ?? 0),
			'status' => $row['call_status'] ?? 'no_answer',
		];
	}
	unset($rows, $row);

	echo json_encode([
		'available' => true,
		'scope' => $scope,
		'hours' => $hours,
		'direction' => $direction,
		'bucket' => $bucket,
		'generated' => date('c'),
		'totals' => $totals,
		'previous' => $previous,
		'statuses' => $statuses,
		'hourly' => $hourly,
		'recent' => $recent,
	], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

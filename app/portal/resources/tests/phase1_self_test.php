<?php

/* Read-only data reconciliation for Portal Phase 1. */

	require_once dirname(__DIR__, 4) . '/resources/require.php';
	require_once dirname(__DIR__) . '/call_status.php';

	$failures = 0;
	function phase1_check(bool $passed, string $label, string $detail = ''): void {
		global $failures;
		echo ($passed ? '[PASS] ' : '[FAIL] ') . $label . ($detail !== '' ? ' - ' . $detail : '') . PHP_EOL;
		if (!$passed) { $failures++; }
	}

	$database = new database;
	$status_sql = portal_call_status_sql();
	$sql = "select count(*) as calls, ";
	$sql .= "count(*) filter (where (" . $status_sql . ") = 'answered') as answered, ";
	$sql .= "count(*) filter (where direction = 'inbound') as inbound, ";
	$sql .= "count(*) filter (where direction = 'inbound' and (" . $status_sql . ") = 'answered') as answered_inbound, ";
	$sql .= "coalesce(sum(billsec), 0) as talk_seconds from v_xml_cdr";
	$totals = $database->select($sql, [], 'row') ?? [];
	$calls = (int) ($totals['calls'] ?? 0);
	$inbound = (int) ($totals['inbound'] ?? 0);
	$answered_inbound = (int) ($totals['answered_inbound'] ?? 0);
	$answer_rate = $inbound > 0 ? ($answered_inbound / $inbound) * 100 : null;
	phase1_check($calls >= (int) ($totals['answered'] ?? 0), 'answered calls do not exceed total calls');
	phase1_check($answer_rate === null || ($answer_rate >= 0 && $answer_rate <= 100), 'inbound answer rate is bounded', $answer_rate === null ? 'n/a' : round($answer_rate, 2) . '%');

	$sql = "select xml_cdr_uuid, record_path, record_name from v_xml_cdr where record_path is not null and record_path <> '' and record_name is not null and record_name <> '' order by start_stamp desc limit 1";
	$recording = $database->select($sql, [], 'row') ?? [];
	if (!empty($recording)) {
		$directory = realpath($recording['record_path']);
		$file = $directory === false ? false : realpath($directory . DIRECTORY_SEPARATOR . basename($recording['record_name']));
		phase1_check($file !== false && strpos($file, $directory . DIRECTORY_SEPARATOR) === 0 && is_readable($file), 'latest recording resolves inside its declared directory');
	} else {
		phase1_check(true, 'recording filesystem check skipped', 'no recording CDR');
	}

	$calls_source = file_get_contents(dirname(__DIR__, 2) . '/service/calls.php');
	foreach (['wait_min', 'wait_max', 'talk_min', 'talk_max', 'recording', 'extension_uuid', 'xml_cdr_export_csv'] as $needle) {
		phase1_check(strpos($calls_source, $needle) !== false, 'calls endpoint supports ' . $needle);
	}

	$dashboard_source = file_get_contents(dirname(__DIR__, 2) . '/service/dashboard.php');
	foreach (['average_talk_seconds', 'average_wait_seconds', 'answer_rate', 'statuses', 'previous', 'direction_sql'] as $needle) {
		phase1_check(strpos($dashboard_source, $needle) !== false, 'dashboard contract includes ' . $needle);
	}

	echo PHP_EOL . ($failures === 0 ? 'Portal Phase 1 self-test passed.' : 'Portal Phase 1 self-test failed with ' . $failures . ' error(s).') . PHP_EOL;
	exit($failures === 0 ? 0 : 1);

?>

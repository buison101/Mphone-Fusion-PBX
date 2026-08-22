<?php

	/* Read-only schema and security contract checks for Portal Phase 4.1.1. */

	require_once dirname(__DIR__, 4).'/resources/require.php';

	$failures = 0;
	function phase411_check(bool $passed, string $label, string $detail = ''): void {
		global $failures;
		echo ($passed ? '[PASS] ' : '[FAIL] ').$label.($detail !== '' ? ' - '.$detail : '').PHP_EOL;
		if (!$passed) { $failures++; }
	}

	$database = new database;
	$required_columns = ['summary_status', 'summary_model', 'summary_duration', 'summary_attempt_count', 'summary_last_error'];
	$columns = $database->select(
		"select column_name from information_schema.columns where table_name = 'v_xml_cdr_transcripts'",
		[],
		'all'
	);
	$column_names = array_column($columns, 'column_name');
	foreach ($required_columns as $column) {
		phase411_check(in_array($column, $column_names, true), 'transcript schema includes '.$column);
	}

	$invalid_states = (int)$database->select(
		"select count(*) from v_xml_cdr_transcripts where summary_status is not null ".
		"and summary_status not in ('disabled', 'processing', 'completed', 'failed', 'skipped')",
		[],
		'column'
	);
	phase411_check($invalid_states === 0, 'persisted summary states use the bounded contract');

	$endpoint = file_get_contents(dirname(__DIR__, 2).'/service/summary_retry.php');
	foreach (['portal_require_csrf', 'transcribe_queue_edit', 'domain_uuid', 'portal_identity_has_domain_scope', "REQUEST_METHOD"] as $needle) {
		phase411_check(strpos($endpoint, $needle) !== false, 'summary retry enforces '.$needle);
	}
	phase411_check(strpos($endpoint, "['error' => 'summary_failed']") !== false, 'summary retry hides provider error details');

	$enrichment = file_get_contents(dirname(__DIR__, 2).'/service/call_enrichment.php');
	phase411_check(strpos($enrichment, 'summary_last_error') === false, 'Portal read response does not expose summary errors');
	phase411_check(strpos($enrichment, 'summary_attempt_count') !== false, 'Portal exposes bounded summary operations metadata');

	echo PHP_EOL.($failures === 0 ? 'Portal Phase 4.1.1 self-test passed.' : 'Portal Phase 4.1.1 self-test failed with '.$failures.' error(s).').PHP_EOL;
	exit($failures === 0 ? 0 : 1);

?>

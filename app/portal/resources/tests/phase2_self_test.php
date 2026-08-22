<?php

	/* Read-only database reconciliation and contract checks for Portal Phase 2. */

	require_once dirname(__DIR__, 4) . '/resources/require.php';
	require_once dirname(__DIR__) . '/call_status.php';

	$failures = 0;
	function phase2_check(bool $passed, string $label, string $detail = ''): void {
		global $failures;
		echo ($passed ? '[PASS] ' : '[FAIL] ') . $label . ($detail !== '' ? ' - ' . $detail : '') . PHP_EOL;
		if (!$passed) { $failures++; }
	}

	$database = new database;
	$domain_uuid = $database->select('select domain_uuid from v_xml_cdr order by start_stamp desc limit 1', [], 'column');
	phase2_check(is_uuid($domain_uuid), 'known CDR domain is available');
	if (is_uuid($domain_uuid)) {
		$parameters = ['domain_uuid' => $domain_uuid];
		$total = (int) $database->select('select count(*) from v_xml_cdr where domain_uuid = :domain_uuid', $parameters, 'column');
		$extensions = (int) $database->select('select coalesce(sum(calls), 0) from (select count(*) calls from v_xml_cdr where domain_uuid = :domain_uuid group by extension_uuid) grouped', $parameters, 'column');
		phase2_check($total === $extensions, 'extension aggregates reconcile with domain total', $extensions . '/' . $total);

		$recordings = (int) $database->select("select count(*) from v_xml_cdr where domain_uuid = :domain_uuid and nullif(record_name, '') is not null and nullif(record_path, '') is not null", $parameters, 'column');
		$duration = (int) $database->select("select coalesce(sum(billsec), 0) from v_xml_cdr where domain_uuid = :domain_uuid and nullif(record_name, '') is not null and nullif(record_path, '') is not null", $parameters, 'column');
		phase2_check($recordings >= 0 && $duration >= 0, 'recording aggregates are non-negative', $recordings . ' recordings, ' . $duration . ' seconds');
	}

	foreach (['recordings.php', 'reports.php'] as $file) {
		$source = file_get_contents(dirname(__DIR__, 2) . '/service/' . $file);
		phase2_check(strpos($source, "permission_exists('portal_view')") !== false, $file . ' requires portal_view');
		phase2_check(strpos($source, 'portal_report_context') !== false, $file . ' uses shared report scope');
	}
	$scope_source = file_get_contents(dirname(__DIR__) . '/report_scope.php');
	foreach (['domain_uuid', 'portal_identity_has_domain_scope', 'extension_uuid', '366'] as $needle) {
		phase2_check(strpos($scope_source, $needle) !== false, 'report scope includes ' . $needle);
	}

	echo PHP_EOL . ($failures === 0 ? 'Portal Phase 2 self-test passed.' : 'Portal Phase 2 self-test failed with ' . $failures . ' error(s).') . PHP_EOL;
	exit($failures === 0 ? 0 : 1);

?>

<?php

/*
	Portal Phase 0 self-test.

	Run from the repository root:
	php app/portal/resources/tests/phase0_self_test.php

	The test is read-only. It checks local runtime dependencies, endpoint scope
	guards, the unauthenticated refusal path, and CDR status reconciliation.
*/

	require_once dirname(__DIR__, 4) . '/resources/require.php';
	require_once dirname(__DIR__) . '/call_status.php';

	$failures = 0;

	function check_result(bool $passed, string $label, string $detail = ''): void {
		global $failures;
		echo ($passed ? '[PASS] ' : '[FAIL] ') . $label;
		if ($detail !== '') {
			echo ' - ' . $detail;
		}
		echo PHP_EOL;
		if (!$passed) {
			$failures++;
		}
	}

	$required_services = [
		'nginx',
		'php8.2-fpm',
		'postgresql',
		'freeswitch',
		'fusionpbx-websockets',
		'fusionpbx-active-calls',
		'xml_cdr',
	];
	foreach ($required_services as $service) {
		$output = [];
		$status = 1;
		exec('systemctl is-active ' . escapeshellarg($service) . ' 2>/dev/null', $output, $status);
		check_result($status === 0 && trim(implode('', $output)) === 'active', 'service ' . $service . ' is active');
	}
	unset($service, $output, $status);

	$scoped_endpoints = [
		dirname(__DIR__, 2) . '/service/dashboard.php',
		dirname(__DIR__, 2) . '/service/calls.php',
		dirname(__DIR__, 2) . '/service/recording.php',
	];
	foreach ($scoped_endpoints as $endpoint) {
		$source = file_get_contents($endpoint);
		$has_domain_parameter = strpos($source, "'domain_uuid' => \$domain_uuid") !== false;
		$has_domain_clause = strpos($source, 'domain_uuid = :domain_uuid') !== false;
		$has_extension_scope = strpos($source, 'extension_uuid in (') !== false;
		check_result($has_domain_parameter && $has_domain_clause && $has_extension_scope, 'scope guards in ' . basename($endpoint));
	}
	unset($scoped_endpoints, $endpoint, $source, $has_domain_parameter, $has_domain_clause, $has_extension_scope);

	$endpoint_urls = [
		'session' => 'https://127.0.0.1/app/portal/service/session.php',
		'dashboard' => 'https://127.0.0.1/app/portal/service/dashboard.php',
		'calls' => 'https://127.0.0.1/app/portal/service/calls.php',
		'recording' => 'https://127.0.0.1/app/portal/service/recording.php?id=00000000-0000-0000-0000-000000000000',
	];
	foreach ($endpoint_urls as $name => $url) {
		$command = "curl -sk -o /dev/null -w '%{http_code}' -H " . escapeshellarg('Host: fusionpbx') . ' ' . escapeshellarg($url);
		$output = [];
		$status = 1;
		exec($command, $output, $status);
		$http_status = trim(implode('', $output));
		check_result($status === 0 && $http_status === '401', 'unauthenticated ' . $name . ' request is refused', 'HTTP ' . $http_status);
	}
	unset($endpoint_urls, $name, $url, $command, $output, $status, $http_status);

	$database = new database;
	$status_sql = portal_call_status_sql();
	$sql = "select count(*) as total, count(*) filter (where effective_status in ('answered', 'no_answer', 'busy', 'missed', 'voicemail', 'cancelled', 'failed')) as classified, count(distinct effective_status) as status_count from (select (" . $status_sql . ") as effective_status from v_xml_cdr) statuses";
	$result = $database->select($sql, [], 'row');
	$total = (int) ($result['total'] ?? 0);
	$classified = (int) ($result['classified'] ?? -1);
	$status_count = (int) ($result['status_count'] ?? 0);
	check_result($total === $classified, 'normalized statuses partition all CDR rows', $classified . '/' . $total);
	check_result($status_count <= count(portal_call_statuses()), 'no unexpected normalized CDR status', $status_count . ' distinct statuses');

	$newest = $database->select('select max(start_stamp) from v_xml_cdr', [], 'column');
	check_result(!empty($newest), 'CDR data is available', (string) $newest);

	echo PHP_EOL . ($failures === 0 ? 'Portal Phase 0 self-test passed.' : 'Portal Phase 0 self-test failed with ' . $failures . ' error(s).') . PHP_EOL;
	exit($failures === 0 ? 0 : 1);

?>

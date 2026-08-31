<?php
	if (PHP_SAPI !== 'cli') { exit(1); }
	$failures = 0;
	function phase3_check(bool $passed, string $label): void {
		global $failures; echo ($passed ? '[PASS] ' : '[FAIL] ') . $label . PHP_EOL;
		if (!$passed) $failures++;
	}
	$endpoint = file_get_contents(dirname(__DIR__, 2) . '/service/simple_call_routing.php');
	foreach (['portal_identity_validate_session(true)', "['role'] ?? '') !== 'owner'", 'invalid_csrf',
		'customer_prepare_simple_route', 'expected_assignment_revision', 'expected_management_revision',
		'register_route_resources', 'publish_route', 'customer_apply_simple_preferences'] as $needle) {
		phase3_check(strpos($endpoint, $needle) !== false, 'endpoint includes ' . $needle);
	}
	$publisher = file_get_contents(dirname(__DIR__) . '/simple_call_routing_publisher.php');
	foreach (['ring_group_strategy', "'simultaneous'", 'ring_group_destination_uuids',
		'apply_outbound_caller_ids', 'restore_outbound_caller_ids'] as $needle) {
		phase3_check(strpos($publisher, $needle) !== false, 'publisher includes ' . $needle);
	}
	$ui = file_get_contents(dirname(__DIR__, 2) . '/spa/src/pages/routing/SimpleCallRouting.jsx');
	phase3_check(strpos($ui, "session?.membership?.role !== 'owner'") !== false, 'UI gates edits to Owner');
	phase3_check(strpos($ui, 'expected_management_revision') !== false, 'UI submits management revision');
	phase3_check(strpos($ui, 'outbound_assignments') !== false, 'UI submits outbound caller IDs');
	echo PHP_EOL . ($failures ? "Simple Call Routing Phase 3 self-test failed with $failures error(s)." : 'Simple Call Routing Phase 3 self-test passed.') . PHP_EOL;
	exit($failures ? 1 : 0);
?>

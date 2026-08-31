<?php

	require_once dirname(__DIR__, 4) . '/resources/require.php';
	require_once dirname(__DIR__) . '/call_routing_platform.php';

	$failures = 0;
	function routing_phase2_check(bool $passed, string $label): void {
		global $failures;
		echo ($passed ? '[PASS] ' : '[FAIL] ') . $label . PHP_EOL;
		if (!$passed) { $failures++; }
	}

	$endpoint = file_get_contents(dirname(__DIR__, 2) . '/service/did_inventory.php');
	foreach (['portal_require_csrf', "if_group('superadmin')", 'permission_exists',
		'prepare_assignment', 'prepare_service_transition', 'prepare_transfer',
		'publish_route', 'activate_assignment', 'finalize_service_transition', 'finalize_transfer'] as $needle) {
		routing_phase2_check(strpos($endpoint, $needle) !== false, 'DID endpoint includes ' . $needle);
	}
	$publisher = file_get_contents(dirname(__DIR__) . '/simple_call_routing_publisher.php');
	foreach (['destination_number_conflict', "dialplan_enabled' => false", "destination_enabled' => false",
		'CALL_REJECTED', 'set_enabled', 'verify'] as $needle) {
		routing_phase2_check(strpos($publisher, $needle) !== false, 'publisher includes ' . $needle);
	}

	$operator = $database->select("select u.user_uuid,u.domain_uuid from v_users u
		join v_user_groups ug on ug.user_uuid=u.user_uuid and ug.domain_uuid=u.domain_uuid
		where ug.group_name='superadmin' and u.user_enabled=true limit 1", [], 'row');
	if (is_array($operator)) {
		$_SESSION['user_uuid'] = $operator['user_uuid'];
		$_SESSION['domain_uuid'] = $operator['domain_uuid'];
		$result = portal_call_routing_platform_transport(['action' => 'inventory_list']);
		routing_phase2_check(($result['status'] ?? 0) === 200, 'internal inventory list responds');
		routing_phase2_check(is_array($result['payload']['customers'] ?? null), 'inventory returns authorized Customer options');
		routing_phase2_check(is_array($result['payload']['extensions'] ?? null), 'inventory returns Customer Extension ownership options');
	}
	else { routing_phase2_check(false, 'active superadmin fixture exists'); }

	foreach (['did_inventory_manage','did_assign','did_suspend','did_release','did_transfer'] as $permission) {
		$ordinary = (int) $database->select("select count(*) from v_group_permissions
			where permission_name=:permission and group_name in ('admin','user')", ['permission' => $permission], 'column');
		routing_phase2_check($ordinary === 0, $permission . ' remains unavailable to admin and user');
	}

	echo PHP_EOL . ($failures === 0 ? 'Simple Call Routing Phase 2 self-test passed.'
		: 'Simple Call Routing Phase 2 self-test failed with ' . $failures . ' error(s).') . PHP_EOL;
	exit($failures === 0 ? 0 : 1);

?>

<?php

	/* Phase 1 static contract and live foundation checks. No DID data is mutated. */

	require_once dirname(__DIR__, 4) . '/resources/require.php';
	require_once dirname(__DIR__) . '/call_routing_platform.php';

	$failures = 0;
	function routing_phase1_check(bool $passed, string $label): void {
		global $failures;
		echo ($passed ? '[PASS] ' : '[FAIL] ') . $label . PHP_EOL;
		if (!$passed) { $failures++; }
	}

	$app_config = file_get_contents(dirname(__DIR__, 2) . '/app_config.php');
	foreach ([
		'did_inventory_view', 'did_inventory_manage', 'did_assign', 'did_suspend', 'did_release',
		'did_transfer', 'call_routing_takeover', 'call_routing_publish_advanced',
		'call_routing_cancel_transition', 'call_routing_release', 'call_routing_view_snapshot',
	] as $permission) {
		routing_phase1_check(strpos($app_config, '"' . $permission . '"') !== false, 'declares ' . $permission);
	}
	$permission_names = [
		'did_inventory_view', 'did_inventory_manage', 'did_assign', 'did_suspend', 'did_release',
		'did_transfer', 'call_routing_takeover', 'call_routing_publish_advanced',
		'call_routing_cancel_transition', 'call_routing_release', 'call_routing_view_snapshot',
	];
	$placeholders = [];
	$parameters = [];
	foreach ($permission_names as $index => $permission) {
		$placeholders[] = ':permission_' . $index;
		$parameters['permission_' . $index] = $permission;
	}
	$permission_list = implode(',', $placeholders);
	$installed_permissions = (int) $database->select(
		'select count(*) from v_permissions where permission_name in (' . $permission_list . ')',
		$parameters,
		'column'
	);
	$superadmin_permissions = (int) $database->select(
		"select count(*) from v_group_permissions where group_name='superadmin' and permission_name in (" . $permission_list . ')',
		$parameters,
		'column'
	);
	$ordinary_permissions = (int) $database->select(
		"select count(*) from v_group_permissions where group_name in ('admin','user') and permission_name in (" . $permission_list . ')',
		$parameters,
		'column'
	);
	routing_phase1_check($installed_permissions === count($permission_names), 'installs every narrow routing permission');
	routing_phase1_check($superadmin_permissions === count($permission_names), 'maps routing permissions to superadmin');
	routing_phase1_check($ordinary_permissions === 0, 'does not grant routing permissions to admin or user');

	$bridge_source = file_get_contents(dirname(__DIR__) . '/call_routing_platform.php');
	routing_phase1_check(strpos($bridge_source, 'permission_exists($required_permission)') !== false, 'PHP bridge enforces a narrow permission');
	routing_phase1_check(strpos($bridge_source, 'X-Mphone-Admin-Secret') !== false, 'PHP bridge keeps the service credential server-side');

	$sql = "select u.user_uuid, u.domain_uuid from v_users u ";
	$sql .= "join v_user_groups ug on ug.user_uuid = u.user_uuid ";
	$sql .= "join v_groups g on g.group_uuid = ug.group_uuid ";
	$sql .= "where g.group_name = 'superadmin' and u.user_enabled = true limit 1";
	$operator = $database->select($sql, [], 'row');
	if (is_array($operator) && is_uuid($operator['user_uuid'] ?? '') && is_uuid($operator['domain_uuid'] ?? '')) {
		$_SESSION['user_uuid'] = $operator['user_uuid'];
		$_SESSION['domain_uuid'] = $operator['domain_uuid'];
		$status = portal_call_routing_platform_transport(['action' => 'foundation_status']);
		routing_phase1_check(($status['status'] ?? 0) === 200, 'internal routing foundation responds');
		routing_phase1_check(($status['payload']['foundation'] ?? '') === 'ready', 'routing foundation reports ready');
		routing_phase1_check(($status['payload']['customer_writes_enabled'] ?? null) === true, 'Phase 3 Customer routing writes are enabled');
	}
	else {
		routing_phase1_check(false, 'active superadmin exists for internal service test');
	}

	echo PHP_EOL . ($failures === 0
		? 'Simple Call Routing Phase 1 self-test passed.'
		: 'Simple Call Routing Phase 1 self-test failed with ' . $failures . ' error(s).') . PHP_EOL;
	exit($failures === 0 ? 0 : 1);

?>

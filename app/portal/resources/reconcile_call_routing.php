<?php

	if (PHP_SAPI !== 'cli') {
		http_response_code(404);
		exit;
	}

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once __DIR__ . '/call_routing_platform.php';

	$sql = "select u.user_uuid, u.domain_uuid ";
	$sql .= "from v_users u join v_user_groups ug on ug.user_uuid = u.user_uuid ";
	$sql .= "join v_groups g on g.group_uuid = ug.group_uuid ";
	$sql .= "where g.group_name = 'superadmin' and u.user_enabled = true ";
	$sql .= "order by u.user_uuid limit 1";
	$operator = $database->select($sql, [], 'row');
	if (!is_array($operator) || !is_uuid($operator['user_uuid'] ?? '') || !is_uuid($operator['domain_uuid'] ?? '')) {
		fwrite(STDERR, "No active FusionPBX superadmin is available for DID reconciliation.\n");
		exit(1);
	}

	$_SESSION['user_uuid'] = $operator['user_uuid'];
	$_SESSION['domain_uuid'] = $operator['domain_uuid'];
	$result = portal_call_routing_platform_transport([
		'action' => 'reconcile_fusion_inventory',
		'operation_key' => 'fusion-inventory-' . gmdate('YmdHi'),
	]);
	if (($result['status'] ?? 0) !== 200) {
		fwrite(STDERR, "DID reconciliation failed with HTTP " . (int) ($result['status'] ?? 0) . ".\n");
		exit(1);
	}

	$payload = $result['payload'] ?? [];
	echo "dids=" . (int) ($payload['scanned']['dids'] ?? 0);
	echo " destinations=" . (int) ($payload['scanned']['destinations'] ?? 0);
	echo " matches=" . (int) ($payload['open_matches'] ?? 0) . "\n";

?>

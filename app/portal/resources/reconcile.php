<?php

	if (PHP_SAPI !== 'cli') {
		http_response_code(404);
		exit;
	}

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__, 2) . '/customer_identities/resources/customer_platform.php';

	$sql = "select u.user_uuid, u.domain_uuid ";
	$sql .= "from v_users u join v_user_groups ug on ug.user_uuid = u.user_uuid ";
	$sql .= "join v_groups g on g.group_uuid = ug.group_uuid ";
	$sql .= "where g.group_name = 'superadmin' and u.user_enabled = 'true' ";
	$sql .= "order by u.user_uuid limit 1";
	$operator = $database->select($sql, [], 'row');
	if (!is_array($operator) || !is_uuid($operator['user_uuid'] ?? '') || !is_uuid($operator['domain_uuid'] ?? '')) {
		fwrite(STDERR, "No active FusionPBX superadmin is available for reconciliation.\n");
		exit(1);
	}

	$_SESSION['user_uuid'] = $operator['user_uuid'];
	$_SESSION['domain_uuid'] = $operator['domain_uuid'];
	$result = customer_platform_request(['action' => 'reconcile']);
	if (($result['status'] ?? 0) !== 200) {
		fwrite(STDERR, "Customer Platform reconciliation failed with HTTP " . (int) ($result['status'] ?? 0) . ".\n");
		exit(1);
	}

	$payload = $result['payload'] ?? [];
	echo "checked=" . (int) ($payload['checked'] ?? 0) . " exceptions=" . (int) ($payload['exceptions'] ?? 0) . "\n";

?>

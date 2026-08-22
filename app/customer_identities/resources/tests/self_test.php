<?php

	require_once dirname(__DIR__, 4) . '/resources/require.php';
	require_once dirname(__DIR__) . '/customer_platform.php';

	$failures = 0;
	function customer_identity_check(bool $passed, string $label): void {
		global $failures;
		echo ($passed ? '[PASS] ' : '[FAIL] ') . $label . PHP_EOL;
		if (!$passed) $failures++;
	}

	$database = database::new();
	$permissions = $database->select("select count(*) from v_permissions where permission_name in ('customer_identity_view','customer_identity_edit')", [], 'column');
	customer_identity_check((int) $permissions === 2, 'operator permissions installed');
	$menu = $database->select("select count(*) from v_menu_items where menu_item_link='/app/customer_identities/customer_identities.php'", [], 'column');
	customer_identity_check((int) $menu === 1, 'operator menu installed');

	$command = "curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' --data '{\"action\":\"list\"}' http://127.0.0.1:8000/functions/v1/mphone-customer-admin";
	$output = [];
	exec($command, $output, $status);
	customer_identity_check($status === 0 && trim(implode('', $output)) === '401', 'admin API rejects missing service credential');

	$user = $database->select("select user_uuid::text, domain_uuid::text from v_users where user_enabled::text='true' order by user_uuid limit 1", [], 'row');
	$_SESSION['user_uuid'] = $user['user_uuid'] ?? '';
	$_SESSION['domain_uuid'] = $user['domain_uuid'] ?? '';
	$result = customer_platform_request(['action' => 'list', 'customer_uuid' => null]);
	customer_identity_check($result['status'] === 200 && isset($result['payload']['customers']), 'PHP bridge lists Customers');
	customer_identity_check(is_readable('/etc/mphone/customer-admin-secret'), 'PHP service credential is readable');

	$source = file_get_contents('/opt/supabase/supabase-project/volumes/functions/mphone-customer-admin/index.ts');
	customer_identity_check(str_contains($source, 'mphone_customer_extensions'), 'assignment API enforces Customer Extension ownership');
	customer_identity_check(str_contains($source, "return json({ error: 'owned_by_another_customer' }, 409)"), 'cross-Customer ownership conflict is explicit');

	echo PHP_EOL . ($failures === 0 ? 'Customer Identity Phase 4 self-test passed.' : "Customer Identity Phase 4 self-test failed with $failures error(s).") . PHP_EOL;
	exit($failures === 0 ? 0 : 1);

?>

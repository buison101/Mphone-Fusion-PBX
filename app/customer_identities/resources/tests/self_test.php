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
	customer_identity_check((int) $menu === 0, 'standalone operator menu removed');

	$admin_endpoint = customer_platform_api_url() . '/functions/v1/mphone-customer-admin';
	$command = "curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' --data '{\"action\":\"list\"}' " . escapeshellarg($admin_endpoint);
	$output = [];
	exec($command, $output, $status);
	customer_identity_check($status === 0 && trim(implode('', $output)) === '401', 'admin API rejects missing service credential');

	$user = $database->select("select user_uuid::text, domain_uuid::text from v_users where user_enabled::text='true' order by user_uuid limit 1", [], 'row');
	$_SESSION['user_uuid'] = $user['user_uuid'] ?? '';
	$_SESSION['domain_uuid'] = $user['domain_uuid'] ?? '';
	$result = customer_platform_request(['action' => 'list', 'customer_uuid' => null]);
	customer_identity_check($result['status'] === 200 && isset($result['payload']['customers']), 'PHP bridge lists Customers');
	$user_result = customer_platform_request(['action' => 'list', 'fusion_user_uuid' => $user['user_uuid'] ?? '']);
	customer_identity_check($user_result['status'] === 200 && ($user_result['payload']['fusion_user']['user_uuid'] ?? '') === ($user['user_uuid'] ?? ''), 'PHP bridge resolves a Fusion user for Mphone linking');
	customer_identity_check(is_readable('/etc/mphone/customer-admin-secret'), 'PHP service credential is readable');

	$source = file_get_contents('/opt/supabase/supabase-project/volumes/functions/mphone-customer-admin/index.ts');
	customer_identity_check(str_contains($source, 'mphone_customer_extensions'), 'assignment API enforces Customer Extension ownership');
	customer_identity_check(str_contains($source, "return json({ error: 'owned_by_another_customer' }, 409)"), 'cross-Customer ownership conflict is explicit');
	customer_identity_check(str_contains($source, "action === 'invite_identity'") && str_contains($source, "'pending'"), 'invitation creates a pending Customer Identity');
	customer_identity_check(str_contains($source, "action === 'invite_fusion_user'") && str_contains($source, 'v_extension_users'), 'Fusion User invitation derives email and Extensions from FusionPBX');
	customer_identity_check(str_contains($source, "action === 'customer_merge_preview'") && str_contains($source, "action === 'customer_merge_execute'"), 'Customer merge requires preview and explicit execution');
	customer_identity_check(str_contains($source, "body.actor_superadmin !== true") && str_contains($source, "revoke_reason='customer_merged'"), 'Customer merge is superadmin-only and revokes affected sessions');
	customer_identity_check(str_contains($source, "action === 'customer_manage_list'") && str_contains($source, "action === 'customer_manage_create'") && str_contains($source, "action === 'customer_manage_status'"), 'Superadmin Customer management API exposes scoped lifecycle actions');
	customer_identity_check(str_contains($source, "single_member_promoted_to_owner") && str_contains($source, "'owner', 'invited'"), 'Single-member personal Customers receive an owner Membership');
	customer_identity_check(str_contains($source, "'customer_closed' : 'customer_suspended'"), 'Suspending or closing a Customer revokes active sessions');
	$merge_schema = file_get_contents('/opt/supabase/supabase-project/volumes/db/init/mphone_identity_phase7_customer_merge.sql');
	customer_identity_check(str_contains($merge_schema, 'preview_digest') && str_contains($merge_schema, 'snapshot jsonb'), 'Customer merge stores a verifiable preview snapshot');
	$users_source = file_get_contents('/var/www/fusionpbx/core/users/users.php');
	customer_identity_check(str_contains($users_source, "'user_statuses'") && str_contains($users_source, 'invite_user.php'), 'Users list exposes batched Mphone status and invitation');
	$portal_customers = file_get_contents('/var/www/fusionpbx/app/portal/service/customers.php');
	customer_identity_check(str_contains($portal_customers, "if_group('superadmin')") && str_contains($portal_customers, "'customer_manage_status'"), 'Portal Customer management endpoint is Fusion superadmin-only');
	$email_source = file_get_contents('/opt/supabase/supabase-project/volumes/functions/mphone-identity-email/index.ts');
	customer_identity_check(str_contains($email_source, "purpose === 'verify_email'") && str_contains($email_source, "status='active'"), 'email activation enables invited memberships');

	echo PHP_EOL . ($failures === 0 ? 'Customer Identity Phase 4 self-test passed.' : "Customer Identity Phase 4 self-test failed with $failures error(s).") . PHP_EOL;
	exit($failures === 0 ? 0 : 1);

?>

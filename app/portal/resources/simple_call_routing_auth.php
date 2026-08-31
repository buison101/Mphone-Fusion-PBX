<?php

	// Refresh only the routing permissions already assigned to the signed-in
	// user's database groups. This supports sessions created before the module
	// was installed without broadening any group assignment.
	if (is_uuid($_SESSION['user_uuid'] ?? '') && is_uuid($_SESSION['domain_uuid'] ?? '')) {
		$routing_permission_names = [
			'did_inventory_view', 'did_inventory_manage', 'did_assign', 'did_suspend',
			'did_release', 'did_transfer', 'call_routing_takeover',
			'call_routing_publish_advanced', 'call_routing_cancel_transition',
			'call_routing_release', 'call_routing_view_snapshot',
		];
		$routing_permissions_missing = false;
		foreach ($routing_permission_names as $routing_permission_name) {
			if (!isset($_SESSION['permissions'][$routing_permission_name])) {
				$routing_permissions_missing = true;
				break;
			}
		}
		if ($routing_permissions_missing) {
			$routing_auth_database = $database ?? database::new();
			$routing_auth_rows = $routing_auth_database->select(
				"select distinct gp.permission_name from v_user_groups ug "
				. "join v_groups g on g.group_uuid=ug.group_uuid "
				. "join v_group_permissions gp on gp.group_name=g.group_name "
				. "where ug.user_uuid=:user_uuid and (g.domain_uuid=:domain_uuid or g.domain_uuid is null) "
				. "and (gp.domain_uuid=:domain_uuid or gp.domain_uuid is null) and gp.permission_assigned='true' "
				. "and gp.permission_name in ('" . implode("','", $routing_permission_names) . "')",
				['user_uuid' => $_SESSION['user_uuid'], 'domain_uuid' => $_SESSION['domain_uuid']], 'all'
			) ?: [];
			foreach ($routing_auth_rows as $routing_auth_row) {
				$routing_permission_name = $routing_auth_row['permission_name'];
				$_SESSION['permissions'][$routing_permission_name] = true;
				$_SESSION['user']['permissions'][$routing_permission_name] = true;
			}
		}
		unset($routing_permission_names, $routing_permission_name, $routing_permissions_missing,
			$routing_auth_database, $routing_auth_rows, $routing_auth_row);
	}

?>

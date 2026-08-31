<?php

	if (PHP_SAPI !== 'cli') { exit(1); }
	require_once dirname(__DIR__, 4) . '/resources/require.php';
	require_once dirname(__DIR__) . '/simple_call_routing_publisher.php';

	$operator = $database->select("select u.user_uuid,u.domain_uuid from v_users u
		join v_user_groups ug on ug.user_uuid=u.user_uuid and ug.domain_uuid=u.domain_uuid
		where ug.group_name='superadmin' and u.user_enabled=true limit 1", [], 'row');
	$extension = $database->select("select extension_uuid,domain_uuid from v_extensions
		where enabled=true order by extension limit 1", [], 'row');
	if (!is_array($operator) || !is_array($extension)) {
		fwrite(STDERR, "Publisher fixture unavailable.\n");
		exit(1);
	}
	$_SESSION['user_uuid'] = $operator['user_uuid'];
	$_SESSION['domain_uuid'] = $operator['domain_uuid'];
	$temporary_permissions = permissions::new();
	foreach (['dialplan_add','dialplan_detail_add','destination_add','ring_group_add','ring_group_destination_add'] as $permission) {
		$temporary_permissions->add($permission, 'temp');
	}
	$resources = null;
	try {
		$publisher = new portal_simple_call_routing_publisher($database, $operator['user_uuid']);
		$resources = $publisher->prepare_direct([
			'fusion_domain_uuid' => $extension['domain_uuid'],
			'canonical_e164' => '+84990000004',
			'route_version_uuid' => uuid(),
			'route_type' => 'simple_direct',
			'desired_state' => ['extension_uuids' => [$extension['extension_uuid']]],
		]);
		$verification = $publisher->verify($resources, false);
		if (!$verification['valid']) { throw new RuntimeException('disabled_route_verification_failed'); }
		echo "Simple Call Routing Phase 2 publisher test passed.\n";
	}
	catch (Throwable $error) {
		fwrite(STDERR, "Publisher test failed: " . $error->getMessage() . "\n");
		$exit_code = 1;
	}
	finally {
		if (is_array($resources)) {
			$database->execute('delete from v_destinations where destination_uuid=:uuid', ['uuid' => $resources['destination_uuid']]);
			$database->execute('delete from v_dialplan_details where dialplan_uuid=:uuid', ['uuid' => $resources['dialplan_uuid']]);
			$database->execute('delete from v_dialplans where dialplan_uuid=:uuid', ['uuid' => $resources['dialplan_uuid']]);
			$database->execute('delete from v_ring_group_destinations where ring_group_uuid=:uuid', ['uuid' => $resources['ring_group_uuid']]);
			$database->execute('delete from v_ring_groups where ring_group_uuid=:uuid', ['uuid' => $resources['ring_group_uuid']]);
		}
	}
	exit($exit_code ?? 0);

?>

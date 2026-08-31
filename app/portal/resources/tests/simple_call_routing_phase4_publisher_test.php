<?php

	if (PHP_SAPI !== 'cli') { exit(1); }
	require_once dirname(__DIR__, 4) . '/resources/require.php';
	require_once dirname(__DIR__) . '/simple_call_routing_publisher.php';

	function phase4_assert(bool $condition, string $message): void {
		if (!$condition) { throw new RuntimeException($message); }
	}

	$operator = $database->select(
		"select u.user_uuid from v_users u join v_user_groups ug on ug.user_uuid=u.user_uuid "
		. "where ug.group_name='superadmin' and u.user_enabled=true limit 1",
		[], 'row'
	);
	$extensions = $database->select(
		'select extension_uuid,domain_uuid,extension from v_extensions where enabled=true '
		. 'and domain_uuid in (select domain_uuid from v_extensions where enabled=true group by domain_uuid having count(*) >= 2) '
		. 'order by domain_uuid,extension limit 2',
		[], 'all'
	);
	phase4_assert(is_array($operator) && count($extensions) === 2, 'fixture_unavailable');
	phase4_assert($extensions[0]['domain_uuid'] === $extensions[1]['domain_uuid'], 'fixture_domain_mismatch');

	$_SESSION['user_uuid'] = $operator['user_uuid'];
	$permissions = permissions::new();
	foreach (['destination_add','dialplan_add','dialplan_detail_add','ring_group_add','ring_group_destination_add'] as $permission) {
		$permissions->add($permission, 'temp');
	}

	$publisher = new portal_simple_call_routing_publisher($database, $operator['user_uuid']);
	$prepared = [];
	try {
		foreach ([
			['simple_greeting', '+84990000007', [], [$extensions[0]['extension_uuid']]],
			['simple_keypad', '+84990000008', ['1' => [$extensions[0]['extension_uuid'], $extensions[1]['extension_uuid']]], [$extensions[0]['extension_uuid']]],
		] as [$type, $did, $mappings, $default_members]) {
			$resources = $publisher->prepare_direct([
				'fusion_domain_uuid' => $extensions[0]['domain_uuid'],
				'canonical_e164' => $did,
				'route_version_uuid' => uuid(),
				'route_type' => $type,
				'greeting_filename' => 'phase4-test.wav',
				'desired_state' => ['extension_uuids' => $default_members, 'keypad_mappings' => $mappings],
			]);
			$prepared[] = $resources;
			phase4_assert(($resources['canonical_e164'] ?? '') === $did, $type . '_cache_key_number_missing');

			$dialplan = $database->select('select dialplan_xml from v_dialplans where dialplan_uuid=:uuid',
				['uuid' => $resources['dialplan_uuid']], 'row');
			$xml = (string) ($dialplan['dialplan_xml'] ?? '');
			phase4_assert(str_contains($xml, '${recordings_dir}/'), $type . '_recording_path_missing');
			phase4_assert(!str_contains($xml, '$${recordings_dir}/'), $type . '_recording_path_uses_global_syntax');
			phase4_assert(!str_contains($xml, 'data="$/'), $type . '_recording_path_corrupt');
			phase4_assert(simplexml_load_string($xml) !== false, $type . '_xml_invalid');

			$detail_types = $database->select(
				'select dialplan_detail_type from v_dialplan_details where dialplan_uuid=:uuid order by dialplan_detail_group,dialplan_detail_order',
				['uuid' => $resources['dialplan_uuid']], 'all');
			$detail_types = array_column($detail_types, 'dialplan_detail_type');
			if ($type === 'simple_keypad') {
				phase4_assert(str_contains($xml, 'application="play_and_get_digits"'), 'keypad_xml_missing');
				phase4_assert(str_contains($xml, 'play_and_get_digits" data="1 1 2 5000'), 'keypad_attempt_count_invalid');
				phase4_assert(str_contains($xml, 'mphone_digit [1]'), 'keypad_allowed_digit_pattern_invalid');
				phase4_assert(str_contains($xml, 'app.lua mphone_keypad '), 'keypad_dispatch_missing');
				phase4_assert(count($resources['ring_group_uuids'] ?? []) === 2, 'keypad_technical_group_count_invalid');
				phase4_assert(str_contains($xml, '1=g:' . $resources['ring_group_uuids'][1]), 'keypad_group_mapping_missing');
				phase4_assert(!str_contains($xml, '1=e:'), 'keypad_direct_extension_mapping_present');
				phase4_assert(in_array('play_and_get_digits', $detail_types, true), 'keypad_detail_missing');
				phase4_assert(in_array('lua', $detail_types, true), 'keypad_dispatch_detail_missing');
			}
			else {
				phase4_assert(str_contains($xml, 'application="playback"'), 'greeting_xml_missing');
				phase4_assert(in_array('playback', $detail_types, true), 'greeting_detail_missing');
			}

			$members = $database->select(
				'select destination_number from v_ring_group_destinations where ring_group_uuid=:uuid order by destination_number',
				['uuid' => $resources['ring_group_uuid']], 'all');
			phase4_assert(array_column($members, 'destination_number') === [$extensions[0]['extension']], $type . '_fallback_members_invalid');
			if ($type === 'simple_keypad') {
				$key_members = $database->select(
					'select destination_number from v_ring_group_destinations where ring_group_uuid=:uuid order by destination_number',
					['uuid' => $resources['ring_group_uuids'][1]], 'all');
				phase4_assert(array_column($key_members, 'destination_number') === [$extensions[0]['extension'], $extensions[1]['extension']],
					'keypad_technical_group_members_invalid');
			}

			$destination = $database->select(
				'select destination_app,destination_actions from v_destinations where destination_uuid=:uuid',
				['uuid' => $resources['destination_uuid']], 'row');
			$expected_app = $type === 'simple_keypad' ? 'play_and_get_digits' : 'playback';
			phase4_assert(($destination['destination_app'] ?? '') === $expected_app, $type . '_destination_app_invalid');
			phase4_assert(str_contains((string) ($destination['destination_actions'] ?? ''), '${recordings_dir}/'), $type . '_destination_path_missing');

			$detail_dialplan = new dialplan;
			$detail_dialplan->source = 'details';
			$detail_dialplan->destination = 'array';
			$detail_dialplan->uuid = $resources['dialplan_uuid'];
			$generated = $detail_dialplan->xml();
			$generated_xml = (string) ($generated[$resources['dialplan_uuid']] ?? '');
			phase4_assert($generated_xml !== '', $type . '_details_xml_missing');
			phase4_assert(str_contains($generated_xml, 'application="' . $expected_app . '"'), $type . '_details_xml_action_missing');
			if ($type === 'simple_keypad') {
				phase4_assert(str_contains($generated_xml, 'app.lua mphone_keypad '), 'keypad_details_xml_dispatch_missing');
				phase4_assert(!str_contains($generated_xml, 'field="${mphone_digit}"'), 'keypad_runtime_variable_condition_present');
			}
		}
		echo "Simple Call Routing Phase 4 publisher test passed.\n";
	}
	finally {
		foreach ($prepared as $resources) { $publisher->delete_prepared($resources); }
	}

?>

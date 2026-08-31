<?php

	class portal_simple_call_routing_publisher {

		private database $database;
		private string $user_uuid;

		public function __construct(database $database, string $user_uuid) {
			$this->database = $database;
			$this->user_uuid = $user_uuid;
		}

		public function prepare_direct(array $work_item): array {
			$domain_uuid = (string) ($work_item['fusion_domain_uuid'] ?? '');
			$did = (string) ($work_item['canonical_e164'] ?? '');
			$route_version_uuid = (string) ($work_item['route_version_uuid'] ?? '');
			$route_type = (string) ($work_item['route_type'] ?? 'simple_direct');
			$extension_uuids = $work_item['desired_state']['extension_uuids'] ?? [];
			$keypad_mappings = (array) ($work_item['desired_state']['keypad_mappings'] ?? []);
			if ($route_type !== 'simple_keypad') { $keypad_mappings = []; }
			$greeting_filename = basename((string) ($work_item['greeting_filename'] ?? ''));
			if (!is_uuid($domain_uuid) || !is_uuid($route_version_uuid)
				|| !preg_match('/^\+[1-9][0-9]{7,14}$/', $did)
				|| !is_array($extension_uuids)
				|| ($route_type !== 'service_suspended' && count($extension_uuids) < 1)) {
				throw new RuntimeException('invalid_route_work_item');
			}
			foreach ($extension_uuids as $extension_uuid) {
				if (!is_uuid($extension_uuid)) { throw new RuntimeException('invalid_extension_uuid'); }
			}
			if (in_array($route_type, ['simple_greeting','simple_keypad'], true) && $greeting_filename === '') {
				throw new RuntimeException('greeting_recording_missing');
			}

			$domain = $this->database->select(
				'select domain_name from v_domains where domain_uuid=:domain_uuid and domain_enabled=true',
				['domain_uuid' => $domain_uuid],
				'row'
			);
			if (!is_array($domain) || empty($domain['domain_name'])) { throw new RuntimeException('domain_not_active'); }
			$normalized_keypad_mappings = [];
			$keypad_extension_uuids = [];
			foreach ($keypad_mappings as $digit => $mapping) {
				if (!preg_match('/^[0-9]$/', (string) $digit)) { throw new RuntimeException('invalid_keypad_mapping'); }
				if (is_string($mapping)) { $mapping = [$mapping]; }
				elseif (is_array($mapping) && isset($mapping['member_extension_uuids'])) { $mapping = $mapping['member_extension_uuids']; }
				if (!is_array($mapping)) { throw new RuntimeException('invalid_keypad_mapping'); }
				$members = array_values(array_unique($mapping));
				if (count($members) < 1) { continue; }
				foreach ($members as $member_uuid) {
					if (!is_uuid($member_uuid)) { throw new RuntimeException('invalid_keypad_mapping'); }
					$keypad_extension_uuids[] = $member_uuid;
				}
				$normalized_keypad_mappings[(string) $digit] = $members;
			}
			$keypad_mappings = $normalized_keypad_mappings;
			$lookup_uuids = array_values(array_unique(array_merge($extension_uuids, $keypad_extension_uuids)));
			$placeholders = []; $parameters = ['domain_uuid' => $domain_uuid];
			foreach ($lookup_uuids as $index => $extension_uuid) {
				$placeholders[] = ':extension_' . $index;
				$parameters['extension_' . $index] = $extension_uuid;
			}
			$extensions = count($lookup_uuids) > 0 ? $this->database->select(
				'select extension_uuid,extension from v_extensions where domain_uuid=:domain_uuid '
				. 'and enabled=true and extension_uuid in (' . implode(',', $placeholders) . ') order by extension',
				$parameters,
				'all'
			) : [];
			if (!is_array($extensions) || count($extensions) !== count($lookup_uuids)) {
				throw new RuntimeException('extension_not_active');
			}
			$normalized_digits = preg_replace('/\D/', '', $did);
			$previous_destination_uuid = '';
			foreach ((array) ($work_item['previous_resources'] ?? []) as $previous_resource) {
				if (($previous_resource['resource_type'] ?? '') === 'destination' && is_uuid($previous_resource['fusion_resource_uuid'] ?? '')) {
					$previous_destination_uuid = $previous_resource['fusion_resource_uuid'];
				}
			}
			$collision_count = (int) $this->database->select(
				"select count(*) from v_destinations d left join v_dialplans p on p.dialplan_uuid=d.dialplan_uuid "
				. "where regexp_replace(coalesce(d.destination_number,''),'[^0-9]+','','g')=:digits "
				. "and d.destination_uuid::text<>:previous_uuid and not (coalesce(d.destination_enabled,false)=false "
				. "and d.destination_description like 'Managed by Mphone route version %' "
				. "and coalesce(p.dialplan_enabled,false)=false and p.dialplan_description like 'Managed by Mphone route version %')",
				['digits' => $normalized_digits, 'previous_uuid' => $previous_destination_uuid],
				'column'
			);
			if ($collision_count > 0) { throw new RuntimeException('destination_number_conflict'); }

			$destination_uuid = uuid();
			$dialplan_uuid = uuid();
			$ring_group_uuid = uuid();
			$domain_name = (string) $domain['domain_name'];
			$regex = '^\\+(' . substr($did, 1) . ')$';
			$bridge_targets = [];
			$extension_by_uuid = [];
			foreach ($extensions as $extension) {
				$extension_by_uuid[$extension['extension_uuid']] = $extension;
				if (!in_array($extension['extension_uuid'], $extension_uuids, true)) { continue; }
				$bridge_targets[] = 'user/' . $extension['extension'] . '@' . $domain_name;
			}
			$bridge_data = implode(',', $bridge_targets);
			$action_app = $route_type === 'service_suspended' ? 'hangup' : 'lua';
			$action_data = $route_type === 'service_suspended' ? 'CALL_REJECTED' : 'app.lua ring_groups';
			$name = 'Mphone DID ' . $did . ' [' . substr($route_version_uuid, 0, 8) . ']';
			$array['ring_groups'][0] = [
				'ring_group_uuid' => $ring_group_uuid, 'domain_uuid' => $domain_uuid,
				'ring_group_name' => $name . ' Default', 'ring_group_strategy' => 'simultaneous',
				'ring_group_call_timeout' => 30, 'ring_group_context' => $domain_name,
				'ring_group_enabled' => false, 'ring_group_description' => 'Managed by Mphone route version ' . $route_version_uuid,
				'insert_date' => date('c'), 'insert_user' => $this->user_uuid,
			];
			$ring_group_destination_uuids = [];
			$ring_group_uuids = [$ring_group_uuid];
			$ring_group_index = 0;
			foreach ($extensions as $extension) {
				if (!in_array($extension['extension_uuid'], $extension_uuids, true)) { continue; }
				$ring_group_destination_uuid = uuid();
				$ring_group_destination_uuids[] = $ring_group_destination_uuid;
				$array['ring_group_destinations'][$ring_group_index++] = [
					'ring_group_destination_uuid' => $ring_group_destination_uuid,
					'domain_uuid' => $domain_uuid, 'ring_group_uuid' => $ring_group_uuid,
					'destination_number' => $extension['extension'], 'destination_delay' => 0,
					'destination_timeout' => 30, 'destination_enabled' => true,
				];
			}
			$keypad_ring_groups = [];
			ksort($keypad_mappings, SORT_STRING);
			foreach ($keypad_mappings as $digit => $member_uuids) {
				$keypad_ring_group_uuid = uuid();
				$ring_group_uuids[] = $keypad_ring_group_uuid;
				$keypad_ring_groups[$digit] = $keypad_ring_group_uuid;
				$array['ring_groups'][] = [
					'ring_group_uuid' => $keypad_ring_group_uuid, 'domain_uuid' => $domain_uuid,
					'ring_group_name' => $name . ' Key ' . $digit, 'ring_group_strategy' => 'simultaneous',
					'ring_group_call_timeout' => 30, 'ring_group_context' => $domain_name,
					'ring_group_enabled' => false, 'ring_group_description' => 'Managed by Mphone route version ' . $route_version_uuid . ' keypad ' . $digit,
					'insert_date' => date('c'), 'insert_user' => $this->user_uuid,
				];
				foreach ($member_uuids as $member_uuid) {
					$extension = $extension_by_uuid[$member_uuid] ?? null;
					if (!is_array($extension)) { throw new RuntimeException('invalid_keypad_mapping'); }
					$ring_group_destination_uuid = uuid();
					$ring_group_destination_uuids[] = $ring_group_destination_uuid;
					$array['ring_group_destinations'][$ring_group_index++] = [
						'ring_group_destination_uuid' => $ring_group_destination_uuid,
						'domain_uuid' => $domain_uuid, 'ring_group_uuid' => $keypad_ring_group_uuid,
						'destination_number' => $extension['extension'], 'destination_delay' => 0,
						'destination_timeout' => 30, 'destination_enabled' => true,
					];
				}
			}
			$xml = '<extension name="' . xml::sanitize($name) . '" continue="false" uuid="' . $dialplan_uuid . '">' . "\n";
			$xml .= "\t<condition field=\"destination_number\" expression=\"" . xml::sanitize($regex) . "\">\n";
			$xml .= "\t\t<action application=\"export\" data=\"call_direction=inbound\" inline=\"true\"/>\n";
			$xml .= "\t\t<action application=\"set\" data=\"domain_uuid=" . $domain_uuid . "\" inline=\"true\"/>\n";
			$xml .= "\t\t<action application=\"set\" data=\"domain_name=" . xml::sanitize($domain_name) . "\" inline=\"true\"/>\n";
			// Keep the FreeSWITCH channel variable outside xml::sanitize(), which removes
			// ${...} expressions. The two path components have already been resolved
			// from trusted database records and are escaped independently.
			$recording_path = '${recordings_dir}/' . xml::sanitize($domain_name) . '/' . xml::sanitize($greeting_filename);
			$keypad_dispatch_data = 'app.lua mphone_keypad ' . $domain_name . ' ' . $ring_group_uuid;
			$keypad_digits = [];
			foreach ($keypad_mappings as $digit => $mapping) {
				$keypad_digits[] = (string) $digit;
				$keypad_dispatch_data .= ' ' . $digit . '=g:' . $keypad_ring_groups[$digit];
			}
			if ($route_type === 'simple_keypad' && count($keypad_digits) < 1) { throw new RuntimeException('keypad_mapping_required'); }
			sort($keypad_digits, SORT_STRING);
			$keypad_digit_pattern = '[' . implode('', $keypad_digits) . ']';
			if ($route_type === 'simple_greeting') {
				$xml .= "\t\t<action application=\"playback\" data=\"" . $recording_path . "\"/>\n";
			}
			if ($route_type === 'simple_keypad') {
				$xml .= "\t\t<action application=\"play_and_get_digits\" data=\"1 1 2 5000 # " . $recording_path . " silence_stream://250 mphone_digit " . $keypad_digit_pattern . "\"/>\n";
				$xml .= "\t\t<action application=\"lua\" data=\"" . xml::sanitize($keypad_dispatch_data) . "\"/>\n";
			}
			if (!in_array($route_type, ['service_suspended','simple_keypad'], true)) {
				$xml .= "\t\t<action application=\"set\" data=\"ring_group_uuid=" . $ring_group_uuid . "\"/>\n";
			}
			if ($route_type !== 'simple_keypad') {
				$xml .= "\t\t<action application=\"" . $action_app . "\" data=\"" . xml::sanitize($action_data) . "\"/>\n";
			}
			$xml .= "\t</condition>\n";
			$xml .= "</extension>";

			if ($route_type === 'service_suspended') {
				$actions = [['destination_app' => 'hangup', 'destination_data' => 'CALL_REJECTED']];
			}
			elseif ($route_type === 'simple_keypad') {
				$actions = [
					['destination_app' => 'play_and_get_digits', 'destination_data' => '1 1 2 5000 # ' . $recording_path . ' silence_stream://250 mphone_digit ' . $keypad_digit_pattern],
					['destination_app' => 'lua', 'destination_data' => $keypad_dispatch_data],
				];
			}
			else {
				$actions = [];
				if ($route_type === 'simple_greeting') {
					$actions[] = ['destination_app' => 'playback', 'destination_data' => $recording_path];
				}
				$actions[] = ['destination_app' => 'set', 'destination_data' => 'ring_group_uuid=' . $ring_group_uuid];
				$actions[] = ['destination_app' => 'lua', 'destination_data' => 'app.lua ring_groups'];
			}
			$array['dialplans'][0] = [
				'dialplan_uuid' => $dialplan_uuid,
				'domain_uuid' => $domain_uuid,
				'app_uuid' => 'c03b422e-13a8-bd1b-e42b-b6b9b4d27ce4',
				'dialplan_context' => 'public',
				'dialplan_name' => $name,
				'dialplan_number' => $did,
				'dialplan_destination' => true,
				'dialplan_continue' => false,
				'dialplan_xml' => $xml,
				'dialplan_order' => 100,
				'dialplan_enabled' => false,
				'dialplan_description' => 'Managed by Mphone route version ' . $route_version_uuid,
				'insert_date' => date('c'),
				'insert_user' => $this->user_uuid,
			];
			$details = [
				[uuid(), 'condition', 'destination_number', $regex, '', '', 0, 10],
				[uuid(), 'action', 'export', 'call_direction=inbound', '', 'true', 0, 20],
				[uuid(), 'action', 'set', 'domain_uuid=' . $domain_uuid, '', 'true', 0, 30],
				[uuid(), 'action', 'set', 'domain_name=' . $domain_name, '', 'true', 0, 40],
			];
			if ($route_type === 'simple_greeting') {
				$details[] = [uuid(), 'action', 'playback', $recording_path, '', 'false', 0, 50];
			}
			if ($route_type === 'simple_keypad') {
				$details[] = [uuid(), 'action', 'play_and_get_digits', '1 1 2 5000 # ' . $recording_path . ' silence_stream://250 mphone_digit ' . $keypad_digit_pattern, '', 'false', 0, 50];
				$details[] = [uuid(), 'action', 'lua', $keypad_dispatch_data, '', 'false', 0, 60];
			}
			elseif ($route_type !== 'service_suspended') {
				$details[] = [uuid(), 'action', 'set', 'ring_group_uuid=' . $ring_group_uuid, '', 'false', 0, 60];
				$details[] = [uuid(), 'action', 'lua', 'app.lua ring_groups', '', 'false', 0, 70];
			}
			else {
				$details[] = [uuid(), 'action', 'hangup', 'CALL_REJECTED', '', 'false', 0, 50];
			}
			foreach ($details as $index => $detail) {
				$array['dialplan_details'][$index] = [
					'dialplan_detail_uuid' => $detail[0], 'domain_uuid' => $domain_uuid,
					'dialplan_uuid' => $dialplan_uuid, 'dialplan_detail_tag' => $detail[1],
					'dialplan_detail_type' => $detail[2], 'dialplan_detail_data' => $detail[3],
					'dialplan_detail_break' => $detail[4], 'dialplan_detail_inline' => $detail[5],
					'dialplan_detail_group' => $detail[6], 'dialplan_detail_order' => $detail[7],
					'dialplan_detail_enabled' => true, 'insert_date' => date('c'), 'insert_user' => $this->user_uuid,
				];
			}
			$array['destinations'][0] = [
				'destination_uuid' => $destination_uuid, 'domain_uuid' => $domain_uuid,
				'dialplan_uuid' => $dialplan_uuid, 'destination_type' => 'inbound',
				'destination_number' => $did, 'destination_condition_field' => 'destination_number',
				'destination_number_regex' => $regex, 'destination_context' => 'public',
				'destination_actions' => json_encode($actions, JSON_UNESCAPED_SLASHES),
				'destination_app' => $actions[0]['destination_app'], 'destination_data' => $actions[0]['destination_data'],
				'destination_order' => 100, 'destination_enabled' => false,
				'destination_description' => 'Managed by Mphone route version ' . $route_version_uuid,
				'insert_date' => date('c'), 'insert_user' => $this->user_uuid,
			];
			$response = $this->database->save($array);
			if ($response === false) { throw new RuntimeException('fusion_route_prepare_failed'); }

			$fingerprint = hash('sha256', json_encode([
				'did' => $did, 'domain_uuid' => $domain_uuid, 'dialplan_xml' => $xml,
				'extensions' => array_column($extensions, 'extension_uuid'),
			], JSON_UNESCAPED_SLASHES));
			return [
				'fingerprint' => $fingerprint,
				'route_type' => $route_type,
				'recording_path' => $recording_path,
				'destination_uuid' => $destination_uuid,
				'dialplan_uuid' => $dialplan_uuid,
				'dialplan_detail_uuids' => array_column($details, 0),
				'ring_group_uuid' => $ring_group_uuid,
				'ring_group_uuids' => $ring_group_uuids,
				'ring_group_destination_uuids' => $ring_group_destination_uuids,
				'domain_uuid' => $domain_uuid,
				'canonical_e164' => $did,
			];
		}

		public function set_enabled(array $resources, bool $enabled): void {
			$value = $enabled ? 'true' : 'false';
			$this->database->execute(
				'update v_destinations set destination_enabled=:enabled,update_date=now(),update_user=:user_uuid '
				. 'where destination_uuid=:uuid and domain_uuid=:domain_uuid',
				['enabled' => $value, 'user_uuid' => $this->user_uuid, 'uuid' => $resources['destination_uuid'], 'domain_uuid' => $resources['domain_uuid']]
			);
			$ring_group_uuids = (array) ($resources['ring_group_uuids'] ?? [$resources['ring_group_uuid'] ?? '']);
			foreach (array_unique($ring_group_uuids) as $ring_group_uuid) {
				if (!is_uuid($ring_group_uuid)) { continue; }
				$this->database->execute(
					'update v_ring_groups set ring_group_enabled=:enabled,update_date=now(),update_user=:user_uuid '
					. 'where ring_group_uuid=:uuid and domain_uuid=:domain_uuid',
					['enabled' => $value, 'user_uuid' => $this->user_uuid, 'uuid' => $ring_group_uuid, 'domain_uuid' => $resources['domain_uuid']]
				);
			}
			$this->database->execute(
				'update v_dialplans set dialplan_enabled=:enabled,update_date=now(),update_user=:user_uuid '
				. 'where dialplan_uuid=:uuid and domain_uuid=:domain_uuid',
				['enabled' => $value, 'user_uuid' => $this->user_uuid, 'uuid' => $resources['dialplan_uuid'], 'domain_uuid' => $resources['domain_uuid']]
			);
			$cache = new cache;
			$cache->delete('dialplan:public');
			if (preg_match('/^\+[1-9][0-9]{7,14}$/', (string) ($resources['canonical_e164'] ?? ''))) {
				$cache->delete('dialplan:public:' . $resources['canonical_e164']);
			}
		}

		public function verify(array $resources, bool $expected_enabled): array {
			$row = $this->database->select(
				'select d.destination_enabled,d.destination_app,d.destination_actions,p.dialplan_enabled,p.dialplan_xml,g.ring_group_enabled, '
				. "(select count(*) from v_dialplan_details x where x.dialplan_uuid=p.dialplan_uuid and x.dialplan_detail_type='playback') as playback_count, "
				. "(select count(*) from v_dialplan_details x where x.dialplan_uuid=p.dialplan_uuid and x.dialplan_detail_type='play_and_get_digits') as keypad_count, "
				. "(select count(*) from v_dialplan_details x where x.dialplan_uuid=p.dialplan_uuid and x.dialplan_detail_type='lua' and x.dialplan_detail_data like 'app.lua mphone_keypad %') as keypad_dispatch_count "
				. 'from v_destinations d '
				. 'join v_dialplans p on p.dialplan_uuid=d.dialplan_uuid and p.domain_uuid=d.domain_uuid '
				. 'left join v_ring_groups g on g.ring_group_uuid=:ring_group_uuid and g.domain_uuid=d.domain_uuid '
				. 'where d.destination_uuid=:destination_uuid and d.domain_uuid=:domain_uuid '
				. 'and p.dialplan_uuid=:dialplan_uuid',
				['destination_uuid' => $resources['destination_uuid'], 'domain_uuid' => $resources['domain_uuid'], 'dialplan_uuid' => $resources['dialplan_uuid'],
					'ring_group_uuid' => $resources['ring_group_uuid'] ?? '00000000-0000-0000-0000-000000000000'],
				'row'
			);
			$route_type = (string) ($resources['route_type'] ?? 'simple_direct');
			$xml = is_array($row) ? (string) ($row['dialplan_xml'] ?? '') : '';
			$ring_groups_valid = true;
			foreach (array_unique((array) ($resources['ring_group_uuids'] ?? [$resources['ring_group_uuid'] ?? ''])) as $ring_group_uuid) {
				if (!is_uuid($ring_group_uuid)) { continue; }
				$ring_group_enabled = $this->database->select(
					'select ring_group_enabled from v_ring_groups where ring_group_uuid=:uuid and domain_uuid=:domain_uuid',
					['uuid' => $ring_group_uuid, 'domain_uuid' => $resources['domain_uuid']], 'column');
				$ring_groups_valid = $ring_groups_valid
					&& filter_var($ring_group_enabled, FILTER_VALIDATE_BOOLEAN) === $expected_enabled;
			}
			$route_valid = is_array($row) && match ($route_type) {
				'simple_keypad' => ($row['destination_app'] ?? '') === 'play_and_get_digits'
					&& (int) ($row['keypad_count'] ?? 0) === 1
					&& (int) ($row['keypad_dispatch_count'] ?? 0) === 1
					&& str_contains($xml, 'application="play_and_get_digits"')
					&& str_contains($xml, 'app.lua mphone_keypad ')
					&& str_contains($xml, '${recordings_dir}/'),
				'simple_greeting' => ($row['destination_app'] ?? '') === 'playback'
					&& (int) ($row['playback_count'] ?? 0) === 1
					&& str_contains($xml, 'application="playback"')
					&& str_contains($xml, '${recordings_dir}/'),
				'service_suspended' => ($row['destination_app'] ?? '') === 'hangup'
					&& str_contains($xml, 'application="hangup"'),
				default => ($row['destination_app'] ?? '') === 'set'
					&& str_contains($xml, 'app.lua ring_groups'),
			};
			$valid = is_array($row)
				&& filter_var($row['destination_enabled'], FILTER_VALIDATE_BOOLEAN) === $expected_enabled
				&& filter_var($row['dialplan_enabled'], FILTER_VALIDATE_BOOLEAN) === $expected_enabled
				&& $ring_groups_valid
				&& str_contains($xml, (string) $resources['dialplan_uuid'])
				&& !str_contains($xml, 'data="$/')
				&& $route_valid;
			return ['valid' => $valid, 'fingerprint' => $resources['fingerprint']];
		}

		public function apply_outbound_caller_ids(array $assignments, array $assignment_numbers, string $domain_uuid): array {
			$previous = [];
			foreach ($assignments as $extension_uuid => $assignment_uuid) {
				if (!is_uuid((string) $extension_uuid) || ($assignment_uuid !== '' && !is_uuid((string) $assignment_uuid))) {
					throw new RuntimeException('invalid_outbound_assignments');
				}
				$row = $this->database->select('select outbound_caller_id_name,outbound_caller_id_number from v_extensions '
					. 'where extension_uuid=:extension_uuid and domain_uuid=:domain_uuid and enabled=true',
					['extension_uuid' => $extension_uuid, 'domain_uuid' => $domain_uuid], 'row');
				if (!is_array($row)) { throw new RuntimeException('extension_not_active'); }
				$previous[$extension_uuid] = $row;
				$number = $assignment_uuid === '' ? '' : (string) ($assignment_numbers[$assignment_uuid] ?? '');
				if ($assignment_uuid !== '' && !preg_match('/^\+[1-9][0-9]{7,14}$/', $number)) {
					throw new RuntimeException('outbound_caller_id_forbidden');
				}
				$this->database->execute('update v_extensions set outbound_caller_id_number=:number,update_date=now(),update_user=:user_uuid '
					. 'where extension_uuid=:extension_uuid and domain_uuid=:domain_uuid',
					['number' => $number, 'user_uuid' => $this->user_uuid, 'extension_uuid' => $extension_uuid, 'domain_uuid' => $domain_uuid]);
			}
			return $previous;
		}

		public function restore_outbound_caller_ids(array $previous, string $domain_uuid): void {
			foreach ($previous as $extension_uuid => $values) {
				$this->database->execute('update v_extensions set outbound_caller_id_name=:name,outbound_caller_id_number=:number,'
					. 'update_date=now(),update_user=:user_uuid where extension_uuid=:extension_uuid and domain_uuid=:domain_uuid',
					['name' => $values['outbound_caller_id_name'] ?? '', 'number' => $values['outbound_caller_id_number'] ?? '',
						'user_uuid' => $this->user_uuid, 'extension_uuid' => $extension_uuid, 'domain_uuid' => $domain_uuid]);
			}
		}

		public function delete_prepared(array $resources): void {
			if (!is_uuid($resources['domain_uuid'] ?? '')) { return; }
			if (is_uuid($resources['destination_uuid'] ?? '')) {
				$this->database->execute('delete from v_destinations where destination_uuid=:uuid and domain_uuid=:domain_uuid and coalesce(destination_enabled,false)=false',
					['uuid'=>$resources['destination_uuid'],'domain_uuid'=>$resources['domain_uuid']]);
			}
			if (is_uuid($resources['dialplan_uuid'] ?? '')) {
				$this->database->execute('delete from v_dialplan_details where dialplan_uuid=:uuid and domain_uuid=:domain_uuid',
					['uuid'=>$resources['dialplan_uuid'],'domain_uuid'=>$resources['domain_uuid']]);
				$this->database->execute('delete from v_dialplans where dialplan_uuid=:uuid and domain_uuid=:domain_uuid and coalesce(dialplan_enabled,false)=false',
					['uuid'=>$resources['dialplan_uuid'],'domain_uuid'=>$resources['domain_uuid']]);
			}
			foreach (array_unique((array) ($resources['ring_group_uuids'] ?? [$resources['ring_group_uuid'] ?? ''])) as $ring_group_uuid) {
				if (!is_uuid($ring_group_uuid)) { continue; }
				$this->database->execute('delete from v_ring_group_destinations where ring_group_uuid=:uuid and domain_uuid=:domain_uuid',
					['uuid'=>$ring_group_uuid,'domain_uuid'=>$resources['domain_uuid']]);
				$this->database->execute('delete from v_ring_groups where ring_group_uuid=:uuid and domain_uuid=:domain_uuid and coalesce(ring_group_enabled,false)=false',
					['uuid'=>$ring_group_uuid,'domain_uuid'=>$resources['domain_uuid']]);
			}
		}
	}

?>

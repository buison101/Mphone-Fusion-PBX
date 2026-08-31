<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/identity_session.php';
	require_once dirname(__DIR__) . '/resources/simple_call_routing_auth.php';
	require_once dirname(__DIR__) . '/resources/request.php';
	require_once dirname(__DIR__) . '/resources/call_routing_platform.php';
	require_once dirname(__DIR__) . '/resources/simple_call_routing_publisher.php';

	portal_json_headers();
	if (!portal_identity_validate_session(true) || empty($_SESSION['authorized'])) {
		http_response_code(401);
		echo json_encode(['error' => 'unauthorized']);
		exit;
	}
	if (portal_identity_is_active() || !if_group('superadmin')) {
		http_response_code(403);
		echo json_encode(['error' => 'forbidden']);
		exit;
	}

	$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
	$input = $method === 'POST' ? json_decode(file_get_contents('php://input'), true) : $_GET;
	$input = is_array($input) ? $input : [];
	if ($method === 'POST') { portal_require_csrf(); }
	elseif ($method !== 'GET') {
		http_response_code(405);
		echo json_encode(['error' => 'method_not_allowed']);
		exit;
	}
	$action = trim((string) ($input['action'] ?? 'list'));
	$permission_map = [
		'list' => 'did_inventory_view',
		'create' => 'did_inventory_manage',
		'reserve' => 'did_inventory_manage',
		'assign' => 'did_assign',
		'suspend' => 'did_suspend',
		'resume' => 'did_suspend',
		'release' => 'did_release',
		'transfer' => 'did_transfer',
		'advanced_inspect' => 'call_routing_view_snapshot',
		'takeover_advanced' => 'call_routing_takeover',
		'release_to_simple' => 'call_routing_release',
	];
	if (!isset($permission_map[$action]) || !permission_exists($permission_map[$action])) {
		http_response_code(isset($permission_map[$action]) ? 403 : 400);
		echo json_encode(['error' => isset($permission_map[$action]) ? 'forbidden' : 'invalid_request']);
		exit;
	}

	function did_inventory_platform(array $payload, string $permission): array {
		$result = portal_call_routing_platform_request($payload, $permission);
		if (!in_array((int) ($result['status'] ?? 0), [200, 201, 202], true)) {
			throw new RuntimeException((string) ($result['payload']['error'] ?? 'service_unavailable'), (int) ($result['status'] ?? 503));
		}
		return is_array($result['payload'] ?? null) ? $result['payload'] : [];
	}

	function did_inventory_publish_work(array $work_item, string $did_uuid, string $operation_key,
		string $permission, portal_simple_call_routing_publisher $publisher): array {
		$resources = $publisher->prepare_direct($work_item);
		$resource_rows = [
			['resource_type' => 'destination', 'fusion_resource_uuid' => $resources['destination_uuid']],
			['resource_type' => 'dialplan', 'fusion_resource_uuid' => $resources['dialplan_uuid']],
		];
		foreach (array_unique((array) ($resources['ring_group_uuids'] ?? [$resources['ring_group_uuid']])) as $ring_group_uuid) {
			$resource_rows[] = ['resource_type' => 'ring_group', 'fusion_resource_uuid' => $ring_group_uuid];
		}
		foreach ($resources['dialplan_detail_uuids'] as $detail_uuid) {
			$resource_rows[] = ['resource_type' => 'dialplan_detail', 'fusion_resource_uuid' => $detail_uuid];
		}
		foreach ($resources['ring_group_destination_uuids'] as $ring_destination_uuid) {
			$resource_rows[] = ['resource_type' => 'ring_group_destination', 'fusion_resource_uuid' => $ring_destination_uuid];
		}
		did_inventory_platform([
			'action' => 'register_route_resources', 'route_version_uuid' => $work_item['route_version_uuid'],
			'fusion_domain_uuid' => $work_item['fusion_domain_uuid'],
			'expected_fingerprint' => $resources['fingerprint'], 'resources' => $resource_rows,
		], $permission);
		did_inventory_platform([
			'action' => 'advance_route', 'route_version_uuid' => $work_item['route_version_uuid'],
			'expected_management_revision' => (int) $work_item['management_revision'],
			'target_status' => 'generated', 'observed_fingerprint' => $resources['fingerprint'],
		], $permission);
		$prepared_verification = $publisher->verify($resources, false);
		if (!$prepared_verification['valid']) { throw new RuntimeException('prepared_route_verification_failed'); }
		did_inventory_platform([
			'action' => 'advance_route', 'route_version_uuid' => $work_item['route_version_uuid'],
			'expected_management_revision' => (int) $work_item['management_revision'],
			'target_status' => 'validated', 'validation_result' => $prepared_verification,
		], $permission);
		$publish_operation = did_inventory_platform([
			'action' => 'begin_operation', 'operation_type' => 'publish_route', 'did_uuid' => $did_uuid,
			'did_assignment_uuid' => $work_item['did_assignment_uuid'],
			'route_version_uuid' => $work_item['route_version_uuid'],
			'expected_assignment_revision' => (int) $work_item['assignment_revision'],
			'expected_management_revision' => (int) $work_item['management_revision'],
			'operation_key' => $operation_key . ':publish', 'request_payload' => [],
		], $permission);
		$previous = ['domain_uuid' => $work_item['fusion_domain_uuid'], 'fingerprint' => 'previous'];
		foreach ((array) ($work_item['previous_resources'] ?? []) as $previous_resource) {
			if (($previous_resource['resource_type'] ?? '') === 'destination') { $previous['destination_uuid'] = $previous_resource['fusion_resource_uuid'] ?? ''; }
			if (($previous_resource['resource_type'] ?? '') === 'dialplan') { $previous['dialplan_uuid'] = $previous_resource['fusion_resource_uuid'] ?? ''; }
			if (($previous_resource['resource_type'] ?? '') === 'ring_group') {
				$previous['ring_group_uuids'][] = $previous_resource['fusion_resource_uuid'] ?? '';
				$previous['ring_group_uuid'] ??= $previous_resource['fusion_resource_uuid'] ?? '';
			}
		}
		$previous['canonical_e164'] = $work_item['canonical_e164'] ?? '';
		$has_previous = is_uuid($previous['destination_uuid'] ?? '') && is_uuid($previous['dialplan_uuid'] ?? '');
		try {
			if ($has_previous) { $publisher->set_enabled($previous, false); }
			$publisher->set_enabled($resources, true);
			$published_verification = $publisher->verify($resources, true);
			if (!$published_verification['valid']) { throw new RuntimeException('published_route_verification_failed'); }
		}
		catch (Throwable $error) {
			try { $publisher->set_enabled($resources, false); } catch (Throwable $ignored) { }
			if ($has_previous) { try { $publisher->set_enabled($previous, true); } catch (Throwable $ignored) { } }
			throw $error;
		}
		did_inventory_platform([
			'action' => 'publish_route',
			'did_operation_uuid' => $publish_operation['operation']['did_operation_uuid'],
			'expected_management_revision' => (int) $work_item['management_revision'],
			'verified_fingerprint' => $resources['fingerprint'],
			'verification_result' => $published_verification,
		], $permission);
		$resources['_previous_resources'] = $previous;
		return $resources;
	}

	try {
		if ($action === 'list') {
			$payload = did_inventory_platform(['action' => 'inventory_list'], $permission_map[$action]);
			http_response_code(200);
			echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
			exit;
		}
		if ($action === 'create') {
			$payload = did_inventory_platform([
				'action' => 'inventory_create',
				'canonical_e164' => trim((string) ($input['canonical_e164'] ?? '')),
				'display_number' => trim((string) ($input['display_number'] ?? '')),
				'country_code' => trim((string) ($input['country_code'] ?? '')),
				'provider_reference' => trim((string) ($input['provider_reference'] ?? '')),
				'provider_service_status' => trim((string) ($input['provider_service_status'] ?? 'provisioning')),
				'capabilities' => [
					'inbound' => ($input['inbound'] ?? false) === true,
					'outbound_caller_id' => ($input['outbound_caller_id'] ?? false) === true,
				],
				'reason' => trim((string) ($input['reason'] ?? '')),
			], $permission_map[$action]);
			http_response_code(201);
			echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
			exit;
		}
		if ($action === 'advanced_inspect') {
			$payload = did_inventory_platform(['action'=>'advanced_inspect',
				'did_assignment_uuid'=>(string)($input['did_assignment_uuid']??'')], $permission_map[$action]);
			echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE); exit;
		}
		if ($action === 'takeover_advanced') {
			$operation = did_inventory_platform(['action'=>'begin_operation','operation_type'=>'takeover',
				'did_uuid'=>(string)($input['did_uuid']??''),'did_assignment_uuid'=>(string)($input['did_assignment_uuid']??''),
				'expected_assignment_revision'=>(int)($input['expected_assignment_revision']??0),
				'expected_management_revision'=>(int)($input['expected_management_revision']??0),
				'operation_key'=>trim((string)($input['operation_key']??'')),'reason'=>trim((string)($input['reason']??'')),
				'request_payload'=>['requested_mode'=>'mphone_advanced']], $permission_map[$action]);
			$payload = did_inventory_platform(['action'=>'takeover_advanced',
				'did_operation_uuid'=>$operation['operation']['did_operation_uuid']], $permission_map[$action]);
			echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE); exit;
		}
		if ($action === 'release_to_simple') {
			$operation_key=trim((string)($input['operation_key']??'')); $operation_uuid=''; $resources=null;
			$publisher=new portal_simple_call_routing_publisher($database,(string)$_SESSION['user_uuid']);
			try {
				$prepared=did_inventory_platform(['action'=>'prepare_release_to_simple','did_uuid'=>(string)($input['did_uuid']??''),
					'did_assignment_uuid'=>(string)($input['did_assignment_uuid']??''),
					'extension_uuids'=>array_values(array_unique(array_filter((array)($input['extension_uuids']??[]),'is_uuid'))),
					'expected_assignment_revision'=>(int)($input['expected_assignment_revision']??0),
					'expected_management_revision'=>(int)($input['expected_management_revision']??0),
					'operation_key'=>$operation_key,'reason'=>trim((string)($input['reason']??''))],$permission_map[$action]);
				$operation_uuid=(string)($prepared['operation_uuid']??''); $work=(array)($prepared['work_item']??[]);
				$resources=did_inventory_publish_work($work,(string)($input['did_uuid']??''),$operation_key,
					$permission_map[$action],$publisher);
				$finalized=did_inventory_platform(['action'=>'finalize_release_to_simple','operation_uuid'=>$operation_uuid],$permission_map[$action]);
				try { $publisher->delete_prepared((array)($resources['_previous_resources']??[])); }
				catch (Throwable $cleanup_error) { error_log('Mphone advanced entry cleanup failed: '.$cleanup_error->getMessage()); }
				if (is_uuid($work['source_route_version_uuid']??'')) {
					try { did_inventory_platform(['action'=>'mark_route_resources_missing',
						'route_version_uuid'=>$work['source_route_version_uuid']],$permission_map[$action]); }
					catch (Throwable $cleanup_error) { error_log('Mphone resource status cleanup failed: '.$cleanup_error->getMessage()); }
				}
				echo json_encode($finalized,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE); exit;
			}
			catch (Throwable $release_error) {
				if (is_array($resources)) { try { $publisher->set_enabled($resources,false); $publisher->delete_prepared($resources); } catch (Throwable) {} }
				if (is_uuid($operation_uuid)) { portal_call_routing_platform_request(['action'=>'fail_release_to_simple',
					'operation_uuid'=>$operation_uuid,'error_code'=>substr($release_error->getMessage(),0,100)],$permission_map[$action]); }
				throw $release_error;
			}
		}
		if ($action === 'reserve') {
			$payload = did_inventory_platform([
				'action' => 'reserve_did',
				'did_uuid' => (string) ($input['did_uuid'] ?? ''),
				'expected_inventory_revision' => (int) ($input['expected_inventory_revision'] ?? 0),
				'operation_key' => trim((string) ($input['operation_key'] ?? '')),
				'reason' => trim((string) ($input['reason'] ?? '')),
			], $permission_map[$action]);
			echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
			exit;
		}
		if (in_array($action, ['suspend', 'resume', 'release'], true)) {
			$operation_key = trim((string) ($input['operation_key'] ?? ''));
			$prepare = did_inventory_platform([
				'action' => 'prepare_service_transition', 'operation_type' => $action,
				'did_uuid' => (string) ($input['did_uuid'] ?? ''),
				'did_assignment_uuid' => (string) ($input['did_assignment_uuid'] ?? ''),
				'expected_assignment_revision' => (int) ($input['expected_assignment_revision'] ?? 0),
				'expected_management_revision' => (int) ($input['expected_management_revision'] ?? 0),
				'operation_key' => $operation_key, 'reason' => trim((string) ($input['reason'] ?? '')),
			], $permission_map[$action]);
			$operation_uuid = (string) ($prepare['operation_uuid'] ?? '');
			$work_item = is_array($prepare['work_item'] ?? null) ? $prepare['work_item'] : [];
			$publisher = new portal_simple_call_routing_publisher($database, (string) $_SESSION['user_uuid']);
			$published = false;
			try {
				did_inventory_publish_work($work_item, (string) ($input['did_uuid'] ?? ''), $operation_key,
					$permission_map[$action], $publisher);
				$published = true;
				$finalized = did_inventory_platform([
					'action' => 'finalize_service_transition', 'operation_uuid' => $operation_uuid,
				], $permission_map[$action]);
				echo json_encode($finalized, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
				exit;
			}
			catch (Throwable $transition_error) {
				if (!$published && is_uuid($operation_uuid)) {
					portal_call_routing_platform_request([
						'action' => 'fail_service_transition', 'operation_uuid' => $operation_uuid,
						'error_code' => substr($transition_error->getMessage(), 0, 100),
					], $permission_map[$action]);
				}
				throw $transition_error;
			}
		}
		if ($action === 'transfer') {
			$operation_key = trim((string) ($input['operation_key'] ?? ''));
			$prepare = did_inventory_platform([
				'action' => 'prepare_transfer', 'did_uuid' => (string) ($input['did_uuid'] ?? ''),
				'source_assignment_uuid' => (string) ($input['did_assignment_uuid'] ?? ''),
				'target_customer_uuid' => (string) ($input['customer_uuid'] ?? ''),
				'target_domain_uuid' => (string) ($input['fusion_domain_uuid'] ?? ''),
				'extension_uuids' => array_values(array_filter((array) ($input['extension_uuids'] ?? []), 'is_uuid')),
				'expected_assignment_revision' => (int) ($input['expected_assignment_revision'] ?? 0),
				'expected_management_revision' => (int) ($input['expected_management_revision'] ?? 0),
				'operation_key' => $operation_key, 'reason' => trim((string) ($input['reason'] ?? '')),
			], $permission_map[$action]);
			$operation_uuid = (string) ($prepare['operation_uuid'] ?? '');
			$work_item = is_array($prepare['work_item'] ?? null) ? $prepare['work_item'] : [];
			$publisher = new portal_simple_call_routing_publisher($database, (string) $_SESSION['user_uuid']);
			$published = false;
			try {
				did_inventory_publish_work($work_item, (string) ($input['did_uuid'] ?? ''), $operation_key,
					$permission_map[$action], $publisher);
				$published = true;
				$finalized = did_inventory_platform(['action' => 'finalize_transfer',
					'operation_uuid' => $operation_uuid], $permission_map[$action]);
				echo json_encode($finalized, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
				exit;
			}
			catch (Throwable $transfer_error) {
				if (!$published && is_uuid($operation_uuid)) {
					portal_call_routing_platform_request(['action' => 'fail_transfer',
						'operation_uuid' => $operation_uuid,
						'error_code' => substr($transfer_error->getMessage(), 0, 100)], $permission_map[$action]);
				}
				throw $transfer_error;
			}
		}
		if ($action === 'assign') {
			$operation_key = trim((string) ($input['operation_key'] ?? ''));
			$prepare = did_inventory_platform([
				'action' => 'prepare_assignment',
				'did_uuid' => (string) ($input['did_uuid'] ?? ''),
				'customer_uuid' => (string) ($input['customer_uuid'] ?? ''),
				'fusion_domain_uuid' => (string) ($input['fusion_domain_uuid'] ?? ''),
				'initial_mode' => 'portal_simple',
				'extension_uuids' => array_values(array_filter((array) ($input['extension_uuids'] ?? []), 'is_uuid')),
				'operation_key' => $operation_key,
				'reason' => trim((string) ($input['reason'] ?? '')),
			], $permission_map[$action]);
			$assignment_operation_uuid = (string) ($prepare['operation_uuid'] ?? '');
			$work_item = is_array($prepare['work_item'] ?? null) ? $prepare['work_item'] : [];
			$resources = null;
			$publisher = new portal_simple_call_routing_publisher($database, (string) $_SESSION['user_uuid']);
			try {
				$resources = $publisher->prepare_direct($work_item);
				$resource_rows = [
					['resource_type' => 'destination', 'fusion_resource_uuid' => $resources['destination_uuid']],
					['resource_type' => 'dialplan', 'fusion_resource_uuid' => $resources['dialplan_uuid']],
					['resource_type' => 'ring_group', 'fusion_resource_uuid' => $resources['ring_group_uuid']],
				];
				foreach ($resources['dialplan_detail_uuids'] as $detail_uuid) {
					$resource_rows[] = ['resource_type' => 'dialplan_detail', 'fusion_resource_uuid' => $detail_uuid];
				}
				foreach ($resources['ring_group_destination_uuids'] as $ring_destination_uuid) {
					$resource_rows[] = ['resource_type' => 'ring_group_destination', 'fusion_resource_uuid' => $ring_destination_uuid];
				}
				did_inventory_platform([
					'action' => 'register_route_resources',
					'route_version_uuid' => $work_item['route_version_uuid'],
					'fusion_domain_uuid' => $work_item['fusion_domain_uuid'],
					'expected_fingerprint' => $resources['fingerprint'],
					'resources' => $resource_rows,
				], $permission_map[$action]);
				did_inventory_platform([
					'action' => 'advance_route', 'route_version_uuid' => $work_item['route_version_uuid'],
					'expected_management_revision' => (int) $work_item['management_revision'],
					'target_status' => 'generated', 'observed_fingerprint' => $resources['fingerprint'],
				], $permission_map[$action]);
				$prepared_verification = $publisher->verify($resources, false);
				if (!$prepared_verification['valid']) { throw new RuntimeException('prepared_route_verification_failed'); }
				did_inventory_platform([
					'action' => 'advance_route', 'route_version_uuid' => $work_item['route_version_uuid'],
					'expected_management_revision' => (int) $work_item['management_revision'],
					'target_status' => 'validated', 'validation_result' => $prepared_verification,
				], $permission_map[$action]);
				$publish_operation = did_inventory_platform([
					'action' => 'begin_operation', 'operation_type' => 'publish_route',
					'did_uuid' => (string) ($input['did_uuid'] ?? ''),
					'did_assignment_uuid' => $work_item['did_assignment_uuid'],
					'route_version_uuid' => $work_item['route_version_uuid'],
					'expected_assignment_revision' => 1,
					'expected_management_revision' => (int) $work_item['management_revision'],
					'operation_key' => $operation_key . ':publish',
					'request_payload' => ['assignment_operation_uuid' => $assignment_operation_uuid],
				], $permission_map[$action]);
				$publisher->set_enabled($resources, true);
				$published_verification = $publisher->verify($resources, true);
				if (!$published_verification['valid']) { throw new RuntimeException('published_route_verification_failed'); }
				did_inventory_platform([
					'action' => 'publish_route',
					'did_operation_uuid' => $publish_operation['operation']['did_operation_uuid'],
					'expected_management_revision' => (int) $work_item['management_revision'],
					'verified_fingerprint' => $resources['fingerprint'],
					'verification_result' => $published_verification,
				], $permission_map[$action]);
				$activated = did_inventory_platform([
					'action' => 'activate_assignment',
					'assignment_operation_uuid' => $assignment_operation_uuid,
				], $permission_map[$action]);
				echo json_encode($activated, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
				exit;
			}
			catch (Throwable $route_error) {
				if (is_array($resources)) {
					try { $publisher->set_enabled($resources, false); } catch (Throwable $ignored) { }
					try { $publisher->delete_prepared($resources); } catch (Throwable $ignored) { }
				}
				if (is_uuid($assignment_operation_uuid)) {
					portal_call_routing_platform_request([
						'action' => 'fail_assignment', 'assignment_operation_uuid' => $assignment_operation_uuid,
						'error_code' => substr($route_error->getMessage(), 0, 100),
					], $permission_map[$action]);
				}
				throw $route_error;
			}
		}
	}
	catch (Throwable $error) {
		$status = (int) $error->getCode();
		if (!in_array($status, [400, 401, 403, 404, 409, 422], true)) { $status = 503; }
		http_response_code($status);
		echo json_encode(['error' => $error->getMessage()]);
	}

?>

<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/identity_session.php';
	require_once dirname(__DIR__) . '/resources/call_routing_platform.php';
	require_once dirname(__DIR__) . '/resources/simple_call_routing_publisher.php';

	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');
	header('X-Content-Type-Options: nosniff');

	if (!portal_identity_validate_session(true) || !portal_identity_has_workspace()) {
		http_response_code(401); echo json_encode(['error' => 'unauthorized']); exit;
	}
	if ((string) ($_SESSION['portal_identity']['membership']['role'] ?? '') !== 'owner') {
		http_response_code(403); echo json_encode(['error' => 'owner_required']); exit;
	}
	$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
	if (!in_array($method, ['GET','POST'], true)) {
		http_response_code(405); echo json_encode(['error' => 'method_not_allowed']); exit;
	}
	$input = $method === 'POST' ? json_decode(file_get_contents('php://input'), true) : $_GET;
	$input = is_array($input) ? $input : [];
	if ($method === 'POST') {
		$provided = trim((string) ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ''));
		$expected = (string) ($_SESSION['portal']['csrf'] ?? '');
		if ($provided === '' || $expected === '' || !hash_equals($expected, $provided)) {
			http_response_code(403); echo json_encode(['error' => 'invalid_csrf']); exit;
		}
	}

	function simple_routing_platform(array $payload): array {
		$result = portal_call_routing_customer_request($payload);
		if (!in_array($result['status'], [200,201,202], true)) {
			throw new RuntimeException((string) ($result['payload']['error'] ?? 'customer_platform_unavailable'), $result['status']);
		}
		return $result['payload'];
	}

	if ($method === 'GET') {
		$result = portal_call_routing_customer_request(['action' => 'customer_routing_view']);
		http_response_code($result['status'] === 200 ? 200 : (in_array($result['status'], [401,403], true) ? $result['status'] : 503));
		echo json_encode($result['payload'], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE); exit;
	}

	if (($input['action'] ?? '') !== 'save_apply') {
		http_response_code(400); echo json_encode(['error' => 'invalid_request']); exit;
	}
	$extension_uuids = array_values(array_unique(array_filter((array) ($input['extension_uuids'] ?? []), 'is_uuid')));
	$outbound_assignments = is_array($input['outbound_assignments'] ?? null) ? $input['outbound_assignments'] : [];
	if (!is_uuid($input['did_uuid'] ?? '') || !is_uuid($input['did_assignment_uuid'] ?? '') || count($extension_uuids) < 1) {
		http_response_code(400); echo json_encode(['error' => 'invalid_request']); exit;
	}

	$publisher = new portal_simple_call_routing_publisher($database, (string) $_SESSION['user_uuid']);
	$new_resources = null; $previous_resources = []; $previous_caller_ids = []; $prepared_route_uuid = ''; $publish_completed = false;
	try {
		$prepared = simple_routing_platform([
			'action' => 'customer_prepare_simple_route', 'did_uuid' => $input['did_uuid'],
			'did_assignment_uuid' => $input['did_assignment_uuid'], 'extension_uuids' => $extension_uuids,
			'outbound_assignments' => $outbound_assignments,
			'route_type' => (string) ($input['route_type'] ?? 'simple_direct'),
			'greeting_recording_uuid' => (string) ($input['greeting_recording_uuid'] ?? ''),
			'keypad_mappings' => is_array($input['keypad_mappings'] ?? null) ? $input['keypad_mappings'] : [],
			'expected_assignment_revision' => (int) ($input['expected_assignment_revision'] ?? 0),
			'expected_management_revision' => (int) ($input['expected_management_revision'] ?? 0),
			'operation_key' => trim((string) ($input['operation_key'] ?? '')) ?: uuid(),
			'reason' => trim((string) ($input['reason'] ?? '')),
		]);
		$work = $prepared['work_item'];
		$prepared_route_uuid = (string) ($work['route_version_uuid'] ?? '');
		$temporary = permissions::new();
		foreach (['destination_add','dialplan_add','dialplan_detail_add','ring_group_add','ring_group_destination_add'] as $permission) {
			$temporary->add($permission, 'temp');
		}
		try { $new_resources = $publisher->prepare_direct($work); }
		finally {
			foreach (['destination_add','dialplan_add','dialplan_detail_add','ring_group_add','ring_group_destination_add'] as $permission) {
				$temporary->delete($permission, 'temp');
			}
		}
		$resource_rows = [
			['resource_type'=>'destination','fusion_resource_uuid'=>$new_resources['destination_uuid']],
			['resource_type'=>'dialplan','fusion_resource_uuid'=>$new_resources['dialplan_uuid']],
		];
		foreach (array_unique((array) ($new_resources['ring_group_uuids'] ?? [$new_resources['ring_group_uuid']])) as $uuid) {
			$resource_rows[] = ['resource_type'=>'ring_group','fusion_resource_uuid'=>$uuid];
		}
		foreach ($new_resources['dialplan_detail_uuids'] as $uuid) $resource_rows[] = ['resource_type'=>'dialplan_detail','fusion_resource_uuid'=>$uuid];
		foreach ($new_resources['ring_group_destination_uuids'] as $uuid) $resource_rows[] = ['resource_type'=>'ring_group_destination','fusion_resource_uuid'=>$uuid];
		simple_routing_platform(['action'=>'register_route_resources','route_version_uuid'=>$work['route_version_uuid'],
			'fusion_domain_uuid'=>$work['fusion_domain_uuid'],'expected_fingerprint'=>$new_resources['fingerprint'],'resources'=>$resource_rows]);
		simple_routing_platform(['action'=>'advance_route','route_version_uuid'=>$work['route_version_uuid'],
			'expected_management_revision'=>(int)$work['management_revision'],'target_status'=>'generated',
			'observed_fingerprint'=>$new_resources['fingerprint']]);
		$verification = $publisher->verify($new_resources, false);
		if (!$verification['valid']) throw new RuntimeException('prepared_route_verification_failed');
		simple_routing_platform(['action'=>'advance_route','route_version_uuid'=>$work['route_version_uuid'],
			'expected_management_revision'=>(int)$work['management_revision'],'target_status'=>'validated','validation_result'=>$verification]);
		foreach ((array) ($work['previous_resources'] ?? []) as $resource) {
			if (($resource['resource_type'] ?? '') === 'destination') $previous_resources['destination_uuid'] = $resource['fusion_resource_uuid'];
			if (($resource['resource_type'] ?? '') === 'dialplan') $previous_resources['dialplan_uuid'] = $resource['fusion_resource_uuid'];
			if (($resource['resource_type'] ?? '') === 'ring_group') {
				$previous_resources['ring_group_uuids'][] = $resource['fusion_resource_uuid'];
				$previous_resources['ring_group_uuid'] ??= $resource['fusion_resource_uuid'];
			}
		}
		$previous_resources['domain_uuid'] = $work['fusion_domain_uuid'];
		if (is_uuid($previous_resources['destination_uuid'] ?? '') && is_uuid($previous_resources['dialplan_uuid'] ?? '')) {
			$publisher->set_enabled($previous_resources, false);
		}
		$previous_caller_ids = $publisher->apply_outbound_caller_ids($outbound_assignments,
			(array) ($work['outbound_numbers'] ?? []), $work['fusion_domain_uuid']);
		$publisher->set_enabled($new_resources, true);
		$enabled = $publisher->verify($new_resources, true);
		if (!$enabled['valid']) throw new RuntimeException('published_route_verification_failed');
		$publish_operation = simple_routing_platform(['action'=>'begin_operation','operation_type'=>'publish_route',
			'did_uuid'=>$input['did_uuid'],'did_assignment_uuid'=>$input['did_assignment_uuid'],
			'route_version_uuid'=>$work['route_version_uuid'],'expected_assignment_revision'=>(int)$work['assignment_revision'],
			'expected_management_revision'=>(int)$work['management_revision'],'operation_key'=>'owner-publish-' . $work['route_version_uuid']]);
		$published = simple_routing_platform(['action'=>'publish_route','did_operation_uuid'=>$publish_operation['operation']['did_operation_uuid'],
			'expected_management_revision'=>(int)$work['management_revision'],'verified_fingerprint'=>$enabled['fingerprint'],
			'verification_result'=>$enabled]);
		$publish_completed = true;
		simple_routing_platform(['action'=>'customer_apply_simple_preferences','route_version_uuid'=>$work['route_version_uuid']]);
		if (is_uuid($work['previous_route_version_uuid'] ?? '')
			&& is_uuid($previous_resources['destination_uuid'] ?? '') && is_uuid($previous_resources['dialplan_uuid'] ?? '')) {
			try {
				$publisher->delete_prepared($previous_resources);
				simple_routing_platform(['action'=>'customer_mark_route_resources_missing',
					'route_version_uuid'=>$work['previous_route_version_uuid']]);
			}
			catch (Throwable $cleanup_error) {
				error_log('Mphone route cleanup failed: ' . $cleanup_error->getMessage());
			}
		}
		echo json_encode(['applied'=>true,'route_version'=>$published['route_version']], JSON_UNESCAPED_SLASHES); exit;
	}
	catch (Throwable $error) {
		if (!$publish_completed && is_array($new_resources)) { try { $publisher->set_enabled($new_resources, false); } catch (Throwable) {} }
		if (!$publish_completed && $previous_caller_ids) { try { $publisher->restore_outbound_caller_ids($previous_caller_ids, (string) ($new_resources['domain_uuid'] ?? '')); } catch (Throwable) {} }
		if (!$publish_completed && is_uuid($previous_resources['destination_uuid'] ?? '') && is_uuid($previous_resources['dialplan_uuid'] ?? '')) {
			try { $publisher->set_enabled($previous_resources, true); } catch (Throwable) {}
		}
		if (!$publish_completed && is_uuid($prepared_route_uuid)) {
			try { portal_call_routing_customer_request(['action'=>'customer_fail_simple_route',
				'route_version_uuid'=>$prepared_route_uuid,'error_code'=>substr($error->getMessage(),0,100)]); } catch (Throwable) {}
		}
		if (!$publish_completed && is_array($new_resources)) {
			try {
				$publisher->delete_prepared($new_resources);
				if (is_uuid($prepared_route_uuid)) {
					portal_call_routing_customer_request(['action'=>'customer_mark_route_resources_missing',
						'route_version_uuid'=>$prepared_route_uuid]);
				}
			}
			catch (Throwable) {}
		}
		$status = in_array($error->getCode(), [400,401,403,404,409,422], true) ? $error->getCode() : 503;
		http_response_code($status); echo json_encode(['error'=>$error->getMessage()]); exit;
	}

?>

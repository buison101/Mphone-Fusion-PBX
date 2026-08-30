<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once __DIR__ . '/identity_session.php';
	require_once dirname(__DIR__, 2) . '/customer_identities/resources/customer_platform.php';

	function portal_entitlement_decision(string $capability): array {
		if (!portal_identity_validate_session(true) || !portal_identity_has_workspace()) {
			return ['allowed' => false, 'effective_allowed' => false, 'enforcement_mode' => 'enforce'];
		}
		static $decisions = [];
		if (array_key_exists($capability, $decisions)) {
			return $decisions[$capability];
		}
		$result = customer_platform_request([
			'action' => 'portal_entitlement_check',
			'customer_uuid' => (string) $_SESSION['portal_identity']['customer_uuid'],
			'actor_identity_uuid' => (string) $_SESSION['portal_identity']['identity_uuid'],
			'actor_session_uuid' => (string) ($_SESSION['portal_identity']['session_id'] ?? ''),
			'capability' => $capability,
		]);
		$payload = $result['status'] === 200 && is_array($result['payload']) ? $result['payload'] : [];
		$decision = [
			'allowed' => ($payload['allowed'] ?? false) === true,
			'effective_allowed' => ($payload['effective_allowed'] ?? false) === true,
			'enforcement_mode' => (string) ($payload['enforcement_mode'] ?? 'enforce'),
			'generation' => $payload['generation'] ?? null,
			'checksum' => $payload['checksum'] ?? null,
		];
		$decisions[$capability] = $decision;
		return $decision;
	}

	function portal_entitlement_allows(string $capability): bool {
		return portal_entitlement_decision($capability)['allowed'] === true;
	}

	function portal_entitlement_require(string $capability): void {
		if (portal_entitlement_allows($capability)) {
			return;
		}
		http_response_code(403);
		header('Content-Type: application/json; charset=utf-8');
		header('Cache-Control: no-store');
		echo json_encode(['error' => 'feature_not_in_plan', 'capability' => $capability]);
		exit;
	}

?>

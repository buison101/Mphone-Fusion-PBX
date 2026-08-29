<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once __DIR__ . '/identity_session.php';
	require_once dirname(__DIR__, 2) . '/customer_identities/resources/customer_platform.php';

	function portal_entitlement_allows(string $capability): bool {
		if (!portal_identity_validate_session(true) || !portal_identity_has_workspace()) {
			return false;
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
		$allowed = $result['status'] === 200 && ($result['payload']['allowed'] ?? false) === true;
		$decisions[$capability] = $allowed;
		return $allowed;
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

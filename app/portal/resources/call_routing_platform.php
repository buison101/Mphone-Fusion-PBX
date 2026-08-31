<?php

	require_once dirname(__DIR__, 2) . '/customer_identities/resources/customer_platform.php';

	function portal_call_routing_platform_transport(array $payload): array {
		$secret_file = '/etc/mphone/customer-admin-secret';
		if (!is_readable($secret_file)) {
			return ['status' => 503, 'payload' => ['error' => 'admin_secret_unavailable']];
		}
		$secret = trim((string) file_get_contents($secret_file));
		$payload['operator_user_uuid'] = $_SESSION['user_uuid'] ?? ($payload['operator_user_uuid'] ?? null);
		$payload['operator_domain_uuid'] = $_SESSION['domain_uuid'] ?? ($payload['operator_domain_uuid'] ?? null);
		$payload['actor_superadmin'] = !function_exists('portal_identity_is_active') || !portal_identity_is_active();
		$handle = curl_init(customer_platform_api_url() . '/functions/v1/mphone-call-routing-admin');
		curl_setopt_array($handle, [
			CURLOPT_POST => true,
			CURLOPT_HTTPHEADER => [
				'Content-Type: application/json',
				'Accept: application/json',
				'X-Mphone-Admin-Secret: ' . $secret,
			],
			CURLOPT_POSTFIELDS => json_encode($payload, JSON_UNESCAPED_SLASHES),
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_CONNECTTIMEOUT => 3,
			CURLOPT_TIMEOUT => 20,
		]);
		$body = curl_exec($handle);
		$status = (int) curl_getinfo($handle, CURLINFO_RESPONSE_CODE);
		curl_close($handle);
		$result = is_string($body) ? json_decode($body, true) : null;
		return ['status' => $status, 'payload' => is_array($result) ? $result : []];
	}

	function portal_call_routing_platform_request(array $payload, string $required_permission): array {
		if ($required_permission === '' || !permission_exists($required_permission)) {
			return ['status' => 403, 'payload' => ['error' => 'forbidden']];
		}
		return portal_call_routing_platform_transport($payload);
	}

	function portal_call_routing_customer_request(array $payload): array {
		if (!portal_identity_is_active() || !portal_identity_has_workspace()
			|| (string) ($_SESSION['portal_identity']['membership']['role'] ?? '') !== 'owner') {
			return ['status' => 403, 'payload' => ['error' => 'owner_required']];
		}
		$payload['actor_identity_uuid'] = (string) $_SESSION['portal_identity']['identity_uuid'];
		$payload['actor_customer_uuid'] = (string) $_SESSION['portal_identity']['customer_uuid'];
		return portal_call_routing_platform_transport($payload);
	}

?>

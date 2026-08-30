<?php

	function customer_platform_api_url(): string {
		$value = getenv('MPHONE_CUSTOMER_PLATFORM_URL');
		$config_file = '/etc/mphone/customer-platform-url';
		if (empty($value) && is_readable($config_file)) {
			$value = trim((string) file_get_contents($config_file));
		}
		return rtrim(!empty($value) ? $value : 'http://127.0.0.1:8000', '/');
	}

	function customer_platform_request(array $payload): array {
		$secret_file = '/etc/mphone/customer-admin-secret';
		if (!is_readable($secret_file)) {
			return ['status' => 503, 'payload' => ['error' => 'admin_secret_unavailable']];
		}
		$secret = trim((string) file_get_contents($secret_file));
		$payload['operator_user_uuid'] = $_SESSION['user_uuid'] ?? ($payload['operator_user_uuid'] ?? null);
		$payload['operator_domain_uuid'] = $_SESSION['domain_uuid'] ?? ($payload['operator_domain_uuid'] ?? null);
		$handle = curl_init(customer_platform_api_url() . '/functions/v1/mphone-customer-admin');
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
			CURLOPT_TIMEOUT => 15,
		]);
		$body = curl_exec($handle);
		$status = (int) curl_getinfo($handle, CURLINFO_RESPONSE_CODE);
		curl_close($handle);
		$result = is_string($body) ? json_decode($body, true) : null;
		return ['status' => $status, 'payload' => is_array($result) ? $result : []];
	}

?>

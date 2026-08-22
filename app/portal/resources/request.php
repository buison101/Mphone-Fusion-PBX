<?php
	require_once __DIR__ . '/identity_session.php';

	function portal_json_headers(): void {
		header('Content-Type: application/json; charset=utf-8');
		header('Cache-Control: no-store');
		header('X-Content-Type-Options: nosniff');
	}

	function portal_require_session(array $permissions = []): void {
		portal_identity_validate_session();
		if (empty($_SESSION['authorized']) || empty($_SESSION['user_uuid'])) { http_response_code(401); echo json_encode(['error' => 'unauthorized']); exit; }
		if (!permission_exists('portal_view')) { http_response_code(403); echo json_encode(['error' => 'forbidden']); exit; }
		foreach ($permissions as $permission) {
			if (!permission_exists($permission)) { http_response_code(403); echo json_encode(['error' => 'forbidden']); exit; }
		}
	}

	function portal_require_csrf(): void {
		$expected = $_SESSION['portal']['csrf'] ?? '';
		$provided = trim($_SERVER['HTTP_X_CSRF_TOKEN'] ?? '');
		if ($expected === '' || $provided === '' || !hash_equals($expected, $provided)) {
			http_response_code(403);
			echo json_encode(['error' => 'invalid_csrf']);
			exit;
		}
	}

	function portal_assigned_extension_uuids(): array {
		$uuids = [];
		foreach (($_SESSION['user']['extension'] ?? []) as $row) {
			if (!empty($row['extension_uuid']) && is_uuid($row['extension_uuid'])) { $uuids[] = $row['extension_uuid']; }
		}
		return array_values(array_unique($uuids));
	}

	function portal_extension_is_assigned(string $extension_uuid): bool {
		return is_uuid($extension_uuid) && in_array($extension_uuid, portal_assigned_extension_uuids(), true);
	}

?>

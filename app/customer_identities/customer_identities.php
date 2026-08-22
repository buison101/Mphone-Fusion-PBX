<?php

	require_once dirname(__DIR__, 2) . '/resources/require.php';
	require_once 'resources/check_auth.php';
	require_once __DIR__ . '/resources/customer_platform.php';

	if (!permission_exists('customer_identity_view')) {
		echo 'access denied';
		exit;
	}

	$language = new text;
	$text = $language->get();
	$customer_uuid = trim((string) ($_REQUEST['customer_uuid'] ?? ''));
	if ($customer_uuid !== '' && !is_uuid($customer_uuid)) {
		$customer_uuid = '';
	}

	if ($_SERVER['REQUEST_METHOD'] === 'POST') {
		$token = new token;
		if (!$token->validate($_SERVER['PHP_SELF'])) {
			message::add($text['message-invalid_token'], 'negative');
			header('Location: customer_identities.php');
			exit;
		}
		if (!permission_exists('customer_identity_edit')) {
			message::add($text['message-access_denied'], 'negative');
			header('Location: customer_identities.php');
			exit;
		}
		$action = trim((string) ($_POST['action'] ?? ''));
		$request = ['action' => $action, 'customer_uuid' => $customer_uuid];
		if ($action === 'save_assignment') {
			$request['identity_uuid'] = trim((string) ($_POST['identity_uuid'] ?? ''));
			$request['extension_uuid'] = trim((string) ($_POST['extension_uuid'] ?? ''));
			$request['can_use'] = isset($_POST['can_use']);
			$request['can_manage'] = isset($_POST['can_manage']);
		}
		elseif ($action === 'claim_extension') {
			$request['extension_uuid'] = trim((string) ($_POST['extension_uuid'] ?? ''));
		}
		elseif ($action === 'remove_assignment') {
			$request['assignment_uuid'] = trim((string) ($_POST['assignment_uuid'] ?? ''));
		}
		$result = customer_platform_request($request);
		if ($result['status'] === 200) {
			$key = $action === 'reconcile' ? 'message-reconciled' : ($action === 'remove_assignment' ? 'message-removed' : ($action === 'claim_extension' ? 'message-claimed' : 'message-saved'));
			message::add($text[$key], 'positive');
		}
		else {
			message::add($text['message-api_error'] . ' (' . escape((string) ($result['payload']['error'] ?? $result['status'])) . ')', 'negative');
		}
		$location = 'customer_identities.php' . ($customer_uuid !== '' ? '?customer_uuid=' . urlencode($customer_uuid) : '');
		header('Location: ' . $location);
		exit;
	}

	$result = customer_platform_request(['action' => 'list', 'customer_uuid' => $customer_uuid ?: null]);
	$data = $result['status'] === 200 ? $result['payload'] : [];
	$customers = $data['customers'] ?? [];
	$memberships = $data['memberships'] ?? [];
	$assignments = $data['assignments'] ?? [];
	$extensions = $data['extensions'] ?? [];
	$extension_candidates = $data['extension_candidates'] ?? [];
	$exceptions = $data['exceptions'] ?? [];
	$token = (new token)->create($_SERVER['PHP_SELF']);

	$document['title'] = $text['title-customer_identities'];
	require_once 'resources/header.php';

	echo "<div class='action_bar' id='action_bar'>\n";
	echo "<div class='heading'><b>" . escape($text['title-customer_identities']) . "</b><div class='description'>" . escape($text['description-customer_identities']) . "</div></div>\n";
	if (permission_exists('customer_identity_edit')) {
		echo "<div class='actions'><form method='post' style='display:inline'><input type='hidden' name='action' value='reconcile'><input type='hidden' name='customer_uuid' value='" . escape($customer_uuid) . "'><input type='hidden' name='" . escape($token['name']) . "' value='" . escape($token['hash']) . "'><button type='submit' class='btn'>" . escape($text['button-reconcile']) . "</button></form></div>\n";
	}
	echo "<div style='clear:both'></div></div>\n";

	if ($result['status'] !== 200) {
		echo "<div class='alert alert_negative'>" . escape($text['message-api_error']) . "</div>";
	}
	echo "<div class='card'><div class='card-header'>" . escape($text['label-customer']) . "</div><div class='card-body'>";
	echo "<select class='formfld' onchange=\"if(this.value){location='?customer_uuid='+encodeURIComponent(this.value)}else{location='customer_identities.php'}\"><option value=''>-- " . escape($text['label-customer']) . " --</option>";
	foreach ($customers as $customer) {
		$selected = $customer_uuid === ($customer['customer_uuid'] ?? '') ? ' selected' : '';
		echo "<option value='" . escape($customer['customer_uuid'] ?? '') . "'" . $selected . ">" . escape(($customer['display_name'] ?? '') . ' · ' . ($customer['customer_code'] ?? '')) . "</option>";
	}
	echo "</select></div></div><br>";
	if ($customer_uuid === '' && count($exceptions) > 0) {
		echo "<div class='card'><div class='card-header'>" . escape($text['label-exceptions']) . "</div><div class='card-body'><table class='list'><tr><th>Reason</th><th>Details</th><th>Created</th></tr>";
		foreach ($exceptions as $row) echo '<tr><td>' . escape($row['reason'] ?? '') . '</td><td><code>' . escape(json_encode($row['details'] ?? [], JSON_UNESCAPED_SLASHES)) . '</code></td><td>' . escape($row['created_at'] ?? '') . '</td></tr>';
		echo "</table></div></div><br>";
	}

	if ($customer_uuid !== '') {
		echo "<div class='card'><div class='card-header'>" . escape($text['label-memberships']) . "</div><div class='card-body'><table class='list'><tr><th>Email</th><th>Role</th><th>Status</th></tr>";
		foreach ($memberships as $row) echo '<tr><td>' . escape($row['primary_email'] ?? '') . '</td><td>' . escape($row['role'] ?? '') . '</td><td>' . escape($row['status'] ?? '') . '</td></tr>';
		echo "</table></div></div><br>";

		if (permission_exists('customer_identity_edit')) {
			echo "<div class='card'><div class='card-header'>" . escape($text['button-claim_extension']) . "</div><div class='card-body'><form method='post'><input type='hidden' name='action' value='claim_extension'><input type='hidden' name='customer_uuid' value='" . escape($customer_uuid) . "'><input type='hidden' name='" . escape($token['name']) . "' value='" . escape($token['hash']) . "'><select class='formfld' name='extension_uuid' required><option value=''>-- Extension --</option>";
			foreach ($extension_candidates as $row) if (empty($row['owner_customer_uuid'])) echo "<option value='" . escape($row['extension_uuid']) . "'>" . escape(($row['extension'] ?? '') . ' · ' . ($row['display_name'] ?? '')) . "</option>";
			echo "</select> <button class='btn' type='submit'>" . escape($text['button-claim_extension']) . "</button></form></div></div><br>";

			echo "<div class='card'><div class='card-header'>" . escape($text['button-save_assignment']) . "</div><div class='card-body'><form method='post'><input type='hidden' name='action' value='save_assignment'><input type='hidden' name='customer_uuid' value='" . escape($customer_uuid) . "'><input type='hidden' name='" . escape($token['name']) . "' value='" . escape($token['hash']) . "'>";
			echo "<select class='formfld' name='identity_uuid' required><option value=''>-- Email --</option>";
			foreach ($memberships as $row) if (($row['status'] ?? '') === 'active') echo "<option value='" . escape($row['identity_uuid']) . "'>" . escape($row['primary_email']) . "</option>";
			echo "</select> <select class='formfld' name='extension_uuid' required><option value=''>-- Extension --</option>";
			foreach ($extensions as $row) if (($row['enabled'] ?? '') === 'true') echo "<option value='" . escape($row['extension_uuid']) . "'>" . escape(($row['extension'] ?? '') . ' · ' . ($row['display_name'] ?? '')) . "</option>";
			echo "</select> <label><input type='checkbox' name='can_use' value='1'> " . escape($text['label-can_use']) . "</label> <label><input type='checkbox' name='can_manage' value='1'> " . escape($text['label-can_manage']) . "</label> <button class='btn' type='submit'>" . escape($text['button-save_assignment']) . "</button></form></div></div><br>";
		}

		echo "<div class='card'><div class='card-header'>" . escape($text['label-assignments']) . "</div><div class='card-body'><table class='list'><tr><th>Email</th><th>Extension UUID</th><th>" . escape($text['label-can_use']) . "</th><th>" . escape($text['label-can_manage']) . "</th><th>Status</th><th></th></tr>";
		foreach ($assignments as $row) {
			echo '<tr><td>' . escape($row['primary_email'] ?? '') . '</td><td>' . escape($row['extension_uuid'] ?? '') . '</td><td>' . (!empty($row['can_use']) ? '✓' : '—') . '</td><td>' . (!empty($row['can_manage']) ? '✓' : '—') . '</td><td>' . escape($row['status'] ?? '') . '</td><td>';
			if (permission_exists('customer_identity_edit') && ($row['status'] ?? '') === 'active') echo "<form method='post'><input type='hidden' name='action' value='remove_assignment'><input type='hidden' name='customer_uuid' value='" . escape($customer_uuid) . "'><input type='hidden' name='assignment_uuid' value='" . escape($row['assignment_uuid']) . "'><input type='hidden' name='" . escape($token['name']) . "' value='" . escape($token['hash']) . "'><button class='btn' type='submit'>" . escape($text['button-remove']) . "</button></form>";
			echo '</td></tr>';
		}
		echo "</table></div></div><br>";

		echo "<div class='card'><div class='card-header'>" . escape($text['label-exceptions']) . "</div><div class='card-body'><table class='list'><tr><th>Reason</th><th>Details</th><th>Created</th></tr>";
		foreach ($exceptions as $row) echo '<tr><td>' . escape($row['reason'] ?? '') . '</td><td><code>' . escape(json_encode($row['details'] ?? [], JSON_UNESCAPED_SLASHES)) . '</code></td><td>' . escape($row['created_at'] ?? '') . '</td></tr>';
		echo "</table></div></div>";
	}

	require_once 'resources/footer.php';

?>

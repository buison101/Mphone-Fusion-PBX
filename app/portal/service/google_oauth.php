<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/identity_session.php';

	header('Cache-Control: no-store');
	header('X-Content-Type-Options: nosniff');
	header('Referrer-Policy: no-referrer');

	function mphone_google_config(): array {
		return [
			'MPHONE_GOOGLE_WEB_CLIENT_ID' => trim((string) getenv('MPHONE_GOOGLE_WEB_CLIENT_ID')),
			'MPHONE_GOOGLE_WEB_CLIENT_SECRET' => trim((string) getenv('MPHONE_GOOGLE_WEB_CLIENT_SECRET')),
			'MPHONE_GOOGLE_ANDROID_CLIENT_ID' => trim((string) getenv('MPHONE_GOOGLE_ANDROID_CLIENT_ID')),
		];
	}

	function mphone_google_redirect(string $result): never {
		header('Location: /p/?google=' . rawurlencode($result), true, 302);
		exit;
	}

	$config = mphone_google_config();
	$client_id = (string) ($config['MPHONE_GOOGLE_WEB_CLIENT_ID'] ?? '');
	$client_secret = (string) ($config['MPHONE_GOOGLE_WEB_CLIENT_SECRET'] ?? '');
	$redirect_uri = 'https://login.mphone.vn/app/portal/service/google_oauth.php?action=callback';
	$action = trim((string) ($_GET['action'] ?? ''));
	if ($client_id === '' || $client_secret === '') {
		if ($action === 'status') {
			header('Content-Type: application/json; charset=utf-8');
			echo json_encode(['enabled' => false]);
			exit;
		}
		mphone_google_redirect('disabled');
	}

	if ($action === 'status') {
		header('Content-Type: application/json; charset=utf-8');
		echo json_encode(['enabled' => true]);
		exit;
	}

	if ($action === 'start') {
		$flow = ($_GET['flow'] ?? '') === 'link' ? 'link' : 'login';
		if ($flow === 'link' && (!portal_identity_validate_session(true) || !portal_identity_is_active())) {
			mphone_google_redirect('unauthorized');
		}
		$state = rtrim(strtr(base64_encode(random_bytes(32)), '+/', '-_'), '=');
		$verifier = rtrim(strtr(base64_encode(random_bytes(48)), '+/', '-_'), '=');
		$_SESSION['mphone_google_oauth'] = [
			'state_hash' => hash('sha256', $state),
			'verifier' => $verifier,
			'expires_at' => time() + 600,
			'flow' => $flow,
		];
		$params = [
			'client_id' => $client_id,
			'redirect_uri' => $redirect_uri,
			'response_type' => 'code',
			'scope' => 'openid email profile',
			'state' => $state,
			'code_challenge' => rtrim(strtr(base64_encode(hash('sha256', $verifier, true)), '+/', '-_'), '='),
			'code_challenge_method' => 'S256',
			'prompt' => 'select_account',
		];
		header('Location: https://accounts.google.com/o/oauth2/v2/auth?' . http_build_query($params), true, 302);
		exit;
	}

	if ($action !== 'callback') {
		http_response_code(404);
		exit;
	}

	$pending = $_SESSION['mphone_google_oauth'] ?? [];
	unset($_SESSION['mphone_google_oauth']);
	$state = (string) ($_GET['state'] ?? '');
	$code = (string) ($_GET['code'] ?? '');
	if ($state === '' || $code === '' || (int) ($pending['expires_at'] ?? 0) < time()
		|| !hash_equals((string) ($pending['state_hash'] ?? ''), hash('sha256', $state))) {
		mphone_google_redirect('invalid_state');
	}

	$handle = curl_init('https://oauth2.googleapis.com/token');
	curl_setopt_array($handle, [
		CURLOPT_POST => true,
		CURLOPT_POSTFIELDS => http_build_query([
			'code' => $code,
			'client_id' => $client_id,
			'client_secret' => $client_secret,
			'redirect_uri' => $redirect_uri,
			'grant_type' => 'authorization_code',
			'code_verifier' => (string) ($pending['verifier'] ?? ''),
		]),
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_CONNECTTIMEOUT => 5,
		CURLOPT_TIMEOUT => 15,
	]);
	$response = curl_exec($handle);
	$status = (int) curl_getinfo($handle, CURLINFO_RESPONSE_CODE);
	curl_close($handle);
	$payload = is_string($response) ? json_decode($response, true) : null;
	$id_token = is_array($payload) ? (string) ($payload['id_token'] ?? '') : '';
	if ($status !== 200 || $id_token === '' || strlen($id_token) > 8192) {
		mphone_google_redirect('exchange_failed');
	}
	$_SESSION['mphone_google_id_token'] = $id_token;
	$_SESSION['mphone_google_id_token_expires_at'] = time() + 120;
	if (($pending['flow'] ?? 'login') === 'link') {
		header('Location: /p/account?google=link_ready', true, 302);
		exit;
	}
	mphone_google_redirect('complete');

?>

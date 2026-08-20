<?php
/*
	FusionPBX
	Version: MPL 1.1

	The contents of this file are subject to the Mozilla Public License Version
	1.1 (the "License"); you may not use this file except in compliance with
	the License. You may obtain a copy of the License at
	http://www.mozilla.org/MPL/

	Software distributed under the License is distributed on an "AS IS" basis,
	WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
	for the specific language governing rights and limitations under the
	License.

	The Original Code is FusionPBX

	Portal session endpoint. Returns the signed in user, the domain scope and a
	short lived websocket token so the single page application can subscribe to
	the websocket router without holding a PHP session on the socket itself.
*/

//includes files
	require_once dirname(__DIR__, 3) . "/resources/require.php";

//json only, never cached, never framed
	header('Content-Type: application/json; charset=utf-8');
	header('Cache-Control: no-store');
	header('X-Content-Type-Options: nosniff');

//the portal only reads, a GET is all that is allowed
	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
		http_response_code(405);
		echo json_encode(['error' => 'method_not_allowed']);
		exit;
	}

//the browser follows redirects, so answer with a status the application can act on
	if (empty($_SESSION['authorized']) || empty($_SESSION['user_uuid'])) {
		http_response_code(401);
		echo json_encode(['error' => 'unauthorized', 'login_url' => PROJECT_PATH . '/']);
		exit;
	}

//the portal is a separate application and carries its own permission
	if (!permission_exists('portal_view')) {
		http_response_code(403);
		echo json_encode(['error' => 'forbidden']);
		exit;
	}

//only the permissions the interface actually branches on are sent to the browser
	$exposed_permissions = [
		'call_active_view',
		'call_active_all',
		'call_active_domain',
		'call_active_hangup',
		'call_active_eavesdrop',
		'call_active_application',
		'call_active_codec',
		'call_active_secure',
		'call_active_profile',
		'xml_cdr_view',
		'xml_cdr_domain',
		'xml_cdr_recording',
		'xml_cdr_recording_play',
		'xml_cdr_recording_download',
		'xml_cdr_export_csv',
		'xml_cdr_transcript_view',
		'transcribe_queue_edit',
		'portal_call_tag_view',
		'portal_call_tag_edit',
		'portal_call_tag_assign',
		'portal_call_note_view',
		'portal_call_note_add',
		'portal_call_note_edit',
		'portal_call_note_delete',
		'contact_view',
		'contact_domain_view',
		'click_to_call_view',
		'click_to_call_call',
		'extension_view',
		'call_forward',
		'do_not_disturb',
		'voicemail_view',
		'voicemail_message_view',
	];
	$permissions = [];
	foreach ($exposed_permissions as $permission_name) {
		if (permission_exists($permission_name)) {
			$permissions[$permission_name] = true;
		}
	}
	unset($permission_name);

//the extensions assigned to this user determine the call scope when the user
//has neither call_active_all nor call_active_domain
	$extensions = [];
	if (!empty($_SESSION['user']['extension']) && is_array($_SESSION['user']['extension'])) {
		foreach ($_SESSION['user']['extension'] as $row) {
			$extensions[] = [
				'extension_uuid' => $row['extension_uuid'] ?? '',
				'extension' => $row['user'] ?? '',
				'destination' => !empty($row['number_alias']) ? $row['number_alias'] : ($row['user'] ?? ''),
			];
		}
		unset($row);
	}

//a single page application lives far longer than a page view, so the previous
//token is released before a new one is issued to keep the session and the
//shared memory directory from growing on every refresh
	$token_key = '/app/portal/service/session.php';
	if (!empty($_SESSION['portal']['ws_token_name'])) {
		$previous_file = subscriber::get_token_file($_SESSION['portal']['ws_token_name']);
		if (file_exists($previous_file)) {
			unlink($previous_file);
		}
		unset($previous_file);
	}
	unset($_SESSION['tokens'][$token_key]);

//issue the websocket token and hand the subscriber the services it may join
	$token_time_limit = (int) $settings->get('portal', 'token_time_limit', 60);
	if ($token_time_limit < 1) {
		$token_time_limit = 60;
	}
	$token = (new token())->create($token_key);
	subscriber::save_token($token, ['active.calls'], $token_time_limit);
	$_SESSION['portal']['ws_token_name'] = $token['name'];

//the websocket router is only proxied on the tls listener
	$host = $_SERVER['HTTP_HOST'] ?? ($_SERVER['SERVER_NAME'] ?? 'localhost');
	$_SESSION['portal']['csrf'] = bin2hex(random_bytes(32));

	echo json_encode([
		'user' => [
			'user_uuid' => $_SESSION['user_uuid'],
			'username' => $_SESSION['username'] ?? '',
			'extensions' => $extensions,
		],
		'domain' => [
			'domain_uuid' => $_SESSION['domain_uuid'] ?? '',
			'domain_name' => $_SESSION['domain_name'] ?? '',
		],
		'permissions' => $permissions,
		'csrf' => $_SESSION['portal']['csrf'],
		'websocket' => [
			'url' => 'wss://' . $host . '/websockets/',
			'services' => ['active.calls'],
			'token' => [
				'name' => $token['name'],
				'hash' => $token['hash'],
			],
			'expires_in' => $token_time_limit * 60,
		],
	], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

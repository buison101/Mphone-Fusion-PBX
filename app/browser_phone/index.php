<?php
/*
	Independent Browser Phone integration for FusionPBX.
	The static client is provisioned only after FusionPBX authentication and
	registers against the extension assigned to the current user.
*/

	require_once dirname(__DIR__, 2) . "/resources/require.php";
	require_once "resources/check_auth.php";

	if (!permission_exists('browser_phone_view')) {
		http_response_code(403);
		echo "access denied";
		exit;
	}

	$language = new text;
	$text = $language->get();
	$database = new database;
	$extensions = [];
	$extension = [];
	$requested_extension_uuid = $_GET['extension_uuid'] ?? '';
	$client_mode = ($_GET['client'] ?? '') === '1';

	if (!$client_mode) {
		$document['title'] = $text['label-browser_phone'];
		$client_url = '/app/browser_phone/index.php?client=1';
		if ($requested_extension_uuid !== '') {
			$client_url .= '&extension_uuid='.rawurlencode($requested_extension_uuid);
		}
		require_once "resources/header.php";
		echo "<style>#main_content { padding: 0 !important; }</style>\n";
		echo "<iframe id='browser_phone_frame' title='".escape($text['label-browser_phone'])."' src='".escape($client_url)."' allow='microphone; camera; autoplay' style='display:block; width:100%; height:calc(100vh - 72px); min-height:600px; border:0; background:#111827;'></iframe>\n";
		require_once "resources/footer.php";
		exit;
	}

	$sql = "select distinct e.extension_uuid, e.extension, e.password, e.effective_caller_id_name ";
	$sql .= "from v_extension_users as eu ";
	$sql .= "inner join v_extensions as e on e.extension_uuid = eu.extension_uuid ";
	$sql .= "where eu.domain_uuid = :domain_uuid ";
	$sql .= "and eu.user_uuid = :user_uuid ";
	$sql .= "and e.enabled = 'true' ";
	$sql .= "order by e.extension asc ";
	$parameters['domain_uuid'] = $_SESSION['domain_uuid'];
	$parameters['user_uuid'] = $_SESSION['user_uuid'];
	$extensions = $database->select($sql, $parameters, 'all');
	unset($sql, $parameters);
	if (!is_array($extensions)) {
		$extensions = [];
	}

	if ($requested_extension_uuid !== '') {
		if (!is_uuid($requested_extension_uuid)) {
			http_response_code(403);
			echo escape($text['message-invalid_extension']);
			exit;
		}

		foreach ($extensions as $available_extension) {
			if ($available_extension['extension_uuid'] === $requested_extension_uuid) {
				$extension = $available_extension;
				break;
			}
		}

		if (empty($extension)) {
			http_response_code(403);
			echo escape($text['message-invalid_extension']);
			exit;
		}
	}

	if (empty($extension)) {
		$extension = $extensions[0] ?? [];
	}

	if (empty($extension['extension']) || empty($extension['password'])) {
		require_once "resources/header.php";
		echo "<div class='card'>\n";
		echo "\t<strong>".escape($text['label-browser_phone'])."</strong><br><br>\n";
		echo "\t".(!empty($extension['extension']) ? $text['message-missing_password'] : $text['message-no_extension'])."\n";
		echo "</div>\n";
		require_once "resources/footer.php";
		exit;
	}

	function browser_phone_json($value) {
		return json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT);
	}

	$request_host = parse_url('https://'.($_SERVER['HTTP_HOST'] ?? ''), PHP_URL_HOST);
	$configured_host = $settings->get('browser_phone', 'websocket_host', '');
	$websocket_host = !empty($configured_host) ? $configured_host : $request_host;
	if (!filter_var($websocket_host, FILTER_VALIDATE_IP) && !preg_match('/^(?=.{1,253}$)[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$/i', $websocket_host)) {
		http_response_code(500);
		echo "Invalid Browser Phone WebSocket host";
		exit;
	}

	$websocket_path = $settings->get('browser_phone', 'websocket_path', '/browser-phone-ws');
	if (!preg_match('#^/[a-z0-9/_-]+$#i', $websocket_path)) {
		$websocket_path = '/browser-phone-ws';
	}
	$ice_servers = $settings->get('browser_phone', 'ice_servers', '[]');
	if (!is_array(json_decode($ice_servers, true))) {
		$ice_servers = '[]';
	}
	$voicemail_did = $settings->get('browser_phone', 'voicemail_did', '*97');
	$video_enabled = $settings->get('browser_phone', 'video_enabled', false);
	$asset_path = '/app/browser_phone/assets/';
	$phone_css_version = (string) filemtime(__DIR__.'/assets/phone.css');
	$phone_js_version = (string) filemtime(__DIR__.'/assets/phone.js');
	$fusion_language = strtolower($settings->get('domain', 'language', 'en-us'));
	$phone_language = $fusion_language === 'vi-vn' ? 'vi' : 'en';
	$favicon = $_SESSION['theme']['favicon']['text'] ?? '';
	if (empty($favicon)) {
		$favicon = '/themes/default/favicon.ico';
	}
	$profile_name = !empty($extension['effective_caller_id_name']) ? $extension['effective_caller_id_name'] : $extension['extension'];
	$extension_choices = [];
	foreach ($extensions as $available_extension) {
		$choice_name = !empty($available_extension['effective_caller_id_name']) ? $available_extension['effective_caller_id_name'] : $available_extension['extension'];
		$extension_choices[] = [
			'uuid' => $available_extension['extension_uuid'],
			'label' => $choice_name.' ('.$available_extension['extension'].')',
		];
	}

	header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
	header('Pragma: no-cache');
	header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' blob:; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; media-src 'self' blob:; connect-src 'self' wss:; font-src 'self' data:; worker-src 'self' blob:; frame-src 'self' blob:; object-src 'none'; base-uri 'self'; frame-ancestors 'self'");
?>
<!DOCTYPE html>
<html lang="<?php echo escape($_SESSION['domain']['language']['code'] ?? 'vi-vn'); ?>">
	<head>
		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
		<meta name="format-detection" content="telephone=no">
		<title><?php echo escape($text['label-browser_phone']); ?></title>
		<link rel="icon" href="<?php echo escape($favicon); ?>">
		<link rel="stylesheet" href="<?php echo $asset_path; ?>lib/Normalize/normalize-v8.0.1.css">
		<link rel="stylesheet" href="<?php echo $asset_path; ?>lib/fonts/font_awesome/css/font-awesome.min.css">
		<link rel="stylesheet" href="<?php echo $asset_path; ?>lib/jquery/jquery-ui-1.13.2.min.css">
		<link rel="stylesheet" href="<?php echo $asset_path; ?>lib/Croppie/croppie.css">
		<link rel="stylesheet" href="<?php echo $asset_path; ?>phone.css?v=<?php echo escape($phone_css_version); ?>">
		<script>
			var phoneOptions = {
				hostingPrefix: <?php echo browser_phone_json($asset_path); ?>,
				loadAlternateLang: true,
				Language: <?php echo browser_phone_json($phone_language); ?>,
				lockLanguageToHost: true,
				profileUserID: <?php echo browser_phone_json($extension['extension_uuid']); ?>,
				profileName: <?php echo browser_phone_json($profile_name); ?>,
				extensionChoices: <?php echo browser_phone_json($extension_choices); ?>,
				selectedExtensionUuid: <?php echo browser_phone_json($extension['extension_uuid']); ?>,
				openDialPadOnStart: true,
				wssServer: <?php echo browser_phone_json($websocket_host); ?>,
				WebSocketPort: "443",
				ServerPath: <?php echo browser_phone_json($websocket_path); ?>,
				WebSocketProtocol: "wss",
				WssInTransport: false,
				RegisterContactParams: '{"transport":"ws"}',
				IpInContact: false,
				SipDomain: <?php echo browser_phone_json($_SESSION['domain_name']); ?>,
				SipUsername: <?php echo browser_phone_json($extension['extension']); ?>,
				SipPassword: <?php echo browser_phone_json($extension['password']); ?>,
				VoicemailDid: <?php echo browser_phone_json($voicemail_did); ?>,
				IceStunServerJson: <?php echo browser_phone_json($ice_servers); ?>,
				userAgentStr: "FusionPBX Browser Phone",
				ChatEngine: "SIMPLE",
				XmppServer: "",
				XmppDomain: "",
				EnableAccountSettings: false,
				EnableVideoCalling: <?php echo $video_enabled ? 'true' : 'false'; ?>,
				UiMaxWidth: 999999,
				UiMessageLayout: "middle"
			};
		</script>
	</head>
	<body>
		<div class="loading"><span class="fa fa-circle-o-notch fa-spin"></span></div>
		<div id="Phone"></div>
		<script src="<?php echo $asset_path; ?>lib/jquery/jquery-3.6.1.min.js"></script>
		<script src="<?php echo $asset_path; ?>lib/jquery/jquery-ui-1.13.2.min.js"></script>
		<script src="<?php echo $asset_path; ?>phone.js?v=<?php echo escape($phone_js_version); ?>"></script>
		<script src="<?php echo $asset_path; ?>lib/jquery/jquery.md5-min.js" defer></script>
		<script src="<?php echo $asset_path; ?>lib/Chart/Chart.bundle-2.7.2.min.js" defer></script>
		<script src="<?php echo $asset_path; ?>lib/SipJS/sip-0.20.0.min.js" defer></script>
		<script src="<?php echo $asset_path; ?>lib/FabricJS/fabric-2.4.6.min.js" defer></script>
		<script src="<?php echo $asset_path; ?>lib/Moment/moment-with-locales-2.24.0.min.js" defer></script>
		<script src="<?php echo $asset_path; ?>lib/Croppie/croppie-2.6.4.min.js" defer></script>
		<script src="<?php echo $asset_path; ?>lib/XMPP/strophe-1.4.1.umd.min.js" defer></script>
	</body>
</html>

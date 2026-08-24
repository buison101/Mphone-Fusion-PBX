<?php

	require_once dirname(__DIR__, 2) . '/resources/require.php';
	require_once 'resources/check_auth.php';
	require_once __DIR__ . '/resources/customer_platform.php';

	if (!permission_exists('customer_identity_edit')) { echo 'access denied'; exit; }
	$language = new text;
	$text = $language->get();
	$user_uuid = trim((string) ($_REQUEST['id'] ?? ''));
	$resend = ($_REQUEST['resend'] ?? '') === '1';
	if (!is_uuid($user_uuid)) { header('Location: ' . PROJECT_PATH . '/core/users/users.php'); exit; }
	$sql = "select username, cast(user_enabled as text) as user_enabled from v_users where user_uuid = :user_uuid and domain_uuid = :domain_uuid limit 1";
	$user = $database->select($sql, ['user_uuid' => $user_uuid, 'domain_uuid' => $_SESSION['domain_uuid']], 'row');
	if (!is_array($user) || ($user['user_enabled'] ?? '') !== 'true') {
		message::add($text['message-fusion_user_unavailable'], 'negative');
		header('Location: ' . PROJECT_PATH . '/core/users/users.php'); exit;
	}
	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
		$token = new token;
		if (!$token->validate($_SERVER['PHP_SELF'])) message::add($text['message-invalid_token'], 'negative');
		else {
			$result = customer_platform_request(['action' => $resend ? 'resend_fusion_user' : 'invite_fusion_user', 'fusion_user_uuid' => $user_uuid]);
			if ($result['status'] === 200) message::add($text[$resend ? 'message-invitation_resent' : 'message-invited'], 'positive');
			else {
				$error = (string) ($result['payload']['error'] ?? $result['status']);
				$key = 'message-' . str_replace('_', '-', $error);
				message::add($text[$key] ?? ($text['message-api_error'] . ' (' . escape($error) . ')'), 'negative');
			}
		}
		header('Location: ' . PROJECT_PATH . '/core/users/users.php'); exit;
	}
	$token = (new token)->create($_SERVER['PHP_SELF']);
	$document['title'] = $text['button-invite'];
	require_once 'resources/header.php';
	echo "<div class='action_bar'><div class='heading'><b>" . escape($text['button-invite']) . "</b></div></div>";
	echo "<div class='card'><div class='card-body'><p>" . escape(sprintf($text[$resend ? 'message-confirm_resend' : 'message-confirm_invite'], $user['username'])) . "</p>";
	echo "<form method='post'><input type='hidden' name='id' value='" . escape($user_uuid) . "'><input type='hidden' name='resend' value='" . ($resend ? '1' : '0') . "'><input type='hidden' name='" . escape($token['name']) . "' value='" . escape($token['hash']) . "'>";
	echo button::create(['type'=>'button','label'=>$text['button-back'],'icon'=>'arrow-left','link'=>PROJECT_PATH.'/core/users/users.php']);
	echo button::create(['type'=>'submit','label'=>$text[$resend ? 'button-resend_invite' : 'button-invite'],'icon'=>'envelope','style'=>'margin-left: 15px;']);
	echo "</form></div></div>";
	require_once 'resources/footer.php';

?>

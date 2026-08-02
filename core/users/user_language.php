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

	The Initial Developer of the Original Code is
	Mark J Crane <markjcrane@fusionpbx.com>
	All Rights Reserved.
*/

//includes files
	require_once dirname(__DIR__, 2) . "/resources/require.php";
	require_once "resources/check_auth.php";

//add multi-lingual support
	$language = new text;
	$text = $language->get();

//get the current domain and user
	$domain_uuid = $_SESSION['domain_uuid'] ?? $domain_uuid ?? '';
	$user_uuid = $_SESSION['user_uuid'] ?? $user_uuid ?? '';
	if (!is_uuid($domain_uuid) || !is_uuid($user_uuid)) {
		header('Location: ' . PROJECT_PATH . '/');
		exit;
	}

//validate the token
	$token = new token;
	if (!$token->validate('userlanguage')) {
		message::add($text['message-invalid_token'], 'negative');
		header('Location: ' . PROJECT_PATH . '/');
		exit;
	}

//validate the requested language
	$user_language = strtolower($_REQUEST['language'] ?? '');
	$allowed_languages = ['en-us', 'vi-vn'];
	if (!in_array($user_language, $allowed_languages, true) || !in_array($user_language, $_SESSION['app']['languages'] ?? [], true)) {
		header('Location: ' . PROJECT_PATH . '/');
		exit;
	}

//check whether the user already has a language setting
	$sql = "select count(*) from v_user_settings ";
	$sql .= "where domain_uuid = :domain_uuid ";
	$sql .= "and user_uuid = :user_uuid ";
	$sql .= "and user_setting_category = 'domain' ";
	$sql .= "and user_setting_subcategory = 'language' ";
	$parameters['domain_uuid'] = $domain_uuid;
	$parameters['user_uuid'] = $user_uuid;
	$user_setting_count = (int) $database->select($sql, $parameters, 'column');
	unset($sql, $parameters);

//save the user setting
	if ($user_setting_count > 0) {
		$sql = "update v_user_settings set ";
		$sql .= "user_setting_value = :user_setting_value, ";
		$sql .= "user_setting_enabled = true, ";
		$sql .= "update_date = now(), ";
		$sql .= "update_user = :update_user ";
		$sql .= "where domain_uuid = :domain_uuid ";
		$sql .= "and user_uuid = :user_uuid ";
		$sql .= "and user_setting_category = 'domain' ";
		$sql .= "and user_setting_subcategory = 'language' ";
		$parameters['user_setting_value'] = $user_language;
		$parameters['update_user'] = $user_uuid;
		$parameters['domain_uuid'] = $domain_uuid;
		$parameters['user_uuid'] = $user_uuid;
		if ($database->execute($sql, $parameters) === false) {
			message::add($database->message['message'] ?? 'Unable to save language.', 'negative');
		}
		unset($sql, $parameters);
	}
	else {
		$sql = "insert into v_user_settings ";
		$sql .= "(user_setting_uuid, domain_uuid, user_uuid, user_setting_category, user_setting_subcategory, user_setting_name, user_setting_value, user_setting_enabled, insert_date, insert_user) ";
		$sql .= "values ";
		$sql .= "(:user_setting_uuid, :domain_uuid, :user_uuid, 'domain', 'language', 'code', :user_setting_value, true, now(), :insert_user)";
		$parameters['user_setting_uuid'] = uuid();
		$parameters['domain_uuid'] = $domain_uuid;
		$parameters['user_uuid'] = $user_uuid;
		$parameters['user_setting_value'] = $user_language;
		$parameters['insert_user'] = $user_uuid;
		if ($database->execute($sql, $parameters) === false) {
			message::add($database->message['message'] ?? 'Unable to save language.', 'negative');
		}
		unset($sql, $parameters);
	}

//clear cached language/menu data
	unset($_SESSION['menu']);
	settings::clear_cache();
	text::clear_cache();

//return to the previous page
	$return_url = $_REQUEST['return'] ?? PROJECT_PATH . '/';
	if (!is_string($return_url) || $return_url === '' || preg_match('/[\r\n]/', $return_url) || preg_match('#^https?://#i', $return_url) || substr($return_url, 0, 2) === '//' || $return_url[0] !== '/') {
		$return_url = PROJECT_PATH . '/';
	}
	$separator = str_contains($return_url, '?') ? '&' : '?';
	header('Location: ' . $return_url . $separator . '_language_updated=' . time());
	exit;

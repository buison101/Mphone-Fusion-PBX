<?php

	//application details
		$apps[$x]['name'] = "Browser Phone";
		$apps[$x]['uuid'] = "caad93fb-3818-4c38-bfd4-6b5356a8cc89";
		$apps[$x]['category'] = "Switch";
		$apps[$x]['subcategory'] = "";
		$apps[$x]['version'] = "1.0";
		$apps[$x]['license'] = "GNU Affero General Public License v3.0";
		$apps[$x]['url'] = "https://github.com/InnovateAsterisk/Browser-Phone";
		$apps[$x]['description']['en-us'] = "Browser Phone integrated with FusionPBX and FreeSWITCH.";
		$apps[$x]['description']['vi-vn'] = "Browser Phone tích hợp độc lập với FusionPBX và FreeSWITCH.";

	//permission details
		$y=0;
		$apps[$x]['permissions'][$y]['name'] = "browser_phone_view";
		$apps[$x]['permissions'][$y]['groups'][] = "user";
		$apps[$x]['permissions'][$y]['groups'][] = "admin";
		$apps[$x]['permissions'][$y]['groups'][] = "superadmin";

	//default settings
		$y=0;
		$apps[$x]['default_settings'][$y]['default_setting_uuid'] = "ca4008e8-a720-435f-a30b-28a664781b12";
		$apps[$x]['default_settings'][$y]['default_setting_category'] = "browser_phone";
		$apps[$x]['default_settings'][$y]['default_setting_subcategory'] = "websocket_host";
		$apps[$x]['default_settings'][$y]['default_setting_name'] = "text";
		$apps[$x]['default_settings'][$y]['default_setting_value'] = "";
		$apps[$x]['default_settings'][$y]['default_setting_enabled'] = "false";
		$apps[$x]['default_settings'][$y]['default_setting_description'] = "Optional WebSocket host. Disabled uses the current request host.";
		$y++;
		$apps[$x]['default_settings'][$y]['default_setting_uuid'] = "bb7e1667-ccef-4af6-a438-aa3aa33048d6";
		$apps[$x]['default_settings'][$y]['default_setting_category'] = "browser_phone";
		$apps[$x]['default_settings'][$y]['default_setting_subcategory'] = "websocket_path";
		$apps[$x]['default_settings'][$y]['default_setting_name'] = "text";
		$apps[$x]['default_settings'][$y]['default_setting_value'] = "/browser-phone-ws";
		$apps[$x]['default_settings'][$y]['default_setting_enabled'] = "true";
		$apps[$x]['default_settings'][$y]['default_setting_description'] = "Same-origin Nginx path for SIP over secure WebSocket.";
		$y++;
		$apps[$x]['default_settings'][$y]['default_setting_uuid'] = "af4f5cda-3054-48be-86f2-e27b83f3bca8";
		$apps[$x]['default_settings'][$y]['default_setting_category'] = "browser_phone";
		$apps[$x]['default_settings'][$y]['default_setting_subcategory'] = "ice_servers";
		$apps[$x]['default_settings'][$y]['default_setting_name'] = "text";
		$apps[$x]['default_settings'][$y]['default_setting_value'] = "[]";
		$apps[$x]['default_settings'][$y]['default_setting_enabled'] = "true";
		$apps[$x]['default_settings'][$y]['default_setting_description'] = "JSON array of WebRTC STUN and TURN servers.";
		$y++;
		$apps[$x]['default_settings'][$y]['default_setting_uuid'] = "70888c11-e2e0-4e3f-9bbe-4017bffc5b2c";
		$apps[$x]['default_settings'][$y]['default_setting_category'] = "browser_phone";
		$apps[$x]['default_settings'][$y]['default_setting_subcategory'] = "voicemail_did";
		$apps[$x]['default_settings'][$y]['default_setting_name'] = "text";
		$apps[$x]['default_settings'][$y]['default_setting_value'] = "*97";
		$apps[$x]['default_settings'][$y]['default_setting_enabled'] = "true";
		$apps[$x]['default_settings'][$y]['default_setting_description'] = "Voicemail destination.";
		$y++;
		$apps[$x]['default_settings'][$y]['default_setting_uuid'] = "ef6f80db-8eb0-443f-82eb-33c026ed666e";
		$apps[$x]['default_settings'][$y]['default_setting_category'] = "browser_phone";
		$apps[$x]['default_settings'][$y]['default_setting_subcategory'] = "video_enabled";
		$apps[$x]['default_settings'][$y]['default_setting_name'] = "boolean";
		$apps[$x]['default_settings'][$y]['default_setting_value'] = "false";
		$apps[$x]['default_settings'][$y]['default_setting_enabled'] = "true";
		$apps[$x]['default_settings'][$y]['default_setting_description'] = "Enable experimental video calls after FreeSWITCH codec validation.";

?>

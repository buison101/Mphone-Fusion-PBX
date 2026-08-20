<?php

	function portal_authorized_cdr(database $database, string $xml_cdr_uuid, string $domain_uuid): array {
		if (!is_uuid($xml_cdr_uuid) || !is_uuid($domain_uuid)) { return []; }
		$parameters = ['xml_cdr_uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid];
		$scope_sql = '';
		if (!permission_exists('xml_cdr_domain')) {
			$extension_uuids = portal_assigned_extension_uuids();
			if (empty($extension_uuids)) { return []; }
			$placeholders = [];
			foreach ($extension_uuids as $index => $extension_uuid) {
				$key = 'extension_uuid_'.$index;
				$placeholders[] = ':'.$key;
				$parameters[$key] = $extension_uuid;
			}
			$scope_sql = 'and extension_uuid in ('.implode(', ', $placeholders).') ';
		}
		return $database->select(
			'select xml_cdr_uuid, duration from v_xml_cdr where xml_cdr_uuid = :xml_cdr_uuid and domain_uuid = :domain_uuid '.$scope_sql,
			$parameters,
			'row'
		) ?: [];
	}

	function portal_normalize_tag_name(string $name): string {
		$name = trim(preg_replace('/\s+/u', ' ', $name));
		return mb_strtolower($name, 'UTF-8');
	}

?>

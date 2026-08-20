<?php

	require_once dirname(__DIR__, 3) . '/resources/require.php';
	require_once dirname(__DIR__) . '/resources/request.php';

	portal_json_headers();
	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') { http_response_code(405); echo json_encode(['error' => 'method_not_allowed']); exit; }
	portal_require_session(['contact_view']);
	$domain_uuid = $_SESSION['domain_uuid'] ?? '';
	if (!is_uuid($domain_uuid)) { http_response_code(400); echo json_encode(['error' => 'invalid_domain']); exit; }
	$page = max(1, (int) ($_GET['page'] ?? 1));
	$page_size = (int) ($_GET['page_size'] ?? 20);
	if (!in_array($page_size, [20, 50, 100], true)) { $page_size = 20; }
	$conditions = ['c.domain_uuid = :domain_uuid'];
	$parameters = ['domain_uuid' => $domain_uuid];
	if (!permission_exists('contact_domain_view')) {
		$conditions[] = "(exists(select 1 from v_contact_users cu where cu.contact_uuid=c.contact_uuid and cu.domain_uuid=c.domain_uuid and cu.user_uuid=:user_uuid) or (not exists(select 1 from v_contact_users cu where cu.contact_uuid=c.contact_uuid) and not exists(select 1 from v_contact_groups cg where cg.contact_uuid=c.contact_uuid)))";
		$parameters['user_uuid'] = $_SESSION['user_uuid'];
	}
	if (!empty($_GET['q'])) {
		$needle = substr(trim((string) $_GET['q']), 0, 64);
		if ($needle !== '') {
			$conditions[] = "(concat_ws(' ',c.contact_name_given,c.contact_name_family,c.contact_organization) ilike :needle or exists(select 1 from v_contact_phones cp where cp.contact_uuid=c.contact_uuid and cp.phone_number ilike :needle))";
			$parameters['needle'] = '%' . $needle . '%';
		}
	}
	$where = 'where ' . implode(' and ', $conditions) . ' ';
	$database = new database;
	$total = (int) $database->select('select count(*) from v_contacts c ' . $where, $parameters, 'column');
	$pages = (int) ceil($total / $page_size);
	if ($pages > 0 && $page > $pages) { $page = $pages; }
	$parameters['page_size'] = $page_size;
	$parameters['page_offset'] = ($page - 1) * $page_size;
	$sql = "select c.contact_uuid,c.contact_type,c.contact_organization,c.contact_name_given,c.contact_name_family,c.contact_title,coalesce(json_agg(json_build_object('label',p.phone_label,'number',p.phone_number,'extension',p.phone_extension,'primary',p.phone_primary) order by p.phone_primary desc nulls last) filter(where p.contact_phone_uuid is not null),'[]') phones from v_contacts c left join v_contact_phones p on p.contact_uuid=c.contact_uuid and p.domain_uuid=c.domain_uuid ";
	$sql .= $where . 'group by c.contact_uuid order by c.contact_name_given,c.contact_name_family,c.contact_organization limit :page_size offset :page_offset';
	$rows = $database->select($sql, $parameters, 'all') ?: [];
	$contacts = [];
	foreach ($rows as $row) {
		$phones = is_array($row['phones']) ? $row['phones'] : (json_decode($row['phones'] ?? '[]', true) ?: []);
		$contacts[] = ['uuid' => $row['contact_uuid'], 'type' => $row['contact_type'] ?? '', 'organization' => $row['contact_organization'] ?? '', 'name' => trim(($row['contact_name_given'] ?? '') . ' ' . ($row['contact_name_family'] ?? '')), 'title' => $row['contact_title'] ?? '', 'phones' => $phones];
	}

	$extension_conditions = ['e.domain_uuid = :domain_uuid', "e.enabled = 'true'"];
	$extension_parameters = ['domain_uuid' => $domain_uuid];
	if (!permission_exists('xml_cdr_domain')) {
		$uuids = portal_assigned_extension_uuids();
		if (empty($uuids)) { $extension_conditions[] = '1=0'; }
		else {
			$placeholders = [];
			foreach ($uuids as $index => $uuid) { $key = 'extension_' . $index; $placeholders[] = ':' . $key; $extension_parameters[$key] = $uuid; }
			$extension_conditions[] = 'e.extension_uuid in (' . implode(',', $placeholders) . ')';
		}
	}
	$sql = 'select e.extension_uuid,e.extension,e.effective_caller_id_name from v_extensions e where ' . implode(' and ', $extension_conditions) . ' order by e.extension limit 200';
	$extensions = $database->select($sql, $extension_parameters, 'all') ?: [];

	echo json_encode(['available' => true, 'scope' => permission_exists('contact_domain_view') ? 'domain' : 'assigned', 'page' => $page, 'page_size' => $page_size, 'pages' => $pages, 'total' => $total, 'contacts' => $contacts, 'extensions' => $extensions, 'capabilities' => ['click_to_call' => permission_exists('click_to_call_call')]], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

?>

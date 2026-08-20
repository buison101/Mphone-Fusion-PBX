<?php

	/* Read-only schema and security contract checks for Portal Phase 4.2. */

	require_once dirname(__DIR__, 4).'/resources/require.php';

	$failures = 0;
	function phase42_check(bool $passed, string $label): void {
		global $failures;
		echo ($passed ? '[PASS] ' : '[FAIL] ').$label.PHP_EOL;
		if (!$passed) { $failures++; }
	}

	$database = new database;
	foreach (['v_portal_call_tags', 'v_portal_call_tag_assignments', 'v_portal_call_notes'] as $table) {
		$exists = (int)$database->select('select count(*) from information_schema.tables where table_name = :table', ['table' => $table], 'column');
		phase42_check($exists === 1, 'schema includes '.$table);
	}

	$required_indexes = [
		'v_portal_call_tags_domain_name_uq',
		'v_portal_call_tag_assignments_call_tag_uq',
		'v_portal_call_tag_assignments_call_idx',
		'v_portal_call_tag_assignments_filter_idx',
		'v_portal_call_notes_call_idx',
	];
	foreach ($required_indexes as $index) {
		$exists = (int)$database->select('select count(*) from pg_indexes where indexname = :index', ['index' => $index], 'column');
		phase42_check($exists === 1, 'schema includes index '.$index);
	}

	foreach (['call_tags.php', 'call_notes.php'] as $file) {
		$source = file_get_contents(dirname(__DIR__, 2).'/service/'.$file);
		foreach (['portal_require_csrf', 'domain_uuid', 'portal_authorized_cdr', 'xml_cdr_view'] as $needle) {
			phase42_check(strpos($source, $needle) !== false, $file.' enforces '.$needle);
		}
	}
	$notes_source = file_get_contents(dirname(__DIR__, 2).'/service/call_notes.php');
	phase42_check(strpos($notes_source, "\$note['user_uuid'] !== \$user_uuid") !== false, 'note updates are limited to their author');
	phase42_check(strpos($notes_source, 'mb_strlen($text) > 2000') !== false, 'note text length is bounded');
	$tags_source = file_get_contents(dirname(__DIR__, 2).'/service/call_tags.php');
	phase42_check(strpos($tags_source, 'mb_strlen($name) > 80') !== false, 'tag name length is bounded');
	phase42_check(strpos($tags_source, "permission_exists('portal_call_tag_edit')") !== false, 'shared tag creation requires tag edit permission');
	phase42_check(strpos($tags_source, "permission_exists('portal_call_tag_assign')") !== false, 'call tag assignment requires tag assign permission');
	phase42_check(strpos($tags_source, "\$action === 'disable'") !== false, 'shared tags support soft disable');
	phase42_check(strpos($tags_source, 'update_user = :user_uuid') !== false, 'tag disable stores update audit user');
	$user_tag_edit = (int)$database->select("select count(*) from v_group_permissions where permission_name = 'portal_call_tag_edit' and group_name in ('user', 'admin')", [], 'column');
	$user_tag_assign = (int)$database->select("select count(*) from v_group_permissions where permission_name = 'portal_call_tag_assign' and group_name = 'user'", [], 'column');
	phase42_check($user_tag_edit === 0, 'admin and ordinary user cannot manage the shared tag catalogue');
	phase42_check($user_tag_assign > 0, 'ordinary user can assign existing tags');
	$calls_source = file_get_contents(dirname(__DIR__, 2).'/service/calls.php');
	foreach (['tag_uuid', 'has_note', 'has_transcript', 'has_summary'] as $filter) {
		phase42_check(strpos($calls_source, $filter) !== false, 'call list supports '.$filter.' filter');
	}

	echo PHP_EOL.($failures === 0 ? 'Portal Phase 4.2 self-test passed.' : 'Portal Phase 4.2 self-test failed with '.$failures.' error(s).').PHP_EOL;
	exit($failures === 0 ? 0 : 1);

?>

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

	Streams a call recording to the portal.

	app/xml_cdr/download.php exists and does the same job, but it looks the record
	up by xml_cdr_uuid alone. This endpoint pins the lookup to the caller's domain
	and, without xml_cdr_domain, to the extensions assigned to them, so a customer
	cannot reach a recording that is not theirs even with a uuid in hand.
*/

	require_once dirname(__DIR__, 3) . "/resources/require.php";
	require_once dirname(__DIR__) . "/resources/identity_session.php";

	header('Cache-Control: private, no-store');
	header('X-Content-Type-Options: nosniff');

	function deny(int $code): void {
		http_response_code($code);
		header('Content-Type: application/json; charset=utf-8');
		echo json_encode(['error' => $code === 401 ? 'unauthorized' : 'forbidden']);
		exit;
	}

	if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
		deny(405);
	}

	portal_identity_validate_session();
	if (empty($_SESSION['authorized']) || empty($_SESSION['user_uuid'])) {
		deny(401);
	}

	if (!permission_exists('portal_view') || !permission_exists('xml_cdr_view')) {
		deny(403);
	}

	if (!permission_exists('xml_cdr_recording')) {
		deny(403);
	}
	if (!permission_exists('xml_cdr_recording_play') && !permission_exists('xml_cdr_recording_download')) {
		deny(403);
	}

	$xml_cdr_uuid = $_GET['id'] ?? '';
	$domain_uuid = $_SESSION['domain_uuid'] ?? '';
	if (!is_uuid($xml_cdr_uuid) || !is_uuid($domain_uuid)) {
		deny(400);
	}

	$parameters = ['xml_cdr_uuid' => $xml_cdr_uuid, 'domain_uuid' => $domain_uuid];
	$scope_sql = '';

	if (!portal_identity_has_domain_scope()) {
		$extension_uuids = [];
		if (!empty($_SESSION['user']['extension']) && is_array($_SESSION['user']['extension'])) {
			foreach ($_SESSION['user']['extension'] as $row) {
				if (!empty($row['extension_uuid']) && is_uuid($row['extension_uuid'])) {
					$extension_uuids[] = $row['extension_uuid'];
				}
			}
			unset($row);
		}
		if (empty($extension_uuids)) {
			deny(403);
		}
		$placeholders = [];
		foreach ($extension_uuids as $index => $uuid) {
			$key = 'extension_uuid_' . $index;
			$placeholders[] = ':' . $key;
			$parameters[$key] = $uuid;
		}
		$scope_sql = "and extension_uuid in (" . implode(', ', $placeholders) . ") ";
		unset($placeholders, $index, $uuid, $key);
	}

	$database = new database;
	$sql = "select record_path, record_name from v_xml_cdr ";
	$sql .= "where xml_cdr_uuid = :xml_cdr_uuid ";
	$sql .= "and domain_uuid = :domain_uuid ";
	$sql .= $scope_sql;
	$row = $database->select($sql, $parameters, 'row');

	if (empty($row['record_path']) || empty($row['record_name'])) {
		deny(404);
	}

//the stored path is trusted only after it is resolved and confirmed to still be
//inside the directory the record claims, so a crafted record cannot walk the disk
	$record_name = basename($row['record_name']);
	$directory = realpath($row['record_path']);
	$file = $directory === false ? false : realpath($directory . DIRECTORY_SEPARATOR . $record_name);

	if ($file === false || strpos($file, $directory . DIRECTORY_SEPARATOR) !== 0 || !is_readable($file)) {
		deny(404);
	}

	$types = [
		'wav' => 'audio/wav',
		'mp3' => 'audio/mpeg',
		'ogg' => 'audio/ogg',
		'm4a' => 'audio/mp4',
	];
	$extension = strtolower(pathinfo($file, PATHINFO_EXTENSION));
	$content_type = $types[$extension] ?? 'application/octet-stream';
	$size = filesize($file);

	$download = isset($_GET['download']) && permission_exists('xml_cdr_recording_download');

	header('Content-Type: ' . $content_type);
	header('Accept-Ranges: bytes');
	header('Content-Disposition: ' . ($download ? 'attachment' : 'inline') . '; filename="' . $record_name . '"');

//range support, the audio element asks for one when the listener seeks
	$start = 0;
	$end = $size - 1;
	if (!empty($_SERVER['HTTP_RANGE']) && preg_match('/bytes=(\d*)-(\d*)/', $_SERVER['HTTP_RANGE'], $matches)) {
		if ($matches[1] !== '') { $start = (int) $matches[1]; }
		if ($matches[2] !== '') { $end = (int) $matches[2]; }
		if ($start > $end || $start >= $size) {
			http_response_code(416);
			header('Content-Range: bytes */' . $size);
			exit;
		}
		if ($end >= $size) { $end = $size - 1; }
		http_response_code(206);
		header('Content-Range: bytes ' . $start . '-' . $end . '/' . $size);
	}

	header('Content-Length: ' . ($end - $start + 1));

	$handle = fopen($file, 'rb');
	if ($handle === false) {
		deny(404);
	}
	fseek($handle, $start);
	$remaining = $end - $start + 1;
	while ($remaining > 0 && !feof($handle)) {
		$chunk = fread($handle, (int) min(8192, $remaining));
		if ($chunk === false) { break; }
		echo $chunk;
		$remaining -= strlen($chunk);
		flush();
	}
	fclose($handle);

?>

<?php

$project_root = dirname(__DIR__, 4);
require_once $project_root.'/resources/require.php';
require_once $project_root.'/resources/check_auth.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');

if (!permission_exists('xml_cdr_statistics')) {
	http_response_code(403);
	echo json_encode(['error' => 'access_denied']);
	exit;
}

require_once dirname(__DIR__).'/classes/cdr_analytics.php';

try {
	$range = $_GET['range'] ?? '7d';
	$data_source = $_GET['data_source'] ?? 'real';
	$data = cdr_analytics_get($range, $data_source);
	echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
catch (Throwable $exception) {
	error_log('CDR analytics request failed: '.$exception->getMessage());
	http_response_code(500);
	echo json_encode(['error' => 'analytics_unavailable']);
}

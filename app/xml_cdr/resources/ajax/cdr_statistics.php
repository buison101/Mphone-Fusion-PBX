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

try {
	require $project_root.'/app/xml_cdr/xml_cdr_statistics_inc.php';
	echo json_encode([
		'chart_range' => $chart_range,
		'data_source' => $data_source,
		'time_zone' => $time_zone,
		'graph' => $graph,
		'stats' => $stats,
	], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
catch (Throwable $exception) {
	error_log('CDR statistics request failed: '.$exception->getMessage());
	http_response_code(500);
	echo json_encode(['error' => 'statistics_unavailable']);
}


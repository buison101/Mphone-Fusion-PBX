<?php

function cdr_analytics_get(string $range = '7d', string $data_source = 'real'): array {
	global $database, $settings;

	if (!in_array($range, ['1h', '3h', 'today', 'yesterday', '7d', '30d', '1y'], true)) {
		$range = 'today';
	}
	$data_source = $data_source === 'test' && permission_exists('xml_cdr_domain') ? 'test' : 'real';
	$time_zone = $settings->get('domain', 'time_zone', date_default_timezone_get());
	switch ($range) {
		case '1h':
			$start_expression = "now() - interval '1 hour'";
			$end_expression = 'now()';
			break;
		case '3h':
			$start_expression = "now() - interval '3 hours'";
			$end_expression = 'now()';
			break;
		case 'yesterday':
			$start_expression = "(date_trunc('day', now() at time zone :time_zone) - interval '1 day') at time zone :time_zone";
			$end_expression = "date_trunc('day', now() at time zone :time_zone) at time zone :time_zone";
			break;
		case '7d':
			$start_expression = "(date_trunc('day', now() at time zone :time_zone) - interval '6 days') at time zone :time_zone";
			$end_expression = "(date_trunc('day', now() at time zone :time_zone) + interval '1 day') at time zone :time_zone";
			break;
		case '30d':
			$start_expression = "(date_trunc('day', now() at time zone :time_zone) - interval '29 days') at time zone :time_zone";
			$end_expression = "(date_trunc('day', now() at time zone :time_zone) + interval '1 day') at time zone :time_zone";
			break;
		case '1y':
			$start_expression = "(date_trunc('day', now() at time zone :time_zone) - interval '1 year' + interval '1 day') at time zone :time_zone";
			$end_expression = "(date_trunc('day', now() at time zone :time_zone) + interval '1 day') at time zone :time_zone";
			break;
		default:
			$start_expression = "date_trunc('day', now() at time zone :time_zone) at time zone :time_zone";
			$end_expression = "(date_trunc('day', now() at time zone :time_zone) + interval '1 day') at time zone :time_zone";
	}

	$parameters = ['time_zone' => $time_zone];
	if ($data_source === 'test') {
		$pdo = new PDO(
			"pgsql:host=".$database->host.";port=".$database->port.";dbname=fusionpbx_analytics_test",
			$database->username,
			$database->password,
			[PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
		);
		$table = 'analytics_test.call_records';
		$where = "c.start_stamp >= ".$start_expression." and c.start_stamp < ".$end_expression;
		$execute = static function (string $sql, array $params = []) use ($pdo): array {
			$statement = $pdo->prepare($sql);
			$statement->execute($params);
			return $statement->fetchAll();
		};
		$extension_source = 'c.extension';
		$extension_target = 'c.extension';
		$customer_source = "case when c.direction = 'inbound' then c.caller_id_number else c.destination_number end";
		$answered = "c.status = 'answered'";
		$missed = 'c.missed_call = true';
		$rejected = "c.status in ('busy', 'cancelled', 'failed')";
	}
	else {
		$table = 'v_xml_cdr';
		$where = "c.domain_uuid = :domain_uuid and c.start_stamp >= ".$start_expression." and c.start_stamp < ".$end_expression;
		$parameters['domain_uuid'] = $_SESSION['domain_uuid'];
		if (!permission_exists('xml_cdr_domain')) {
			$extensions = [];
			foreach (($_SESSION['user']['extension'] ?? []) as $extension) {
				if (!empty($extension['user'])) {
					$extensions[] = (string) $extension['user'];
				}
			}
			$extensions = array_values(array_unique($extensions));
			if (empty($extensions)) {
				$where .= ' and false';
			}
			else {
				$extension_conditions = [];
				foreach ($extensions as $index => $extension) {
					$key = 'analytics_extension_'.$index;
					$parameters[$key] = $extension;
					$extension_conditions[] = "c.caller_id_number = :".$key." or c.destination_number = :".$key;
				}
				$where .= ' and ('.implode(' or ', $extension_conditions).')';
			}
		}
		$where .= " and c.originating_leg_uuid is null and (c.cc_side is null or c.cc_side <> 'agent')";
		if (!permission_exists('xml_cdr_lose_race')) {
			$where .= " and coalesce(c.hangup_cause, '') <> 'LOSE_RACE'";
		}
		$execute = static function (string $sql, array $params = []) use ($database): array {
			$result = $database->select($sql, $params, 'all');
			return is_array($result) ? $result : [];
		};
		$extension_source = 'c.caller_id_number';
		$extension_target = 'c.destination_number';
		$customer_source = "case when c.direction = 'inbound' then c.caller_id_number else c.destination_number end";
		$answered = 'c.answer_stamp is not null and c.billsec > 0';
		$missed = "coalesce(c.missed_call, false) = true or c.hangup_cause = 'NO_ANSWER'";
		$rejected = "not (".$answered.") and not (".$missed.")";
	}

	$summary_sql = "select
		count(*) filter (where c.direction = 'inbound') as inbound,
		count(*) filter (where c.direction = 'outbound') as outbound,
		count(*) filter (where c.direction = 'local' or c.direction is null) as local,
		count(*) filter (where (".$answered.") and not (".$missed.")) as answered,
		count(*) filter (where ".$rejected.") as rejected,
		count(*) filter (where ".$missed.") as missed
		from ".$table." c where ".$where;
	$summary = $execute($summary_sql, $parameters)[0] ?? [];

	$top_query = static function (string $expression, string $extra_where = 'true') use ($execute, $table, $where, $parameters): array {
		$sql = "select ".$expression." as number, count(*) as call_count, coalesce(round(sum(c.billsec) / 60.0), 0) as total_minutes
			from ".$table." c where ".$where." and ".$extra_where." and nullif(".$expression.", '') is not null
			group by ".$expression." order by call_count desc, total_minutes desc limit 10";
		return $execute($sql, $parameters);
	};

	$extension_filter = $data_source === 'test'
		? 'true'
		: "exists (select 1 from v_extensions e where e.domain_uuid = :domain_uuid and e.extension = ";
	$top_callers = $top_query($extension_source, $data_source === 'test' ? 'true' : $extension_filter.$extension_source.')');
	$top_called = $top_query($extension_target, $data_source === 'test' ? 'true' : $extension_filter.$extension_target.')');
	$top_customers = $top_query($customer_source, "c.direction in ('inbound', 'outbound')".($data_source === 'test' ? '' : " and not exists (select 1 from v_extensions e where e.domain_uuid = :domain_uuid and e.extension = ".$customer_source.")"));
	$top_missed = $top_query($customer_source, "c.direction = 'inbound' and (".$missed.")");

	$duration_sql = "select extract(epoch from c.start_stamp)::bigint as start_epoch, c.caller_id_number, c.destination_number, c.billsec, c.direction
		from ".$table." c where ".$where." and ".$answered." and c.billsec > 0 order by c.billsec %s limit 10";
	$longest = $execute(sprintf($duration_sql, 'desc'), $parameters);
	$shortest = $execute(sprintf($duration_sql, 'asc'), $parameters);

	return [
		'range' => $range,
		'time_zone' => $time_zone,
		'summary' => array_map('intval', array_merge(['inbound'=>0,'outbound'=>0,'local'=>0,'answered'=>0,'rejected'=>0,'missed'=>0], $summary)),
		'top_callers' => $top_callers,
		'top_called' => $top_called,
		'top_customers' => $top_customers,
		'top_missed' => $top_missed,
		'longest' => $longest,
		'shortest' => $shortest,
	];
}

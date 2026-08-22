<?php
	require_once __DIR__ . '/identity_session.php';

/* Shared, read-only CDR scope and bounded reporting period for Portal reports. */

	function portal_report_context(): array {
		$domain_uuid = $_SESSION['domain_uuid'] ?? '';
		if (!is_uuid($domain_uuid)) {
			throw new InvalidArgumentException('invalid_domain');
		}

		$to = !empty($_GET['to']) && strtotime($_GET['to']) !== false ? date('Y-m-d', strtotime($_GET['to'])) : date('Y-m-d');
		$from = !empty($_GET['from']) && strtotime($_GET['from']) !== false ? date('Y-m-d', strtotime($_GET['from'])) : date('Y-m-d', strtotime($to . ' -29 days'));
		if (strtotime($from) > strtotime($to)) { [$from, $to] = [$to, $from]; }
		if ((strtotime($to) - strtotime($from)) > 366 * 86400) {
			$from = date('Y-m-d', strtotime($to . ' -366 days'));
		}

		$scope = 'domain';
		$conditions = ['c.domain_uuid = :domain_uuid', 'c.start_stamp >= :from_stamp', 'c.start_stamp < :to_stamp'];
		$parameters = [
			'domain_uuid' => $domain_uuid,
			'from_stamp' => $from . ' 00:00:00',
			'to_stamp' => date('Y-m-d', strtotime($to . ' +1 day')) . ' 00:00:00',
		];

		if (!portal_identity_has_domain_scope()) {
			$scope = 'extensions';
			$extension_uuids = [];
			foreach (($_SESSION['user']['extension'] ?? []) as $row) {
				if (!empty($row['extension_uuid']) && is_uuid($row['extension_uuid'])) { $extension_uuids[] = $row['extension_uuid']; }
			}
			if (empty($extension_uuids)) {
				$conditions[] = '1 = 0';
			}
			else {
				$placeholders = [];
				foreach (array_values(array_unique($extension_uuids)) as $index => $uuid) {
					$key = 'scope_extension_' . $index;
					$placeholders[] = ':' . $key;
					$parameters[$key] = $uuid;
				}
				$conditions[] = 'c.extension_uuid in (' . implode(', ', $placeholders) . ')';
			}
		}

		if (!empty($_GET['extension_uuid']) && is_uuid($_GET['extension_uuid'])) {
			$conditions[] = 'c.extension_uuid = :selected_extension_uuid';
			$parameters['selected_extension_uuid'] = $_GET['extension_uuid'];
		}
		if (!empty($_GET['direction']) && in_array($_GET['direction'], ['inbound', 'outbound', 'local'], true)) {
			$conditions[] = 'c.direction = :direction';
			$parameters['direction'] = $_GET['direction'];
		}

		return [
			'domain_uuid' => $domain_uuid,
			'scope' => $scope,
			'from' => $from,
			'to' => $to,
			'where' => 'where ' . implode(' and ', $conditions) . ' ',
			'parameters' => $parameters,
		];
	}

?>

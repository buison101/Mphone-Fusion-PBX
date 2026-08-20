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

	Call status for the portal.

	answer_stamp cannot be used to decide whether a call was answered. The switch
	sets it on legs that never connected: on this system every single record has
	an answer stamp, including the ones with status cancelled, busy and failed.
	The status column is the value FusionPBX itself displays and filters on.

	When status is empty the CDR page derives it in PHP. The same rules are
	expressed here as SQL so the portal never shows a row without a status and
	never disagrees with the administration pages.

	See app/xml_cdr/xml_cdr.php, the "set the status" block.
*/

//hangup causes the CDR page treats as a failed call
if (!function_exists('portal_call_status_failed_causes')) {
	function portal_call_status_failed_causes(): array {
		return [
			'CALL_REJECTED',
			'CHAN_NOT_IMPLEMENTED',
			'DESTINATION_OUT_OF_ORDER',
			'EXCHANGE_ROUTING_ERROR',
			'INCOMPATIBLE_DESTINATION',
			'INVALID_NUMBER_FORMAT',
			'MANDATORY_IE_MISSING',
			'NETWORK_OUT_OF_ORDER',
			'NORMAL_TEMPORARY_FAILURE',
			'NO_ROUTE_DESTINATION',
			'RECOVERY_ON_TIMER_EXPIRE',
			'REQUESTED_CHAN_UNAVAIL',
			'SUBSCRIBER_ABSENT',
			'SYSTEM_SHUTDOWN',
			'UNALLOCATED_NUMBER',
		];
	}
}

//the statuses a caller may filter by, same list the CDR page offers
if (!function_exists('portal_call_statuses')) {
	function portal_call_statuses(): array {
		return ['answered', 'no_answer', 'busy', 'missed', 'voicemail', 'cancelled', 'failed'];
	}
}

/**
 * SQL expression producing the effective status of a row.
 *
 * The order of the cases is the reverse of the PHP, because a CASE returns its
 * first match while the PHP block lets later assignments overwrite earlier ones.
 */
if (!function_exists('portal_call_status_sql')) {
	function portal_call_status_sql(string $alias = ''): string {
		$failed = "'" . implode("', '", portal_call_status_failed_causes()) . "'";
		$prefix = $alias !== '' ? rtrim($alias, '.') . '.' : '';

		return "case
			when {$prefix}status is not null and {$prefix}status <> '' then {$prefix}status
			when {$prefix}hangup_cause in ($failed) then 'failed'
			when {$prefix}hangup_cause = 'USER_BUSY' then 'busy'
			when {$prefix}hangup_cause = 'ORIGINATOR_CANCEL' then 'cancelled'
			when {$prefix}destination_number like '*99%' then 'voicemail'
			when {$prefix}missed_call is true then 'missed'
			when {$prefix}hangup_cause = 'NO_ANSWER' then 'no_answer'
			when {$prefix}billsec > 0 then 'answered'
			else 'no_answer'
		end";
	}
}

?>

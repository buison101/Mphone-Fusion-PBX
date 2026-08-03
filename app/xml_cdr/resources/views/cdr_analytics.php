<?php

$analytics_id = $analytics_id ?? 'cdr_analytics_'.substr(md5((string) microtime(true)), 0, 8);
$analytics_compact = $analytics_compact ?? false;
$analytics_show_summary = $analytics_show_summary ?? true;
$analytics_show_top = $analytics_show_top ?? true;
$analytics_language = strtolower($settings->get('domain', 'language', 'en-us'));
$analytics_vi = $analytics_language === 'vi' || str_starts_with($analytics_language, 'vi-');
$analytics_labels = $analytics_vi ? [
	'title' => 'Phân tích cuộc gọi', 'range' => 'Khoảng', 'inbound' => 'Cuộc gọi đến',
	'outbound' => 'Cuộc gọi đi', 'local' => 'Cuộc gọi nội bộ', 'answered' => 'Thành công',
	'rejected' => 'Từ chối', 'missed' => 'Cuộc gọi nhỡ', 'top_callers' => 'Top 10 Extension gọi nhiều',
	'top_called' => 'Top 10 Extension bị gọi', 'top_customers' => 'Top 10 khách hàng', 'top_missed' => 'Top 10 số bị nhỡ',
	'longest' => 'Top 10 cuộc gọi dài nhất', 'shortest' => 'Top 10 cuộc gọi ngắn nhất', 'number' => 'Số',
	'calls' => 'Số cuộc gọi', 'minutes' => 'Tổng phút', 'time' => 'Thời gian', 'source' => 'Nguồn',
	'destination' => 'Đích', 'duration' => 'Thời lượng',
] : [
	'title' => 'Call Analytics', 'range' => 'Range', 'inbound' => 'Inbound', 'outbound' => 'Outbound',
	'local' => 'Internal', 'answered' => 'Successful', 'rejected' => 'Rejected', 'missed' => 'Missed',
	'top_callers' => 'Top calling extensions', 'top_called' => 'Top called extensions',
	'top_customers' => 'Top customers', 'top_missed' => 'Top missed numbers', 'longest' => 'Longest calls',
	'shortest' => 'Shortest calls', 'number' => 'Number', 'calls' => 'Calls', 'minutes' => 'Total minutes',
	'time' => 'Time', 'source' => 'Source', 'destination' => 'Destination', 'duration' => 'Duration',
];
$analytics_tabs = ['top_callers','top_called','top_customers','top_missed','longest','shortest'];
?>
<div id="<?=$analytics_id?>" style="width:100%;">
	<div style="display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap;margin-bottom:12px;">
		<strong><?=escape($analytics_labels['title'])?></strong>
	</div>
	<?php if ($analytics_show_summary) { ?>
	<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:16px;margin-top:32px;margin-bottom:16px;">
		<div style="height:<?=$analytics_compact ? '180' : '220'?>px;"><canvas id="<?=$analytics_id?>_direction"></canvas></div>
		<div style="height:<?=$analytics_compact ? '180' : '220'?>px;"><canvas id="<?=$analytics_id?>_outcome"></canvas></div>
	</div>
	<?php } ?>
	<?php if ($analytics_show_top) { ?>
	<div style="display:flex;gap:6px;flex-wrap:wrap;margin-bottom:10px;">
		<?php foreach ($analytics_tabs as $index => $tab) { ?>
		<button type="button" class="btn btn-default" data-analytics-tab="<?=$tab?>" style="<?=$index === 0 ? 'color:#fff;background:#48484a;background-image:unset;' : ''?>"><?=escape($analytics_labels[$tab])?></button>
		<?php } ?>
	</div>
	<?php foreach ($analytics_tabs as $index => $tab) { ?>
	<div data-analytics-panel="<?=$tab?>" style="display:<?=$index === 0 ? 'block' : 'none'?>;overflow:auto;max-height:<?=$analytics_compact ? '260px' : 'none'?>;">
		<table class="list" style="width:100%;">
			<tr class="list-header">
			<?php if (in_array($tab, ['longest','shortest'], true)) { ?>
				<th><?=escape($analytics_labels['time'])?></th><th><?=escape($analytics_labels['source'])?></th><th><?=escape($analytics_labels['destination'])?></th><th><?=escape($analytics_labels['duration'])?></th>
			<?php } else { ?>
				<th><?=escape($analytics_labels['number'])?></th><th><?=escape($analytics_labels['calls'])?></th><th><?=escape($analytics_labels['minutes'])?></th>
			<?php } ?>
			</tr>
			<tbody data-analytics-body="<?=$tab?>">
			<?php foreach (($cdr_analytics_data[$tab] ?? []) as $row) { ?>
			<tr class="list-row">
			<?php if (in_array($tab, ['longest','shortest'], true)) {
				$stamp = (new DateTimeImmutable('@'.(int) $row['start_epoch']))->setTimezone(new DateTimeZone($cdr_analytics_data['time_zone'])); ?>
				<td class="no-wrap"><?=escape($stamp->format('d/m/Y H:i'))?></td><td><?=escape($row['caller_id_number'])?></td><td><?=escape($row['destination_number'])?></td><td><?=escape(gmdate('H:i:s', (int) $row['billsec']))?></td>
			<?php } else { ?>
				<td><?=escape($row['number'])?></td><td><?=escape(number_format((int) $row['call_count'], 0, $analytics_vi ? ',' : '.', $analytics_vi ? '.' : ','))?></td><td><?=escape(number_format((int) $row['total_minutes'], 0, $analytics_vi ? ',' : '.', $analytics_vi ? '.' : ','))?></td>
			<?php } ?>
			</tr>
			<?php } ?>
			</tbody>
		</table>
	</div>
	<?php } ?>
	<?php } ?>
</div>
<script>
(() => {
	const root = document.getElementById(<?=json_encode($analytics_id)?>);
	<?php if ($analytics_show_top) { ?>
	root.querySelectorAll('[data-analytics-tab]').forEach((button) => button.addEventListener('click', () => {
		root.querySelectorAll('[data-analytics-tab]').forEach((item) => item.style.cssText = '');
		root.querySelectorAll('[data-analytics-panel]').forEach((panel) => panel.style.display = 'none');
		button.style.cssText = 'color:#fff;background:#48484a;background-image:unset;';
		root.querySelector(`[data-analytics-panel="${button.dataset.analyticsTab}"]`).style.display = 'block';
	}));
	<?php } ?>
	let summary = <?=json_encode($cdr_analytics_data['summary'], JSON_NUMERIC_CHECK)?>;
	<?php if ($analytics_show_summary) { ?>
	const doughnut = (id, labels, values, colors) => new Chart(document.getElementById(id), {
		type: 'doughnut', data: {labels, datasets:[{data:values,backgroundColor:colors,borderWidth:0}]},
		options: {responsive:true,maintainAspectRatio:false,cutout:'62%',plugins:{legend:{position:'bottom',labels:{boxWidth:12,padding:16,usePointStyle:true,pointStyle:'circle'}}}}
	});
	const direction_chart = doughnut(<?=json_encode($analytics_id.'_direction')?>, <?=json_encode([$analytics_labels['inbound'],$analytics_labels['outbound'],$analytics_labels['local']])?>, [summary.inbound,summary.outbound,summary.local], ['#22C55E','#4F7FE2','#F59E0B']);
	const outcome_chart = doughnut(<?=json_encode($analytics_id.'_outcome')?>, <?=json_encode([$analytics_labels['answered'],$analytics_labels['rejected'],$analytics_labels['missed']])?>, [summary.answered,summary.rejected,summary.missed], ['#22C55E','#F59E0B','#EF4444']);
	<?php } ?>
	<?php if ($analytics_show_top) { ?>
	const number_formatter = new Intl.NumberFormat(<?=json_encode($analytics_vi ? 'vi-VN' : $analytics_language)?>, {maximumFractionDigits: 0});
	const date_formatter = new Intl.DateTimeFormat(<?=json_encode($analytics_vi ? 'vi-VN' : $analytics_language)?>, {
		timeZone: <?=json_encode($cdr_analytics_data['time_zone'])?>, day:'2-digit', month:'2-digit', year:'numeric', hour:'2-digit', minute:'2-digit', hourCycle:'h23'
	});
	const duration_formatter = (seconds) => {
		seconds = Number(seconds) || 0;
		const hours = Math.floor(seconds / 3600);
		const minutes = Math.floor((seconds % 3600) / 60);
		const remaining = seconds % 60;
		return [hours, minutes, remaining].map((value) => String(value).padStart(2, '0')).join(':');
	};
	const append_cell = (row, value, class_name = '') => {
		const cell = document.createElement('td');
		cell.textContent = value ?? '';
		if (class_name) cell.className = class_name;
		row.append(cell);
	};
	const render_tables = (data) => {
		<?=json_encode($analytics_tabs)?>.forEach((tab) => {
			const body = root.querySelector(`[data-analytics-body="${tab}"]`);
			body.replaceChildren();
			(data[tab] ?? []).forEach((item) => {
				const row = document.createElement('tr');
				row.className = 'list-row';
				if (tab === 'longest' || tab === 'shortest') {
					append_cell(row, date_formatter.format(new Date(Number(item.start_epoch) * 1000)), 'no-wrap');
					append_cell(row, item.caller_id_number);
					append_cell(row, item.destination_number);
					append_cell(row, duration_formatter(item.billsec));
				}
				else {
					append_cell(row, item.number);
					append_cell(row, number_formatter.format(Number(item.call_count) || 0));
					append_cell(row, number_formatter.format(Number(item.total_minutes) || 0));
				}
				body.append(row);
			});
		});
	};
	<?php } ?>
	const update_analytics = (data) => {
		summary = data.summary;
		<?php if ($analytics_show_summary) { ?>
		direction_chart.data.datasets[0].data = [summary.inbound, summary.outbound, summary.local];
		outcome_chart.data.datasets[0].data = [summary.answered, summary.rejected, summary.missed];
		direction_chart.update();
		outcome_chart.update();
		<?php } ?>
		<?php if ($analytics_show_top) { ?>
		render_tables(data);
		<?php } ?>
	};
	window.cdrAnalyticsUpdaters = window.cdrAnalyticsUpdaters || [];
	window.cdrAnalyticsUpdaters.push(update_analytics);
})();
</script>

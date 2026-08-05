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

	The Initial Developer of the Original Code is
	Mark J Crane <markjcrane@fusionpbx.com>
	Portions created by the Initial Developer are Copyright (C) 2008-2025
	the Initial Developer. All Rights Reserved.

	Contributor(s):
	Mark J Crane <markjcrane@fusionpbx.com>
*/

//includes files
	require_once dirname(__DIR__, 2) . "/resources/require.php";
	require_once "resources/check_auth.php";
	require_once "xml_cdr_statistics_inc.php";

//check permissions
	if (!permission_exists('xml_cdr_statistics')) {
		echo "access denied";
		exit;
	}
	header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
	header('Pragma: no-cache');

//add multi-lingual support
	$language = new text;
	$text = $language->get();
	$language_code = strtolower($settings->get('domain', 'language', 'en-us'));
	$is_vietnamese = $language_code === 'vi' || str_starts_with($language_code, 'vi-');
	if (in_array($chart_range, ['1h', '3h'], true)) {
		$chart_bucket_label = $text['label-minutes'] ?? ($is_vietnamese ? 'Phút' : 'Minutes');
	}
	else if (in_array($chart_range, ['today', 'yesterday'], true)) {
		$chart_bucket_label = $text['label-hours'] ?? ($is_vietnamese ? 'Giờ' : 'Hours');
	}
	else if ($chart_range === '1y') {
		$chart_bucket_label = $text['label-months'] ?? ($is_vietnamese ? 'Tháng' : 'Months');
	}
	else {
		$chart_bucket_label = $text['label-days'] ?? ($is_vietnamese ? 'Ngày' : 'Days');
	}
	$chart_labels = [
		'volume' => $is_vietnamese ? 'Số cuộc gọi' : 'Call count',
		'minutes' => $is_vietnamese ? 'Tổng phút' : 'Total minutes',
		'missed' => $is_vietnamese ? 'Cuộc gọi nhỡ' : 'Missed calls',
		'asr' => $is_vietnamese ? 'Tỷ lệ trả lời' : 'Answer rate',
		'aloc' => $is_vietnamese ? 'Thời lượng trung bình' : 'Average duration',
	];
	$format_stat_number = static function ($value, int $decimals = 2) use ($is_vietnamese) {
		if (!$is_vietnamese) {
			return (string) round((float) $value, $decimals);
		}
		$formatted = number_format((float) $value, $decimals, ',', '.');
		if ($decimals > 0) {
			$formatted = rtrim(rtrim($formatted, '0'), ',');
		}
		return $formatted;
	};

//set default showall
	$show_all = false;

//additional includes
	$document['title'] = $text['title-call-statistics'];
	require_once "resources/header.php";

//search url
	$search_url = '';
	if ($data_source === 'test') {
		$search_url .= '&data_source=test';
	}
	$search_url .= '&chart_range='.urlencode($chart_range);
	if (permission_exists('xml_cdr_search_advanced')) {
		$search_url .= '&redirect=xml_cdr_statistics';
	}
	if(permission_exists('xml_cdr_all') && (isset($_GET['showall']) && $_GET['showall'] === 'true')){
		$search_url .= '&showall=true';
		$show_all = true;
	}
	if (!empty($_GET['direction'])) {
		$search_url .= '&direction='.urlencode($_GET['direction']);
	}
	if (!empty($_GET['leg'])) {
		$search_url .= '&leg='.urlencode($_GET['leg']);
	}
	if (!empty($_GET['caller_id_name'])) {
		$search_url .= '&caller_id_name='.urlencode($_GET['caller_id_name']);
	}
	if (!empty($_GET['caller_extension_uuid'])) {
		$search_url .= '&caller_extension_uuid='.urlencode($_GET['caller_extension_uuid']);
	}
	if (!empty($_GET['caller_id_number'])) {
		$search_url .= '&caller_id_number='.urlencode($_GET['caller_id_number']);
	}
	if (!empty($_GET['destination_number'])) {
		$search_url .= '&destination_number='.urlencode($_GET['destination_number']);
	}
	if (!empty($_GET['context'])) {
		$search_url .= '&context='.urlencode($_GET['context']);
	}
	if (!empty($_GET['start_stamp_begin'])) {
		$search_url .= '&start_stamp_begin='.urlencode($_GET['start_stamp_begin']);
	}
	if (!empty($_GET['start_stamp_end'])) {
		$search_url .= '&start_stamp_end='.urlencode($_GET['start_stamp_end']);
	}
	if (!empty($_GET['answer_stamp_begin'])) {
		$search_url .= '&answer_stamp_begin='.urlencode($_GET['answer_stamp_begin']);
	}
	if (!empty($_GET['answer_stamp_end'])) {
		$search_url .= '&answer_stamp_end='.urlencode($_GET['answer_stamp_end']);
	}
	if (!empty($_GET['end_stamp_begin'])) {
		$search_url .= '&end_stamp_begin='.urlencode($_GET['end_stamp_begin']);
	}
	if (!empty($_GET['end_stamp_end'])) {
		$search_url .= '&end_stamp_end='.urlencode($_GET['end_stamp_end']);
	}
	if (!empty($_GET['duration'])) {
		$search_url .= '&duration='.urlencode($_GET['duration']);
	}
	if (!empty($_GET['billsec'])) {
		$search_url .= '&billsec='.urlencode($_GET['billsec']);
	}
	if (!empty($_GET['hangup_cause'])) {
		$search_url .= '&hangup_cause='.urlencode($_GET['hangup_cause']);
	}
	if (!empty($_GET['uuid'])) {
		$search_url .= '&uuid='.urlencode($_GET['uuid']);
	}
	if (!empty($_GET['bleg_uuid'])) {
		$search_url .= '&bleg_uuid='.urlencode($_GET['bleg_uuid']);
	}
	if (!empty($_GET['accountcode'])) {
		$search_url .= '&accountcode='.urlencode($_GET['accountcode']);
	}
	if (!empty($_GET['read_codec'])) {
		$search_url .= '&read_codec='.urlencode($_GET['read_codec']);
	}
	if (!empty($_GET['write_codec'])) {
		$search_url .= '&write_codec='.urlencode($_GET['write_codec']);
	}
	if (!empty($_GET['remote_media_ip'])) {
		$search_url .= '&remote_media_ip='.urlencode($_GET['remote_media_ip']);
	}
	if (!empty($_GET['network_addr'])) {
		$search_url .= '&network_addr='.urlencode($_GET['network_addr']);
	}
	if (!empty($_GET['mos_comparison'])) {
		$search_url .= '&mos_comparison='.urlencode($_GET['mos_comparison']);
	}
	if (!empty($_GET['mos_score'])) {
		$search_url .= '&mos_score='.urlencode($_GET['mos_score']);
	}

//set the chart time format
	if ($settings->get('domain', 'time_format') == '24h') {
		$chart_time_format = 'H:mm';
	}
	else {
		$chart_time_format = 'h a';
	}

//show the content
	echo "<div class='action_bar' id='action_bar'>\n";
	echo "	<div class='heading'><b>".$text['title-call-statistics']."</b></div>\n";
	echo "	<div class='actions'>\n";
	if ($can_use_test_data) {
		echo "		<span style='display: inline-flex; align-items: center; gap: 6px; margin-right: 12px;'>\n";
		echo "			<span>".escape($text['label-data_source'] ?? ($is_vietnamese ? 'Nguồn dữ liệu' : 'Data source')).":</span>\n";
		echo button::create(['type'=>'button','label'=>($is_vietnamese ? 'Thật' : 'Real'),'icon'=>($data_source === 'real' ? 'check-circle' : 'database'),'link'=>'xml_cdr_statistics.php?chart_range='.urlencode($chart_range)]);
		$test_token_object = new token;
		$test_token = $test_token_object->create($_SERVER['PHP_SELF']);
		echo "<form method='post' action='xml_cdr_statistics.php' style='display: inline; margin: 0;'>\n";
		echo "<input type='hidden' name='".escape($test_token['name'])."' value='".escape($test_token['hash'])."'>\n";
		echo "<input type='hidden' name='data_source' value='test'>\n";
		echo "<input type='hidden' name='chart_range' value='".escape($chart_range)."'>\n";
		echo "<input type='hidden' name='regenerate_test_data' value='true'>\n";
		echo button::create(['type'=>'submit','label'=>'Test','icon'=>($data_source === 'test' ? 'check-circle' : 'flask')]);
		echo "</form>\n";
		echo "		</span>\n";
	}
	echo "		<span style='display: inline-flex; align-items: center; gap: 6px; margin-right: 12px;'>\n";
	echo "			<span>".escape($text['label-chart_range'] ?? ($is_vietnamese ? 'Khoảng biểu đồ' : 'Chart range')).":</span>\n";
	$range_options = $is_vietnamese
		? ['today' => 'Hôm nay', '1h' => '1 giờ', '3h' => '3 giờ', 'yesterday' => 'Hôm qua', '7d' => '7 ngày', '30d' => '30 ngày', '1y' => '1 năm']
		: ['today' => 'Today', '1h' => '1 hour', '3h' => '3 hours', 'yesterday' => 'Yesterday', '7d' => '7 days', '30d' => '30 days', '1y' => '1 year'];
	foreach ($range_options as $range_value => $range_label) {
		$range_active = $chart_range === $range_value;
		echo "<button type='button' class='btn btn-default' data-cdr-chart-range='".escape($range_value)."'".($range_active ? " style='color:#ffffff;background:#48484a;background-image:unset;'" : null).">";
		echo "<span class='fa-solid fa-".($range_active ? 'check-circle' : 'chart-line')." fa-fw'></span>";
		echo "<span class='button-label pad'>".escape($range_label)."</span>";
		echo "</button>";
	}
	echo "		</span>\n";
	if (substr_count($_SERVER['HTTP_REFERER'], 'app/xml_cdr/xml_cdr.php') != 0) {
		echo button::create(['type'=>'button','label'=>$text['button-back'],'icon'=>$settings->get('theme', 'button_icon_back'),'id'=>'btn_back','style'=>'margin-right: 15px;','link'=>'xml_cdr.php']);
	}
	if (permission_exists('xml_cdr_search_advanced')) {
		echo button::create(['type'=>'button','label'=>$text['button-advanced_search'],'icon'=>'tools','link'=>'xml_cdr_search.php?type=advanced'.$search_url]);
	}
	if (permission_exists('xml_cdr_all') && !$show_all) {
		echo button::create(['type'=>'button','label'=>$text['button-show_all'],'icon'=>$settings->get('theme', 'button_icon_all'),'link'=>'xml_cdr_statistics.php?showall=true'.$search_url]);
	}
	echo button::create(['type'=>'button','label'=>$text['button-extension_summary'],'icon'=>'list','link'=>'xml_cdr_extension_summary.php']);
	echo button::create(['type'=>'button','label'=>$text['button-download_csv'],'icon'=>$settings->get('theme', 'button_icon_download'),'link'=>'xml_cdr_statistics_csv.php?type=csv'.$search_url]);
	echo "	</div>\n";
	echo "	<div style='clear: both;'></div>\n";
	echo "</div>\n";

	//load the call analytics once; the common range selector updates every chart
	require_once __DIR__.'/resources/classes/cdr_analytics.php';
	$cdr_analytics_data = cdr_analytics_get($chart_range, $data_source);
	?>
	<script src='/resources/chartjs/chart.min.js'></script>
	<script src='/resources/chartjs/chartjs-adapter-date-fns.bundle.min.js'></script>
	<style>
		.cdr-statistics-chart-grid { display:grid; grid-template-columns:minmax(0,3fr) minmax(0,2fr); grid-template-areas:'statistics analytics'; gap:16px; align-items:stretch; margin-bottom:16px; }
		.cdr-statistics-chart-grid > .card { margin:0; min-width:0; }
		.cdr-statistics-analytics-card { grid-area:analytics; }
		.cdr-statistics-main-card { grid-area:statistics; }
		@media (max-width:1024px) {
			.cdr-statistics-chart-grid { grid-template-columns:minmax(0,1fr); grid-template-areas:'statistics' 'analytics'; }
		}
	</style>
	<div class="cdr-statistics-chart-grid">
		<div class="card cdr-statistics-analytics-card">
		<?php
		$analytics_id = 'cdr_statistics_analytics_summary';
		$analytics_compact = false;
		$analytics_show_summary = true;
		$analytics_show_top = false;
		require __DIR__.'/resources/views/cdr_analytics.php';
		?>
		</div>
		<div class="card cdr-statistics-main-card">
	<div align='center' style="justify-content: center; margin-top: 16px; margin-bottom: 0px;">
		<div style="max-width: 100%; width: 800px;">
			<div id="cdr_stats_legend" style="display: flex; flex-wrap: wrap; align-items: center; justify-content: center; gap: 10px 18px; min-height: 20px; margin-bottom: 8px;"></div>
			<div style="height: 280px;">
				<canvas id="cdr_stats_chart" style="width: 100%; height: 100%;"></canvas>
			</div>
		</div>
	</div>

	<script type="text/javascript">
		var ctx = document.getElementById("cdr_stats_chart").getContext('2d');

		const cdr_stats_data = {
			datasets: [
				{
					label: <?php echo json_encode($chart_labels['volume']); ?>,
					data: <?php echo json_encode($graph['volume']); ?>,
					backgroundColor: "#22C55E",
					borderColor: "#22C55E",
					fill: false
				},
				{
					label: <?php echo json_encode($chart_labels['minutes']); ?>,
					data: <?php echo json_encode($graph['minutes']); ?>,
					backgroundColor: "#4F7FE2",
					borderColor: "#4F7FE2",
					fill: false
				},
				{
					label: <?php echo json_encode($chart_labels['missed']); ?>,
					data: <?php echo json_encode($graph['missed']); ?>,
					backgroundColor: "#EF4444",
					borderColor: "#EF4444",
					fill: false
				},
				{
					label: <?php echo json_encode($chart_labels['aloc']); ?>,
					data: <?php echo json_encode($graph['aloc']); ?>,
					backgroundColor: "#F59E0B",
					borderColor: "#F59E0B",
					fill: false
				},
				{
					label: <?php echo json_encode($chart_labels['asr']); ?>,
					unit: '%',
					yAxisID: 'yAsr',
					data: <?php echo json_encode($graph['asr']); ?>,
					backgroundColor: "#B9CEF8",
					borderColor: "#B9CEF8",
					hidden: true,
					fill: false
				}
			]
		};

		<?php
			$tooltip_date_options = ['timeZone' => $time_zone];
			$axis_date_options = ['timeZone' => $time_zone];
			$chart_time_unit = 'day';
			$axis_max_ticks = 10;
			switch ($chart_range) {
				case '1h':
				case '3h':
					$chart_time_unit = 'minute';
					$axis_max_ticks = $chart_range === '1h' ? 12 : 10;
					$tooltip_date_options['hour'] = '2-digit';
					$tooltip_date_options['minute'] = '2-digit';
					$tooltip_date_options['hour12'] = $settings->get('domain', 'time_format') != '24h';
					$tooltip_date_options['day'] = '2-digit';
					$tooltip_date_options['month'] = '2-digit';
					$axis_date_options['hour'] = '2-digit';
					$axis_date_options['minute'] = '2-digit';
					$axis_date_options['hour12'] = $settings->get('domain', 'time_format') != '24h';
					break;
				case '1y':
					$chart_time_unit = 'month';
					$axis_max_ticks = 12;
					$tooltip_date_options['month'] = '2-digit';
					$tooltip_date_options['year'] = 'numeric';
					$axis_date_options = $tooltip_date_options;
					break;
				case '7d':
					$axis_max_ticks = 7;
					$tooltip_date_options['day'] = '2-digit';
					$tooltip_date_options['month'] = '2-digit';
					$axis_date_options = $tooltip_date_options;
					break;
				case '30d':
					$tooltip_date_options['day'] = '2-digit';
					$tooltip_date_options['month'] = '2-digit';
					$tooltip_date_options['year'] = 'numeric';
					$axis_date_options['day'] = '2-digit';
					$axis_date_options['month'] = '2-digit';
					break;
				default:
					$chart_time_unit = 'hour';
					$axis_max_ticks = 12;
					$tooltip_date_options['hour'] = '2-digit';
					$tooltip_date_options['minute'] = '2-digit';
					$tooltip_date_options['hour12'] = $settings->get('domain', 'time_format') != '24h';
					$tooltip_date_options['day'] = '2-digit';
					$tooltip_date_options['month'] = '2-digit';
					$axis_date_options['hour'] = '2-digit';
					$axis_date_options['minute'] = '2-digit';
					$axis_date_options['hour12'] = $settings->get('domain', 'time_format') != '24h';
			}
		?>
		const cdr_tooltip_date_formatter = new Intl.DateTimeFormat(
			<?php echo json_encode($is_vietnamese ? 'vi-VN' : $language_code); ?>,
			<?php echo json_encode($tooltip_date_options); ?>
		);
		const cdr_axis_date_formatter = new Intl.DateTimeFormat(
			<?php echo json_encode($is_vietnamese ? 'vi-VN' : $language_code); ?>,
			<?php echo json_encode($axis_date_options); ?>
		);
		const cdr_axis_parts_formatter = new Intl.DateTimeFormat('vi-VN', {
			timeZone: <?php echo json_encode($time_zone); ?>,
			year: 'numeric',
			month: '2-digit',
			day: '2-digit',
			hour: '2-digit',
			minute: '2-digit',
			hourCycle: 'h23'
		});
		let cdr_chart_range = <?php echo json_encode($chart_range); ?>;
		const cdr_is_vietnamese = <?php echo $is_vietnamese ? 'true' : 'false'; ?>;
		const cdr_chart_locale = <?php echo json_encode($language_code); ?>;
		const cdr_chart_time_zone = <?php echo json_encode($time_zone); ?>;
		const cdr_dynamic_date_label = (date, tooltip = false) => {
			const options = {timeZone: cdr_chart_time_zone};
			if (cdr_chart_range === '1y') Object.assign(options, {month:'2-digit', year:'numeric'});
			else if (cdr_chart_range === '7d') Object.assign(options, {day:'2-digit', month:'2-digit'});
			else if (cdr_chart_range === '30d') Object.assign(options, {day:'2-digit', month:'2-digit'}, tooltip ? {year:'numeric'} : {});
			else Object.assign(options, {hour:'2-digit', minute:'2-digit', hour12:<?php echo $settings->get('domain', 'time_format') != '24h' ? 'true' : 'false'; ?>}, tooltip ? {day:'2-digit', month:'2-digit'} : {});
			return new Intl.DateTimeFormat(cdr_chart_locale, options).format(date);
		};
		const cdr_date_parts = (date) => Object.fromEntries(
			cdr_axis_parts_formatter.formatToParts(date)
				.filter((part) => part.type !== 'literal')
				.map((part) => [part.type, part.value])
		);
		const cdr_axis_label = (timestamp) => {
			const date = new Date(timestamp);
			if (cdr_is_vietnamese) {
				const parts = cdr_date_parts(date);
				if (cdr_chart_range === '1y') return `${parts.month}/${parts.year}`;
				if (cdr_chart_range === '7d' || cdr_chart_range === '30d') return `${parts.day}/${parts.month}`;
				return `${parts.hour}:${parts.minute}`;
			}
			return cdr_dynamic_date_label(date, false);
		};
		const cdr_tooltip_label = (timestamp) => {
			const date = new Date(timestamp);
			if (cdr_is_vietnamese) {
				const parts = cdr_date_parts(date);
				if (cdr_chart_range === '1y') return `${parts.month}/${parts.year}`;
				if (cdr_chart_range === '7d') return `${parts.day}/${parts.month}`;
				if (cdr_chart_range === '30d') return `${parts.day}/${parts.month}/${parts.year}`;
				return `${parts.hour}:${parts.minute} ${parts.day}/${parts.month}`;
			}
			return cdr_dynamic_date_label(date, true);
		};
		const cdr_number_formatter = new Intl.NumberFormat(
			<?php echo json_encode($is_vietnamese ? 'vi-VN' : $language_code); ?>,
			{ maximumFractionDigits: 2 }
		);
		const cdr_html_legend_plugin = {
			id: 'cdrHtmlLegend',
			afterUpdate: (chart) => {
				const legend = document.getElementById('cdr_stats_legend');
				legend.replaceChildren();
				chart.data.datasets.forEach((dataset, dataset_index) => {
					const visible = chart.isDatasetVisible(dataset_index);
					const item = document.createElement('button');
					item.type = 'button';
					item.style.cssText = 'display:inline-flex;align-items:center;gap:6px;padding:0;border:0;background:transparent;color:#444;cursor:pointer;font:inherit;line-height:14px;';
					item.onclick = () => {
						chart.setDatasetVisibility(dataset_index, !chart.isDatasetVisible(dataset_index));
						chart.update();
					};

					const swatch = document.createElement('span');
					swatch.style.cssText = `display:inline-flex;align-items:center;justify-content:center;flex:0 0 14px;width:14px;height:14px;background:${dataset.borderColor};`;
					if (visible) {
						swatch.innerHTML = '<svg width="13" height="13" viewBox="0 0 640 640" aria-hidden="true"><path fill="#1c1c1e" d="M530.8 134.1C545.1 144.5 548.3 164.5 537.9 178.8L281.9 530.8C276.4 538.4 267.9 543.1 258.5 543.9C249.1 544.7 240 541.2 233.4 534.6L105.4 406.6C92.9 394.1 92.9 373.8 105.4 361.3C117.9 348.8 138.2 348.8 150.7 361.3L252.2 462.8L486.2 141.1C496.6 126.8 516.6 123.6 530.9 134z"/></svg>';
					}

					const label = document.createElement('span');
					label.textContent = dataset.label;
					item.append(swatch, label);
					legend.append(item);
				});
			}
		};
		Chart.Tooltip.positioners.cdrNearestBottomCorner = function(elements, event_position) {
			const points = elements
				.map((item) => item.element)
				.filter((point) => Number.isFinite(point?.x) && Number.isFinite(point?.y));
			if (!points.length) return false;
			const nearest_point = points.reduce((nearest, point) => {
				const distance = Math.hypot(point.x - event_position.x, point.y - event_position.y);
				return distance < nearest.distance ? {point, distance} : nearest;
			}, {point: points[0], distance: Number.POSITIVE_INFINITY}).point;
			const tooltip_width = this.width || this._size?.width || 220;
			const reaches_right_edge = nearest_point.x + tooltip_width > this.chart.width;
			return {
				x: nearest_point.x,
				y: nearest_point.y,
				xAlign: reaches_right_edge ? 'right' : 'left',
				yAlign: 'bottom'
			};
		};
		const cdr_tooltip_shadow_plugin = {
			id: 'cdrTooltipShadow',
			beforeTooltipDraw: (chart, args) => {
				const tooltip = args.tooltip;
				if (!tooltip || tooltip.opacity <= 0) return;
				const context = chart.ctx;
				context.save();
				context.shadowColor = 'rgba(0, 0, 0, 0.08)';
				context.shadowBlur = 12;
				context.shadowOffsetX = 0;
				context.shadowOffsetY = 4;
				context.fillStyle = 'rgba(252, 252, 253, 0.92)';
				context.fillRect(tooltip.x, tooltip.y, tooltip.width, tooltip.height);
				context.restore();
			}
		};

		const cdr_stats_config = {
			type: 'line',
			data: cdr_stats_data,
			plugins: [cdr_html_legend_plugin, cdr_tooltip_shadow_plugin],
			options: {
				responsive: true,
				maintainAspectRatio: false,
				interaction: {
					mode: 'index',
					axis: 'x',
					intersect: false
				},
				plugins: {
					legend: {
						display: false
					},
					tooltip: {
						mode: 'index',
						intersect: false,
						position: 'cdrNearestBottomCorner',
						caretSize: 0,
						caretPadding: 0,
						cornerRadius: 0,
						backgroundColor: 'rgba(252, 252, 253, 0.92)',
						titleColor: '#1c1c1e',
						bodyColor: '#1c1c1e',
						footerColor: '#1c1c1e',
						usePointStyle: true,
						boxWidth: 12,
						boxHeight: 12,
						callbacks: {
							title: (items) => {
								if (!items.length) return '';
								return cdr_tooltip_label(items[0].parsed.x);
							},
							labelColor: (context) => ({
								backgroundColor: context.dataset.backgroundColor,
								borderColor: context.dataset.backgroundColor,
								borderWidth: 0
							}),
							labelPointStyle: () => ({pointStyle: 'rect', rotation: 0}),
							label: (context) => {
								const suffix = context.dataset.unit ?? '';
								return `${context.dataset.label}: ${cdr_number_formatter.format(context.parsed.y)}${suffix}`;
							}
						}
					}
				},
					scales: {
						x: {
							type: "time",
							bounds: "data",
							offset: false,
							time: {
							unit: <?php echo json_encode($chart_time_unit); ?>,
								displayFormats: {
								minute: 'HH:mm',
								hour: '<?php echo $chart_time_format; ?>',
								day: 'dd MMM',
								month: 'MMM yyyy',
							}
						},
						ticks: {
							source: "data",
							autoSkip: true,
							maxTicksLimit: <?php echo (int) $axis_max_ticks; ?>,
							maxRotation: 0,
							callback: (value, index, ticks) => cdr_axis_label(ticks[index].value)
						}
					},
					y: {
						min: 0,
						ticks: {
							callback: (value) => cdr_number_formatter.format(value)
						}
					},
					yAsr: {
						type: 'linear',
						display: false,
						position: 'right',
						min: 0,
						max: 100,
						grid: {
							drawOnChartArea: false
						},
						ticks: {
							stepSize: 25,
							callback: (value) => `${cdr_number_formatter.format(value)}%`
						}
					}
				},
				elements: {
					line: {
						tension: 0.3
					}
				}
			}
		};

		const cdr_stats_chart = new Chart(ctx, cdr_stats_config);
		const cdr_statistics_table_body = () => document.getElementById('cdr_statistics_table_body');
		const cdr_append_cell = (row, value, class_name = '') => {
			const cell = document.createElement('td');
			cell.textContent = value;
			if (class_name) cell.className = class_name;
			row.append(cell);
			return cell;
		};
		const cdr_table_time = (item) => {
			const start = new Date(Number(item.start_epoch) * 1000);
			const end = new Date(Number(item.end_epoch) * 1000);
			const parts = cdr_date_parts(start);
			if (cdr_chart_range === '1y') return `${parts.month}/${parts.year}`;
			if (cdr_chart_range === '30d') return `${parts.day}/${parts.month}`;
			if (cdr_chart_range === '7d') {
				const weekday_key = new Intl.DateTimeFormat('en-US', {timeZone:cdr_chart_time_zone,weekday:'short'}).format(start);
				const weekday = cdr_is_vietnamese
					? ({Mon:'T2', Tue:'T3', Wed:'T4', Thu:'T5', Fri:'T6', Sat:'T7', Sun:'CN'}[weekday_key] ?? weekday_key)
					: weekday_key;
				return `${weekday}, ${parts.day}/${parts.month}`;
			}
			const end_parts = cdr_date_parts(end);
			return `${parts.hour}:${parts.minute} - ${end_parts.hour}:${end_parts.minute} ${parts.day}/${parts.month}`;
		};
		const cdr_render_statistics_table = (stats) => {
			const table_body = cdr_statistics_table_body();
			if (!table_body) return;
			table_body.replaceChildren();
			stats.forEach((item) => {
				const row = document.createElement('tr');
				row.className = 'list-row';
				cdr_append_cell(row, cdr_table_time(item), 'no-wrap');
				cdr_append_cell(row, cdr_number_formatter.format(Number(item.volume) || 0));
				cdr_append_cell(row, cdr_number_formatter.format(Math.round(Number(item.minutes) || 0)));
				const missed_cell = cdr_append_cell(row, '', 'center');
				const missed_link = document.createElement('a');
				missed_link.href = `xml_cdr.php?call_result=missed&direction=${encodeURIComponent(<?php echo json_encode($direction); ?>)}&start_epoch=${encodeURIComponent(item.start_epoch ?? '')}&stop_epoch=${encodeURIComponent(item.end_epoch ?? '')}`;
				missed_link.textContent = cdr_number_formatter.format(Number(item.missed) || 0);
				missed_cell.append(missed_link);
				cdr_append_cell(row, cdr_number_formatter.format(Number(item.aloc) || 0));
				cdr_append_cell(row, `${cdr_number_formatter.format(Number(item.asr) || 0)}%`);
				table_body.append(row);
			});
		};
		const cdr_range_chart_options = (range) => {
			if (range === '1h') return {unit:'minute', maxTicks:12};
			if (range === '3h') return {unit:'minute', maxTicks:10};
			if (range === 'today' || range === 'yesterday') return {unit:'hour', maxTicks:12};
			if (range === '7d') return {unit:'day', maxTicks:7};
			if (range === '30d') return {unit:'day', maxTicks:10};
			return {unit:'month', maxTicks:12};
		};
		document.querySelectorAll('[data-cdr-chart-range]').forEach((button) => button.addEventListener('click', async () => {
			const buttons = document.querySelectorAll('[data-cdr-chart-range]');
			const table_body = cdr_statistics_table_body();
			const analytics_roots = document.querySelectorAll('[id^="cdr_statistics_analytics_"]');
			buttons.forEach((item) => item.disabled = true);
			ctx.canvas.style.opacity = '0.55';
			if (table_body) table_body.style.opacity = '0.55';
			analytics_roots.forEach((item) => item.style.opacity = '0.55');
			try {
				const query = new URLSearchParams(window.location.search);
				query.set('chart_range', button.dataset.cdrChartRange);
				query.set('data_source', <?php echo json_encode($data_source); ?>);
				const analytics_query = new URLSearchParams({range:button.dataset.cdrChartRange, data_source:<?php echo json_encode($data_source); ?>});
				const [response, analytics_response] = await Promise.all([
					fetch('/app/xml_cdr/resources/ajax/cdr_statistics.php?' + query.toString(), {credentials:'same-origin',cache:'no-store'}),
					fetch('/app/xml_cdr/resources/ajax/cdr_analytics.php?' + analytics_query.toString(), {credentials:'same-origin',cache:'no-store'})
				]);
				if (!response.ok || !analytics_response.ok) throw new Error('statistics_request_failed');
				const [data, analytics_data] = await Promise.all([response.json(), analytics_response.json()]);
				cdr_chart_range = data.chart_range;
				const graph = data.graph;
				cdr_stats_chart.data.datasets[0].data = graph.volume ?? [];
				cdr_stats_chart.data.datasets[1].data = graph.minutes ?? [];
				cdr_stats_chart.data.datasets[2].data = graph.missed ?? [];
				cdr_stats_chart.data.datasets[3].data = graph.aloc ?? [];
				cdr_stats_chart.data.datasets[4].data = graph.asr ?? [];
				const range_options = cdr_range_chart_options(cdr_chart_range);
				cdr_stats_chart.options.scales.x.time.unit = range_options.unit;
				cdr_stats_chart.options.scales.x.ticks.maxTicksLimit = range_options.maxTicks;
				cdr_stats_chart.update();
				cdr_render_statistics_table(data.stats ?? []);
				(window.cdrAnalyticsUpdaters ?? []).forEach((update) => update(analytics_data));
				buttons.forEach((item) => {
					item.style.cssText = '';
					const icon = item.querySelector('.fa-solid');
					icon.className = 'fa-solid fa-chart-line fa-fw';
				});
				button.style.cssText = 'color:#ffffff;background:#48484a;background-image:unset;';
				button.querySelector('.fa-solid').className = 'fa-solid fa-check-circle fa-fw';
				const page_url = new URL(window.location.href);
				page_url.searchParams.set('chart_range', cdr_chart_range);
				history.replaceState({}, '', page_url);
			}
			catch (error) {
				console.error('Unable to update CDR statistics', error);
			}
			finally {
				buttons.forEach((item) => item.disabled = false);
				ctx.canvas.style.opacity = '1';
				if (table_body) table_body.style.opacity = '1';
				analytics_roots.forEach((item) => item.style.opacity = '1');
			}
		}));
	</script>

	<?php
	echo "</div>\n";
	echo "</div>\n";

//show the results
	echo "<div class='card'>\n";
	echo "<table class='list'>\n";
	echo "<thead>\n";
	echo "<tr class='list-header'>\n";
	echo "	<th class='no-wrap'>".$text['label-time']."</th>\n";
	echo "	<th title='".$text['description-volume']."'>".escape($chart_labels['volume'])."</th>\n";
	echo "	<th>".escape($chart_labels['minutes'])."</th>\n";
	echo "	<th class='center'>".escape($chart_labels['missed'])."</th>\n";
	echo "	<th title='".$text['description-aloc']."'>".escape($chart_labels['aloc'])."</th>\n";
	echo "	<th title='".$text['description-asr']."'>".escape($chart_labels['asr'])."</th>\n";
	echo "</tr>\n";
	echo "</thead>\n";
	echo "<tbody id='cdr_statistics_table_body'>\n";

	foreach ($stats as $row) {
		$display_date = $row['date'];
		$display_time = $row['time'];
		if (!empty($row['start_epoch']) && !empty($row['end_epoch'])) {
			$start_date_time = (new DateTimeImmutable('@'.(int) $row['start_epoch']))->setTimezone(new DateTimeZone($time_zone));
			$end_date_time = (new DateTimeImmutable('@'.(int) $row['end_epoch']))->setTimezone(new DateTimeZone($time_zone));
			switch ($chart_range) {
				case '1y':
					$display_date = $start_date_time->format('m/Y');
					$display_time = '';
					break;
				case '7d':
					$weekdays = $is_vietnamese
						? [1 => 'T2', 2 => 'T3', 3 => 'T4', 4 => 'T5', 5 => 'T6', 6 => 'T7', 7 => 'CN']
						: [1 => 'Mon', 2 => 'Tue', 3 => 'Wed', 4 => 'Thu', 5 => 'Fri', 6 => 'Sat', 7 => 'Sun'];
					$display_date = $weekdays[(int) $start_date_time->format('N')].', '.$start_date_time->format('d/m');
					$display_time = '';
					break;
				case '30d':
					$display_date = $start_date_time->format('d/m');
					$display_time = '';
					break;
				default:
					$display_date = $start_date_time->format('H:i').' - '.$end_date_time->format('H:i');
					$display_time = $start_date_time->format('d/m');
			}
		}
		$combined_time = trim($display_date.(!empty($display_time) ? ' '.$display_time : ''));
		echo "<tr class='list-row'>\n";
		echo "	<td class='no-wrap'>".escape($combined_time)."&nbsp;</td>\n";
		echo "	<td>".escape($format_stat_number($row['volume'], 0))."&nbsp;</td>\n";
		echo "	<td>".escape($format_stat_number($row['minutes'] ?? 0, 0))."&nbsp;</td>\n";
		echo "	<td class='center'><a href=\"xml_cdr.php?call_result=missed&direction=".$direction."&start_epoch=".escape($row['start_epoch'] ?? '')."&stop_epoch=".escape($row['stop_epoch'] ?? '')."\">".escape($format_stat_number($row['missed'] ?? 0, 0))."</a>&nbsp;</td>\n";
		echo "	<td>".escape($format_stat_number($row['aloc'] ?? 0))."&nbsp;</td>\n";
		echo "	<td>".escape($format_stat_number($row['asr'] ?? 0))."%&nbsp;</td>\n";
		echo "</tr >\n";
	}
	echo "</tbody>\n";
	echo "</table>\n";
	echo "</div>\n";

//show the Top 10 tables in their existing card below the statistics table
	$analytics_id = 'cdr_statistics_analytics_top';
	$analytics_compact = false;
	$analytics_show_summary = false;
	$analytics_show_top = true;
	echo "<div class='card'>\n";
	require __DIR__.'/resources/views/cdr_analytics.php';
	echo "</div>\n";
	echo "<br><br>";

//include the footer
	require_once "resources/footer.php";

?>

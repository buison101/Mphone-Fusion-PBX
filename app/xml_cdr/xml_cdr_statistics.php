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

//add multi-lingual support
	$language = new text;
	$text = $language->get();
	$language_code = strtolower($settings->get('domain', 'language', 'en-us'));
	$is_vietnamese = $language_code === 'vi' || str_starts_with($language_code, 'vi-');
	if ($chart_range === '24h') {
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
		echo button::create(['type'=>'button','label'=>'Test','icon'=>($data_source === 'test' ? 'check-circle' : 'flask'),'link'=>'xml_cdr_statistics.php?data_source=test&chart_range='.urlencode($chart_range)]);
		echo "		</span>\n";
	}
	echo "		<span style='display: inline-flex; align-items: center; gap: 6px; margin-right: 12px;'>\n";
	echo "			<span>".escape($text['label-chart_range'] ?? ($is_vietnamese ? 'Khoảng biểu đồ' : 'Chart range')).":</span>\n";
	$range_options = $is_vietnamese
		? ['24h' => '24 giờ', '7d' => '7 ngày', '30d' => '30 ngày', '1y' => '1 năm']
		: ['24h' => '24 hours', '7d' => '7 days', '30d' => '30 days', '1y' => '1 year'];
	foreach ($range_options as $range_value => $range_label) {
		$range_query = ($data_source === 'test' ? 'data_source=test&' : '').'chart_range='.$range_value;
		echo button::create(['type'=>'button','label'=>$range_label,'icon'=>($chart_range === $range_value ? 'check-circle' : 'chart-line'),'link'=>'xml_cdr_statistics.php?'.$range_query]);
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

	echo "<div class='card'>\n";
	?>
	<script src='/resources/chartjs/chart.min.js'></script>
	<script src='/resources/chartjs/chartjs-adapter-date-fns.bundle.min.js'></script>

	<div align='center' style="justify-content: center; margin-bottom: 25px;">
		<div style="max-width: 100%; width: 800px; height: 280px;">
			<canvas id="cdr_stats_chart" style="width: 100%; height: 100%;"></canvas>
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
					label: <?php echo json_encode($chart_labels['asr']); ?>,
					unit: '%',
					data: <?php echo json_encode($graph['asr']); ?>,
					backgroundColor: "#F59E0B",
					borderColor: "#F59E0B",
					fill: false
				},
				{
					label: <?php echo json_encode($chart_labels['aloc']); ?>,
					data: <?php echo json_encode($graph['aloc']); ?>,
					backgroundColor: "#B9CEF8",
					borderColor: "#B9CEF8",
					fill: false
				}
			]
		};

		<?php
			$tooltip_date_options = ['timeZone' => $time_zone];
			switch ($chart_range) {
				case '1y':
					$tooltip_date_options['month'] = '2-digit';
					$tooltip_date_options['year'] = 'numeric';
					break;
				case '7d':
					$tooltip_date_options['day'] = '2-digit';
					$tooltip_date_options['month'] = '2-digit';
					break;
				case '30d':
					$tooltip_date_options['day'] = '2-digit';
					$tooltip_date_options['month'] = '2-digit';
					$tooltip_date_options['year'] = 'numeric';
					break;
				default:
					$tooltip_date_options['hour'] = '2-digit';
					$tooltip_date_options['minute'] = '2-digit';
					$tooltip_date_options['hour12'] = $settings->get('domain', 'time_format') != '24h';
					$tooltip_date_options['day'] = '2-digit';
					$tooltip_date_options['month'] = '2-digit';
			}
		?>
		const cdr_tooltip_date_formatter = new Intl.DateTimeFormat(
			<?php echo json_encode($is_vietnamese ? 'vi-VN' : $language_code); ?>,
			<?php echo json_encode($tooltip_date_options); ?>
		);
		const cdr_number_formatter = new Intl.NumberFormat(
			<?php echo json_encode($is_vietnamese ? 'vi-VN' : $language_code); ?>,
			{ maximumFractionDigits: 2 }
		);

		const cdr_stats_config = {
			type: 'line',
			data: cdr_stats_data,
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
						display: true,
						labels: {
							usePointStyle: true,
							pointStyle: 'rect',
							color: '#444',
							boxWidth: 15
						}
					},
					tooltip: {
						mode: 'index',
						intersect: false,
						callbacks: {
							title: (items) => {
								if (!items.length) return '';
								return cdr_tooltip_date_formatter.format(new Date(items[0].parsed.x));
							},
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
						time: {
							displayFormats: {
								hour: '<?php echo $chart_time_format; ?>',
								day: 'dd MMM',
								month: 'MMM yyyy',
							}
						},
					},
					y: {
						min: 0,
						ticks: {
							callback: (value) => cdr_number_formatter.format(value)
						}
					}
				},
				elements: {
					line: {
						tension: 0.3
					}
				}
			},
			scales: {
				<?php
				if ($hours <= 48) {
					echo "xAxes: {type: \"time\",timeFormat: \"%d:%H\",minTickSize: [1, \"hour\"]}";
				}
				else if ($hours > 48 && $hours < 168) {
					echo "xAxes: {type: \"time\",timeFormat: \"%m:%d\",minTickSize: [1, \"day\"]}";
				}
				else {
					echo "xAxes: {type: \"time\",timeFormat: \"%m:%d\",minTickSize: [1, \"month\"]}";
				}
				?>,
				yAxes: [{
					ticks: {
						beginAtZero: true
					}
				}]
			}
		};

		const cdr_stats_chart = new Chart(ctx, cdr_stats_config);
	</script>

	<?php
	echo "</div>\n";

//show the results
	echo "<div class='card'>\n";
	echo "<table class='list'>\n";
	echo "<tr class='list-header'>\n";
	echo "	<th class='no-wrap'>".$text['label-time']."</th>\n";
	echo "	<th title='".$text['description-volume']."'>".escape($chart_labels['volume'])."</th>\n";
	echo "	<th>".escape($chart_labels['minutes'])."</th>\n";
	echo "	<th class='center'>".escape($chart_labels['missed'])."</th>\n";
	echo "	<th title='".$text['description-asr']."'>".escape($chart_labels['asr'])."</th>\n";
	echo "	<th title='".$text['description-aloc']."'>".escape($chart_labels['aloc'])."</th>\n";
	echo "</tr>\n";

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
		echo "	<td>".escape($format_stat_number($row['asr'] ?? 0))."%&nbsp;</td>\n";
		echo "	<td>".escape($format_stat_number($row['aloc'] ?? 0))."&nbsp;</td>\n";
		echo "</tr >\n";
	}
	echo "</table>\n";
	echo "</div>\n";
	echo "<br><br>";

//include the footer
	require_once "resources/footer.php";

?>

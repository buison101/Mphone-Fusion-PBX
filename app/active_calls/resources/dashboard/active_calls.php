<?php
/*
 * The MIT License
 *
 * Copyright 2025 Tim Fry <tim@fusionpbx.com>.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

//set project root
$project_root = dirname(__DIR__, 4);

//includes files
require_once "$project_root/resources/require.php";

//check permisions
require_once "$project_root/resources/check_auth.php";
if (!permission_exists('call_active_view')) {
	return;
}

//set the row style
$c = 0;
$row_style["0"] = "row_style0";
$row_style["1"] = "row_style1";

//set the dashboard icon to a solid color phone
$widget_icon = 'fa-solid fa-phone';

//convert to a key
$widget_key = str_replace(' ', '_', strtolower($widget_name));

//add multi-lingual support
$text = (new text)->get($settings->get('domain', 'language', 'en-us'), 'app/active_calls');
$active_calls_language = strtolower($settings->get('domain', 'language', 'en-us'));
$active_calls_vi = $active_calls_language === 'vi' || str_starts_with($active_calls_language, 'vi-');
$active_calls_range_labels = $active_calls_vi
	? ['1m' => '1 phút', '15m' => '15 phút', '1h' => '1 giờ']
	: ['1m' => '1 minute', '15m' => '15 minutes', '1h' => '1 hour'];

//get the dashboard label
$widget_label = $text['label-'.$widget_key] ?? $widget_name;

//show the widget
echo "<div class='hud_box'>\n";

//create a token
$token = (new token())->create($_SERVER['PHP_SELF']);
echo "  <input id='current_context' type='hidden' name='current_context' value='" . $_SESSION['domain_name'] . "'>\n";
echo "	<input id='token' type='hidden' name='" . $token['name'] . "' value='" . $token['hash'] . "'>\n";

//subscribe to service
subscriber::save_token($token, ['active.calls']);

//define row styles
$c = 0;
$row_style["0"] = "row_style0";
$row_style["1"] = "row_style1";

//icon and count
echo "<div class='hud_content' ".($widget_details_state == "disabled" ?: "onclick=\"$('#hud_active_calls_details').slideToggle('fast');\"").">\n";
	echo "<span class='hud_title'><a onclick=\"document.location.href='".PROJECT_PATH."/app/active_calls/active_calls.php'\">".escape($widget_label)."</a></span>\n";
	if ($widget_chart_type == 'line') {
		echo "<div class='hud_chart' style='width:90%;height:80%;display:flex;flex-direction:column;'>\n";
			echo "<div id='active_calls_chart_ranges' style='display:flex;justify-content:center;gap:4px;margin-bottom:4px;'>\n";
			foreach ($active_calls_range_labels as $range_value => $range_label) {
				echo "<button type='button' class='btn btn-default' data-active-calls-range='".escape($range_value)."' onclick='event.stopPropagation();' style='padding:2px 7px;font-size:11px;line-height:16px;'>".escape($range_label)."</button>\n";
			}
			echo "</div>\n";
			echo "<div style='position:relative;flex:1;min-height:0;'><canvas id='active_calls_chart'></canvas></div>\n";
			echo "<input type=hidden id='calls_active_count' name='calls_active_count' value='0'>\n";
		echo "</div>\n";
	}
	if ($widget_chart_type == 'icon') {
		echo "<div style='position: relative; display: inline-block;'>\n";
			echo "<span class='hud_stat'><i class=\"fas " . $widget_icon . " \"></i></span>\n";
			echo "<span id='calls_active_count' name='calls_active_count' style=\"background-color: " . (!empty($widget_number_background_color) ? $widget_number_background_color : '#34c759') . "; color: " . (!empty($widget_number_text_color) ? $widget_number_text_color : '#ffffff') . "; font-size: 10px; text-align: center; position: absolute; top: 28px; left: 24px; padding: 2px 7px 1px 7px; border-radius: 10px; white-space: nowrap;\">0</span>\n";
		echo "</div>\n";
	}
echo "</div>\n";

//active call details
echo "<div class='hud_details hud_box' id='hud_active_calls_details'>\n";
if ($widget_details_state != 'disabled') {
	echo "<table id='active_calls' name='active_calls' class='tr_hover' width='100%' cellpadding='0' cellspacing='0' border='0'>\n";
		echo "<thead id='head_active_calls' name='head_active_calls'>\n";
			echo "<tr>\n";
				echo "<th class='hud_heading' width='25%'>".$text['label-cid-number']."</th>\n";
				echo "<th class='hud_heading' width='25%'>".$text['label-destination']."</th>\n";
				echo "<th class='hud_heading' width='25%'>".$text['label-status']."</th>\n";
				echo "<th class='hud_heading' width='25%'>".$text['label-duration']."</th>\n";
			echo "</tr>\n";
		echo "</thead>\n";
		echo "<tbody id='active_calls_body' name='active_calls_body'>\n";
		echo "</tbody>\n";
	echo "</table>\n";
}
echo "</div>\n";

//include arrows when not changed
$version = md5(file_get_contents($project_root . '/app/active_calls/resources/javascript/arrows.js'));
echo "<script src='/app/active_calls/resources/javascript/arrows.js?v=$version'></script>\n";

?>
<script>
	const timers = [];
	const callsMap = new Map();

	var showAll = false;
	const websockets_domain_name = '<?= $_SESSION['domain_name'] ?>';
    const active_calls_widget_chart_type = '<?= $widget_chart_type ?>';

	// push PHP values into JS
	const authToken = {
		name: "<?= $token['name'] ?>",
		hash: "<?= $token['hash'] ?>"
	};
	if (active_calls_widget_chart_type === 'line') {
		const active_calls_ranges = {
			'1m': {duration:60000, sample:1000, maxTicks:4, seconds:true},
			'15m': {duration:900000, sample:5000, maxTicks:4, seconds:false},
			'1h': {duration:3600000, sample:10000, maxTicks:5, seconds:false}
		};
		const active_calls_range_storage_key = 'fusionpbx.active_calls.chart_range';
		const active_calls_render_delay = 2000;
		let active_calls_range = localStorage.getItem(active_calls_range_storage_key) || '15m';
		if (!active_calls_ranges[active_calls_range]) active_calls_range = '15m';
		const active_calls_history = [];
		const active_calls_time_formatter = (include_seconds) => new Intl.DateTimeFormat(
			<?=json_encode($active_calls_vi ? 'vi-VN' : $active_calls_language)?>,
			{hour:'2-digit', minute:'2-digit', ...(include_seconds ? {second:'2-digit'} : {}), hourCycle:'h23'}
		);
		const active_calls_visible_history = () => {
			const range = active_calls_ranges[active_calls_range];
			const cutoff = Date.now() - range.duration - active_calls_render_delay;
			const buckets = new Map();
			let boundary_value = null;
			active_calls_history.forEach((point) => {
				if (point.x < cutoff) boundary_value = point.y;
				else buckets.set(Math.floor(point.x / range.sample) * range.sample, point);
			});
			const points = Array.from(buckets.values());
			if (boundary_value === null && points.length) boundary_value = points[0].y;
			if (boundary_value !== null) points.unshift({x:cutoff, y:boundary_value});
			return points;
		};
		const active_calls_count = document.getElementById('active_calls_chart').getContext('2d');
        window.active_calls_chart = new Chart(active_calls_count, {
            type: 'line',
            data: {
                datasets: [
                    {
                        label: 'Active Calls',
                        borderColor: '#007aff',
                        backgroundColor: 'rgba(0,122,255,0.12)',
                        fill: true,
						tension: 0,
						stepped: true,
                        pointRadius: 0,
                        pointHoverRadius: 6,
                        pointHitRadius: 10,
                        spanGaps: true,
                        data: []
                    }
                ]
            },
            options: {
                // streaming usually looks best with animation off; tweak if you like a tiny slide
                animation: false,
                //parsing: {xAxisKey: 'x', yAxisKey: 'y'},
                maintainAspectRatio: false,
                scales: {
					x: {
						type: 'realtime',
						realtime: {
							duration: active_calls_ranges[active_calls_range].duration,
							refresh: 1000,
							delay: active_calls_render_delay,
							onRefresh: (chart) => {
								const now = Date.now();
								active_calls_history.push({x:now, y:get_count()});
								while (active_calls_history.length && active_calls_history[0].x < now - 3600000) active_calls_history.shift();
								chart.data.datasets[0].data = active_calls_visible_history();
							}
						},
						grid: {drawOnChartArea: false, color: '#d1d1d6'},
						ticks: {
							display: true,
							color: '#8e8e93',
							maxRotation: 0,
							maxTicksLimit: active_calls_ranges[active_calls_range].maxTicks,
							callback: (value) => active_calls_time_formatter(active_calls_ranges[active_calls_range].seconds).format(new Date(value))
						},
                    },
                    y: {
                        beginAtZero: true,
                        grace: '10%',
						ticks: {
							color: '#48484a',
							precision: 0,  //whole numbers only
                            callback: (v) => Number.isInteger(v) ? v : v.toFixed(0)
                        },
                        grid: {color: '#d1d1d6'},
                        suggestedMax: 4  //becomes 5 because chart adds the 0 line as a y-axis value
                    }
                },
                plugins: {
                    legend: {display: false},
                    tooltip: {
                        enabled: false
                    }
                }
            }
		});
		const set_active_calls_range = (range_key) => {
			if (!active_calls_ranges[range_key]) return;
			active_calls_range = range_key;
			localStorage.setItem(active_calls_range_storage_key, range_key);
			const range = active_calls_ranges[range_key];
			window.active_calls_chart.options.scales.x.realtime.duration = range.duration;
			window.active_calls_chart.options.scales.x.ticks.maxTicksLimit = range.maxTicks;
			window.active_calls_chart.data.datasets[0].data = active_calls_visible_history();
			document.querySelectorAll('[data-active-calls-range]').forEach((button) => {
				button.style.cssText = 'padding:2px 7px;font-size:11px;line-height:16px;';
				if (button.dataset.activeCallsRange === range_key) {
					button.style.cssText += 'color:#ffffff;background:#48484a;background-image:unset;';
				}
			});
			window.active_calls_chart.update('none');
		};
		document.querySelectorAll('[data-active-calls-range]').forEach((button) => button.addEventListener('click', () => set_active_calls_range(button.dataset.activeCallsRange)));
		set_active_calls_range(active_calls_range);

		// Create custom tooltip element
        const tooltipEl = document.createElement('div');
        tooltipEl.id = 'chartjs-tooltip';
        tooltipEl.style.cssText = 'position: absolute; background: rgba(0, 0, 0, 0.8); color: white; padding: 6px 10px; border-radius: 4px; font-size: 12px; pointer-events: none; opacity: 0; transition: opacity 0.2s; z-index: 1000;';
        document.body.appendChild(tooltipEl);

        // Manual hover detection on canvas
        const canvas = document.getElementById('active_calls_chart');
        canvas.addEventListener('mousemove', function(e) {
            const rect = canvas.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;

            // Get the chart's scale information
            const chart = window.active_calls_chart;
            const xScale = chart.scales.x;
            const yScale = chart.scales.y;

            // Find closest data point
            let closestPoint = null;
            let minDistance = Infinity;
            const threshold = 15; // pixels

            chart.data.datasets[0].data.forEach((point, index) => {
                if (point && typeof point.x !== 'undefined' && typeof point.y !== 'undefined') {
                    const pixelX = xScale.getPixelForValue(point.x);
                    const pixelY = yScale.getPixelForValue(point.y);
                    const distance = Math.sqrt(Math.pow(x - pixelX, 2) + Math.pow(y - pixelY, 2));

                    if (distance < minDistance && distance < threshold) {
                        minDistance = distance;
                        closestPoint = point;
                    }
                }
            });

            if (closestPoint && Number.isFinite(closestPoint.y)) {
                tooltipEl.textContent = `Active Calls: ${closestPoint.y}`;
                tooltipEl.style.opacity = '1';
                tooltipEl.style.left = (e.pageX + 10) + 'px';
                tooltipEl.style.top = (e.pageY - 30) + 'px';
            } else {
                tooltipEl.style.opacity = '0';
            }
        });

        canvas.addEventListener('mouseleave', function() {
            tooltipEl.style.opacity = '0';
        });
    }
<?php
$user['extensions'] = [];
// translate the current users assigned extensions
if (!empty($_SESSION['user']['extension'])) {
	echo "const extension = {\n";
	foreach ($_SESSION['user']['extension'] as $user) {
		echo "		extension_uuid: '" . $user['extension_uuid'] . "',\n";
		echo "		extension: '" . $user['user'] . "',\n";
		if (!empty($user['number_alias'])) {
			$user_contact = $user['number_alias'];
		}
		else {
			$user_contact = $user['user'];
		}
		echo "		extension_destination: '$user_contact',\n";
		$user['extensions'][$user['extension_uuid']] = $user_contact;
	}
	echo "	last_entry_so_no_comma: '-100'";
	echo "	};\n";
}
?>

	const colors = {
		RINGING: 'blue',
		CONNECTED: '<?php echo $settings->get('theme', 'heading_count_background_color', '#34c759'); ?>',
		HANGUP: 'red',
		INACTIVE: 'black'
	}

	// pre-cache arrows
	const arrows = {
		inbound: {
			red: create_arrow('inbound', colors.HANGUP),
			green: create_arrow('inbound', colors.CONNECTED),
			blue: create_arrow('inbound', colors.RINGING),
			black: create_arrow('inbound', colors.INACTIVE)
		},
		outbound: {
			red: create_arrow('outbound', colors.HANGUP),
			green: create_arrow('outbound', colors.CONNECTED),
			blue: create_arrow('outbound', colors.RINGING),
			black: create_arrow('outbound', colors.INACTIVE)
		},
		local: {
			red: create_arrow('local', colors.HANGUP),
			green: create_arrow('local', colors.CONNECTED),
			blue: create_arrow('local', colors.RINGING),
			black: create_arrow('local', colors.INACTIVE)
		},
		voicemail: {
			red: create_arrow('voicemail', colors.HANGUP),
			green: create_arrow('voicemail', colors.CONNECTED),
			blue: create_arrow('voicemail', colors.RINGING),
			black: create_arrow('voicemail', colors.INACTIVE)
		},
		missed: {
			red: create_arrow('missed', colors.HANGUP),
			green: create_arrow('missed', colors.CONNECTED),
			blue: create_arrow('missed', colors.RINGING),
			black: create_arrow('missed', colors.INACTIVE)
		}
	}

	let active_calls_widget_client = null;
	let reconnectAttempts = 0;

	function connect_active_calls_widget() {
		const maxReconnectDelay = 30000; // 30 seconds
		const baseReconnectDelay = 1000; // 1 second

		active_calls_widget_client = new ws_client(`wss://${window.location.hostname}/websockets/`, authToken);

		if (!active_calls_widget_client) {
			console.error('Unable to connect to web socket server');
		}

		// CONNECTED
		active_calls_widget_client.ws.addEventListener("open", async () => {
			try {
				console.log('Connected');
				reconnectAttempts = 0;

				//set the status as inactive while waiting
				const status = document.getElementById('calls_active_count');
				status.style.backgroundColor = colors.INACTIVE;
			} catch (err) {
				console.error("WS setup failed: ", err);
				return;
			}
		});

		// Handle incoming messages for authentication
		active_calls_widget_client.ws.addEventListener("message", async (event) => {
			try {
				const message = JSON.parse(event.data);
				// Check for authentication request from server
				if (message.status_code === 407 && message.service_name === 'authentication') {
					console.log('Authentication required - sending credentials');
					await active_calls_widget_client.request('authentication');
					console.log('Authentication sent');

					//bind active call event to function
					active_calls_widget_client.onEvent("CHANNEL_CALLSTATE", channel_callstate_event);
					console.log('Sent request for calls in progress');

					//get the in progress calls
					active_calls_widget_client.request('active.calls', 'in.progress');

					//display green circle for connected
					const status = document.getElementById('calls_active_count');
					status.style.backgroundColor = colors.CONNECTED;
				}
			} catch (err) {
				// Let the ws_client handle other messages
			}
		});

		// DISCONNECTED
		active_calls_widget_client.ws.addEventListener("close", async () => {
			const status = document.getElementById('calls_active_count');
			status.style.background = '#ff3b30';
			console.warn("Websocket Disconnected");
		});

	}

	/////////////////////
	// Event Functions //
	/////////////////////

	// Ringing, Answer, Hangup
	function channel_callstate_event(call) {
		if (call === null || typeof call !== 'object') {
			return;
		}

		const state = normalize_answer_state(call);
		call.answer_state = state;
		//update color
		const uuid = call.unique_id;
		//console.log(call.event_name, call.unique_id, state, call);
		let row = document.getElementById(uuid) || null;
		//create a row for the call
		if (row === null) {
			new_call(call);
		}
		const other_leg_rdnis = call.other_leg_rdnis ?? '';
		const other_leg_unique_id = call.other_leg_unique_id ?? '';
		switch (state) {
			case 'ringing':
				//update the data
				update_call(call);
				replace_arrow_color(uuid, colors.RINGING);
				//enforce a local arrow for eavesdrop
				if (call.caller_caller_id_name === '<?= $text['label-eavesdrop'] ?>') {
					replace_arrow_icon(uuid, 'local');
					row.dataset.forced_direction = 'local';
				}
				//calls with an rdnis means that it came from an outside source
				if (other_leg_rdnis !== '') {
					replace_arrow_icon(uuid, 'inbound');
				} else {
					if (other_leg_unique_id !== '') {
						const matched_call = document.getElementById(other_leg_unique_id);
						if (matched_call.dataset.forced_direction) {
							replace_arrow_icon(uuid, matched_call.dataset.forced_direction);
						}
					} else {
						replace_arrow_icon(uuid, call.call_direction);
					}
				}
				break;
			case 'answered':
				update_call(call);
				//console.log('ANSWERED', call);
				if (row !== null) {
					replace_arrow_color(uuid, colors.CONNECTED);
				}
				break;
			case 'hangup':
				if (row !== null)
					replace_arrow_color(uuid, colors.HANGUP);
				hangup_call(call);
				break;
		}
	}

	function normalize_answer_state(call) {
		if (call === null || typeof call !== 'object') {
			return '';
		}

		const answer_state = String(call.answer_state ?? '').toLowerCase();
		if (answer_state !== 'ringing') {
			return answer_state;
		}

		// The in.progress bootstrap payload is currently synthesized as "ringing"
		// even when a call is already established. Mark those request-seeded rows as answered.
		if (call.__from_request === true) {
			return 'answered';
		}

		return answer_state;
	}

	//////////////////////
	// Helper functions //
	//////////////////////

	function replace_arrow_color(uuid, color) {
		const row = document.getElementById(uuid);
		if (!row) {
			return;
		}

		//get the table cell
		const span = document.getElementById(`arrow_${uuid}`) ?? null;
		if (!span) {
			return;
		}
		const icon = span.dataset.icon ?? 'local';

		//nothing to do
		if (color === span.dataset.color) {
			return;
		}

		span.dataset.icon = icon;
		span.dataset.color = color;

		//copy the cached arrow
		const cached_arrow = arrows[icon][color];
		const arrow = cached_arrow.cloneNode(true);

		//check for exiting arrow and add or replace
		const span_arrow = span.firstChild ?? null;
		if (span_arrow !== null) {
			span.replaceChild(arrow, span_arrow);
		} else {
			span.appendChild(arrow);
		}
	}

	function replace_arrow_icon(uuid, icon) {

		const row = document.getElementById(uuid);
		if (!row) {
			return;
		}

		//get the table cell
		const span = document.getElementById(`arrow_${uuid}`) ?? null;
		if (!span) {
			return;
		}
		const color = span.dataset.color ?? colors.RINGING;


		if (span.dataset.icon === null) {
			throw Exception('icon empty');
		}

		//nothing to do
		if (icon === span.dataset.icon) {
			return;
		}

		span.dataset.icon = icon;
		span.dataset.color = color;

		//copy the cached arrow
		const cached_arrow = arrows[icon][color];
		const arrow = cached_arrow.cloneNode(true);

		const span_arrow = span.firstChild ?? null;
		if (span_arrow !== null) {
			span.replaceChild(arrow, span_arrow);
		} else {
			span.appendChild(create_arrow(icon, color));
		}
	}

	function new_call(call) {
		//console.log(call);
		const tbody = document.getElementById("active_calls_body");

		if (!callsMap.has(call.unique_id)) {
			// create the row
			const uuid = call.unique_id;

			//create or get the row
			let row = document.getElementById(uuid);
			if (!row) {
				row = document.createElement("tr");
			}
			row.id = uuid;
			row.className = 'list-row';
			row.dataset.color = colors.RINGING;

			// start string block
			row.innerHTML = `<?php
echo '<td id="caller_id_number_${uuid}">${call.caller_caller_id_number}</td>' . PHP_EOL;
echo '<td id="destination_${uuid}">${call.caller_destination_number}</td>' . PHP_EOL;
echo '<td id="answer_state_${uuid}">${call.answer_state}</td>' . PHP_EOL;
echo '<td id="duration_${uuid}"></td>'.PHP_EOL;
?>`;
//end string block
			// Only display calls that belong to the current domain (server-side filtering ensures proper security)
			// The backend filter already restricts calls based on user permissions
			row.style.display = 'table-row';

			// add the row to the table
			tbody.appendChild(row);

			//console.log('NEW ROW ADDED', row.id);

			// start the timer
			start_duration_timer(call.unique_id, call.caller_channel_created_time);

			// add the uuid to the map
			callsMap.set(call.unique_id, row);
		}
		updateCount();
	}

	function update_call(call) {

		const tbody = document.getElementById("active_calls_body");

		if (callsMap.has(call.unique_id)) {

			//set values
			const uuid = call.unique_id;
			const row = document.getElementById(uuid);
			const caller_caller_id_number = call.caller_caller_id_number ?? '';
			const caller_destination_number = call.caller_destination_number ?? '';
			const answer_state = call.answer_state ?? '';

			//update table cells
			update_call_element(`caller_id_number_${uuid}`, caller_caller_id_number);
			update_call_element(`destination_${uuid}`, caller_destination_number);
			update_call_element(`answer_state_${uuid}`, answer_state);
		}

	}

	// Only updates the field when the data is not empty and has changed
	function update_call_element(element_name, value) {
		if (typeof value === 'undefined')
			return;
		const element = document.getElementById(element_name);
		if (element !== null && value !== null && value.length > 0 && element.textContent !== value) {
			element.textContent = value;
		}
	}

	function basename(path) {
		return path.replace(/^.*[\\\/]/, '')
	}

	function updateCount() {
		const calls_active_count = document.getElementById('calls_active_count');
        if (!calls_active_count) {return;}

		const totalCount = callsMap.size;
		calls_active_count.textContent = get_count();
	}

    function get_count() {
        let visibleCount = 0;
        callsMap.forEach((row) => {
            if (row.style.display !== 'none') {
                visibleCount++;
            }
        });
        return visibleCount;
    }

	function start_duration_timer(uuid, start_time) {
		const td = document.getElementById(`duration_${uuid}`)

		// Render function closes over startMs
		function render() {
			//calculate already elapsed time
			const start = new Date(start_time / 1000);
			const now = new Date();
			let elapsed = Math.floor(now.getTime() - start.getTime());

			// Fix rounding issue where floor can produce negative elapsed time
			if (elapsed < 0) {
				elapsed = 0;
			}

			//format time
			const hh = Math.floor(elapsed / (1000 * 3600)).toString();
			const mm = Math.floor((elapsed % (1000 * 3600)) / (1000 * 60)).toString().padStart(2, "0");
			const ss = Math.floor((elapsed % (1000 * 60)) / 1000).toString().padStart(2, "0"); // Convert remaining milliseconds to seconds

			td.textContent = `${hh}:${mm}:${ss}`;
		}

		render();
		const timerId = setInterval(render, 1000);

		timers[uuid] = timerId

		// Return stop function
		return () => clearInterval(timerId);
	}

	function stop_duration_timer(uuid) {
		//clear the timer on the row
		const timer_id = timers[uuid]
		if (timer_id) {
			clearInterval(timer_id)
			delete timers[uuid]
		}
	}

	function hangup_call(call) {
		const row = callsMap.get(call.unique_id);
		if (row) {
			const uuid = call.unique_id;
			callsMap.delete(uuid);
			const calls_active_count = document.getElementById('calls_active_count');
			let visibleCount = 0;
			callsMap.forEach((row) => {
				if (row.style.display !== 'none') {
					visibleCount++;
				}
			});

			const totalCount = callsMap.size;
			calls_active_count.textContent = `${visibleCount}`;
			stop_duration_timer(uuid);
			row.remove();
		}
	}

	//////////////////////////
	// Start the connection //
	//////////////////////////
	connect_active_calls_widget();
</script>

<?php echo "</div>\n"; ?>

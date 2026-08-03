-- Relay the terminal call-forward event outside the call-processing thread.

local event_id = tostring(argv[2] or '')
local caller_number = tostring(argv[3] or '')
local dialed_number = tostring(argv[4] or '')
local extension = tostring(argv[5] or '')
local domain_name = tostring(argv[6] or '')
local forward_destination = tostring(argv[7] or '')
local hangup_cause = tostring(argv[8] or '')
local start_epoch = tostring(argv[9] or '')
local answer_epoch = tostring(argv[10] or '')
local end_epoch = tostring(argv[11] or '')
local duration = tostring(argv[12] or '')
local billsec = tostring(argv[13] or '')

if event_id == '' or caller_number == '' or extension == '' or domain_name == '' then
	return
end

local json = require 'resources.functions.lunajson'
local payload = json.encode({
	event_type = 'ended',
	event_id = event_id,
	caller_number = caller_number,
	dialed_number = dialed_number,
	extension = extension,
	domain_name = domain_name,
	forward_destination = forward_destination,
	hangup_cause = hangup_cause,
	start_epoch = start_epoch,
	answer_epoch = answer_epoch,
	end_epoch = end_epoch,
	duration = duration,
	billsec = billsec,
})
local command = 'http://127.0.0.1/app/mphone_api/push_notify.php content-type application/json post ' .. payload
local response = freeswitch.API():executeString('curl ' .. command)
freeswitch.consoleLog('debug', '[mphone_forward_notify_end] relay response: ' .. tostring(response) .. '\n')

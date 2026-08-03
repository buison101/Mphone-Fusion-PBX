-- Sends the call metadata to the localhost-only Mphone push relay when the
-- dialed extension has immediate forwarding enabled. This script is started
-- with luarun so notification delivery never delays the call bridge.

local event_id = tostring(argv[2] or '')
local caller_number = tostring(argv[3] or '')
local sip_to_user = tostring(argv[4] or '')
local caller_destination = tostring(argv[5] or '')
local extension = tostring(argv[6] or '')
local domain_name = tostring(argv[7] or '')

if event_id == '' or caller_number == '' or extension == '' or domain_name == '' then
	return
end

local api = freeswitch.API()
local forward_enabled = api:executeString(
	'user_data ' .. extension .. '@' .. domain_name .. ' var forward_all_enabled'
)
local forward_destination = api:executeString(
	'user_data ' .. extension .. '@' .. domain_name .. ' var forward_all_destination'
)
forward_enabled = tostring(forward_enabled or ''):lower():gsub('%s+', '')
forward_destination = tostring(forward_destination or ''):gsub('%s+', '')
if (forward_enabled ~= 'true' and forward_enabled ~= '1') or forward_destination == '' then
	return
end

local dialed_number = sip_to_user
if dialed_number == '' then dialed_number = caller_destination end
if dialed_number == '' then dialed_number = extension end

local json = require 'resources.functions.lunajson'
local payload = json.encode({
	event_id = event_id,
	caller_number = caller_number,
	dialed_number = dialed_number,
	extension = extension,
	domain_name = domain_name,
})
local command = 'http://127.0.0.1/app/mphone_api/push_notify.php content-type application/json post ' .. payload
local response = api:executeString('curl ' .. command)
freeswitch.consoleLog('debug', '[mphone_forward_notify] relay response: ' .. tostring(response) .. '\n')


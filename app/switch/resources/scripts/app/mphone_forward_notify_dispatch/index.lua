-- Schedule call-forward notification work in the FreeSWITCH background API
-- pool, allowing the dialplan to continue immediately to the bridge action.

if session == nil or not session:ready() then
	return
end

local function channel_value(name)
	local value = tostring(session:getVariable(name) or ''):gsub('[%s\'\"]', '')
	return value
end

local event_id = channel_value('uuid')
local caller_number = channel_value('caller_id_number')
local sip_to_user = channel_value('sip_to_user')
local caller_destination = channel_value('caller_destination')
local extension = channel_value('dialed_extension')
if extension == '' then extension = channel_value('destination_number') end
local domain_name = channel_value('domain_name')
if event_id == '' or caller_number == '' or extension == '' or domain_name == '' then
	return
end

-- Keep the original forwarding metadata on the A-leg. execute_on_hangup runs
-- in the channel context and only schedules background work, so hangup is
-- never delayed by the HTTP/FCM request.
session:setVariable('mphone_forward_event_id', event_id)
session:setVariable('mphone_forward_caller_number', caller_number)
session:setVariable('mphone_forward_dialed_number', sip_to_user ~= '' and sip_to_user or caller_destination)
session:setVariable('mphone_forward_extension', extension)
session:setVariable('mphone_forward_domain_name', domain_name)
session:setVariable('mphone_forward_destination', channel_value('forward_all_destination'))

local command = table.concat({
	'luarun app.lua mphone_forward_notify',
	"'" .. event_id .. "'",
	"'" .. caller_number .. "'",
	"'" .. sip_to_user .. "'",
	"'" .. caller_destination .. "'",
	"'" .. extension .. "'",
	"'" .. domain_name .. "'",
}, ' ')
freeswitch.API():executeString('bgapi ' .. command)

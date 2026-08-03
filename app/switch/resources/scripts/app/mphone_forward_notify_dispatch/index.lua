-- Schedule call-forward notification work in the FreeSWITCH background API
-- pool, allowing the dialplan to continue immediately to the bridge action.

if session == nil or not session:ready() then
	return
end

local function channel_value(name)
	return tostring(session:getVariable(name) or ''):gsub('[%s\'\"]', '')
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

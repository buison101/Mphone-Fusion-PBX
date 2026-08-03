-- Capture terminal call-forward state from the A-leg, then hand all network
-- work to FreeSWITCH's background API pool.

if session == nil then
	return
end

local function channel_value(name)
	local value = tostring(session:getVariable(name) or ''):gsub('[%s\'\"]', '')
	return value
end

local event_id = channel_value('mphone_forward_event_id')
local caller_number = channel_value('mphone_forward_caller_number')
local dialed_number = channel_value('mphone_forward_dialed_number')
local extension = channel_value('mphone_forward_extension')
local domain_name = channel_value('mphone_forward_domain_name')
local forward_destination = channel_value('mphone_forward_destination')
local hangup_cause = channel_value('hangup_cause')
local start_epoch = channel_value('start_epoch')
local answer_epoch = channel_value('answer_epoch')
local end_epoch = channel_value('end_epoch')
local duration = channel_value('duration')
local billsec = channel_value('billsec')

if event_id == '' or caller_number == '' or extension == '' or domain_name == '' then
	return
end

local command = table.concat({
	'luarun app.lua mphone_forward_notify_end',
	"'" .. event_id .. "'",
	"'" .. caller_number .. "'",
	"'" .. dialed_number .. "'",
	"'" .. extension .. "'",
	"'" .. domain_name .. "'",
	"'" .. forward_destination .. "'",
	"'" .. hangup_cause .. "'",
	"'" .. start_epoch .. "'",
	"'" .. answer_epoch .. "'",
	"'" .. end_epoch .. "'",
	"'" .. duration .. "'",
	"'" .. billsec .. "'",
}, ' ')
freeswitch.API():executeString('bgapi ' .. command)

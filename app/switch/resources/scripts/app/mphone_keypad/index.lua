-- Route a digit collected by the managed Mphone keypad dialplan.
-- argv: app.lua mphone_keypad <domain> <fallback_ring_group_uuid> [digit=e:extension|g:ring_group_uuid ...]

	local domain_name = tostring(argv[2] or "")
	local ring_group_uuid = tostring(argv[3] or "")
	local digit = tostring(session:getVariable("mphone_digit") or "")
	local target_type = nil
	local target = nil

	if not domain_name:match("^[%w%.%-]+$") then
		freeswitch.consoleLog("ERR", "[mphone_keypad] invalid domain\n")
		return
	end
	if not ring_group_uuid:match("^[0-9a-fA-F%-]+$") then
		freeswitch.consoleLog("ERR", "[mphone_keypad] invalid ring group UUID\n")
		return
	end

	for index = 4, #argv do
		local mapping_digit, mapping_type, mapping_target = tostring(argv[index] or ""):match("^([0-9])=([eg]):([0-9a-fA-F%-]+)$")
		if mapping_digit == digit then
			target_type = mapping_type
			target = mapping_target
			break
		end
	end

	if target_type == "e" and target and target:match("^[0-9]+$") then
		session:execute("transfer", target .. " XML " .. domain_name)
		return
	end
	if target_type == "g" and target and target:match("^[0-9a-fA-F%-]+$") then
		session:setVariable("ring_group_uuid", target)
		loadfile(scripts_dir .. "/app/ring_groups/index.lua")(argv)
		return
	end

	-- Invalid/no input uses the current version's verified Default Ring Group.
	session:setVariable("ring_group_uuid", ring_group_uuid)
	loadfile(scripts_dir .. "/app/ring_groups/index.lua")(argv)

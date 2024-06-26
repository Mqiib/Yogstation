/datum/computer_file/program/ntnet_dos
	filename = "ntn_dos"
	filedesc = "DoS Traffic Generator"
	category = PROGRAM_CATEGORY_EQUIPMENT
	program_icon_state = "hostile"
	extended_desc = "This advanced script can perform denial of service attacks against NTNet quantum relays. The system administrator will probably notice this. Multiple devices can run this program together against the same relay for increased effect"
	size = 20
	requires_ntnet = TRUE
	available_on_ntnet = FALSE
	available_on_syndinet = TRUE
	tgui_id = "NtosNetDos"
	program_icon = "satellite-dish"

	var/obj/machinery/ntnet_relay/target = null
	var/dos_speed = 0
	var/error = ""
	var/executed = 0

/datum/computer_file/program/ntnet_dos/process_tick()
	dos_speed = 0
	switch(ntnet_status)
		if(1)
			dos_speed = NTNETSPEED_LOWSIGNAL * 10
		if(2)
			dos_speed = NTNETSPEED_HIGHSIGNAL * 10
		if(3)
			dos_speed = NTNETSPEED_ETHERNET * 10
	if(target && executed)
		target.dos_overload += dos_speed
		if(!target.is_operational())
			target.dos_sources.Remove(src)
			target = null
			error = "Connection to destination relay lost."

/datum/computer_file/program/ntnet_dos/kill_program(forced = FALSE)
	if(target)
		target.dos_sources.Remove(src)
	target = null
	executed = FALSE

	..()

/datum/computer_file/program/ntnet_dos/ui_act(action, params)
	if(..())
		return
	computer.play_interact_sound()
	switch(action)
		if("PRG_target_relay")
			for(var/obj/machinery/ntnet_relay/R as anything in SSmachines.get_machines_by_type(/obj/machinery/ntnet_relay))
				if(R.uid == text2num(params["targid"]))
					target = R
					break
			return TRUE
		if("PRG_reset")
			if(target)
				target.dos_sources.Remove(src)
				target = null
			executed = FALSE
			error = ""
			return TRUE
		if("PRG_execute")
			if(target)
				executed = TRUE
				target.dos_sources.Add(src)
				if(SSmodular_computers.intrusion_detection_enabled)
					var/obj/item/computer_hardware/network_card/network_card = computer.all_components[MC_NET]
					SSmodular_computers.add_log("IDS WARNING - Excess traffic flood targeting relay [target.uid] detected from device: [network_card.get_network_tag()]")
					SSmodular_computers.intrusion_detection_alarm = TRUE
			return TRUE

/datum/computer_file/program/ntnet_dos/ui_data(mob/user)
	if(!SSmodular_computers)
		return

	var/list/data = get_header_data()

	data["error"] = error
	if(target && executed)
		data["target"] = TRUE
		data["speed"] = dos_speed

		data["overload"] = target.dos_overload
		data["capacity"] = target.dos_capacity
	else
		data["target"] = FALSE
		data["relays"] = list()
		for(var/obj/machinery/ntnet_relay/R as anything in SSmachines.get_machines_by_type(/obj/machinery/ntnet_relay))
			data["relays"] += list(list("id" = R.uid))
		data["focus"] = target ? target.uid : null

	return data

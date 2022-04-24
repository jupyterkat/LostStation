/obj/machinery/atmospherics/components/trinary/filter
	name = "gas filter"
	icon_state = "filter_off"
	desc = "Very useful for filtering gasses."
	density = FALSE
	can_unwrench = 1
	var/on = FALSE
	var/transfer_rate = MAX_TRANSFER_RATE
	var/filter_type = null
	var/frequency = 0
	var/datum/radio_frequency/radio_connection

	construction_type = /obj/item/pipe/trinary/flippable
	pipe_state = "filter"

/obj/machinery/atmospherics/components/trinary/filter/flipped
	icon_state = "filter_off_f"
	flipped = 1

// These two filter types have critical_machine flagged to on and thus causes the area they are in to be exempt from the Grid Check event.

/obj/machinery/atmospherics/components/trinary/filter/critical
	critical_machine = TRUE

/obj/machinery/atmospherics/components/trinary/filter/flipped/critical
	critical_machine = TRUE

/obj/machinery/atmospherics/components/trinary/filter/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = SSradio.add_object(src, frequency, GLOB.RADIO_ATMOSIA)

/obj/machinery/atmospherics/components/trinary/filter/Destroy()
	SSradio.remove_object(src,frequency)
	return ..()

/obj/machinery/atmospherics/components/trinary/filter/update_icon()
	cut_overlays()
	for(var/direction in GLOB.cardinals)
		if(direction & initialize_directions)
			var/obj/machinery/atmospherics/node = findConnecting(direction)
			if(node)
				add_overlay(getpipeimage('icons/obj/atmospherics/components/trinary_devices.dmi', "cap[piping_layer]", direction, node.pipe_color))
				continue
			add_overlay(getpipeimage('icons/obj/atmospherics/components/trinary_devices.dmi', "cap[piping_layer]", direction))
	..()

/obj/machinery/atmospherics/components/trinary/filter/update_icon_nopipes()

	if(!(stat & NOPOWER) && on && NODE1 && NODE2 && NODE3)
		icon_state = "filter_on[flipped?"_f":""]"
		return

	icon_state = "filter_off[flipped?"_f":""]"

/obj/machinery/atmospherics/components/trinary/filter/power_change()
	var/old_stat = stat
	..()
	if(stat & NOPOWER)
		on = FALSE
	if(old_stat != stat)
		update_icon()

/obj/machinery/atmospherics/components/trinary/filter/process_atmos()
	..()
	if(!on)
		return 0
	if(!(NODE1 && NODE2 && NODE3))
		return 0

	var/datum/gas_mixture/air1 = AIR1
	var/datum/gas_mixture/air2 = AIR2
	var/datum/gas_mixture/air3 = AIR3

	var/output_starting_pressure = air3.return_pressure()

	if(output_starting_pressure >= MAX_OUTPUT_PRESSURE)
		//No need to mix if target is already full!
		return 1

	var/transfer_ratio = transfer_rate / air1.return_volume()

	//Actually transfer the gas

	if(transfer_ratio <= 0)
		return

	if(filter_type && air2.return_pressure() <= 9000)
		air1.scrub_into(air2, transfer_ratio, list(filter_type))
	if(air3.return_pressure() <= 9000)
		air1.transfer_ratio_to(air3, transfer_ratio)

	update_parents()

	return 1

/obj/machinery/atmospherics/components/trinary/filter/atmosinit()
	set_frequency(frequency)
	return ..()

/obj/machinery/atmospherics/components/trinary/filter/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosFilter", name)
		ui.open()

/obj/machinery/atmospherics/components/trinary/filter/ui_data()
	var/data = list()
	data["on"] = on
	data["rate"] = round(transfer_rate)
	data["max_rate"] = round(MAX_TRANSFER_RATE)

	data["filter_types"] = list()
	data["filter_types"] += list(list("name" = "Nothing", "id" = "", "selected" = !filter_type))
	for(var/id in GLOB.gas_data.ids)
		data["filter_types"] += list(list("name" = GLOB.gas_data.names[id], "id" = id, "selected" = (id == filter_type)))

	return data

/obj/machinery/atmospherics/components/trinary/filter/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("power")
			on = !on
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("rate")
			var/rate = params["rate"]
			if(rate == "max")
				rate = MAX_TRANSFER_RATE
				. = TRUE
			else if(rate == "input")
				rate = input("New transfer rate (0-[MAX_TRANSFER_RATE] L/s):", name, transfer_rate) as num|null
				if(!isnull(rate) && !..())
					. = TRUE
			else if(text2num(rate) != null)
				rate = text2num(rate)
				. = TRUE
			if(.)
				transfer_rate = clamp(rate, 0, MAX_TRANSFER_RATE)
				investigate_log("was set to [transfer_rate] L/s by [key_name(usr)]", INVESTIGATE_ATMOS)
		if("filter")
			filter_type = ""
			var/filter_name = "nothing"
			var/gas = params["mode"]
			if(gas in GLOB.gas_data.names)
				filter_type = gas
				filter_name	= GLOB.gas_data.names[gas]
			investigate_log("was set to filter [filter_name] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
	update_icon()

#define SIPHONING	0
#define SCRUBBING	1

/obj/machinery/atmospherics/components/unary/vent_scrubber
	name = "air scrubber"
	desc = "Has a valve and pump attached to it."
	icon_state = "scrub_map"
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 60
	can_unwrench = 1
	welded = FALSE
	level = 1
	layer = GAS_SCRUBBER_LAYER

	var/id_tag = null
	var/on = FALSE
	var/scrubbing = SCRUBBING //0 = siphoning, 1 = scrubbing

	var/filter_types = list(GAS_CO2)
	var/list/clean_filter_types = null

	var/volume_rate = 200
	var/widenet = 0 //is this scrubber acting on the 3x3 area around it.
	var/list/turf/adjacent_turfs = list()

	var/frequency = 1439
	var/datum/radio_frequency/radio_connection
	var/radio_filter_out
	var/radio_filter_in

	pipe_state = "scrubber"

/obj/machinery/atmospherics/components/unary/vent_scrubber/New()
	..()
	if(!id_tag)
		assign_uid()
		id_tag = num2text(uid)
	
	generate_clean_filter_types()

/obj/machinery/atmospherics/components/unary/vent_scrubber/on
	on = TRUE
	icon_state = "scrub_map_on"

/obj/machinery/atmospherics/components/unary/vent_scrubber/Destroy()
	var/area/A = get_area(src)
	A.air_scrub_names -= id_tag
	A.air_scrub_info -= id_tag

	SSradio.remove_object(src,frequency)
	radio_connection = null

	for(var/I in adjacent_turfs)
		I = null

	return ..()

/obj/machinery/atmospherics/components/unary/vent_scrubber/auto_use_power()
	if(!powered(power_channel))
		return 0
	if(!on || welded)
		return 0
	if(stat & (NOPOWER|BROKEN))
		return 0

	var/amount = idle_power_usage

	if(scrubbing & SCRUBBING)
		amount += idle_power_usage * length(filter_types)
	else //scrubbing == SIPHONING
		amount = active_power_usage

	if(widenet)
		amount += amount * (adjacent_turfs.len * (adjacent_turfs.len / 2))
	use_power(amount, power_channel)
	return 1

/obj/machinery/atmospherics/components/unary/vent_scrubber/update_icon_nopipes()
	cut_overlays()
	if(showpipe)
		add_overlay(getpipeimage(icon, "scrub_cap", initialize_directions))

	if(welded)
		icon_state = "scrub_welded"
		return

	if(!NODE1 || !on || stat & (NOPOWER|BROKEN))
		icon_state = "scrub_off"
		return

	if(scrubbing & SCRUBBING)
		icon_state = "scrub_on"
	else //scrubbing == SIPHONING
		icon_state = "scrub_purge"

/obj/machinery/atmospherics/components/unary/vent_scrubber/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = SSradio.add_object(src, frequency, radio_filter_in)

/obj/machinery/atmospherics/components/unary/vent_scrubber/proc/broadcast_status()
	if(!radio_connection)
		return 0
	
	var/list/f_types = list()
	for(var/id in GLOB.gas_data.ids)
		f_types += list(list("gas_id" = id, "gas_name" = GLOB.gas_data.names[id], "enabled" = (id in filter_types)))

	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.source = src
	signal.data = list(
		"tag" = id_tag,
		"frequency" = frequency,
		"device" = "VS",
		"timestamp" = world.time,
		"power" = on,
		"scrubbing" = scrubbing,
		"widenet" = widenet,
		"filter_types" = f_types,
		"sigtype" = "status"
	)

	var/area/A = get_area(src)
	if(!A.air_scrub_names[id_tag])
		name = "\improper [A.name] air scrubber #[A.air_scrub_names.len + 1]"
		A.air_scrub_names[id_tag] = name
	A.air_scrub_info[id_tag] = signal.data

	radio_connection.post_signal(src, signal, radio_filter_out)

	return 1

/obj/machinery/atmospherics/components/unary/vent_scrubber/atmosinit()
	radio_filter_in = frequency==initial(frequency)?(GLOB.RADIO_FROM_AIRALARM):null
	radio_filter_out = frequency==initial(frequency)?(GLOB.RADIO_TO_AIRALARM):null
	if(frequency)
		set_frequency(frequency)
	broadcast_status()
	check_turfs()
	..()

/obj/machinery/atmospherics/components/unary/vent_scrubber/process_atmos()
	..()
	if(stat & (NOPOWER|BROKEN))
		return
	if (!NODE1)
		on = FALSE
	if(!on || welded)
		return 0
	scrub(loc)
	if(widenet)
		for (var/turf/tile in adjacent_turfs)
			scrub(tile)

/obj/machinery/atmospherics/components/unary/vent_scrubber/proc/generate_clean_filter_types()
	clean_filter_types = list()
	for(var/id in filter_types)
		if(id in GLOB.gas_data.groups)
			clean_filter_types += GLOB.gas_data.groups[id]
		else
			clean_filter_types += id

/obj/machinery/atmospherics/components/unary/vent_scrubber/proc/scrub(var/turf/tile)
	if (!istype(tile))
		return 0
	var/datum/gas_mixture/environment = tile.return_air()
	var/datum/gas_mixture/air_contents = AIR1

	if(air_contents.return_pressure() >= 50 * ONE_ATMOSPHERE || !islist(clean_filter_types)) 
		return FALSE

	if(scrubbing & SCRUBBING)
		environment.scrub_into(air_contents, volume_rate/environment.return_volume(), clean_filter_types) 

	else //Just siphoning all air
		environment.transfer_ratio_to(air_contents, volume_rate/environment.return_volume())

	update_parents()
	return 1


//There is no easy way for an object to be notified of changes to atmos can pass flags
//	So we check every machinery process (2 seconds)
/obj/machinery/atmospherics/components/unary/vent_scrubber/process()
	if (widenet)
		check_turfs()

//we populate a list of turfs with nonatmos-blocked cardinal turfs AND
//	diagonal turfs that can share atmos with *both* of the cardinal turfs
/obj/machinery/atmospherics/components/unary/vent_scrubber/proc/check_turfs()
	adjacent_turfs.Cut()
	var/turf/T = get_turf(src)
	if(istype(T))
		adjacent_turfs = T.GetAtmosAdjacentTurfs(alldir = 1)


/obj/machinery/atmospherics/components/unary/vent_scrubber/receive_signal(datum/signal/signal)
	if(stat & (NOPOWER|BROKEN))
		return
	if(!signal.data["tag"] || (signal.data["tag"] != id_tag) || (signal.data["sigtype"]!="command"))
		return 0

	if("power" in signal.data)
		on = text2num(signal.data["power"])
	if("power_toggle" in signal.data)
		on = !on

	if("widenet" in signal.data)
		widenet = text2num(signal.data["widenet"])
	if("toggle_widenet" in signal.data)
		widenet = !widenet

	if("scrubbing" in signal.data)
		scrubbing = text2num(signal.data["scrubbing"])
	if("toggle_scrubbing" in signal.data)
		scrubbing = !scrubbing
	
	if("toggle_filter" in signal.data)
		filter_types ^= signal.data["toggle_filter"]
		generate_clean_filter_types()

	if("set_filters" in signal.data)
		filter_types = list()
		for(var/gas in signal.data["set_filters"])
			filter_types += gas
		generate_clean_filter_types()

	if("init" in signal.data)
		name = signal.data["init"]
		return

	if("status" in signal.data)
		broadcast_status()
		return //do not update_icon

	broadcast_status()
	update_icon()
	return

/obj/machinery/atmospherics/components/unary/vent_scrubber/power_change()
	..()
	update_icon_nopipes()

/obj/machinery/atmospherics/components/unary/vent_scrubber/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/weldingtool))
		var/obj/item/weldingtool/WT = W
		if(WT.remove_fuel(0,user))
			playsound(loc, WT.usesound, 40, 1)
			to_chat(user, "<span class='notice'>Now welding the scrubber.</span>")
			if(do_after(user, 20*W.toolspeed, target = src))
				if(!src || !WT.isOn())
					return
				playsound(src.loc, 'sound/items/welder2.ogg', 50, 1)
				if(!welded)
					user.visible_message("[user] welds the scrubber shut.","You weld the scrubber shut.", "You hear welding.")
					welded = TRUE
				else
					user.visible_message("[user] unwelds the scrubber.", "You unweld the scrubber.", "You hear welding.")
					welded = FALSE
				update_icon()
				pipe_vision_img = image(src, loc, layer = ABOVE_HUD_LAYER, dir = dir)
				pipe_vision_img.plane = ABOVE_HUD_PLANE
			return 0
	else
		return ..()

/obj/machinery/atmospherics/components/unary/vent_scrubber/can_unwrench(mob/user)
	if(..())
		if (!(stat & NOPOWER) && on)
			to_chat(user, "<span class='warning'>You cannot unwrench [src], turn it off first!</span>")
		else
			return 1

/obj/machinery/atmospherics/components/unary/vent_scrubber/can_crawl_through()
	return !welded

/obj/machinery/atmospherics/components/unary/vent_scrubber/attack_alien(mob/user)
	if(!welded || !(do_after(user, 20, target = src)))
		return
	user.visible_message("[user] furiously claws at [src]!", "You manage to clear away the stuff blocking the scrubber.", "You hear loud scraping noises.")
	welded = FALSE
	update_icon()
	pipe_vision_img = image(src, loc, layer = ABOVE_HUD_LAYER, dir = dir)
	pipe_vision_img.plane = ABOVE_HUD_PLANE
	playsound(loc, 'sound/weapons/bladeslice.ogg', 100, 1)



#undef SIPHONING
#undef SCRUBBING

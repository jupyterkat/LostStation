#define CAN_DEFAULT_RELEASE_PRESSURE (ONE_ATMOSPHERE)

/obj/machinery/portable_atmospherics/canister
	name = "canister"
	desc = "A canister for the storage of gas."
	icon_state = "yellow"
	density = TRUE

	var/valve_open = FALSE
	var/obj/machinery/atmospherics/components/binary/passive_gate/pump
	var/release_log = ""

	volume = 1000
	var/filled = 0.5
	var/gas_type = ""
	var/release_pressure = ONE_ATMOSPHERE
	var/can_max_release_pressure = (ONE_ATMOSPHERE * 10)
	var/can_min_release_pressure = (ONE_ATMOSPHERE / 10)

	armor = list(melee = 50, bullet = 50, laser = 50, energy = 100, bomb = 10, bio = 100, rad = 100, fire = 80, acid = 50)
	max_integrity = 250
	integrity_failure = 100
	var/temperature_resistance = 1000 + T0C
	var/starter_temp = T20C
	// Prototype vars
	var/prototype = FALSE
	var/valve_timer = null
	var/timer_set = 30
	var/default_timer_set = 30
	var/minimum_timer_set = 1
	var/maximum_timer_set = 300
	var/timing = FALSE
	var/restricted = FALSE
	req_access = list()

	var/update = 0
	var/static/list/label2types = list(
		"n2" = /obj/machinery/portable_atmospherics/canister/nitrogen,
		"o2" = /obj/machinery/portable_atmospherics/canister/oxygen,
		"co2" = /obj/machinery/portable_atmospherics/canister/carbon_dioxide,
		"plasma" = /obj/machinery/portable_atmospherics/canister/toxins,
		"n2o" = /obj/machinery/portable_atmospherics/canister/nitrous_oxide,
		"bz" = /obj/machinery/portable_atmospherics/canister/bz,
		"air" = /obj/machinery/portable_atmospherics/canister/air,
		"freon" = /obj/machinery/portable_atmospherics/canister/freon,
		"water vapor" = /obj/machinery/portable_atmospherics/canister/water_vapor,
		"caution" = /obj/machinery/portable_atmospherics/canister,
	)

/obj/machinery/portable_atmospherics/canister/interact(mob/user)
	if(!allowed(user))
		to_chat(user, "<span class='warning'>Error - Unauthorized User</span>")
		playsound(src, 'sound/misc/compiler-failure.ogg', 50, 1)
		return
	..()

/obj/machinery/portable_atmospherics/canister/nitrogen
	name = "n2 canister"
	desc = "Nitrogen gas. Reportedly useful for something."
	icon_state = "red"
	gas_type = GAS_N2

/obj/machinery/portable_atmospherics/canister/oxygen
	name = "o2 canister"
	desc = "Oxygen. Necessary for human life."
	icon_state = "blue"
	gas_type = GAS_O2

/obj/machinery/portable_atmospherics/canister/carbon_dioxide
	name = "co2 canister"
	desc = "Carbon dioxide. What the fuck is carbon dioxide?"
	icon_state = "black"
	gas_type = GAS_CO2

/obj/machinery/portable_atmospherics/canister/toxins
	name = "plasma canister"
	desc = "Plasma gas. The reason YOU are here. Highly toxic."
	icon_state = "orange"
	gas_type = GAS_PLASMA

/obj/machinery/portable_atmospherics/canister/agent_b
	name = "agent b canister"
	desc = "Oxygen Agent B. You're not quite sure what it does."
	gas_type = GAS_O2B

/obj/machinery/portable_atmospherics/canister/bz
	name = "BZ canister"
	desc = "BZ, a powerful hallucinogenic nerve agent."
	icon_state = "purple"
	gas_type = GAS_BZ

/obj/machinery/portable_atmospherics/canister/nitrous_oxide
	name = "n2o canister"
	desc = "Nitrous oxide gas. Known to cause drowsiness."
	icon_state = "redws"
	gas_type = GAS_NITROUS

/obj/machinery/portable_atmospherics/canister/air
	name = "air canister"
	desc = "Pre-mixed air."
	icon_state = "grey"

/obj/machinery/portable_atmospherics/canister/freon
	name = "freon canister"
	desc = "Freon. Great for the atmosphere!"
	icon_state = "freon"
	gas_type = GAS_FREON
	starter_temp = 120

/obj/machinery/portable_atmospherics/canister/water_vapor
	name = "water vapor canister"
	desc = "Water Vapor. We get it, you vape."
	icon_state = "water_vapor"
	gas_type = GAS_H2O
	filled = 1

/obj/machinery/portable_atmospherics/canister/proc/get_time_left()
	if(timing)
		. = round(max(0, valve_timer - world.time) / 10, 1)
	else
		. = timer_set

/obj/machinery/portable_atmospherics/canister/proc/set_active()
	timing = !timing
	if(timing)
		valve_timer = world.time + (timer_set * 10)
	update_icon()

/obj/machinery/portable_atmospherics/canister/proto
	name = "prototype canister"


/obj/machinery/portable_atmospherics/canister/proto/default
	name = "prototype canister"
	desc = "The best way to fix an atmospheric emergency... or the best way to introduce one."
	icon_state = "proto"
	icon_state = "proto"
	volume = 5000
	max_integrity = 300
	temperature_resistance = 2000 + T0C
	can_max_release_pressure = (ONE_ATMOSPHERE * 30)
	can_min_release_pressure = (ONE_ATMOSPHERE / 30)
	prototype = TRUE


/obj/machinery/portable_atmospherics/canister/proto/default/oxygen
	name = "prototype canister"
	desc = "A prototype canister for a prototype bike, what could go wrong?"
	icon_state = "proto"
	gas_type = GAS_O2
	filled = 1
	release_pressure = ONE_ATMOSPHERE*2



/obj/machinery/portable_atmospherics/canister/New(loc, datum/gas_mixture/existing_mixture)
	..()
	if(existing_mixture)
		air_contents.copy_from(existing_mixture)
	else
		create_gas()
	pump = new(src, FALSE)
	pump.on = TRUE
	pump.stat = 0
	pump.build_network()

	update_icon()

/obj/machinery/portable_atmospherics/canister/Destroy()
	qdel(pump)
	pump = null
	return ..()

/obj/machinery/portable_atmospherics/canister/proc/create_gas()
	if(gas_type)
		if(starter_temp)
			air_contents.set_temperature(starter_temp)
		if(!air_contents.return_volume())
			CRASH("Auxtools is failing somehow! Gas with pointer [air_contents._extools_pointer_gasmixture] is not valid.")
		air_contents.set_moles(gas_type, (maximum_pressure * filled) * air_contents.return_volume() / (R_IDEAL_GAS_EQUATION * air_contents.return_temperature()))

/obj/machinery/portable_atmospherics/canister/air/create_gas()
	air_contents.set_temperature(starter_temp)
	air_contents.set_moles(GAS_O2, (O2STANDARD * maximum_pressure * filled) * air_contents.return_volume() / (R_IDEAL_GAS_EQUATION * air_contents.return_temperature()))
	air_contents.set_moles(GAS_N2, (N2STANDARD * maximum_pressure * filled) * air_contents.return_volume() / (R_IDEAL_GAS_EQUATION * air_contents.return_temperature()))


#define HOLDING 1
#define CONNECTED 2
#define EMPTY 4
#define LOW 8
#define MEDIUM 16
#define FULL 32
#define DANGER 64
/obj/machinery/portable_atmospherics/canister/update_icon()
	if(stat & BROKEN)
		cut_overlays()
		icon_state = "[initial(icon_state)]-1"
		return

	var/last_update = update
	update = 0

	if(holding)
		update |= HOLDING
	if(connected_port)
		update |= CONNECTED
	var/pressure = air_contents.return_pressure()
	if(pressure < 10)
		update |= EMPTY
	else if(pressure < 5 * ONE_ATMOSPHERE)
		update |= LOW
	else if(pressure < 10 * ONE_ATMOSPHERE)
		update |= MEDIUM
	else if(pressure < 40 * ONE_ATMOSPHERE)
		update |= FULL
	else
		update |= DANGER


	if(update == last_update)
		return

	cut_overlays()

	if(update & HOLDING)
		add_overlay("can-open")
	if(update & CONNECTED)
		add_overlay("can-connector")
	if(update & LOW)
		add_overlay("can-o0")
	else if(update & MEDIUM)
		add_overlay("can-o1")
	else if(update & FULL)
		add_overlay("can-o2")
	else if(update & DANGER)
		add_overlay("can-o3")

#undef HOLDING
#undef CONNECTED
#undef EMPTY
#undef MEDIUM

/obj/machinery/portable_atmospherics/canister/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > temperature_resistance)
		take_damage(5, BURN, 0)


/obj/machinery/portable_atmospherics/canister/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(!(stat & BROKEN))
			canister_break()
		if(disassembled)
			new /obj/item/stack/sheet/metal (loc, 10)
		else
			new /obj/item/stack/sheet/metal (loc, 5)
	qdel(src)

/obj/machinery/portable_atmospherics/canister/attackby(obj/item/W, mob/user, params)
	if(user.a_intent != INTENT_HARM && istype(W, /obj/item/weldingtool))
		var/obj/item/weldingtool/WT = W
		if(stat & BROKEN)
			if(!WT.remove_fuel(0, user))
				return
			playsound(loc, WT.usesound, 40, 1)
			to_chat(user, "<span class='notice'>You begin cutting [src] apart...</span>")
			if(do_after(user, 30, target = src))
				deconstruct(TRUE)
		else
			to_chat(user, "<span class='notice'>You cannot slice [src] apart when it isn't broken.</span>")
		return 1
	else
		return ..()

/obj/machinery/portable_atmospherics/canister/obj_break(damage_flag)
	if((flags_1 & BROKEN) || (flags_1 & NODECONSTRUCT_1))
		return
	canister_break()

/obj/machinery/portable_atmospherics/canister/proc/canister_break()
	disconnect()
	var/datum/gas_mixture/expelled_gas = air_contents.remove(air_contents.total_moles())
	var/turf/T = get_turf(src)
	T.assume_air(expelled_gas)
	air_update_turf()

	stat |= BROKEN
	density = FALSE
	playsound(src.loc, 'sound/effects/spray.ogg', 10, 1, -3)
	update_icon()
	investigate_log("was destroyed.", INVESTIGATE_ATMOS)

	if(holding)
		holding.forceMove(T)
		holding = null

/obj/machinery/portable_atmospherics/canister/process_atmos()
	..()
	if(stat & BROKEN)
		return PROCESS_KILL
	if(timing && valve_timer < world.time)
		valve_open = !valve_open
		timing = FALSE
	if(!valve_open)
		pump.AIR1 = null
		pump.AIR2 = null
		return

	var/turf/T = get_turf(src)
	pump.AIR1 = air_contents
	pump.AIR2 = holding ? holding.air_contents : T.return_air()
	pump.target_pressure = release_pressure

	pump.process_atmos() // Pump gas.
	if(!holding)
		air_update_turf() // Update the environment if needed.
	update_icon()

/obj/machinery/portable_atmospherics/canister/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Canister", name)
		ui.open()

/obj/machinery/portable_atmospherics/canister/ui_data()
	var/data = list()
	data["portConnected"] = connected_port ? 1 : 0
	data["tankPressure"] = round(air_contents.return_pressure() ? air_contents.return_pressure() : 0)
	data["releasePressure"] = round(release_pressure ? release_pressure : 0)
	data["defaultReleasePressure"] = round(CAN_DEFAULT_RELEASE_PRESSURE)
	data["minReleasePressure"] = round(can_min_release_pressure)
	data["maxReleasePressure"] = round(can_max_release_pressure)
	data["valveOpen"] = valve_open ? 1 : 0

	data["isPrototype"] = prototype ? 1 : 0
	if (prototype)
		data["restricted"] = restricted
		data["timing"] = timing
		data["time_left"] = get_time_left()
		data["timer_set"] = timer_set
		data["timer_is_not_default"] = timer_set != default_timer_set
		data["timer_is_not_min"] = timer_set != minimum_timer_set
		data["timer_is_not_max"] = timer_set != maximum_timer_set

	data["hasHoldingTank"] = holding ? 1 : 0
	if (holding)
		data["holdingTank"] = list()
		data["holdingTank"]["name"] = holding.name
		data["holdingTank"]["tankPressure"] = round(holding.air_contents.return_pressure())
	return data

/obj/machinery/portable_atmospherics/canister/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("relabel")
			var/label = input("New canister label:", name) as null|anything in label2types
			if(label && !..())
				var/newtype = label2types[label]
				if(newtype)
					var/obj/machinery/portable_atmospherics/canister/replacement = newtype
					name = initial(replacement.name)
					desc = initial(replacement.name)
					icon_state = initial(replacement.icon_state)
		if("restricted")
			restricted = !restricted
			if(restricted)
				req_access = list(ACCESS_ENGINE)
			else
				req_access = list()
				. = TRUE
		if("pressure")
			var/pressure = params["pressure"]
			if(pressure == "reset")
				pressure = CAN_DEFAULT_RELEASE_PRESSURE
				. = TRUE
			else if(pressure == "min")
				pressure = can_min_release_pressure
				. = TRUE
			else if(pressure == "max")
				pressure = can_max_release_pressure
				. = TRUE
			else if(pressure == "input")
				pressure = input("New release pressure ([can_min_release_pressure]-[can_max_release_pressure] kPa):", name, release_pressure) as num|null
				if(!isnull(pressure) && !..())
					. = TRUE
			else if(text2num(pressure) != null)
				pressure = text2num(pressure)
				. = TRUE
			if(.)
				release_pressure = clamp(round(pressure), can_min_release_pressure, can_max_release_pressure)
				investigate_log("was set to [release_pressure] kPa by [key_name(usr)].", INVESTIGATE_ATMOS)
		if("valve")
			var/logmsg
			valve_open = !valve_open
			if(valve_open)
				logmsg = "Valve was <b>opened</b> by [key_name(usr)], starting a transfer into \the [holding || "air"].<br>"
				if(!holding)
					var/list/danger = list()
					for(var/id in air_contents.get_gases())
						if(!(GLOB.gas_data.flags[id] & GAS_FLAG_DANGEROUS))
							continue
						if(air_contents.get_moles(id) > (GLOB.gas_data.visibility[id] || MOLES_GAS_VISIBLE)) //if moles_visible is undefined, default to default visibility
							danger[GLOB.gas_data.names[id]] = air_contents.get_moles(id) //ex. "plasma" = 20

					if(danger.len)
						message_admins("[ADMIN_LOOKUPFLW(usr)] opened a canister that contains the following: [ADMIN_JMP(src)]")
						log_admin("[key_name(usr)] opened a canister that contains the following at [COORD(src)]:")
						for(var/name in danger)
							var/msg = "[name]: [danger[name]] moles."
							log_admin(msg)
							message_admins(msg)
			else
				logmsg = "Valve was <b>closed</b> by [key_name(usr)], stopping the transfer into \the [holding || "air"].<br>"
			investigate_log(logmsg, "atmos")
			release_log += logmsg
			. = TRUE
		if("timer")
			var/change = params["change"]
			switch(change)
				if("reset")
					timer_set = default_timer_set
				if("decrease")
					timer_set = max(minimum_timer_set, timer_set - 10)
				if("increase")
					timer_set = min(maximum_timer_set, timer_set + 10)
				if("input")
					var/user_input = input(usr, "Set time to valve toggle.", name) as null|num
					if(!user_input)
						return
					var/N = text2num(user_input)
					if(!N)
						return
					timer_set = clamp(N,minimum_timer_set,maximum_timer_set)
					log_admin("[key_name(usr)] has activated a prototype valve timer")
					. = TRUE
				if("toggle_timer")
					set_active()
		if("eject")
			if(holding)
				if(valve_open)
					investigate_log("[key_name(usr)] removed the [holding], leaving the valve open and transferring into the <span class='boldannounce'>air</span><br>", INVESTIGATE_ATMOS)
				holding.forceMove(get_turf(src))
				holding = null
				. = TRUE
	update_icon()

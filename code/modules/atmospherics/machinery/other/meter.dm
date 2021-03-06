/obj/machinery/meter
	name = "gas flow meter"
	desc = "It measures something."
	icon = 'icons/obj/meter.dmi'
	icon_state = "meterX"
	var/atom/target = null
	anchored = TRUE
	power_channel = ENVIRON
	var/frequency = 0
	var/id_tag
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 4
	max_integrity = 150
	armor = list(melee = 0, bullet = 0, laser = 0, energy = 100, bomb = 0, bio = 100, rad = 100, fire = 40, acid = 0)
	var/target_layer = PIPING_LAYER_DEFAULT

/obj/machinery/meter/Destroy()
	SSair.atmos_machinery -= src
	target = null
	return ..()

/obj/machinery/meter/Initialize(mapload, new_piping_layer)
	if(!isnull(new_piping_layer))
		target_layer = new_piping_layer
	SSair.atmos_machinery += src
	if(!target)
		reattach_to_layer()

	switch(target_layer)
		if (PIPING_LAYER_MIN)
			pixel_x = -6
			pixel_y = -6
		if (PIPING_LAYER_DEFAULT)
			pixel_x = 0
			pixel_y = 0
		if (PIPING_LAYER_MAX)
			pixel_x = 6
			pixel_y = 6

	return ..()

/obj/machinery/meter/proc/reattach_to_layer()
	for(var/obj/machinery/atmospherics/pipe/pipe in loc)
		if(pipe.piping_layer == target_layer)
			target = pipe
			setAttachLayer(pipe.piping_layer)
			break

/obj/machinery/meter/proc/setAttachLayer(var/new_layer)
	target_layer = new_layer

/obj/machinery/meter/process_atmos()
	if(!target)
		icon_state = "meterX"
		return 0

	if(stat & (BROKEN|NOPOWER))
		icon_state = "meter0"
		return 0

	use_power(5)

	var/datum/gas_mixture/environment = target.return_air()

	cut_overlays()

	if(!environment)
		icon_state = "meterX"
		return 0

	var/env_pressure = environment.return_pressure()
	if(env_pressure <= 0.15*ONE_ATMOSPHERE)
		icon_state = "meter0"
	else if(env_pressure <= 1.8*ONE_ATMOSPHERE)
		var/val = round(env_pressure/(ONE_ATMOSPHERE*0.3) + 0.5)
		icon_state = "meter1_[val]"
	else if(env_pressure <= 30*ONE_ATMOSPHERE)
		var/val = round(env_pressure/(ONE_ATMOSPHERE*5)-0.35) + 1
		icon_state = "meter2_[val]"
	else if(env_pressure <= 59*ONE_ATMOSPHERE)
		var/val = round(env_pressure/(ONE_ATMOSPHERE*5) - 6) + 1
		icon_state = "meter3_[val]"
	else
		icon_state = "meter4"


	var/env_temp = environment.return_temperature()

	if (env_temp < 273.2)
		add_overlay("cold")
	else if(env_temp < 360)
		add_overlay("normal")
	else
		add_overlay("hot")

	if(frequency)
		var/datum/radio_frequency/radio_connection = SSradio.return_frequency(frequency)

		if(!radio_connection)
			return

		var/datum/signal/signal = new
		signal.source = src
		signal.transmission_method = 1
		signal.data = list(
			"id_tag" = id_tag,
			"device" = "AM",
			"pressure" = round(env_pressure),
			"sigtype" = "status"
		)
		radio_connection.post_signal(src, signal)

/obj/machinery/meter/proc/status()
	var/t = ""
	if (target)
		var/datum/gas_mixture/environment = target.return_air()
		if(environment)
			t += "The pressure gauge reads [round(environment.return_pressure(), 0.01)] kPa; [round(environment.return_temperature(),0.01)] K ([round(environment.return_temperature()-T0C,0.01)]&deg;C)"
		else
			t += "The sensor error light is blinking."
	else
		t += "The connect error light is blinking."
	return t

/obj/machinery/meter/examine(mob/user)
	..()
	to_chat(user, status())


/obj/machinery/meter/attackby(obj/item/W, mob/user, params)
	if (istype(W, /obj/item/wrench))
		playsound(src, W.usesound, 50, 1)
		to_chat(user, "<span class='notice'>You begin to unfasten \the [src]...</span>")
		if (do_after(user, 40*W.toolspeed, target = src))
			user.visible_message( \
				"[user] unfastens \the [src].", \
				"<span class='notice'>You unfasten \the [src].</span>", \
				"<span class='italics'>You hear ratchet.</span>")
			new /obj/item/pipe_meter(loc)
			qdel(src)
	else
		return ..()

/obj/machinery/meter/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/meter/attack_paw(mob/user)
	return attack_hand(user)

/obj/machinery/meter/attack_hand(mob/user)

	if(stat & (NOPOWER|BROKEN))
		return 1
	else
		to_chat(usr, status())
		return 1

/obj/machinery/meter/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		new /obj/item/pipe_meter(loc)
		qdel(src)

// TURF METER - REPORTS A TILE'S AIR CONTENTS
//	why are you yelling?
/obj/machinery/meter/turf

/obj/machinery/meter/turf/Initialize()
	..()
	target = loc

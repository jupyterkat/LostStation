
// Drill, Diamond drill, Mining scanner


/obj/item/mecha_parts/mecha_equipment/drill
	name = "exosuit drill"
	desc = "Equipment for engineering and combat exosuits. This is the drill that'll pierce the heavens!"
	icon_state = "mecha_drill"
	equip_cooldown = 30
	energy_drain = 10
	force = 15

/obj/item/mecha_parts/mecha_equipment/drill/action(atom/target)
	if(!action_checks(target))
		return
	if(isspaceturf(target))
		return
	if(isobj(target))
		var/obj/target_obj = target
		if(target_obj.resistance_flags & UNACIDABLE)
			return
	target.visible_message("<span class='warning'>[chassis] starts to drill [target].</span>", \
					"<span class='userdanger'>[chassis] starts to drill [target]...</span>", \
					 "<span class='italics'>You hear drilling.</span>")

	if(do_after_cooldown(target))
		if(isturf(target))
			var/turf/T = target
			T.drill_act(src)
		else
			log_message("Drilled through [target]")
			if(isliving(target))
				if(istype(src , /obj/item/mecha_parts/mecha_equipment/drill/diamonddrill))
					drill_mob(target, chassis.occupant, 120)
				else
					drill_mob(target, chassis.occupant)
			else
				target.ex_act(EXPLODE_HEAVY)

/turf/proc/drill_act(obj/item/mecha_parts/mecha_equipment/drill/drill)
	return

/turf/closed/wall/r_wall/drill_act(obj/item/mecha_parts/mecha_equipment/drill/drill)
	if(istype(drill, /obj/item/mecha_parts/mecha_equipment/drill/diamonddrill))
		if(drill.do_after_cooldown(src))//To slow down how fast mechs can drill through the station
			drill.log_message("Drilled through [src]")
			ex_act(EXPLODE_LIGHT)
	else
		drill.occupant_message("<span class='danger'>[src] is too durable to drill through.</span>")

/turf/closed/mineral/drill_act(obj/item/mecha_parts/mecha_equipment/drill/drill)
	for(var/turf/closed/mineral/M in range(drill.chassis,1))
		if(get_dir(drill.chassis,M)&drill.chassis.dir)
			M.gets_drilled()
	drill.log_message("Drilled through [src]")
	drill.move_ores()

/turf/open/floor/plating/asteroid/drill_act(obj/item/mecha_parts/mecha_equipment/drill/drill)
	for(var/turf/open/floor/plating/asteroid/M in range(1, drill.chassis))
		if(get_dir(drill.chassis,M)&drill.chassis.dir)
			for(var/I in GetComponents(/datum/component/archaeology))
				var/datum/component/archaeology/archy = I
				archy.gets_dug()
	drill.log_message("Drilled through [src]")
	drill.move_ores()


/obj/item/mecha_parts/mecha_equipment/drill/proc/move_ores()
	if(locate(/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp) in chassis.equipment && istype(chassis, /obj/mecha/working/ripley))
		var/obj/mecha/working/ripley/R = chassis //we could assume that it's a ripley because it has a clamp, but that's ~unsafe~ and ~bad practice~
		R.collect_ore()

/obj/item/mecha_parts/mecha_equipment/drill/can_attach(obj/mecha/M as obj)
	if(..())
		if(istype(M, /obj/mecha/working) || istype(M, /obj/mecha/combat))
			return 1
	return 0

/obj/item/mecha_parts/mecha_equipment/drill/proc/drill_mob(mob/living/target, mob/user, var/drill_damage=80)
	target.visible_message("<span class='danger'>[chassis] drills [target] with [src].</span>", \
						"<span class='userdanger'>[chassis] drills [target] with [src].</span>")
	add_logs(user, target, "attacked", "[name]", "(INTENT: [uppertext(user.a_intent)]) (DAMTYPE: [uppertext(damtype)])")
	if(target.stat == STAT_DEAD)
		if(target.butcher_results)
			target.harvest(chassis)//Butcher the mob with our drill.
		else
			target.gib()
	else
		target.take_bodypart_damage(drill_damage)

	if(target)
		target.Unconscious(200)
		target.updatehealth()


/obj/item/mecha_parts/mecha_equipment/drill/diamonddrill
	name = "diamond-tipped exosuit drill"
	desc = "Equipment for engineering and combat exosuits. This is an upgraded version of the drill that'll pierce the heavens!"
	icon_state = "mecha_diamond_drill"
	origin_tech = "materials=4;engineering=4"
	equip_cooldown = 20
	force = 15


/obj/item/mecha_parts/mecha_equipment/mining_scanner
	name = "exosuit mining scanner"
	desc = "Equipment for engineering and combat exosuits. It will automatically check surrounding rock for useful minerals."
	icon_state = "mecha_analyzer"
	selectable = 0
	equip_cooldown = 30
	var/scanning_time = 0

/obj/item/mecha_parts/mecha_equipment/mining_scanner/New()
	..()
	START_PROCESSING(SSobj, src)

/obj/item/mecha_parts/mecha_equipment/mining_scanner/process()
	if(!loc)
		STOP_PROCESSING(SSobj, src)
		qdel(src)
	if(istype(loc, /obj/mecha/working) && scanning_time <= world.time)
		var/obj/mecha/working/mecha = loc
		if(!mecha.occupant)
			return
		scanning_time = world.time + equip_cooldown
		mineral_scan_pulse(get_turf(src))

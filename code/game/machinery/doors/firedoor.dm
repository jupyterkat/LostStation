#define CONSTRUCTION_COMPLETE 0 //No construction done - functioning as normal
#define CONSTRUCTION_PANEL_OPEN 1 //Maintenance panel is open, still functioning
#define CONSTRUCTION_WIRES_EXPOSED 2 //Cover plate is removed, wires are available
#define CONSTRUCTION_GUTTED 3 //Wires are removed, circuit ready to remove
#define CONSTRUCTION_NOCIRCUIT 4 //Circuit board removed, can safely weld apart

#define RECLOSE_DELAY 1 SECONDS // How long until a firelock tries to shut itself if it's blocking a vacuum.

/obj/machinery/door/firedoor
	name = "firelock"
	desc = "Apply crowbar."
	icon = 'icons/obj/doors/Doorfireglass.dmi'
	icon_state = "door_open"
	opacity = 0
	density = FALSE
	max_integrity = 300
	resistance_flags = FIRE_PROOF
	heat_proof = TRUE
	glass = TRUE
	var/nextstate = null
	sub_door = TRUE
	explosion_block = 1
	safe = FALSE
	closingLayer = CLOSED_FIREDOOR_LAYER
	assemblytype = /obj/structure/firelock_frame
	armor = list(melee = 30, bullet = 30, laser = 20, energy = 20, bomb = 10, bio = 100, rad = 100, fire = 95, acid = 70)
	var/boltslocked = TRUE
	var/list/affecting_areas
	var/emergency_close_timer = 0

/obj/machinery/door/firedoor/Initialize()
	. = ..()
	CalculateAffectingAreas()

/obj/machinery/door/firedoor/examine(mob/user)
	..()
	if(!density)
		to_chat(user, "<span class='notice'>It is open, but could be <b>pried</b> closed.</span>")
	else
		if(!welded)
			to_chat(user, "<span class='notice'>It is closed, but could be <i>pried</i> open. Deconstruction would require it to be <b>welded</b> shut.</span>")
		else
			if(boltslocked)
				to_chat(user, "<span class='notice'>It is <i>welded</i> shut. The floor bolt have been locked by <b>screws</b>.</span>")
			else
				to_chat(user, "<span class='notice'>The bolt locks have been <i>unscrewed</i>, but the bolts themselves are still <b>wrenched</b> to the floor.</span>")

/obj/machinery/door/firedoor/proc/CalculateAffectingAreas()
	remove_from_areas()
	affecting_areas = get_adjacent_open_areas(src) | get_area(src)
	for(var/I in affecting_areas)
		var/area/A = I
		LAZYADD(A.firedoors, src)

/obj/machinery/door/firedoor/closed
	icon_state = "door_closed"
	opacity = TRUE
	density = TRUE

//see also turf/AfterChange for adjacency shennanigans

/obj/machinery/door/firedoor/proc/remove_from_areas()
	if(affecting_areas)
		for(var/I in affecting_areas)
			var/area/A = I
			LAZYREMOVE(A.firedoors, src)

/obj/machinery/door/firedoor/Destroy()
	remove_from_areas()
	affecting_areas.Cut()
	return ..()
	
/obj/machinery/door/firedoor/CollidedWith(atom/movable/AM)
	if(panel_open || operating || welded || (stat & NOPOWER))
		return
	if(ismob(AM))
		var/mob/user = AM
		if(allow_hand_open(user))
			add_fingerprint(user)
			open()
			return TRUE
	if(istype(AM, /obj/mecha))
		var/obj/mecha/M = AM
		if(M.occupant && allow_hand_open(M.occupant))
			open()
			return TRUE
	return FALSE

/obj/machinery/door/firedoor/proc/allow_hand_open(mob/user)
	var/area/A = get_area(src)
	if(A && A.fire)
		return FALSE
	return !is_holding_pressure()

/obj/machinery/door/firedoor/power_change()
	if(powered(power_channel))
		stat &= ~NOPOWER
		latetoggle()
	else
		stat |= NOPOWER

/obj/machinery/door/firedoor/attack_hand(mob/user)

	if (!welded && !operating)
		if (stat & NOPOWER)
			user.visible_message("[user] tries to open \the [src] manually.",
						 "You operate the manual lever on \the [src].")
			if (!do_after(user, 30, TRUE, src))
				return FALSE
		else if (density && !allow_hand_open(user))
			return FALSE

		add_fingerprint(user)
		if(density)
			emergency_close_timer = world.time + RECLOSE_DELAY // prevent it from instaclosing again if in space
			open()
		else
			close()
		return TRUE

	if(operating || !density)
		return
	
	user.changeNext_move(CLICK_CD_MELEE)

	user.visible_message("[user] bangs on \the [src].",
						 "You bang on \the [src].")
	playsound(loc, 'sound/effects/glassknock.ogg', 10, FALSE, frequency = 32000)

/obj/machinery/door/firedoor/attackby(obj/item/C, mob/user, params)
	add_fingerprint(user)
	if(operating)
		return

	if(welded)
		if(istype(C, /obj/item/wrench))
			if(boltslocked)
				to_chat(user, "<span class='notice'>There are screws locking the bolts in place!</span>")
				return
			playsound(get_turf(src), C.usesound, 50, 1)
			user.visible_message("<span class='notice'>[user] starts undoing [src]'s bolts...</span>", \
								 "<span class='notice'>You start unfastening [src]'s floor bolts...</span>")
			if(!do_after(user, 50*C.toolspeed, target = src))
				return
			playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
			user.visible_message("<span class='notice'>[user] unfastens [src]'s bolts.</span>", \
								 "<span class='notice'>You undo [src]'s floor bolts.</span>")
			deconstruct(TRUE)
			return
		if(istype(C, /obj/item/screwdriver))
			user.visible_message("<span class='notice'>[user] [boltslocked ? "unlocks" : "locks"] [src]'s bolts.</span>", \
								 "<span class='notice'>You [boltslocked ? "unlock" : "lock"] [src]'s floor bolts.</span>")
			playsound(get_turf(src), C.usesound, 50, 1)
			boltslocked = !boltslocked
			return

	return ..()

/obj/machinery/door/firedoor/try_to_activate_door(mob/user)
	return

/obj/machinery/door/firedoor/try_to_weld(obj/item/weldingtool/W, mob/user)
	if(W.remove_fuel(0, user))
		playsound(get_turf(src), W.usesound, 50, 1)
		user.visible_message("<span class='notice'>[user] starts [welded ? "unwelding" : "welding"] [src].</span>", "<span class='notice'>You start welding [src].</span>")
		if(do_after(user, 40*W.toolspeed, 1, target=src))
			playsound(get_turf(src), W.usesound, 50, 1)
			welded = !welded
			to_chat(user, "<span class='danger'>[user] [welded?"welds":"unwelds"] [src].</span>", "<span class='notice'>You [welded ? "weld" : "unweld"] [src].</span>")
			update_icon()

/obj/machinery/door/firedoor/try_to_crowbar(obj/item/I, mob/user)
	if(welded || operating)
		return

	if(density)
		if(is_holding_pressure())
			// tell the user that this is a bad idea, and have a do_after as well
			to_chat(user, "<span class='warning'>As you begin crowbarring \the [src] a gush of air blows in your face... maybe you should reconsider?</span>")
			if(!do_after(user, 10, TRUE, src)) // give them a few seconds to reconsider their decision.
				return
			// since we have high-pressure-ness, close all other firedoors on the tile
			whack_a_mole()
		if(welded || operating || !density)
			return // in case things changed during our do_after
		emergency_close_timer = world.time + RECLOSE_DELAY // prevent it from instaclosing again if in space
		open()
	else
		close()
	
/obj/machinery/door/proc/is_holding_pressure()
	var/turf/open/T = loc
	if(!T)
		return FALSE
	if(!density)
		return FALSE
	// alrighty now we check for how much pressure we're holding back
	var/min_moles = T.air.total_moles()
	var/max_moles = min_moles
	// okay this is a bit hacky. First, we set density to 0 and recalculate our adjacent turfs
	density = FALSE
	T.CalculateAdjacentTurfs()
	// then we use those adjacent turfs to figure out what the difference between the lowest and highest pressures we'd be holding is
	for(var/turf/open/T2 in T.atmos_adjacent_turfs)
		if((flags_1 & ON_BORDER_1) && get_dir(src, T2) != dir)
			continue
		var/moles = T2.air.total_moles()
		if(moles < min_moles)
			min_moles = moles
		if(moles > max_moles)
			max_moles = moles
	density = TRUE
	T.CalculateAdjacentTurfs() // alright lets put it back
	return max_moles - min_moles > 20

/obj/machinery/door/firedoor/attack_ai(mob/user)
	add_fingerprint(user)
	if(welded || operating || stat & NOPOWER)
		return
	if(density)
		open()
	else
		close()

/obj/machinery/door/firedoor/attack_alien(mob/user)
	add_fingerprint(user)
	if(welded)
		to_chat(user, "<span class='warning'>[src] refuses to budge!</span>")
		return
	open()

/obj/machinery/door/firedoor/do_animate(animation)
	switch(animation)
		if("opening")
			flick("door_opening", src)
		if("closing")
			flick("door_closing", src)

/obj/machinery/door/firedoor/update_icon()
	cut_overlays()
	if(density)
		icon_state = "door_closed"
		if(welded)
			add_overlay("welded")
	else
		icon_state = "door_open"
		if(welded)
			add_overlay("welded_open")

/obj/machinery/door/firedoor/open()
	. = ..()
	latetoggle()

/obj/machinery/door/firedoor/close()
	. = ..()
	latetoggle()

/obj/machinery/door/firedoor/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/obj/structure/firelock_frame/F = new assemblytype(get_turf(src))
		if(disassembled)
			F.constructionStep = CONSTRUCTION_PANEL_OPEN
		else
			F.constructionStep = CONSTRUCTION_WIRES_EXPOSED
			F.obj_integrity = F.max_integrity * 0.5
		F.update_icon()
	qdel(src)


/obj/machinery/door/firedoor/proc/latetoggle()
	if(operating || stat & NOPOWER || !nextstate)
		return
	switch(nextstate)
		if(FIREDOOR_OPEN)
			nextstate = null
			open()
		if(FIREDOOR_CLOSED)
			nextstate = null
			close()

/obj/machinery/door/firedoor/proc/whack_a_mole(reconsider_immediately = FALSE)
	set waitfor = 0
	for(var/cdir in GLOB.cardinals)
		if((flags_1 & ON_BORDER_1) && cdir != dir)
			continue
		whack_a_mole_part(get_step(src, cdir), reconsider_immediately)
	if(flags_1 & ON_BORDER_1)
		whack_a_mole_part(get_turf(src), reconsider_immediately)

/obj/machinery/door/firedoor/proc/whack_a_mole_part(turf/start_point, reconsider_immediately)
	set waitfor = 0
	var/list/doors_to_close = list()
	var/list/turfs = list()
	turfs[start_point] = 1
	for(var/i = 1; (i <= turfs.len && i <= 11); i++) // check up to 11 turfs.
		var/turf/open/T = turfs[i]
		if(istype(T, /turf/open/space))
			return -1
		for(var/T2 in T.atmos_adjacent_turfs)
			if(turfs[T2])
				continue
			var/is_cut_by_unopen_door = FALSE
			for(var/obj/machinery/door/firedoor/FD in T2)
				if((FD.flags_1 & ON_BORDER_1) && get_dir(T2, T) != FD.dir)
					continue
				if(FD.operating || FD == src || FD.welded || FD.density)
					continue
				doors_to_close += FD
				is_cut_by_unopen_door = TRUE

			for(var/obj/machinery/door/firedoor/FD in T)
				if((FD.flags_1 & ON_BORDER_1) && get_dir(T, T2) != FD.dir)
					continue
				if(FD.operating || FD == src || FD.welded || FD.density)
					continue
				doors_to_close += FD
				is_cut_by_unopen_door= TRUE
			if(!is_cut_by_unopen_door)
				turfs[T2] = 1
	if(turfs.len > 10)
		return // too big, don't bother
	for(var/obj/machinery/door/firedoor/FD in doors_to_close)
		FD.emergency_pressure_stop(FALSE)
		if(reconsider_immediately)
			var/turf/open/T = FD.loc
			if(istype(T))
				T.CalculateAdjacentTurfs()

/obj/machinery/door/firedoor/proc/emergency_pressure_stop(consider_timer = TRUE)
	if(density || operating || welded)
		return
	if(world.time >= emergency_close_timer || !consider_timer)
		emergency_pressure_close()

/obj/machinery/door/firedoor/proc/emergency_pressure_close()
	if(density)
		return
	if(operating || welded)
		return

	density = TRUE
	air_update_turf(1)
	update_icon()
	if(visible && !glass)
		set_opacity(1)
	update_freelook_sight()
	if(safe)
		CheckForMobs()
	else if(!(flags_1 & ON_BORDER_1))
		crush()
	latetoggle()

/obj/machinery/door/firedoor/border_only
	icon = 'icons/obj/doors/edge_Doorfire.dmi'
	flags_1 = ON_BORDER_1
	CanAtmosPass = ATMOS_PASS_PROC

/obj/machinery/door/firedoor/border_only/CanPass(atom/movable/mover, turf/target)
	if(istype(mover) && mover.checkpass(PASSGLASS))
		return 1
	if(get_dir(loc, target) == dir) //Make sure looking at appropriate border
		return !density
	else
		return 1

/obj/machinery/door/firedoor/border_only/CheckExit(atom/movable/mover as mob|obj, turf/target)
	if(istype(mover) && mover.checkpass(PASSGLASS))
		return 1
	if(get_dir(loc, target) == dir)
		return !density
	else
		return 1

/obj/machinery/door/firedoor/border_only/CanAtmosPass(turf/T)
	if(get_dir(loc, T) == dir)
		return !density
	else
		return 1

/obj/machinery/door/firedoor/border_only/emergency_pressure_close()
	if(density)
		return TRUE
	if(operating || welded)
		return
	var/turf/T1 = get_turf(src)
	var/turf/T2 = get_step(T1, dir)
	for(var/mob/living/M in T1)
		if(M.stat == STAT_CONSCIOUS && M.pulling && M.pulling.loc == T2 && !M.pulling.anchored)
			var/mob/living/M2 = M.pulling
			if(!istype(M2) || !M2.buckled || !M2.buckled.buckle_prevents_pull)
				to_chat(M, "<span class='notice'>You pull [M.pulling] through [src] right as it closes.</span>")
				M.pulling.forceMove(T1)
				M.start_pulling(M2)
	for(var/mob/living/M in T2)
		if(M.stat == STAT_CONSCIOUS && M.pulling && M.pulling.loc == T1 && !M.pulling.anchored)
			var/mob/living/M2 = M.pulling
			if(!istype(M2) || !M2.buckled || !M2.buckled.buckle_prevents_pull)
				to_chat(M, "<span class='notice'>You pull [M.pulling] through [src] right as it closes.</span>")
				M.pulling.forceMove(T2)
				M.start_pulling(M2)
	return ..()

/obj/machinery/door/firedoor/border_only/allow_hand_open(mob/user)
	var/area/A = get_area(src)
	if((!A || !A.fire) && !is_holding_pressure())
		return TRUE
	whack_a_mole(TRUE) // WOOP WOOP SIDE EFFECTS
	var/turf/T = loc
	var/turf/T2 = get_step(T, dir)
	if(!T || !T2)
		return
	var/status1 = check_door_side(T)
	var/status2 = check_door_side(T2)
	if((status1 == 1 && status2 == -1) || (status1 == -1 && status2 == 1))
		to_chat(user, "<span class='warning'>Access denied. Try closing another firedoor to minimize decompression, or using a crowbar.</span>")
		return FALSE
	return TRUE

/obj/machinery/door/firedoor/border_only/proc/check_door_side(turf/open/start_point)
	var/list/turfs = list()
	turfs[start_point] = 1
	for(var/i = 1; (i <= turfs.len && i <= 11); i++) // check up to 11 turfs.
		var/turf/open/T = turfs[i]
		if(istype(T, /turf/open/space))
			return -1
		for(var/T2 in T.atmos_adjacent_turfs)
			turfs[T2] = 1
	if(turfs.len <= 10)
		return 0 // not big enough to matter
	return start_point.air.return_pressure() < 20 ? -1 : 1

/obj/machinery/door/firedoor/heavy
	name = "heavy firelock"
	icon = 'icons/obj/doors/Doorfire.dmi'
	glass = FALSE
	explosion_block = 2
	assemblytype = /obj/structure/firelock_frame/heavy
	max_integrity = 550


/obj/item/electronics/firelock
	name = "firelock circuitry"
	desc = "A circuit board used in construction of firelocks."
	icon_state = "mainboard"

/obj/structure/firelock_frame
	name = "firelock frame"
	desc = "A partially completed firelock."
	icon = 'icons/obj/doors/Doorfire.dmi'
	icon_state = "frame1"
	anchored = FALSE
	density = TRUE
	var/constructionStep = CONSTRUCTION_NOCIRCUIT
	var/reinforced = 0

/obj/structure/firelock_frame/examine(mob/user)
	..()
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			to_chat(user, "<span class='notice'>It is <i>unbolted</i> from the floor. A small <b>loosely connected</b> metal plate is covering the wires.</span>")
			if(!reinforced)
				to_chat(user, "<span class='notice'>It could be reinforced with plasteel.</span>")
		if(CONSTRUCTION_WIRES_EXPOSED)
			to_chat(user, "<span class='notice'>The maintenance plate has been <i>pried away</i>, and <b>wires</b> are trailing.</span>")
		if(CONSTRUCTION_GUTTED)
			to_chat(user, "<span class='notice'>The maintenance panel is missing <i>wires</i> and the circuit board is <b>loosely connected</b>.</span>")
		if(CONSTRUCTION_NOCIRCUIT)
			to_chat(user, "<span class='notice'>There are no <i>firelock electronics</i> in the frame. The frame could be <b>cut</b> apart.</span>")

/obj/structure/firelock_frame/update_icon()
	..()
	icon_state = "frame[constructionStep]"

/obj/structure/firelock_frame/attackby(obj/item/C, mob/user)
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			if(istype(C, /obj/item/crowbar))
				playsound(get_turf(src), C.usesound, 50, 1)
				user.visible_message("<span class='notice'>[user] starts prying something out from [src]...</span>", \
									 "<span class='notice'>You begin prying out the wire cover...</span>")
				if(!do_after(user, 50*C.toolspeed, target = src))
					return
				if(constructionStep != CONSTRUCTION_PANEL_OPEN)
					return
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				user.visible_message("<span class='notice'>[user] pries out a metal plate from [src], exposing the wires.</span>", \
									 "<span class='notice'>You remove the cover plate from [src], exposing the wires.</span>")
				constructionStep = CONSTRUCTION_WIRES_EXPOSED
				update_icon()
				return
			if(istype(C, /obj/item/wrench))
				if(locate(/obj/machinery/door/firedoor) in get_turf(src))
					to_chat(user, "<span class='warning'>There's already a firelock there.</span>")
					return
				playsound(get_turf(src), C.usesound, 50, 1)
				user.visible_message("<span class='notice'>[user] starts bolting down [src]...</span>", \
									 "<span class='notice'>You begin bolting [src]...</span>")
				if(!do_after(user, 30*C.toolspeed, target = src))
					return
				if(locate(/obj/machinery/door/firedoor) in get_turf(src))
					return
				user.visible_message("<span class='notice'>[user] finishes the firelock.</span>", \
									 "<span class='notice'>You finish the firelock.</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(reinforced)
					new /obj/machinery/door/firedoor/heavy(get_turf(src))
				else
					new /obj/machinery/door/firedoor(get_turf(src))
				qdel(src)
				return
			if(istype(C, /obj/item/stack/sheet/plasteel))
				var/obj/item/stack/sheet/plasteel/P = C
				if(reinforced)
					to_chat(user, "<span class='warning'>[src] is already reinforced.</span>")
					return
				if(P.get_amount() < 2)
					to_chat(user, "<span class='warning'>You need more plasteel to reinforce [src].</span>")
					return
				user.visible_message("<span class='notice'>[user] begins reinforcing [src]...</span>", \
									 "<span class='notice'>You begin reinforcing [src]...</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(do_after(user, 60, target = src))
					if(constructionStep != CONSTRUCTION_PANEL_OPEN || reinforced || P.get_amount() < 2 || !P)
						return
					user.visible_message("<span class='notice'>[user] reinforces [src].</span>", \
										 "<span class='notice'>You reinforce [src].</span>")
					playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
					P.use(2)
					reinforced = 1
				return

		if(CONSTRUCTION_WIRES_EXPOSED)
			if(istype(C, /obj/item/wirecutters))
				playsound(get_turf(src), C.usesound, 50, 1)
				user.visible_message("<span class='notice'>[user] starts cutting the wires from [src]...</span>", \
									 "<span class='notice'>You begin removing [src]'s wires...</span>")
				if(!do_after(user, 60*C.toolspeed, target = src))
					return
				if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
					return
				user.visible_message("<span class='notice'>[user] removes the wires from [src].</span>", \
									 "<span class='notice'>You remove the wiring from [src], exposing the circuit board.</span>")
				new/obj/item/stack/cable_coil(get_turf(src), 5)
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
			if(istype(C, /obj/item/crowbar))
				playsound(get_turf(src), C.usesound, 50, 1)
				user.visible_message("<span class='notice'>[user] starts prying a metal plate into [src]...</span>", \
									 "<span class='notice'>You begin prying the cover plate back onto [src]...</span>")
				if(!do_after(user, 80*C.toolspeed, target = src))
					return
				if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
					return
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				user.visible_message("<span class='notice'>[user] pries the metal plate into [src].</span>", \
									 "<span class='notice'>You pry [src]'s cover plate into place, hiding the wires.</span>")
				constructionStep = CONSTRUCTION_PANEL_OPEN
				update_icon()
				return
		if(CONSTRUCTION_GUTTED)
			if(istype(C, /obj/item/crowbar))
				user.visible_message("<span class='notice'>[user] begins removing the circuit board from [src]...</span>", \
									 "<span class='notice'>You begin prying out the circuit board from [src]...</span>")
				playsound(get_turf(src), C.usesound, 50, 1)
				if(!do_after(user, 50*C.toolspeed, target = src))
					return
				if(constructionStep != CONSTRUCTION_GUTTED)
					return
				user.visible_message("<span class='notice'>[user] removes [src]'s circuit board.</span>", \
									 "<span class='notice'>You remove the circuit board from [src].</span>")
				new /obj/item/electronics/firelock(get_turf(src))
				playsound(get_turf(src), C.usesound, 50, 1)
				constructionStep = CONSTRUCTION_NOCIRCUIT
				update_icon()
				return
			if(istype(C, /obj/item/stack/cable_coil))
				var/obj/item/stack/cable_coil/B = C
				if(B.get_amount() < 5)
					to_chat(user, "<span class='warning'>You need more wires to add wiring to [src].</span>")
					return
				user.visible_message("<span class='notice'>[user] begins wiring [src]...</span>", \
									 "<span class='notice'>You begin adding wires to [src]...</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(do_after(user, 60, target = src))
					if(constructionStep != CONSTRUCTION_GUTTED || B.get_amount() < 5 || !B)
						return
					user.visible_message("<span class='notice'>[user] adds wires to [src].</span>", \
										 "<span class='notice'>You wire [src].</span>")
					playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
					B.use(5)
					constructionStep = CONSTRUCTION_WIRES_EXPOSED
					update_icon()
				return
		if(CONSTRUCTION_NOCIRCUIT)
			if(istype(C, /obj/item/weldingtool))
				var/obj/item/weldingtool/W = C
				if(W.remove_fuel(1,user))
					playsound(get_turf(src), W.usesound, 50, 1)
					user.visible_message("<span class='notice'>[user] begins cutting apart [src]'s frame...</span>", \
										 "<span class='notice'>You begin slicing [src] apart...</span>")
					if(!do_after(user, 80*C.toolspeed, target = src))
						return
					if(constructionStep != CONSTRUCTION_NOCIRCUIT)
						return
					user.visible_message("<span class='notice'>[user] cuts apart [src]!</span>", \
										 "<span class='notice'>You cut [src] into metal.</span>")
					playsound(get_turf(src), 'sound/items/welder2.ogg', 50, 1)
					var/turf/T = get_turf(src)
					new /obj/item/stack/sheet/metal(T, 3)
					if(reinforced)
						new /obj/item/stack/sheet/plasteel(T, 2)
					qdel(src)
				return
			if(istype(C, /obj/item/electronics/firelock))
				user.visible_message("<span class='notice'>[user] starts adding [C] to [src]...</span>", \
									 "<span class='notice'>You begin adding a circuit board to [src]...</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(!do_after(user, 40, target = src))
					return
				if(constructionStep != CONSTRUCTION_NOCIRCUIT)
					return
				user.drop_item()
				qdel(C)
				user.visible_message("<span class='notice'>[user] adds a circuit to [src].</span>", \
									 "<span class='notice'>You insert and secure [C].</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
	return ..()

/obj/structure/firelock_frame/heavy
	name = "heavy firelock frame"
	reinforced = 1

#undef CONSTRUCTION_COMPLETE
#undef CONSTRUCTION_PANEL_OPEN
#undef CONSTRUCTION_WIRES_EXPOSED
#undef CONSTRUCTION_GUTTED
#undef CONSTRUCTION_NOCIRCUIT

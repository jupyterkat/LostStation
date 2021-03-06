/mob/CanPass(atom/movable/mover, turf/target)
	if((mover.pass_flags & PASSMOB))
		return TRUE
	if(istype(mover, /obj/item/projectile) || mover.throwing)
		return (!density || lying)
	if(buckled == mover)
		return TRUE
	if(ismob(mover))
		if (mover in buckled_mobs)
			return TRUE
	return (!mover.density || !density || lying)


/client/verb/drop_item()
	set hidden = 1
	if(!iscyborg(mob) && mob.stat == STAT_CONSCIOUS)
		mob.dropItemToGround(mob.get_active_held_item())
	return

/client/proc/Move_object(direct)
	if(mob && mob.control_object)
		if(mob.control_object.density)
			step(mob.control_object,direct)
			if(!mob.control_object)
				return
			mob.control_object.setDir(direct)
		else
			mob.control_object.loc = get_step(mob.control_object,direct)
	return

#define MOVEMENT_DELAY_BUFFER 0.75
#define MOVEMENT_DELAY_BUFFER_DELTA 1.25

/client/Move(n, direct)
	if(world.time < move_delay) //do not move anything ahead of this check please
		return FALSE
	
	next_move_dir_add = 0
	next_move_dir_sub = 0
	var/old_move_delay = move_delay
	move_delay = world.time+world.tick_lag //this is here because Move() can now be called mutiple times per tick
	if(!mob || !mob.loc)
		return FALSE
	if(!n || !direct)
		return FALSE
	if(mob.notransform)
		return FALSE	//This is sota the goto stop mobs from moving var
	if(mob.control_object)
		return Move_object(direct)
	if(!isliving(mob))
		return mob.Move(n, direct)
	if(mob.stat == STAT_DEAD)
		mob.ghostize()
		return FALSE
	if(mob.force_moving)
		return FALSE

	var/mob/living/L = mob  //Already checked for isliving earlier
	if(L.incorporeal_move)	//Move though walls
		Process_Incorpmove(direct)
		return FALSE

	if(mob.remote_control)					//we're controlling something, our movement is relayed to it
		return mob.remote_control.relaymove(mob, direct)

	if(isAI(mob))
		return AIMove(n,direct,mob)

	if(Process_Grab()) //are we restrained by someone's grip?
		return

	if(mob.buckled)							//if we're buckled to something, tell it we moved.
		return mob.buckled.relaymove(mob, direct)

	if(!mob.canmove)
		return FALSE

	if(isobj(mob.loc) || ismob(mob.loc))	//Inside an object, tell it we moved
		var/atom/O = mob.loc
		return O.relaymove(mob, direct)

	if(!mob.Process_Spacemove(direct))
		return FALSE
	//We are now going to move
	var/add_delay = mob.movement_delay()
	if(old_move_delay + world.tick_lag > world.time)
		move_delay = old_move_delay
	else
		move_delay = world.time
	var/oldloc = mob.loc

	if(mob.confused)
		var/newdir = 0
		if(mob.confused > 40)
			newdir = pick(GLOB.alldirs)
		else if(prob(mob.confused * 1.5))
			newdir = angle2dir(dir2angle(direct) + pick(90, -90))
		else if(prob(mob.confused * 3))
			newdir = angle2dir(dir2angle(direct) + pick(45, -45))
		if(newdir)
			direct = newdir
			n = get_step(mob, direct)

	. = ..()

	if(mob.loc != oldloc)
		move_delay += add_delay
	if(.) // If mob is null here, we deserve the runtime
		if(mob.throwing)
			mob.throwing.finalize(FALSE)

	if(LAZYLEN(mob.user_movement_hooks))
		for(var/obj/O in mob.user_movement_hooks)
			O.intercept_user_move(direct, mob, n, oldloc)
	
	var/atom/movable/P = mob.pulling
	if(P && !ismob(P) && P.density)
		mob.dir = turn(mob.dir, 180)

/mob/Moved(oldLoc, dir, Forced = FALSE)
	. = ..()
	for(var/obj/O in contents)
		O.on_mob_move(dir, src, oldLoc, Forced)

/mob/setDir(newDir)
	. = ..()
	for(var/obj/O in contents)
		O.on_mob_turn(newDir, src)


///Process_Grab()
///Called by client/Move()
///Checks to see if you are being grabbed and if so attemps to break it
/client/proc/Process_Grab()
	if(mob.pulledby)
		if(mob.incapacitated(ignore_restraints = 1))
			move_delay = world.time + 10
			return TRUE
		else if(mob.restrained(ignore_grab = 1))
			move_delay = world.time + 10
			to_chat(src, "<span class='warning'>You're restrained! You can't move!</span>")
			return TRUE
		else
			return mob.resist_grab(1)

///Process_Incorpmove
///Called by client/Move()
///Allows mobs to run though walls
/client/proc/Process_Incorpmove(direct)
	var/turf/mobloc = get_turf(mob)
	if(!isliving(mob))
		return
	var/mob/living/L = mob
	switch(L.incorporeal_move)
		if(INCORPOREAL_MOVE_BASIC)
			var/T = get_step(L,direct)
			if(T)
				L.loc = T
			L.setDir(direct)
		if(INCORPOREAL_MOVE_SHADOW)
			if(prob(50))
				var/locx
				var/locy
				switch(direct)
					if(NORTH)
						locx = mobloc.x
						locy = (mobloc.y+2)
						if(locy>world.maxy)
							return
					if(SOUTH)
						locx = mobloc.x
						locy = (mobloc.y-2)
						if(locy<1)
							return
					if(EAST)
						locy = mobloc.y
						locx = (mobloc.x+2)
						if(locx>world.maxx)
							return
					if(WEST)
						locy = mobloc.y
						locx = (mobloc.x-2)
						if(locx<1)
							return
					else
						return
				var/target = locate(locx,locy,mobloc.z)
				if(target)
					L.loc = target
					var/limit = 2//For only two trailing shadows.
					for(var/turf/T in getline(mobloc, L.loc))
						new /obj/effect/temp_visual/dir_setting/ninja/shadow(T, L.dir)
						limit--
						if(limit<=0)
							break
			else
				new /obj/effect/temp_visual/dir_setting/ninja/shadow(mobloc, L.dir)
				var/T = get_step(L,direct)
				if(T)
					L.loc = T
			L.setDir(direct)
		if(INCORPOREAL_MOVE_JAUNT) //Incorporeal move, but blocked by holy-watered tiles and salt piles.
			var/turf/open/floor/stepTurf = get_step(L, direct)
			if(stepTurf)
				for(var/obj/effect/decal/cleanable/salt/S in stepTurf)
					to_chat(L, "<span class='warning'>[S] bars your passage!</span>")
					if(isrevenant(L))
						var/mob/living/simple_animal/revenant/R = L
						R.reveal(20)
						R.stun(20)
					return
				if(stepTurf.flags_1 & NOJAUNT_1)
					to_chat(L, "<span class='warning'>Holy energies block your path.</span>")
				else
					L.loc = get_step(L, direct)
			L.setDir(direct)
	return TRUE


///Process_Spacemove
///Called by /client/Move()
///For moving in space
///return TRUE for movement 0 for none
/mob/Process_Spacemove(movement_dir = 0)
	if(spacewalk || ..())
		return TRUE
	var/atom/movable/backup = get_spacemove_backup()
	if(backup)
		if(istype(backup) && movement_dir && !backup.anchored)
			if(backup.newtonian_move(turn(movement_dir, 180))) //You're pushing off something movable, so it moves
				to_chat(src, "<span class='info'>You push off of [backup] to propel yourself.</span>")
		return TRUE
	return FALSE

/mob/get_spacemove_backup()
	for(var/A in orange(1, get_turf(src)))
		if(isarea(A))
			continue
		else if(isturf(A))
			var/turf/turf = A
			if(isspaceturf(turf))
				continue
			if(!turf.density && !mob_negates_gravity())
				continue
			return A
		else
			var/atom/movable/AM = A
			if(AM == buckled)
				continue
			if(ismob(AM))
				var/mob/M = AM
				if(M.buckled)
					continue
			if(!AM.CanPass(src) || AM.density)
				if(AM.anchored)
					return AM
				if(pulling == AM)
					continue
				. = AM

/mob/proc/mob_has_gravity()
	return has_gravity()

/mob/proc/mob_negates_gravity()
	return FALSE

//moves the mob/object we're pulling
/mob/proc/Move_Pulled(atom/A)
	if(!pulling)
		return
	if(pulling.anchored || !pulling.Adjacent(src))
		stop_pulling()
		return
	if(isliving(pulling))
		var/mob/living/L = pulling
		if(L.buckled && L.buckled.buckle_prevents_pull) //if they're buckled to something that disallows pulling, prevent it
			stop_pulling()
			return
	if(A == loc && pulling.density)
		return
	if(!Process_Spacemove(get_dir(pulling.loc, A)))
		return
	step(pulling, get_dir(pulling.loc, A))


/mob/proc/slip(s_amount, w_amount, obj/O, lube)
	return

/mob/proc/update_gravity()
	return

//bodypart selection - Cyberboss
//8 toggles through head - eyes - mouth
//4: r-arm 5: chest 6: l-arm
//1: r-leg 2: groin 3: l-leg

/client/proc/check_has_body_select()
	return mob && mob.hud_used && mob.hud_used.zone_select && istype(mob.hud_used.zone_select, /obj/screen/zone_sel)

/client/verb/body_toggle_head()
	set name = "body-toggle-head"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/next_in_line
	switch(mob.zone_selected)
		if("head")
			next_in_line = "eyes"
		if("eyes")
			next_in_line = "mouth"
		else
			next_in_line = "head"

	var/obj/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone(next_in_line, mob)

/client/verb/body_r_arm()
	set name = "body-r-arm"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/obj/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone("r_arm", mob)

/client/verb/body_chest()
	set name = "body-chest"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/obj/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone("chest", mob)

/client/verb/body_l_arm()
	set name = "body-l-arm"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/obj/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone("l_arm", mob)

/client/verb/body_r_leg()
	set name = "body-r-leg"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/obj/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone("r_leg", mob)

/client/verb/body_groin()
	set name = "body-groin"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/obj/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone("groin", mob)

/client/verb/body_l_leg()
	set name = "body-l-leg"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/obj/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone("l_leg", mob)

/client/verb/toggle_walk_run()
	set name = "toggle-walk-run"
	set hidden = TRUE
	set instant = TRUE
	if(mob)
		mob.toggle_move_intent()

/mob/proc/toggle_move_intent()
	if(hud_used && hud_used.static_inventory)
		for(var/obj/screen/mov_intent/selector in hud_used.static_inventory)
			selector.toggle(src)
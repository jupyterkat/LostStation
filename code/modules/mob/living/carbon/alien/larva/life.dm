

/mob/living/carbon/alien/larva/Life()
	set invisibility = 0
	set background = BACKGROUND_ENABLED

	if (notransform)
		return
	if(..()) //not dead
		// GROW!
		if(amount_grown < max_grown)
			amount_grown++
			update_icons()


/mob/living/carbon/alien/larva/update_stat()
	if(status_flags & GODMODE)
		return
	if(stat != STAT_DEAD)
		if(health<= -maxHealth || !getorgan(/obj/item/organ/brain))
			death()
			return
		if(IsUnconscious() || IsSleeping() || getOxyLoss() > 50 || (status_flags & FAKEDEATH) || health <= HEALTH_THRESHOLD_CRIT)
			if(stat == STAT_CONSCIOUS)
				stat = STATS_UNCONSCIOUS
				blind_eyes(1)
				update_canmove()
		else
			if(stat == STATS_UNCONSCIOUS)
				stat = STAT_CONSCIOUS
				resting = 0
				adjust_blindness(-1)
				update_canmove()
	update_damage_hud()
	update_health_hud()

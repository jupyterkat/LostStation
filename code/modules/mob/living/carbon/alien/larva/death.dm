/mob/living/carbon/alien/larva/death(gibbed)
	if(stat == STAT_DEAD)
		return

	. = ..()

	update_icons()

/mob/living/carbon/alien/larva/spawn_gibs(with_bodyparts)
	if(with_bodyparts)
		new /obj/effect/gibspawner/larva(get_turf(src))
	else
		new /obj/effect/gibspawner/larvabodypartless(get_turf(src))

/mob/living/carbon/alien/larva/gib_animation()
	new /obj/effect/temp_visual/gib_animation(loc, "gibbed-l")

/mob/living/carbon/alien/larva/spawn_dust()
	new /obj/effect/decal/remains/xeno(loc)

/mob/living/carbon/alien/larva/dust_animation()
	new /obj/effect/temp_visual/dust_animation(loc, "dust-l")

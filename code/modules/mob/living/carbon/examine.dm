/mob/living/carbon/examine(mob/user)
	var/t_He = p_they(TRUE)
	var/t_His = p_their(TRUE)
	var/t_his = p_their()
	var/t_him = p_them()
	var/t_has = p_have()
	var/t_is = p_are()

	var/msg = "<span class='info'>*---------*\nThis is [icon2html(src, user)] \a <EM>[src]</EM>!\n"

	if (handcuffed)
		msg += "<span class='warning'>[t_He] [t_is] [icon2html(handcuffed, user)] handcuffed!</span>\n"
	if (head)
		msg += "[t_He] [t_is] wearing [icon2html(head, user)] \a [src.head] on [t_his] head. \n"
	if (wear_mask)
		msg += "[t_He] [t_is] wearing [icon2html(wear_mask, user)] \a [src.wear_mask] on [t_his] face.\n"
	if (wear_neck)
		msg += "[t_He] [t_is] wearing [icon2html(wear_neck, user)] \a [src.wear_neck] around [t_his] neck.\n"

	for(var/obj/item/I in held_items)
		if(!(I.flags_1 & ABSTRACT_1))
			if(I.blood_DNA)
				msg += "<span class='warning'>[t_He] [t_is] holding [icon2html(I, user)] [I.gender==PLURAL?"some":"a"] blood-stained [I.name] in [t_his] [get_held_index_name(get_held_index_of_item(I))]!</span>\n"
			else
				msg += "[t_He] [t_is] holding [icon2html(I, user)] \a [I] in [t_his] [get_held_index_name(get_held_index_of_item(I))].\n"

	if (back)
		msg += "[t_He] [t_has] [icon2html(back, user)] \a [src.back] on [t_his] back.\n"
	var/appears_dead = 0
	if (stat == STAT_DEAD)
		appears_dead = 1
		if(getorgan(/obj/item/organ/brain))
			msg += "<span class='deadsay'>[t_He] [t_is] limp and unresponsive, with no signs of life.</span>\n"
		else if(get_bodypart("head"))
			msg += "<span class='deadsay'>[t_He] appears that [t_his] brain is missing...</span>\n"

	var/list/missing = get_missing_limbs()
	for(var/t in missing)
		if(t=="head")
			msg += "<span class='deadsay'><B>[t_His] [parse_zone(t)] is missing!</B></span>\n"
			continue
		msg += "<span class='warning'><B>[t_His] [parse_zone(t)] is missing!</B></span>\n"

	msg += "<span class='warning'>"
	var/temp = getBruteLoss()
	if(!(user == src && src.hal_screwyhud == SCREWYHUD_HEALTHY)) //fake healthy
		if(temp)
			if (temp < 25)
				msg += "[t_He] [t_has] minor bruising.\n"
			else if (temp < 50)
				msg += "[t_He] [t_has] <b>moderate</b> bruising!\n"
			else
				msg += "<B>[t_He] [t_has] severe bruising!</B>\n"

		temp = getFireLoss()
		if(temp)
			if (temp < 25)
				msg += "[t_He] [t_has] minor burns.\n"
			else if (temp < 50)
				msg += "[t_He] [t_has] <b>moderate</b> burns!\n"
			else
				msg += "<B>[t_He] [t_has] severe burns!</B>\n"

		temp = getCloneLoss()
		if(temp)
			if(temp < 25)
				msg += "[t_He] [t_is] slightly deformed.\n"
			else if (temp < 50)
				msg += "[t_He] [t_is] <b>moderately</b> deformed!\n"
			else
				msg += "<b>[t_He] [t_is] severely deformed!</b>\n"

	if(disabilities & DUMB)
		msg += "[t_He] seems to be clumsy and unable to think.\n"

	if(fire_stacks > 0)
		msg += "[t_He] [t_is] covered in something flammable.\n"
	if(fire_stacks < 0)
		msg += "[t_He] [t_is] looks a little soaked.\n"

	if(pulledby && pulledby.grab_state)
		msg += "[t_He] [t_is] restrained by [pulledby]'s grip.\n"

	msg += "</span>"

	if(!appears_dead)
		if(stat == STATS_UNCONSCIOUS)
			msg += "[t_He] [t_is]n't responding to anything around [t_him] and seems to be asleep.\n"

		if(digitalcamo)
			msg += "[t_He] [t_is] moving [t_his] body in an unnatural and blatantly unsimian manner.\n"



	msg += "*---------*</span>"

	to_chat(user, msg)

/datum/surgery/implant_removal
	name = "implant removal"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/retract_skin, /datum/surgery_step/extract_implant, /datum/surgery_step/close)
	species = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list("chest")
	bodypart_types = BODYPART_ORGANIC

/datum/surgery/implant_removal/robotic
	steps = list(/datum/surgery_step/unscrew, /datum/surgery_step/pry_off, /datum/surgery_step/extract_implant, /datum/surgery_step/close_hatch)
	bodypart_types = BODYPART_ROBOTIC

//extract implant
/datum/surgery_step/extract_implant
	name = "extract implant"
	implements = list(/obj/item/hemostat = 100, /obj/item/crowbar = 65)
	time = 64
	var/obj/item/implant/I = null

/datum/surgery_step/extract_implant/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	for(var/obj/item/O in target.implants)
		I = O
		break
	if(I)
		user.visible_message("[user] begins to extract [I] from [target]'s [target_zone].", "<span class='notice'>You begin to extract [I] from [target]'s [target_zone]...</span>")
	else
		user.visible_message("[user] looks for an implant in [target]'s [target_zone].", "<span class='notice'>You look for an implant in [target]'s [target_zone]...</span>")

/datum/surgery_step/extract_implant/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(I)
		user.visible_message("[user] successfully removes [I] from [target]'s [target_zone]!", "<span class='notice'>You successfully remove [I] from [target]'s [target_zone].</span>")
		I.removed(target)

		var/obj/item/implantcase/case
		for(var/obj/item/implantcase/ic in user.held_items)
			case = ic
			break
		if(!case)
			case = locate(/obj/item/implantcase) in get_turf(target)
		if(case && !case.imp)
			case.imp = I
			I.loc = case
			case.update_icon()
			user.visible_message("[user] places [I] into [case]!", "<span class='notice'>You place [I] into [case].</span>")
		else
			qdel(I)

	else
		to_chat(user, "<span class='warning'>You can't find anything in [target]'s [target_zone]!</span>")
	return 1
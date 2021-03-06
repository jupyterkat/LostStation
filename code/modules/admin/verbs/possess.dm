/proc/possess(obj/O in world)
	set name = "Possess Obj"
	set category = "Object"

	if(O.dangerous_possession && CONFIG_GET(flag/forbid_singulo_possession))
		to_chat(usr, "[O] is too powerful for you to possess.")
		return

	var/turf/T = get_turf(O)

	if(T)
		log_admin("[key_name(usr)] has possessed [O] ([O.type]) at ([T.x], [T.y], [T.z])")
		message_admins("[key_name(usr)] has possessed [O] ([O.type]) at ([T.x], [T.y], [T.z])")
	else
		log_admin("[key_name(usr)] has possessed [O] ([O.type]) at an unknown location")
		message_admins("[key_name(usr)] has possessed [O] ([O.type]) at an unknown location")

	if(!usr.control_object) //If you're not already possessing something...
		usr.name_archive = usr.real_name

	usr.loc = O
	usr.real_name = O.name
	usr.name = O.name
	usr.reset_perspective(O)
	usr.control_object = O
	SSblackbox.add_details("admin_verb","Possess Object") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/proc/release()
	set name = "Release Obj"
	set category = "Object"
	//usr.loc = get_turf(usr)

	if(usr.control_object && usr.name_archive) //if you have a name archived and if you are actually relassing an object
		usr.real_name = usr.name_archive
		usr.name_archive = ""
		usr.name = usr.real_name
		if(ishuman(usr))
			var/mob/living/carbon/human/H = usr
			H.name = H.get_visible_name()
//		usr.regenerate_icons() //So the name is updated properly

	usr.loc = get_turf(usr.control_object)
	usr.reset_perspective()
	usr.control_object = null
	SSblackbox.add_details("admin_verb","Release Object") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/proc/givetestverbs(mob/M in GLOB.mob_list)
	set desc = "Give this guy possess/release verbs"
	set category = "Debug"
	set name = "Give Possessing Verbs"
	M.verbs += /proc/possess
	M.verbs += /proc/release
	SSblackbox.add_details("admin_verb","Give Possessing Verbs") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

//Dead mobs can exist whenever. This is needful

INITIALIZE_IMMEDIATE(/mob/dead)

/mob/dead
	sight = SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF

/mob/dead/Initialize()
	if(initialized)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	initialized = TRUE
	tag = "mob_[next_mob_id++]"
	GLOB.mob_list += src

	prepare_huds()

	if(CONFIG_GET(string/cross_server_address))
		verbs += /mob/dead/proc/server_hop
	set_focus(src)
	return INITIALIZE_HINT_NORMAL

/mob/dead/dust()	//ghosts can't be vaporised.
	return

/mob/dead/gib()		//ghosts can't be gibbed.
	return

/mob/dead/ConveyorMove()	//lol
	return



/mob/dead/proc/server_hop()
	set category = "OOC"
	set name = "Server Hop!"
	set desc= "Jump to the other server"
	if(notransform)
		return
	var/csa = CONFIG_GET(string/cross_server_address)
	if(csa)
		verbs -= /mob/dead/proc/server_hop
		to_chat(src, "<span class='notice'>Server Hop has been disabled.</span>")
		return
	if (alert(src, "Jump to server running at [csa]?", "Server Hop", "Yes", "No") != "Yes")
		return 0
	if (client && csa)
		to_chat(src, "<span class='notice'>Sending you to [csa].</span>")
		new /obj/screen/splash(client)
		notransform = TRUE
		sleep(29)	//let the animation play
		notransform = FALSE
		winset(src, null, "command=.options") //other wise the user never knows if byond is downloading resources
		client << link(csa + "?server_hop=[key]")
	else
		to_chat(src, "<span class='error'>There is no other server configured!</span>")

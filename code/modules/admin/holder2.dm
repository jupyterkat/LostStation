GLOBAL_LIST_EMPTY(admin_datums)
GLOBAL_PROTECT(admin_datums)

GLOBAL_VAR_INIT(href_token, GenerateToken())
GLOBAL_PROTECT(href_token)

/datum/admins
	var/datum/admin_rank/rank

	var/client/owner = null
	var/fakekey = null
	var/following = null

	var/datum/marked_datum

	var/spamcooldown = 0

	var/admincaster_screen = 0	//TODO: remove all these 5 variables, they are completly unacceptable
	var/datum/newscaster/feed_message/admincaster_feed_message = new /datum/newscaster/feed_message
	var/datum/newscaster/wanted_message/admincaster_wanted_message = new /datum/newscaster/wanted_message
	var/datum/newscaster/feed_channel/admincaster_feed_channel = new /datum/newscaster/feed_channel
	var/admin_signature
	var/href_token

/datum/admins/New(datum/admin_rank/R, ckey)
	if(!ckey)
		QDEL_IN(src, 0)
		throw EXCEPTION("Admin datum created without a ckey")
		return
	if(!istype(R))
		QDEL_IN(src, 0)
		throw EXCEPTION("Admin datum created without a rank")
		return
	rank = R
	admin_signature = "Nanotrasen Officer #[rand(0,9)][rand(0,9)][rand(0,9)]"
	href_token = GenerateToken()
	GLOB.admin_datums[ckey] = src
	if(R.rights & R_DEBUG) //grant profile access
		world.SetConfig("APP/admin", ckey, "role=admin")

/proc/GenerateToken()
	. = ""
	for(var/I in 1 to 32)
		. += "[rand(10)]"

/proc/RawHrefToken(forceGlobal = FALSE)
	var/tok = GLOB.href_token
	if(!forceGlobal && usr)
		var/client/C = usr.client
		if(!C)
			CRASH("No client for HrefToken()!")
		var/datum/admins/holder = C.holder
		if(holder)
			tok = holder.href_token
	return tok

/proc/HrefToken(forceGlobal = FALSE)
	return "admin_token=[RawHrefToken(forceGlobal)]"

/proc/HrefTokenFormField(forceGlobal = FALSE)
	return "<input type='hidden' name='admin_token' value='[RawHrefToken(forceGlobal)]'>"

/datum/admins/proc/associate(client/C)
	if(IsAdminAdvancedProcCall())
		var/msg = " has tried to elevate permissions!"
		message_admins("[key_name_admin(usr)][msg]")
		log_admin_private("[key_name(usr)][msg]")
		return
	if(istype(C))
		owner = C
		owner.holder = src
		owner.add_admin_verbs()	//TODO
		owner.verbs -= /client/proc/readmin
		GLOB.admins |= C

/datum/admins/proc/disassociate()
	if(owner)
		GLOB.admins -= owner
		owner.remove_admin_verbs()
		owner.holder = null
		owner = null

/datum/admins/proc/check_if_greater_rights_than_holder(datum/admins/other)
	if(!other)
		return 1 //they have no rights
	if(rank.rights == 65535)
		return 1 //we have all the rights
	if(src == other)
		return 1 //you always have more rights than yourself
	if(rank.rights != other.rank.rights)
		if( (rank.rights & other.rank.rights) == other.rank.rights )
			return 1 //we have all the rights they have and more
	return 0

/datum/admins/vv_edit_var(var_name, var_value)
	return FALSE //nice try trialmin

/*
checks if usr is an admin with at least ONE of the flags in rights_required. (Note, they don't need all the flags)
if rights_required == 0, then it simply checks if they are an admin.
if it doesn't return 1 and show_msg=1 it will prints a message explaining why the check has failed
generally it would be used like so:

/proc/admin_proc()
	if(!check_rights(R_ADMIN))
		return
	to_chat(world, "you have enough rights!")

NOTE: it checks usr! not src! So if you're checking somebody's rank in a proc which they did not call
you will have to do something like if(client.rights & R_ADMIN) yourself.
*/
/proc/check_rights(rights_required, show_msg=1)
	if(usr && usr.client)
		if (check_rights_for(usr.client, rights_required))
			return 1
		else
			if(show_msg)
				to_chat(usr, "<font color='red'>Error: You do not have sufficient rights to do that. You require one of the following flags:[rights2text(rights_required," ")].</font>")
	return 0

//probably a bit iffy - will hopefully figure out a better solution
/proc/check_if_greater_rights_than(client/other)
	if(usr && usr.client)
		if(usr.client.holder)
			if(!other || !other.holder)
				return 1
			return usr.client.holder.check_if_greater_rights_than_holder(other.holder)
	return 0

//This proc checks whether subject has at least ONE of the rights specified in rights_required.
/proc/check_rights_for(client/subject, rights_required)
	if(subject && subject.holder && subject.holder.rank)
		if(rights_required && !(rights_required & subject.holder.rank.rights))
			return 0
		return 1
	return 0

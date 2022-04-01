/client/proc/get_antag_tokens_count()
	var/datum/DBQuery/query_get_antag_tokens = SSdbcore.NewQuery("SELECT antag_tokens FROM [format_table_name("player")] WHERE ckey = '[ckey]'")
	var/atoken_count = 0
	if(query_get_antag_tokens.warn_execute())
		if(query_get_antag_tokens.NextRow())
			atoken_count = query_get_antag_tokens.item[1]

	qdel(query_get_antag_tokens)
	return text2num(atoken_count)

/client/proc/set_antag_tokens_count(atoken_count, ann=TRUE)
	var/datum/DBQuery/query_set_antag_tokens = SSdbcore.NewQuery("UPDATE [format_table_name("player")] SET antag_tokens = '[atoken_count]' WHERE ckey = '[ckey]'")
	query_set_antag_tokens.warn_execute()
	qdel(query_set_antag_tokens)
	if(ann)
		to_chat(src, "Your new antag token balance is [atoken_count]!")

/client/proc/inc_antag_tokens_count(atoken_count, ann=TRUE)
	var/datum/DBQuery/query_inc_antag_tokens = SSdbcore.NewQuery("UPDATE [format_table_name("player")] SET antag_tokens = antag_tokens + '[atoken_count]' WHERE ckey = '[ckey]'")
	query_inc_antag_tokens.warn_execute()
	qdel(query_inc_antag_tokens)
	if(ann)
		to_chat(src, "[atoken_count] antag token have been deposited to your account!")

/client/proc/cmd_admin_mod_antag_tokens(client/C in GLOB.clients, var/operation)
	set category = "Adminbus"
	set name = "Modify Antagonist Tokens"

	if(!check_rights(R_ADMIN))
		return

	var/msg = ""
	var/log_text = ""

	if(operation == "zero")
		log_text = "Set to 0"
		C.set_antag_tokens_count(0)
	else
		var/prompt = "Please enter the amount of tokens to [operation]:"

		if(operation == "set")
			prompt = "Please enter the new token amount:"

		msg = input("Message:", prompt) as num|null

		if (!msg)
			return

		if(operation == "set")
			log_text = "Set to [num2text(msg)]"
			C.set_antag_tokens_count(msg)
		else if(operation == "add")
			log_text = "Added [num2text(msg)]"
			C.inc_antag_tokens_count(msg)
		else if(operation == "subtract")
			log_text = "Subtracted [num2text(msg)]"
			C.inc_antag_tokens_count(-msg)
		else
			to_chat(src, "Invalid operation for antag token modification: [operation] by user [key_name(usr)]")
			return


	log_admin("[key_name(usr)]: Modified [key_name(C)]'s antagonist tokens [log_text]")
	message_admins("<span class='adminnotice'>[key_name_admin(usr)]: Modified [key_name(C)]'s antagonist tokens ([log_text])</span>")
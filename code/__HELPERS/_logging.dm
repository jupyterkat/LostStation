//wrapper macros for easier grepping
#define DIRECT_OUTPUT(A, B) A << B
#define SEND_IMAGE(target, image) DIRECT_OUTPUT(target, image)
#define SEND_SOUND(target, sound) DIRECT_OUTPUT(target, sound)
#define SEND_TEXT(target, text) DIRECT_OUTPUT(target, text)
#define WRITE_FILE(file, text) DIRECT_OUTPUT(file, text)

//print a warning message to world.log
#define WARNING(MSG) warning("[MSG] in [__FILE__] at line [__LINE__] src: [src] usr: [usr].")
/proc/warning(msg)
	msg = "## WARNING: [msg]"
	log_world(msg)

//not an error or a warning, but worth to mention on the world log, just in case.
#define NOTICE(MSG) notice(MSG)
/proc/notice(msg)
	msg = "## NOTICE: [msg]"
	log_world(msg)

//print a testing-mode debug message to world.log and world
#ifdef TESTING
#define testing(msg) log_world("## TESTING: [msg]"); to_chat(world, "## TESTING: [msg]")
#else
#define testing(msg)
#endif

/proc/log_admin(text)
	GLOB.admin_log.Add(text)
	if (CONFIG_GET(flag/log_admin))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]ADMIN: [text]")

//Items using this proc are stripped from public logs - use with caution
/proc/log_admin_private(text)
	GLOB.admin_log.Add(text)
	if (CONFIG_GET(flag/log_admin))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]ADMINPRIVATE: [text]")

/proc/log_adminsay(text)
	if (CONFIG_GET(flag/log_adminchat))
		log_admin_private("ASAY: [text]")

/proc/log_mentor(text)
	GLOB.mentorlog.Add(text)
	if (CONFIG_GET(flag/log_admin))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]MENTOR: [text]")

/proc/log_dsay(text)
	if (CONFIG_GET(flag/log_adminchat))
		log_admin("DSAY: [text]")

/proc/log_game(text)
	if (CONFIG_GET(flag/log_game))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]GAME: [text]")

/proc/log_vote(text)
	if (CONFIG_GET(flag/log_vote))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]VOTE: [text]")

/proc/log_access(text)
	if (CONFIG_GET(flag/log_access))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]ACCESS: [text]")

/proc/log_say(text)
	if (CONFIG_GET(flag/log_say))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]SAY: [text]")

/proc/log_prayer(text)
	if (CONFIG_GET(flag/log_prayer))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]PRAY: [text]")

/proc/log_law(text)
	if (CONFIG_GET(flag/log_law))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]LAW: [text]")

/proc/log_looc(text)
	if (CONFIG_GET(flag/log_looc))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]LOOC: [text]")

/proc/log_ooc(text)
	if (CONFIG_GET(flag/log_ooc))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]OOC: [text]")

/proc/log_whisper(text)
	if (CONFIG_GET(flag/log_whisper))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]WHISPER: [text]")

/proc/log_emote(text)
	if (CONFIG_GET(flag/log_emote))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]EMOTE: [text]")

/proc/log_attack(text)
	if (CONFIG_GET(flag/log_attack))
		WRITE_FILE(GLOB.world_attack_log, "\[[time_stamp()]]ATTACK: [text]")

/proc/log_pda(text)
	if (CONFIG_GET(flag/log_pda))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]PDA: [text]")

/proc/log_comment(text)
	if (CONFIG_GET(flag/log_pda))
		//reusing the PDA option because I really don't think news comments are worth a config option
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]COMMENT: [text]")

/proc/log_chat(text)
	if (CONFIG_GET(flag/log_pda))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]CHAT: [text]")

/proc/log_qdel(text)
	WRITE_FILE(GLOB.world_qdel_log, "\[[time_stamp()]]QDEL: [text]")

/proc/log_sql(text)
	if(CONFIG_GET(flag/sql_enabled))
		WRITE_FILE(GLOB.world_game_log, "\[[time_stamp()]]SQL: [text]")

/proc/log_config(text)
	WRITE_FILE(GLOB.config_error_log, text)
	SEND_TEXT(world.log, text)

//This replaces world.log so it displays both in DD and the file
/proc/log_world(text)
	WRITE_FILE(GLOB.world_runtime_log, text)
	SEND_TEXT(world.log, text)

/**
 * Appends a tgui-related log entry. All arguments are optional.
 */
/proc/log_tgui(user, message, context,
		datum/tgui_window/window,
		datum/src_object)
	var/entry = ""
	// Insert user info
	if(!user)
		entry += "<nobody>"
	else if(istype(user, /mob))
		var/mob/mob = user
		entry += "[mob.ckey] (as [mob] at [mob.x],[mob.y],[mob.z])"
	else if(istype(user, /client))
		var/client/client = user
		entry += "[client.ckey]"
	// Insert context
	if(context)
		entry += " in [context]"
	else if(window)
		entry += " in [window.id]"
	// Resolve src_object
	if(!src_object && window?.locked_by)
		src_object = window.locked_by.src_object
	// Insert src_object info
	if(src_object)
		entry += "\nUsing: [src_object.type] [REF(src_object)]"
	// Insert message
	if(message)
		entry += "\n[message]"
	WRITE_FILE(GLOB.tgui_log, entry)

/proc/log_asset(text)
	if(CONFIG_GET(flag/log_asset))
		WRITE_FILE(GLOB.world_asset_log, "ASSET: [text]")

// Helper procs for building detailed log lines

/proc/datum_info_line(datum/D)
	if(!istype(D))
		return
	if(!ismob(D))
		return "[D] ([D.type])"
	var/mob/M = D
	return "[M] ([M.ckey]) ([M.type])"

/proc/atom_loc_line(atom/A)
	if(!istype(A))
		return
	var/turf/T = get_turf(A)
	if(istype(T))
		return "[A.loc] [COORD(T)] ([A.loc.type])"
	else if(A.loc)
		return "[A.loc] (0, 0, 0) ([A.loc.type])"

/world/New()
	//Keep the auxtools stuff at the top
	AUXTOOLS_CHECK(AUXMOS)

	log_world("World loaded at [time_stamp()]")

	GLOB.config_error_log = GLOB.world_href_log = GLOB.world_runtime_log = GLOB.world_attack_log = GLOB.world_game_log = file("data/logs/config_error.log") //temporary file used to record errors with loading config, moved to log directory once logging is set bl

	//initialises global lists for referencing frequently used datums (so that we only ever do it once)
	make_datum_references_lists()

	var/datum/controller/configuration/config_holder = new /datum/controller/configuration
	config_holder.Load()
	GLOB.revdata.Load()

	CheckSchemaVersion()
	SetRoundID()

	SetupLogs()

	if(!RunningService())	//tgs2 support
		GLOB.revdata.DownloadPRDetails()

	load_motd()
	load_admins()
	load_mentors()
	LoadVerbs(/datum/verbs/menu)
	if(CONFIG_GET(flag/usewhitelist))
		load_whitelist()
	LoadBans()

	GLOB.timezoneOffset = text2num(time2text(0,"hh")) * 36000

	Master.Initialize(10, FALSE)

	if(CONFIG_GET(flag/irc_announce_new_game))
		if(CONFIG_GET(string/server))
			var/address = CONFIG_GET(string/server)
			IRCBroadcast("New round starting on [SSmapping.config.map_name]! <byond://[address]>")
		else
			IRCBroadcast("New round starting on [SSmapping.config.map_name]!")

/world/proc/CheckSchemaVersion()
	if(CONFIG_GET(flag/sql_enabled))
		if(SSdbcore.Connect())
			log_world("Database connection established.")
			var/datum/DBQuery/query_db_version = SSdbcore.NewQuery("SELECT major, minor FROM [format_table_name("schema_revision")] ORDER BY date DESC LIMIT 1")
			query_db_version.Execute()
			if(query_db_version.NextRow())
				var/db_major = text2num(query_db_version.item[1])
				var/db_minor = text2num(query_db_version.item[2])
				if(db_major != DB_MAJOR_VERSION || db_minor != DB_MINOR_VERSION)
					var/which = "behind"
					if(db_major < DB_MAJOR_VERSION || db_minor < DB_MINOR_VERSION)
						which = "ahead of"
					message_admins("Database schema ([db_major].[db_minor]) is [which] the latest schema version ([DB_MAJOR_VERSION].[DB_MINOR_VERSION]), this may lead to undefined behaviour or errors")
					log_sql("Database schema ([db_major].[db_minor]) is [which] the latest schema version ([DB_MAJOR_VERSION].[DB_MINOR_VERSION]), this may lead to undefined behaviour or errors")
			else
				message_admins("Could not get schema version from database")
		else
			log_world("Your server failed to establish a connection with the database.")

/world/proc/SetRoundID()
	if(CONFIG_GET(flag/sql_enabled))
		if(SSdbcore.Connect())
			var/datum/DBQuery/query_round_start = SSdbcore.NewQuery("INSERT INTO [format_table_name("round")] (start_datetime, server_ip, server_port) VALUES (Now(), INET_ATON(IF('[world.internet_address]' LIKE '', '0', '[world.internet_address]')), '[world.port]')")
			query_round_start.Execute()
			var/datum/DBQuery/query_round_last_id = SSdbcore.NewQuery("SELECT LAST_INSERT_ID()")
			query_round_last_id.Execute()
			if(query_round_last_id.NextRow())
				GLOB.round_id = query_round_last_id.item[1]

/world/proc/SetupLogs()
	GLOB.log_directory = "data/logs/[time2text(world.realtime, "YYYY/MM/DD")]/round-"
	if(GLOB.round_id)
		GLOB.log_directory += "[GLOB.round_id]"
	else
		GLOB.log_directory += "[replacetext(time_stamp(), ":", ".")]"
	GLOB.world_game_log = file("[GLOB.log_directory]/game.log")
	GLOB.world_attack_log = file("[GLOB.log_directory]/attack.log")
	GLOB.world_runtime_log = file("[GLOB.log_directory]/runtime.log")
	GLOB.world_qdel_log = file("[GLOB.log_directory]/qdel.log")
	GLOB.world_href_log = file("[GLOB.log_directory]/hrefs.html")
	WRITE_FILE(GLOB.world_game_log, "\n\nStarting up round ID [GLOB.round_id]. [time_stamp()]\n---------------------")
	WRITE_FILE(GLOB.world_attack_log, "\n\nStarting up round ID [GLOB.round_id]. [time_stamp()]\n---------------------")
	WRITE_FILE(GLOB.world_runtime_log, "\n\nStarting up round ID [GLOB.round_id]. [time_stamp()]\n---------------------")
	GLOB.changelog_hash = md5('html/changelog.html')					//used for telling if the changelog has changed recently
	if(fexists(GLOB.config_error_log))
		fcopy(GLOB.config_error_log, "[GLOB.log_directory]/config_error.log")
		fdel(GLOB.config_error_log)

	if(GLOB.round_id)
		log_game("Round ID: [GLOB.round_id]")

/world/Topic(T, addr, master, key)
	var/list/input = params2list(T)

	var/pinging = ("ping" in input)
	var/playing = ("players" in input)

	if(!pinging && !playing && config && CONFIG_GET(flag/log_world_topic))
		WRITE_FILE(GLOB.world_game_log, "TOPIC: \"[T]\", from:[addr], master:[master], key:[key]")

	if(input[SERVICE_CMD_PARAM_KEY])
		return ServiceCommand(input)
	var/comms_key = CONFIG_GET(string/comms_key)
	var/key_valid = (comms_key && input["key"] == comms_key)

	if(pinging)
		var/x = 1
		for (var/client/C in GLOB.clients)
			x++
		return x

	else if(playing)
		var/n = 0
		for(var/mob/M in GLOB.player_list)
			if(M.client)
				n++
		return n

	else if("ircstatus" in input)	//tgs2 support
		var/static/last_irc_status = 0
		if(world.time - last_irc_status < 50)
			return
		var/list/adm = get_admin_counts()
		var/list/allmins = adm["total"]
		var/status = "Admins: [allmins.len] (Active: [english_list(adm["present"])] AFK: [english_list(adm["afk"])] Stealth: [english_list(adm["stealth"])] Skipped: [english_list(adm["noflags"])]). "
		status += "Players: [GLOB.clients.len] (Active: [get_active_player_count(0,1,0)]). Mode: [SSticker.mode.name]."
		send2irc("Status", status)
		last_irc_status = world.time

	else if("status" in input)
		var/list/s = list()
		s["version"] = GLOB.game_version
		s["mode"] = GLOB.master_mode
		s["respawn"] = config ? !CONFIG_GET(flag/norespawn) : FALSE
		s["enter"] = GLOB.enter_allowed
		s["vote"] = CONFIG_GET(flag/allow_vote_mode)
		s["ai"] = CONFIG_GET(flag/allow_ai)
		s["host"] = host ? host : null
		s["active_players"] = get_active_player_count()
		s["players"] = GLOB.clients.len
		s["revision"] = GLOB.revdata.commit
		s["revision_date"] = GLOB.revdata.date

		var/list/adm = get_admin_counts()
		var/list/presentmins = adm["present"]
		var/list/afkmins = adm["afk"]
		s["admins"] = presentmins.len + afkmins.len //equivalent to the info gotten from adminwho

		var/list/mnt = get_mentor_counts()
		s["mentors"] = mnt["total"] // we don't have stealth mentors, so we can just use the total.

		s["gamestate"] = SSticker.current_state

		s["map_name"] = SSmapping.config.map_name

		if(key_valid && SSticker.HasRoundStarted())
			s["real_mode"] = SSticker.mode.name
			// Key-authed callers may know the truth behind the "secret"

		s["security_level"] = get_security_level()
		s["round_duration"] = SSticker ? round((world.time-SSticker.round_start_time)/10) : 0
		// Amount of world's ticks in seconds, useful for calculating round duration

		if(SSshuttle && SSshuttle.emergency)
			s["shuttle_mode"] = SSshuttle.emergency.mode
			// Shuttle status, see /__DEFINES/stat.dm
			s["shuttle_timer"] = SSshuttle.emergency.timeLeft()
			// Shuttle timer, in seconds

		return list2params(s)

	else if("announce" in input)
		if(!key_valid)
			return "Bad Key"
		else
			AnnouncePR(input["announce"], json_decode(input["payload"]))

	else if("crossmessage" in input)
		if(!key_valid)
			return
		else
			if(input["crossmessage"] == "Ahelp")
				relay_msg_admins("<span class='adminnotice'><b><font color=red>HELP: </font> [input["source"]] [input["message_sender"]]: [input["message"]]</b></span>")
			if(input["crossmessage"] == "Comms_Console")
				minor_announce(input["message"], "Incoming message from [input["message_sender"]]")
				for(var/obj/machinery/computer/communications/CM in GLOB.machines)
					CM.overrideCooldown()
			if(input["crossmessage"] == "News_Report")
				minor_announce(input["message"], "Breaking update from [input["message_sender"]]")

	else if("adminmsg" in input)	//tgs2 support
		if(!key_valid)
			return "Bad Key"
		else
			return IrcPm(input["adminmsg"],input["msg"],input["sender"])

	else if("namecheck" in input)	//tgs2 support
		if(!key_valid)
			return "Bad Key"
		else
			log_admin("IRC Name Check: [input["sender"]] on [input["namecheck"]]")
			message_admins("IRC name checking on [input["namecheck"]] from [input["sender"]]")
			return keywords_lookup(input["namecheck"],1)
	else if("adminwho" in input)	//tgs2 support
		if(!key_valid)
			return "Bad Key"
		else
			return ircadminwho()
	else if("server_hop" in input)
		show_server_hop_transfer_screen(input["server_hop"])

/world/proc/AnnouncePR(announcement, list/payload)
	var/static/list/PRcounts = list()	//PR id -> number of times announced this round
	var/id = "[payload["pull_request"]["id"]]"
	if(!PRcounts[id])
		PRcounts[id] = 1
	else
		++PRcounts[id]
		if(PRcounts[id] > PR_ANNOUNCEMENTS_PER_ROUND)
			return

	var/final_composed = "<span class='announce'>PR: [announcement]</span>"
	for(var/client/C in GLOB.clients)
		C.AnnouncePR(final_composed)

/world/Reboot(reason = 0, fast_track = FALSE)
	ServiceReboot() //handles alternative actions if necessary
	if (reason || fast_track) //special reboot, do none of the normal stuff
		if (usr)
			log_admin("[key_name(usr)] has requested an immediate world restart via client side debugging tools")
			message_admins("[key_name_admin(usr)] has requested an immediate world restart via client side debugging tools")
		to_chat(world, "<span class='boldannounce'>Rebooting World immediately due to host request</span>")
	else
		to_chat(world, "<span class='boldannounce'>Rebooting world...</span>")
		Master.Shutdown()	//run SS shutdowns
	log_world("World rebooted at [time_stamp()]")

	if(CONFIG_GET(flag/shutdown_for_update))
		var/http = world.Export(CONFIG_GET(string/update_version_string_uri))
		if (http)
			var/local_hash = file2text(file("COMMIT_HASH"))
			var/remote_hash = file2text(http["CONTENT"])

			if(local_hash != remote_hash)
				to_chat(world, "<span class='narsiesmall'>Server is updating! You may need to reconnect!</span>")
				shutdown()
				return
	AUXTOOLS_SHUTDOWN(AUXMOS)
	..()

/world/Del()
	AUXTOOLS_SHUTDOWN(AUXMOS)
	..()

/world/proc/load_motd()
	GLOB.join_motd = file2text("config/motd.txt") + "<br>" + GLOB.revdata.GetTestMergeInfo()

/world/proc/update_status()

	var/list/features = list()

	if(GLOB.master_mode)
		features += GLOB.master_mode

	if (!GLOB.enter_allowed)
		features += "closed"

	var/s = ""
	var/hostedby
	if(config)
		var/server_name = CONFIG_GET(string/servername)
		if (server_name)
			s += "<b>[server_name]</b> &#8212; "
		features += "[CONFIG_GET(flag/norespawn) ? "no " : ""]respawn"
		if(CONFIG_GET(flag/allow_vote_mode))
			features += "vote"
		if(CONFIG_GET(flag/allow_ai))
			features += "AI allowed"
		hostedby = CONFIG_GET(string/hostedby)

	s += "<b>[station_name()]</b>";
	s += " ("
	s += "<a href=\"http://\">" //Change this to wherever you want the hub to link to.
	s += "Default"  //Replace this with something else. Or ever better, delete it and uncomment the game version.
	s += "</a>"
	s += ")"

	var/n = 0
	for (var/mob/M in GLOB.player_list)
		if (M.client)
			n++

	if (n > 1)
		features += "~[n] players"
	else if (n > 0)
		features += "~[n] player"

	if (!host && hostedby)
		features += "hosted by <b>[hostedby]</b>"

	if (features)
		s += ": [jointext(features, ", ")]"

	status = s

/world/proc/update_hub_visibility(new_visibility)
	if(new_visibility == GLOB.hub_visibility)
		return
	GLOB.hub_visibility = new_visibility
	if(GLOB.hub_visibility)
		hub_password = "kMZy3U5jJHSiBQjr"
	else
		hub_password = "SORRYNOPASSWORD"

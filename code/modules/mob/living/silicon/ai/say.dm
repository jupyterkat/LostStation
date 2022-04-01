/mob/living/silicon/ai/say(message, language)
	if(parent && istype(parent) && parent.stat != 2) //If there is a defined "parent" AI, it is actually an AI, and it is alive, anything the AI tries to say is said by the parent instead.
		parent.say(message, language)
		return
	..(message)

/mob/living/silicon/ai/compose_track_href(atom/movable/speaker, namepart)
	var/mob/M = speaker.GetSource()
	if(M)
		return "<a href='?src=[REF(src)];track=[html_encode(namepart)]'>"
	return ""

/mob/living/silicon/ai/compose_job(atom/movable/speaker, message_langs, raw_message, radio_freq)
	//Also includes the </a> for AI hrefs, for convenience.
	return "[radio_freq ? " (" + speaker.GetJob() + ")" : ""]" + "[speaker.GetSource() ? "</a>" : ""]"

/mob/living/silicon/ai/IsVocal()
	return !CONFIG_GET(flag/silent_ai)

/mob/living/silicon/ai/radio(message, message_mode, list/spans, language)
	if(!radio_enabled || aiRestorePowerRoutine || stat) //AI cannot speak if radio is disabled (via intellicard) or depowered.
		to_chat(src, "<span class='danger'>Your radio transmitter is offline!</span>")
		return 0
	..()

/mob/living/silicon/ai/get_message_mode(message)
	if(copytext(message, 1, 3) in list(":h", ":H", ".h", ".H", "#h", "#H"))
		return MODE_HOLOPAD
	else
		return ..()

/mob/living/silicon/ai/handle_inherent_channels(message, message_mode, language)
	. = ..()
	if(.)
		return .

	if(message_mode == MODE_HOLOPAD)
		holopad_talk(message, language)
		return 1

//For holopads only. Usable by AI.
/mob/living/silicon/ai/proc/holopad_talk(message, language)


	message = trim(message)

	if (!message)
		return

	var/obj/machinery/holopad/T = current
	if(istype(T) && T.masters[src])//If there is a hologram and its master is the user.
		var/turf/padturf = get_turf(T)
		var/padloc
		if(padturf)
			padloc = COORD(padturf)
		else
			padloc = "(UNKNOWN)"
		log_talk(src,"HOLOPAD [padloc]: [key_name(src)] : [message]", LOGSAY)
		send_speech(message, 7, T, "robot", get_spans(), language)
		to_chat(src, "<i><span class='game say'>Holopad transmitted, <span class='name'>[real_name]</span> <span class='message robot'>\"[message]\"</span></span></i>")
	else
		to_chat(src, "No holopad connected.")

/mob/living/silicon/ai/verb/announcement_help()

	set name = "Announcement Help"
	set desc = "Display a list of vocal words to announce to the crew."
	set category = "AI Commands"

	if(usr.stat == 2)
		return //won't work if dead

	var/dat = "Here is a list of words you can type into the 'Announcement' button to create sentences to vocally announce to everyone on the same level at you.<BR> \
	<UL><LI>You can also click on the word to preview it.</LI>\
	<LI>You can only say 30 words for every announcement.</LI>\
	<LI>Do not use punctuation as you would normally, if you want a pause you can use the full stop and comma characters by separating them with spaces, like so: 'Alpha . Test , Bravo'.</LI></UL>"

	var/datum/browser/popup = new(src, "announce_help", "Announcement Help", 500, 400)
	popup.set_content(dat)
	popup.open()


/mob/living/silicon/ai/proc/announcement()
	var/message = input(src, "More help is available in 'Announcement Help'", "Announcement", src.last_announcement) as text

	last_announcement = message

	if(!message || stat != STAT_CONSCIOUS)
		return

	if(control_disabled)
		to_chat(src, "<span class='notice'>Wireless interface disabled, unable to interact with announcement PA.</span>")
		return

	var/list/words = splittext(trim(message), " ")
	var/list/incorrect_words = list()

	if(words.len > 30)
		words.len = 30

	for(var/word in words)
		word = lowertext(trim(word))
		if(!word)
			words -= word
			continue
		
		incorrect_words += word

	if(incorrect_words.len)
		to_chat(src, "<span class='notice'>These words are not available on the announcement system: [english_list(incorrect_words)].</span>")
		return


	log_game("[key_name(src)] made a vocal announcement with the following message: [message].")

/*
	for(var/mob/M in player_list)
		if(M.client)
			var/turf/T = get_turf(M)
			var/turf/our_turf = get_turf(src)
			if(T.z == our_turf.z)
				to_chat(M, "<b><font size = 3><font color = red>AI announcement:</font color> [message]</font size></b>")
*/

/mob/living/silicon/ai/could_speak_in_language(datum/language/dt)
	if(is_servant_of_ratvar(src))
		// Ratvarian AIs can only speak Ratvarian
		. = ispath(dt, /datum/language/ratvar)
	else
		. = ..()

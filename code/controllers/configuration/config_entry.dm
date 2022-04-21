#define LIST_MODE_NUM 0
#define LIST_MODE_TEXT 1
#define LIST_MODE_FLAG 2

#define VALUE_MODE_NUM 0
#define VALUE_MODE_TEXT 1
#define VALUE_MODE_FLAG 2

#define KEY_MODE_TEXT 0
#define KEY_MODE_TYPE 1

/datum/config_entry
	var/name	//read-only, this is determined by the last portion of the derived entry type
	var/value
	var/default	//read-only, just set value directly

	var/resident_file	//the file which this belongs to, must be set
	var/modified = FALSE	//set to TRUE if the default has been overridden by a config entry

	var/protection = NONE
	var/abstract_type = /datum/config_entry	//do not instantiate if type matches this

	/// Force validate and set on VV. VAS proccall guard will run regardless.
	var/vv_VAS = TRUE

	var/dupes_allowed = FALSE

/datum/config_entry/New()
	if(!resident_file)
		CRASH("Config entry [type] has no resident_file set")
	if(type == abstract_type)
		CRASH("Abstract config entry [type] instatiated!")
	name = lowertext(type2top(type))
	if(islist(value))
		var/list/L = value
		default = L.Copy()
	else
		default = value

/datum/config_entry/Destroy()
	config.RemoveEntry(src)
	return ..()

/datum/config_entry/can_vv_get(var_name)
	. = ..()
	if(var_name == "value" || var_name == "default")
		. &= !(protection & CONFIG_ENTRY_HIDDEN)

/datum/config_entry/vv_edit_var(var_name, var_value)
	var/static/list/banned_edits = list("name", "default", "resident_file", "protection", "vv_VAS", "abstract_type", "modified", "dupes_allowed")
	if(var_name == "value")
		if(protection & CONFIG_ENTRY_LOCKED)
			return FALSE
		if(vv_VAS)
			. = ValidateAndSet("[var_value]")
			if(.)
				var_edited = TRUE
			return
	if(var_name in banned_edits)
		return FALSE
	return ..()

/datum/config_entry/proc/VASProcCallGuard(str_val)
	. = !((protection & CONFIG_ENTRY_LOCKED) && IsAdminAdvancedProcCall() && GLOB.LastAdminCalledProc == "ValidateAndSet" && GLOB.LastAdminCalledTargetRef == "[REF(src)]")
	if(!.)
		log_admin_private("Config set of [type] to [str_val] attempted by [key_name(usr)]")

/datum/config_entry/proc/ValidateAndSet(str_val)
	VASProcCallGuard(str_val)
	CRASH("Invalid config entry type!")

/datum/config_entry/proc/ValidateKeyedList(str_val, list_mode, splitter)
	str_val = trim(str_val)
	var/key_pos = findtext(str_val, splitter)
	var/key_name = null
	var/key_value = null

	if(key_pos || list_mode == LIST_MODE_FLAG)
		key_name = lowertext(copytext(str_val, 1, key_pos))
		key_value = copytext(str_val, key_pos + 1)
		var/temp
		var/continue_check
		switch(list_mode)
			if(LIST_MODE_FLAG)
				temp = TRUE
				continue_check = TRUE
			if(LIST_MODE_NUM)
				temp = text2num(key_value)
				continue_check = !isnull(temp)
			if(LIST_MODE_TEXT)
				temp = key_value
				continue_check = temp
		if(continue_check && ValidateKeyName(key_name))
			value[key_name] = temp
			return TRUE
	return FALSE

/datum/config_entry/proc/ValidateKeyName(key_name)
	return TRUE

/datum/config_entry/proc/ValidateListEntry(key_name, key_value)
	return TRUE

/datum/config_entry/string
	value = ""
	abstract_type = /datum/config_entry/string
	var/auto_trim = TRUE

/datum/config_entry/string/vv_edit_var(var_name, var_value)
	return var_name != "auto_trim" && ..()

/datum/config_entry/string/ValidateAndSet(str_val)
	if(!VASProcCallGuard(str_val))
		return FALSE
	value = auto_trim ? trim(str_val) : str_val
	return TRUE

/datum/config_entry/number
	value = 0
	abstract_type = /datum/config_entry/number
	var/integer = TRUE
	var/max_val = INFINITY
	var/min_val = -INFINITY

/datum/config_entry/number/ValidateAndSet(str_val)
	if(!VASProcCallGuard(str_val))
		return FALSE
	var/temp = text2num(trim(str_val))
	if(!isnull(temp))
		value = clamp(integer ? round(temp) : temp, min_val, max_val)
		if(value != temp && !var_edited)
			log_config("Changing [name] from [temp] to [value]!")
		return TRUE
	return FALSE

/datum/config_entry/number/vv_edit_var(var_name, var_value)
	var/static/list/banned_edits = list("max_val", "min_val", "integer")
	return !(var_name in banned_edits) && ..()

/datum/config_entry/flag
	value = FALSE
	abstract_type = /datum/config_entry/flag

/datum/config_entry/flag/ValidateAndSet(str_val)
	if(!VASProcCallGuard(str_val))
		return FALSE
	value = text2num(trim(str_val)) != 0
	return TRUE

/datum/config_entry/number_list
	abstract_type = /datum/config_entry/number_list
	value = list()

/datum/config_entry/number_list/ValidateAndSet(str_val)
	if(!VASProcCallGuard(str_val))
		return FALSE
	str_val = trim(str_val)
	var/list/new_list = list()
	var/list/values = splittext(str_val," ")
	for(var/I in values)
		var/temp = text2num(I)
		if(isnull(temp))
			return FALSE
		new_list += temp
	if(!new_list.len)
		return FALSE
	value = new_list
	return TRUE

/datum/config_entry/keyed_flag_list
	abstract_type = /datum/config_entry/keyed_flag_list
	value = list()
	dupes_allowed = TRUE

/datum/config_entry/keyed_flag_list/ValidateAndSet(str_val)
	if(!VASProcCallGuard(str_val))
		return FALSE
	return ValidateKeyedList(str_val, LIST_MODE_FLAG, " ")

/datum/config_entry/keyed_number_list
	abstract_type = /datum/config_entry/keyed_number_list
	value = list()
	dupes_allowed = TRUE
	var/splitter = " "

/datum/config_entry/keyed_number_list/vv_edit_var(var_name, var_value)
	return var_name != "splitter" && ..()

/datum/config_entry/keyed_number_list/ValidateAndSet(str_val)
	if(!VASProcCallGuard(str_val))
		return FALSE
	return ValidateKeyedList(str_val, LIST_MODE_NUM, splitter)

/datum/config_entry/keyed_string_list
	abstract_type = /datum/config_entry/keyed_string_list
	value = list()
	dupes_allowed = TRUE
	var/splitter = " "

/datum/config_entry/keyed_string_list/vv_edit_var(var_name, var_value)
	return var_name != "splitter" && ..()

/datum/config_entry/keyed_string_list/ValidateAndSet(str_val)
	if(!VASProcCallGuard(str_val))
		return FALSE
	return ValidateKeyedList(str_val, LIST_MODE_TEXT, splitter)


/datum/config_entry/keyed_list
	abstract_type = /datum/config_entry/keyed_list
	default = list()
	dupes_allowed = TRUE
	vv_VAS = FALSE //VAS will not allow things like deleting from lists, it'll just bug horribly.
	var/key_mode
	var/value_mode
	var/splitter = " "
	/// whether the key names will be lowercased on ValidateAndSet or not.
	var/lowercase_key = TRUE

/datum/config_entry/keyed_list/New()
	. = ..()
	if(isnull(key_mode) || isnull(value_mode))
		CRASH("Keyed list of type [type] created with null key or value mode!")

/datum/config_entry/keyed_list/ValidateAndSet(str_val)
	if(!VASProcCallGuard(str_val))
		return FALSE

	str_val = trim(str_val)

	var/list/new_entry = parse_key_and_value(str_val)

	var/new_key = new_entry["config_key"]
	var/new_value = new_entry["config_value"]

	if(!isnull(new_value) && !isnull(new_key) && ValidateListEntry(new_key, new_value))
		value[new_key] = new_value
		return TRUE
	return FALSE

/datum/config_entry/keyed_list/proc/parse_key_and_value(option_string)
	// Blank or null option string? Bad mojo!
	if(!option_string)
		log_config("ERROR: Keyed list config tried to parse with no key or value data.")
		return null

	var/list/config_entry_words = splittext(option_string, splitter)
	var/config_value
	var/config_key
	var/is_ambiguous = FALSE

	// If this config entry's value mode is flag, the value can either be TRUE or FALSE.
	// However, the config supports implicitly setting a config entry to TRUE by omitting the value.
	// This value mode should also support config overrides disabling it too.
	// The following code supports config entries as such:
	// Implicitly enable the config entry: CONFIG_ENTRY config key goes here
	// Explicitly enable the config entry: CONFIG_ENTRY config key goes here 1
	// Explicitly disable the config entry: CONFIG_ENTRY config key goes here 0
	if(value_mode == VALUE_MODE_FLAG)
		var/value = peek(config_entry_words)
		config_value = TRUE

		if(value == "0")
			config_key = jointext(config_entry_words, splitter, length(config_entry_words) - 1)
			config_value = FALSE
			is_ambiguous = (length(config_entry_words) > 2)
		else if(value == "1")
			config_key = jointext(config_entry_words, splitter, length(config_entry_words) - 1)
			is_ambiguous = (length(config_entry_words) > 2)
		else
			config_key = option_string
			is_ambiguous = (length(config_entry_words) > 1)
	// Else it has to be a key value pair and we parse it under that assumption.
	else
		// If config_entry_words only has 1 or 0 words in it and isn't value_mode == VALUE_MODE_FLAG then it's an invalid config entry.
		if(length(config_entry_words) <= 1)
			log_config("ERROR: Could not parse value from config entry string: [option_string]")
			return null

		config_value = pop(config_entry_words)
		config_key = jointext(config_entry_words, splitter)

		if(lowercase_key)
			config_key = lowertext(config_key)

		is_ambiguous = (length(config_entry_words) > 2)

	config_key = validate_config_key(config_key)
	config_value = validate_config_value(config_value)

	// If there are multiple splitters, it's definitely ambiguous and we'll warn about how we parsed it. Helps with debugging config issues.
	if(is_ambiguous)
		log_config("WARNING: Multiple splitter characters (\"[splitter]\") found. Using \"[config_key]\" as config key and \"[config_value]\" as config value.")

	return list("config_key" = config_key, "config_value" = config_value)

/// Takes a given config key and validates it. If successful, returns the formatted key. If unsuccessful, returns null.
/datum/config_entry/keyed_list/proc/validate_config_key(key)
	switch(key_mode)
		if(KEY_MODE_TEXT)
			return key
		if(KEY_MODE_TYPE)
			if(ispath(key))
				return key

			var/key_path = text2path(key)
			if(isnull(key_path))
				log_config("ERROR: Invalid KEY_MODE_TYPE typepath. Is not a valid typepath: [key]")
				return

			return key_path


/// Takes a given config value and validates it. If successful, returns the formatted key. If unsuccessful, returns null.
/datum/config_entry/keyed_list/proc/validate_config_value(value)
	switch(value_mode)
		if(VALUE_MODE_FLAG)
			return value
		if(VALUE_MODE_NUM)
			if(isnum(value))
				return value

			var/value_num = text2num(value)
			if(isnull(value_num))
				log_config("ERROR: Invalid VALUE_MODE_NUM number. Could not parse a valid number: [value]")
				return

			return value_num
		if(VALUE_MODE_TEXT)
			return value

/datum/config_entry/keyed_list/vv_edit_var(var_name, var_value)
	return var_name != NAMEOF(src, splitter) && ..()


#undef LIST_MODE_NUM
#undef LIST_MODE_TEXT
#undef LIST_MODE_FLAG

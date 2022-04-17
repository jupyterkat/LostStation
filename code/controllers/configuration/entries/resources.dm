#define CURRENT_RESIDENT_FILE "resources.txt"

CONFIG_DEF(keyed_list/external_rsc_urls)
	key_mode = KEY_MODE_TEXT
	value_mode = VALUE_MODE_FLAG

CONFIG_DEF(flag/asset_simple_preload)

CONFIG_DEF(string/asset_transport)
/datum/config_entry/string/asset_transport/ValidateAndSet(str_val)
	return (lowertext(str_val) in list("simple", "webroot")) && ..(lowertext(str_val))

CONFIG_DEF(string/asset_cdn_webroot)
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/string/asset_cdn_webroot/ValidateAndSet(str_var)
	if (!str_var || trim(str_var) == "")
		return FALSE
	if (str_var && str_var[length(str_var)] != "/")
		str_var += "/"
	return ..(str_var)

CONFIG_DEF(string/asset_cdn_url)
	protection = CONFIG_ENTRY_LOCKED
	default = null

/datum/config_entry/string/asset_cdn_url/ValidateAndSet(str_var)
	if (!str_var || trim(str_var) == "")
		return FALSE
	if (str_var && str_var[length(str_var)] != "/")
		str_var += "/"
	return ..(str_var)

/datum
	var/gc_destroyed //Time when this object was destroyed.
	var/list/active_timers  //for SStimer
	var/list/datum_components //for /datum/components
	var/ui_screen = "home"  //for tgui
	var/use_tag = FALSE

	/// Status traits attached to this datum. associative list of the form: list(trait name (string) = list(source1, source2, source3,...))
	var/list/status_traits

#ifdef TESTING
	var/running_find_references
	var/last_find_references = 0
#endif

// Default implementation of clean-up code.
// This should be overridden to remove all references pointing to the object being destroyed.
// Return the appropriate QDEL_HINT; in most cases this is QDEL_HINT_QUEUE.
/datum/proc/Destroy(force=FALSE)
	tag = null
	var/list/timers = active_timers
	active_timers = null
	for(var/thing in timers)
		var/datum/timedevent/timer = thing
		if (timer.spent)
			continue
		qdel(timer)
	var/list/dc = datum_components
	if(dc)
		var/all_components = dc[/datum/component]
		if(length(all_components))
			for(var/I in all_components)
				var/datum/component/C = I
				C._RemoveFromParent()
				qdel(C)
		else
			var/datum/component/C = all_components
			C._RemoveFromParent()
			qdel(C)
		dc.Cut()

	var/list/focusers = src.focusers
	if(focusers)
		for(var/i in 1 to focusers.len)
			var/mob/M = focusers[i]
			M.set_focus(M)

	return QDEL_HINT_QUEUE

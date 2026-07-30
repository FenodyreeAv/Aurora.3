#define GET_COMMUNE_TYPE(owner) alert(owner.client, "What type of chat message would you like to use for your commune?", "Say Type", "Say", "Whisper", "Emote")
#define GET_COMMUNE_TEXT(owner) tgui_input_text(owner, "Write what you wish to say for your commune.", "Commune")

/datum/action/commune
	name = "Commune"
	action_type = 6
	procname = "queue_click"
	button_icon = 'icons/hud/action_buttons/actions.dmi'
	button_icon_state = "mindswap"

/datum/action/commune/proc/queue_click()
	if (!owner)
		return

	to_chat(owner, SPAN_NOTICE("You prepare yourself to commune with others. Left click on yourself to search for familiar minds and familiarize yourself with those in sight. Left click on another person to instead share direct words with them."))
	RegisterSignal(owner, COMSIG_MOB_CLICKON, PROC_REF(get_target), override = TRUE)

/datum/action/commune/proc/get_target(owner, atom/target, modifiers)
	SIGNAL_HANDLER
	UnregisterSignal(owner, COMSIG_MOB_CLICKON)
	if (. == COMSIG_MOB_CANCEL_CLICKON)
		return . // Another signal-handler already got to it.

	if (owner == target)
		UNLINT(deliver_commune_area(owner))
	else
		UNLINT(deliver_commune_target(owner, target))
	return COMSIG_MOB_CANCEL_CLICKON

/datum/action/commune/proc/deliver_commune_area(mob/owner)
	set waitfor = FALSE // Immediately return control to the caller.
	if (!istype(owner))
		return

	owner.visible_message(SPAN_NOTICE("[owner] prepares to commune with those around them."))
	var/speech_text = GET_COMMUNE_TEXT(owner)
	if (!speech_text)
		owner.visible_message(SPAN_NOTICE("[owner] has stopped speaking."))
		return

	owner.say(speech_text)

/datum/action/commune/proc/deliver_commune_target(mob/owner, mob/target)
	set waitfor = FALSE // Immediately return control to the caller.
	if (!istype(owner) || !istype(target))
		return

	if (!target.client)
		to_chat(owner, SPAN_NOTICE("[target] cannot hear your commune."))
		return

	owner.visible_message(SPAN_NOTICE("[owner] prepares to commune with [target]."))
	var/speech_type = GET_COMMUNE_TYPE(owner)
	var/speech_text = GET_COMMUNE_TEXT(owner)
	if (!speech_text)
		owner.visible_message(SPAN_NOTICE("[owner] has stopped speaking."))
		return

	switch(speech_type)
		if ("Say")
			if (get_dist(owner, target) >= 7)
				to_chat(owner, SPAN_NOTICE("You must be closer to [target] to commune with them"))
				return
			owner.say(speech_text)
		if ("Whisper")
			if (get_dist(owner, target) >= 2)
				to_chat(owner, SPAN_NOTICE("You must be adjacent to [target] to whisper to them"))
				return
			owner.whisper(speech_text)
		if ("Emote")
			if (get_dist(owner, target) >= 7)
				to_chat(owner, SPAN_NOTICE("You must be closer to [target] to commune with them"))
			owner.emote(speech_text)

/**
 * Component used for the Commune action.
 * Having the component grants access to a "Commune" action for the owner.
 */
/datum/component/skill/commune
	/// The action icon stored for this ability.
	var/datum/action/commune/commune_action

/datum/component/skill/commune/Initialize(level)
	. = ..()
	if (!parent)
		return

	commune_action = new /datum/action/commune()
	commune_action.SetTarget(commune_action)
	commune_action.Grant(parent)

	RegisterSignal(parent, COMSIG_MOB_AFTER_LOGIN, PROC_REF(setup_action_button), override = TRUE)

/datum/component/skill/commune/Destroy(force)
	if (!parent)
		return ..()

	UnregisterSignal(parent, COMSIG_MOB_AFTER_LOGIN)
	commune_action?.Remove(parent)
	QDEL_NULL(commune_action)
	return ..()

/datum/component/skill/commune/proc/setup_action_button()
	astype(parent, /mob)?.update_action_buttons()

#undef GET_COMMUNE_TYPE
#undef GET_COMMUNE_TEXT

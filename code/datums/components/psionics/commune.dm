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
	commune_mouse_cursor_on()

/datum/action/commune/proc/commune_mouse_cursor_on()
	if (!owner || !owner.client)
		return

	if(owner.client?.mouse_pointer_icon == initial(owner.client.mouse_pointer_icon))
		owner.client.mouse_pointer_icon = icon(button_icon, button_icon_state)

/datum/action/commune/proc/commune_mouse_cursor_off()
	if (!owner || !owner.client)
		return

	owner.client.mouse_pointer_icon = initial(owner.client.mouse_pointer_icon)

/datum/action/commune/proc/get_target(owner, atom/target, modifiers)
	SIGNAL_HANDLER
	UnregisterSignal(owner, COMSIG_MOB_CLICKON)
	commune_mouse_cursor_off()
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
		owner.visible_message(SPAN_NOTICE("[owner] has stopped communing."))
		return

	owner.say(speech_text)

/datum/action/commune/proc/deliver_commune_target(mob/owner, mob/target)
	set waitfor = FALSE // Immediately return control to the caller.
	if (!istype(owner) || !istype(target))
		return

	owner.visible_message(SPAN_NOTICE("[owner] prepares to commune with [target]."))
	var/speech_text = GET_COMMUNE_TEXT(owner)
	if (!speech_text)
		owner.visible_message(SPAN_NOTICE("[owner] has stopped communing."))
		return

	speech_text = formalize_text(speech_text)

	if (target.stat == DEAD)
		to_chat(owner, SPAN_WARNING("Not even a psion of your level can speak to the dead."))
		return

	var/psi_blocked = target.is_psi_blocked(owner, FALSE)
	if (psi_blocked)
		to_chat(owner, psi_blocked)
		return

	log_say("[key_name(owner)] communed to [key_name(target)]: [speech_text]")

	to_chat(owner, SPAN_CULT("You psionically say to [target]: [speech_text]"))

	for (var/mob/M in GLOB.dead_mob_list)
		if (M.client.prefs.toggles & CHAT_GHOSTEARS)
			to_chat(M, "<span class='notice'>[owner] psionically says to [target]:</span> [speech_text]")

	var/mob/living/carbon/human/H = target
	var/target_sensitivity = H.check_psi_sensitivity()
	if (target_sensitivity >= 1)
		to_chat(H, SPAN_NOTICE("<i>[owner] blinks, their eyes briefly developing an unnatural shine.</i>"))
		to_chat(H, SPAN_CULT("<b>You instinctively sense [owner] passing a thought into your mind:</b> [speech_text]"))
	else if (target_sensitivity >= 0)
		to_chat(H, SPAN_ALIEN("<b>A thought from outside your consciousness slips into your mind:</b> [speech_text]"))
	else
		var/scrambled_message = stars(speech_text, (abs(target_sensitivity) * 25))
		to_chat(H, SPAN_ALIEN("<b>A half-formed thought passes through your mind:</b> [scrambled_message]"))

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

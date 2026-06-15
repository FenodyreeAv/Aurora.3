/obj/structure/machinery/ship_weapon/longbow
	name = "longbow cannon"
	desc = "A Kumar Arms high-velocity cannon and flagship of <i>\"Chivalry\"</i> weapons line, developed in 2461 as an upgrade to its predecessor, the Ballista. Its upgrades include a bigger payload, a more streamlined loading process, and easier maintenance, making this cannon one of the best armaments in the Spur."
	icon_state = "weapon_base"

	projectile_type = /obj/projectile/ship_ammo/longbow
	caliber = SHIP_CALIBER_406MM
	firing_effects = FIRING_EFFECT_FLAG_EXTREMELY_LOUD
	screenshake_type = SHIP_GUN_SCREENSHAKE_ALL_MOBS

/obj/structure/machinery/ammunition_loader/longbow
	name = "longbow shell loader"

/obj/projectile/ship_ammo/longbow
	icon_state = "heavy"
	damage = 300
	armor_penetration = 100
	anti_materiel_potential = 10
	var/penetrated = FALSE

/obj/projectile/ship_ammo/longbow/fire_projectile(projectile_type, atom/target, sound, firer, list/ignore_targets)
	if(ammo.impact_type == SHIP_AMMO_IMPACT_HE)
		explosion_strength = list(6, 8, 10)
	if(ammo.impact_type == SHIP_AMMO_IMPACT_AP)
		explosion_strength = list(4, 6, 8)
		penetrating = 2 //Detonates on the 2nd wall hit.
	if(ammo.impact_type == SHIP_AMMO_IMPACT_BUNKERBUSTER)
		explosion_strength = list(1, 2, 4)
		penetrating = 4 //Detonates on the 4th wall hit.
	. = ..()

/obj/projectile/ship_ammo/longbow/on_hit(atom/target, blocked, def_zone, is_landmark_hit)
	. = ..()
	var/turf/epicenter = get_turf(target)
	if(ismob(target))
		var/mob/M = target
		M.visible_message(SPAN_DANGER("<font size=5>\The [src] blows [M] apart and punches straight through!</font>"))
		pierces = max(0, pierces - 1) //A mob won't even slow it down.

	if(isobj(target))
		if(target.should_use_health) //Only an object with more than 200 health will count as a pierced object. This means the shell will penetrate most things that aren't walls.
			if (target.health <= OBJECT_HEALTH_HIGH)
				pierces = max(0, pierces - 1)

	if(pierces >= penetrating)
		switch(ammo.impact_type)
			if(SHIP_AMMO_IMPACT_AP)
				target.visible_message(SPAN_DANGER("<font size=5>\The [src] punches straight through \the [target]!</font>"))
				explosion(epicenter, explosion_strength[1], explosion_strength[2], explosion_strength[3])
			if(SHIP_AMMO_IMPACT_BUNKERBUSTER)
				target.visible_message(SPAN_DANGER("<font size=5>\The [src] punches straight through \the [target]!</font>"))
				explosion(epicenter, explosion_strength[1], explosion_strength[2], explosion_strength[3])
			if(SHIP_AMMO_IMPACT_HE)
				explosion(epicenter, explosion_strength[1], explosion_strength[2], explosion_strength[3])

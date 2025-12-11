var/emissive_alpha = 0
/datum/quirk/always_dirty
	name = "Always dirty"
	desc = "Be it for your biology, poor hygiene or a curse, you are always dirty! God, it's EVERYWHERE! Poor janitors..."
	value = 0
	icon = FA_ICON_SHOE_PRINTS
	gain_text = span_notice("You feel perpetually grimy.")
	lose_text = span_notice("You finally feel clean again.")
	medical_record_text = "Subject constantly leaves dirt wherever they go."


/obj/effect/decal/cleanable/dirty/footprints
	name = "dirty footprints"
	desc = "Oh god, it's ALL OVER."
	icon = 'icons/effects/footprints.dmi'
	icon_state = "blood1"

	var/entered_dirs = NONE
	var/exited_dirs = NONE
	dir = NONE
	/// Lazylist of species that have made footprints here. (YOINKED FROM BLOOD.DM - raph)
	var/list/species_types



/datum/quirk/always_dirty/add(client/C)
	..()

	if(isnull(C))
		world.log << "[src]: add() — client is null!"
		return

	var/mob/living/carbon/human/H = null

	if(!isnull(quirk_holder))
		H = quirk_holder
	else if(!isnull(C.mob) && istype(C.mob, /mob/living/carbon/human))
		H = C.mob

	if(isnull(H))
		world.log << "Always dirty: Could not find valid mob for client [C]"
		return

	RegisterSignal(H, COMSIG_MOVABLE_MOVED, PROC_REF(dirty_stain))
	world.log << "Always dirty: Registered COMSIG_MOVABLE_MOVED on [H]"
	world.log << "DEBUG(add): quirk_holder=[quirk_holder], C=[C], H=[H]"


/datum/quirk/always_dirty/remove(mob/living/carbon/human/H)
	..()

	if(isnull(H))
		return

	UnregisterSignal(H, COMSIG_MOVABLE_MOVED)
	world.log << "[src]: Unregistered signal for [H.real_name]"



/datum/quirk/always_dirty/proc/dirty_stain(datum/source, atom/old_loc, dir, Forced)
	SIGNAL_HANDLER
	world.log << "DEBUG(dirty_stain): source=[source] old_loc=[old_loc] dir=[dir] Forced=[Forced]"
	var/mob/living/m = source
	if(!m)
		return

	var/dir_used = dir ? dir : m.dir

	var/turf/old_t = get_turf(old_loc)
	var/turf/new_t = get_turf(m)

	if(!old_t || !new_t)
		return

	// EXIT footprint on the old tile
	var/obj/effect/decal/cleanable/dirty/footprints/Fexit = new /obj/effect/decal/cleanable/dirty/footprints(old_t)
	world.log << "DEBUG: Created EXIT footprint=[Fexit] at [old_t], exited_dirs=[Fexit.exited_dirs] dir=[Fexit.dir]"
	Fexit.exited_dirs |= dir_used
	Fexit.setDir(dir_used)

	// ENTER footprint on the new tile
	var/obj/effect/decal/cleanable/dirty/footprints/Fenter = new /obj/effect/decal/cleanable/dirty/footprints(new_t)
	world.log << "DEBUG: Created ENTER footprint=[Fenter] at [new_t], entered_dirs=[Fenter.entered_dirs]"

	Fenter.entered_dirs |= dir_used
	Fenter.setDir(dir_used)

/obj/effect/decal/cleanable/dirty/footprints/setDir(newdir)
	if(dir == newdir)
		return ..()
	world.log << "setDir PROC SIGNALED"
	var/ang_change = dir2angle(newdir) - dir2angle(dir)
	var/old_entered_dirs = entered_dirs
	var/old_exited_dirs = exited_dirs
	entered_dirs = NONE
	exited_dirs = NONE

	for(var/dir in GLOB.cardinals)
		if(old_entered_dirs & dir)
			entered_dirs |= angle2dir_cardinal(dir2angle(dir) + ang_change)
		if(old_exited_dirs & dir)
			exited_dirs |= angle2dir_cardinal(dir2angle(dir) + ang_change)

	update_appearance()
	return ..()
/obj/effect/decal/cleanable/dirty/footprints/update_overlays()
	. = ..()
	var/static/list/dirty_footprints_cache = list()
	var/icon_state_to_use = "blood"
	if(LAZYACCESS(species_types, BODYPART_ID_DIGITIGRADE))
		icon_state_to_use += "claw"
	else if(LAZYACCESS(species_types, SPECIES_MONKEY))
		icon_state_to_use += "paw"
	else if(LAZYACCESS(species_types, "bot"))
		icon_state_to_use += "bot"

	for(var/dir in GLOB.cardinals)
		if(entered_dirs & dir)
			var/enter_state = "entered-[icon_state_to_use]-[2]"
			var/image/dirtystep_overlay = dirty_footprints_cache[enter_state]
			if(!dirtystep_overlay)
				dirtystep_overlay = image(icon, "[icon_state_to_use]1", dir = dir)
				dirty_footprints_cache[enter_state] = dirtystep_overlay
			. += dirtystep_overlay

			if(emissive_alpha && emissive_alpha)
				var/enter_emissive_state = "[enter_state]_emissive-[emissive_alpha]"
				var/mutable_appearance/emissive_overlay = dirty_footprints_cache[enter_emissive_state]
				if(!emissive_overlay)
					emissive_overlay = dirty_emissive(icon, "[icon_state_to_use]1")
					emissive_overlay.dir = dir
					dirty_footprints_cache[enter_emissive_state] = emissive_overlay
				. += emissive_overlay

		if(exited_dirs & dir)
			var/exit_state = "exited-[icon_state_to_use]-[4]"
			var/image/dirtystep_overlay = dirty_footprints_cache[exit_state]
			if(!dirtystep_overlay)
				dirtystep_overlay = image(icon, "[icon_state_to_use]2", dir = dir)
				dirty_footprints_cache[exit_state] = dirtystep_overlay
			. += dirtystep_overlay

			if(emissive_alpha && emissive_alpha)
				var/exit_emissive_state = "[exit_state]_emissive-[emissive_alpha]"
				var/mutable_appearance/emissive_overlay = dirty_footprints_cache[exit_emissive_state]
				if(!emissive_overlay)
					emissive_overlay = dirty_emissive(icon, "[icon_state_to_use]2")
					emissive_overlay.dir = dir
					dirty_footprints_cache[exit_emissive_state] = emissive_overlay
				. += emissive_overlay

/obj/effect/decal/cleanable/dirty/proc/dirty_emissive(icon_to_use, icon_state_to_use)
	return emissive_appearance(icon_to_use, icon_state_to_use, src, alpha = 255 * emissive_alpha / alpha, effect_type = EMISSIVE_NO_BLOOM)

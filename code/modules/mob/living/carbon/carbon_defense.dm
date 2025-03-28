/mob/living/carbon/get_eye_protection()
	. = ..()
	if(HAS_TRAIT(src, TRAIT_BLIND))
		return INFINITY //Can't get flashed if you cant see
	var/obj/item/organ/eyes/E = getorganslot(ORGAN_SLOT_EYES)
	if(!E)
		return INFINITY //Can't get flashed without eyes
	else
		. += E.flash_protect
	if(isclothing(head)) //Adds head protection
		. += head.flash_protect
	if(isclothing(glasses)) //Glasses
		. += glasses.flash_protect
	if(isclothing(wear_mask)) //Mask
		. += wear_mask.flash_protect

/mob/living/carbon/get_ear_protection()
	. = ..()
	var/obj/item/organ/ears/E = getorganslot(ORGAN_SLOT_EARS)
	if(!E)
		return INFINITY
	else
		. += E.bang_protect

/mob/living/carbon/is_mouth_covered(head_only = 0, mask_only = 0)
	if( (!mask_only && head && (head.flags_cover & HEADCOVERSMOUTH)) || (!head_only && wear_mask && (wear_mask.flags_cover & MASKCOVERSMOUTH)) )
		return TRUE

/mob/living/carbon/is_eyes_covered(check_glasses = TRUE, check_head = TRUE, check_mask = TRUE)
	if(check_head && head && (head.flags_cover & HEADCOVERSEYES))
		return head
	if(check_mask && wear_mask && (wear_mask.flags_cover & MASKCOVERSEYES))
		return wear_mask
	if(check_glasses && glasses && (glasses.flags_cover & GLASSESCOVERSEYES))
		return glasses

/mob/living/carbon/check_projectile_dismemberment(obj/projectile/P, def_zone)
	var/obj/item/bodypart/affecting = get_bodypart(def_zone)
	if(affecting && affecting.dismemberable && affecting.get_damage() >= (affecting.max_damage - P.dismemberment))
		affecting.dismember(P.damtype)

/mob/living/carbon/proc/can_catch_item(skip_throw_mode_check)
	. = FALSE
	if(!skip_throw_mode_check && !in_throw_mode)
		return
	if(get_active_held_item())
		return
	if(!(mobility_flags & MOBILITY_MOVE))
		return
	if(restrained())
		return
	return TRUE

/mob/living/carbon/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	var/obj/item/I = AM
	if(istype(I, /obj/item))
		if(((throwingdatum ? throwingdatum.speed : I.throw_speed) >= EMBED_THROWSPEED_THRESHOLD) || I.embedding.embedded_ignore_throwspeed_threshold)
			var/obj/item/bodypart/body_part = pick(bodyparts)
			if(prob(clamp(I.embedding.embed_chance - run_armor_check(body_part, MELEE), 0, 100)) && embed_object(I, body_part, deal_damage = TRUE))
				hitpush = FALSE
				skipcatch = TRUE //can't catch the now embedded item
		if(!skipcatch)	//ugly, but easy
			if(can_catch_item())
				if(I.item_flags & UNCATCHABLE)
					return FALSE
				if(isturf(I.loc))
					I.attack_hand(src)
					if(get_active_held_item() == I) //if our attack_hand() picks up the item...
						visible_message(span_warning("[src] catches [I]!")) //catch that sucker!
						update_inv_hands()
						I.pixel_x = initial(I.pixel_x)
						I.pixel_y = initial(I.pixel_y)
						I.transform = initial(I.transform)
						throw_mode_off()
						return TRUE
	..()

/**
  *	Embeds an object into this carbon
  */
/mob/living/carbon/proc/embed_object(obj/item/embedding, part, deal_damage, silent, forced)
	if(!(forced || (can_embed(embedding) && !HAS_TRAIT(src, TRAIT_PIERCEIMMUNE))) || get_embedded_part(embedding))
		return FALSE
	var/obj/item/bodypart/body_part = part
	// In case its a zone
	if(!istype(body_part) && body_part)
		body_part = get_bodypart(body_part)
	// Otherwise pick one
	if(!istype(body_part))
		body_part = pick(bodyparts)
		// Thats probably not good
		if(!istype(body_part))
			return FALSE
	if(CHECK_BITFIELD(SEND_SIGNAL(embedding, COMSIG_ITEM_EMBEDDED, src), COMSIG_ITEM_BLOCK_EMBED) || !embedding)
		return FALSE
	LAZYADD(body_part.embedded_objects, embedding)
	if(embedding.embedding.embedded_bleed_rate)
		embedding.add_mob_blood(src)//it embedded itself in you, of course it's bloody!
	embedding.forceMove(src)
	SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "embedded", /datum/mood_event/embedded)
	if(deal_damage)
		body_part.receive_damage(embedding.w_class*embedding.embedding.embedded_impact_pain_multiplier, wound_bonus=-30, sharpness = TRUE)
	if(!silent)
		throw_alert("embeddedobject", /atom/movable/screen/alert/embeddedobject)
		visible_message(span_danger("[embedding] embeds itself in [src]'s [body_part.name]!"), span_userdanger("[embedding] embeds itself in your [body_part.name]!"))
	return TRUE

/**
  *	Removes the given embedded object from this carbon
  */
/mob/living/carbon/proc/remove_embedded_object(obj/item/embedded, new_loc, silent, forced, unsafe)
	var/obj/item/bodypart/body_part = get_embedded_part(embedded)
	if(!body_part)
		return FALSE
	var/sig_return = SEND_SIGNAL(embedded, COMSIG_ITEM_EMBED_REMOVAL, src)
	if(CHECK_BITFIELD(sig_return, COMSIG_ITEM_BLOCK_EMBED_REMOVAL))
		LAZYADD(body_part.embedded_objects, embedded)
		return FALSE
	LAZYREMOVE(body_part.embedded_objects, embedded)
	if(unsafe)
		var/damage_amount = embedded.embedding.embedded_unsafe_removal_pain_multiplier * embedded.w_class
		if(embedded.embedding.embedded_bleed_rate)
			body_part.receive_damage(damage_amount * 0.25, sharpness = SHARP_EDGED)//It hurts to rip it out, get surgery you dingus.
			body_part.check_wounding(WOUND_SLASH, damage_amount, 20, 0)
		else
			body_part.receive_damage(stamina = damage_amount * 0.25, sharpness = SHARP_EDGED)//Non-harmful stuff causes stamina damage when removed

		if(!silent && damage_amount)
			INVOKE_ASYNC(src, TYPE_PROC_REF(/mob, emote), "scream")

	if(!has_embedded_objects())
		clear_alert("embeddedobject")
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "embedded")
	if(CHECK_BITFIELD(sig_return, COMSIG_ITEM_QDEL_EMBED_REMOVAL))
		qdel(embedded)
	else if(new_loc)
		embedded.forceMove(new_loc)
	return TRUE

/**
  *	Called when a mob tries to remove an embedded object from this carbon
  */
/mob/living/carbon/proc/try_remove_embedded_object(mob/user)
	var/list/choice_list = list()
	var/obj/item/bodypart/body_part
	for(var/obj/item/bodypart/part in bodyparts)
		for(var/obj/item/embedded in part.embedded_objects)
			choice_list[embedded] = image(embedded)
	var/obj/item/choice = show_radial_menu(user, src, choice_list, tooltips = TRUE)
	body_part = get_embedded_part(choice)
	if(!istype(choice) || !(choice in choice_list))
		return
	var/time_taken = choice.embedding.embedded_unsafe_removal_time * choice.w_class
	user.visible_message(span_warning("[user] attempts to remove [choice] from [user.p_their()] [body_part.name]."),span_notice("You attempt to remove [choice] from your [body_part.name]... (It will take [DisplayTimeText(time_taken)].)"))
	if(!do_after(user, time_taken, target = src) && !(choice in body_part.embedded_objects))
		return
	if(remove_embedded_object(choice, get_turf(src), unsafe = TRUE) && !QDELETED(choice))
		user.put_in_hands(choice)
		user.visible_message("[user] successfully rips [choice] out of [user == src? p_their() : "[src]'s"] [body_part.name]!", span_notice("You successfully remove [choice] from your [body_part.name]."))
	return TRUE

/**
  *	Returns the bodypart that the item is embedded in or returns false if it is not currently embedded
  */
/mob/living/carbon/proc/get_embedded_part(obj/item/embedded)
	if(!embedded)
		return FALSE
	var/obj/item/bodypart/body_part
	for(var/obj/item/bodypart/part in bodyparts)
		if(embedded in part.embedded_objects)
			body_part = part
	if(!body_part)
		return FALSE

	if(embedded.loc != src)
		LAZYREMOVE(body_part.embedded_objects, embedded)
		if(!has_embedded_objects())
			clear_alert("embeddedobject")
			SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "embedded")
		return FALSE
	return body_part

/**
  *	Returns a list of all embedded objects
  */
/mob/living/carbon/proc/get_embedded_objects()
	for(var/obj/item/bodypart/part in bodyparts)
		if(part.embedded_objects)
			LAZYADD(., part.embedded_objects)

/mob/living/carbon/proc/get_interaction_efficiency(zone)
	var/obj/item/bodypart/limb = get_bodypart(zone)
	if(!limb)
		return

/mob/living/carbon/attacked_by(obj/item/I, mob/living/user)
	var/obj/item/bodypart/affecting
	if(user == src)
		affecting = get_bodypart(check_zone(user.zone_selected)) //we're self-mutilating! yay!
	else
		var/zone_hit_chance = 80
		if(!(mobility_flags & MOBILITY_STAND)) // half as likely to hit a different zone if they're on the ground
			zone_hit_chance += 10
		affecting = get_bodypart(ran_zone(user.zone_selected, zone_hit_chance))
	if(!affecting) //missing limb? we select the first bodypart (you can never have zero, because of chest)
		affecting = bodyparts[1]
	SEND_SIGNAL(I, COMSIG_ITEM_ATTACK_ZONE, src, user, affecting)
	send_item_attack_message(I, user, affecting.name, affecting)
	if(I.force)
		var/attack_direction = get_dir(user, src)
		apply_damage(I.force, I.damtype, affecting, wound_bonus = I.wound_bonus, bare_wound_bonus = I.bare_wound_bonus, sharpness = I.sharpness, attack_direction = attack_direction)
		if(I.damtype == BRUTE && affecting.status == BODYPART_ORGANIC)
			if(prob(33))
				I.add_mob_blood(src)
				var/turf/location = get_turf(src)
				add_splatter_floor(location)
				if(get_dist(user, src) <= 1)	//people with TK won't get smeared with blood
					user.add_mob_blood(src)
				if(affecting.body_zone == BODY_ZONE_HEAD)
					if(wear_mask)
						wear_mask.add_mob_blood(src)
						update_inv_wear_mask()
					if(wear_neck)
						wear_neck.add_mob_blood(src)
						update_inv_neck()
					if(head)
						head.add_mob_blood(src)
						update_inv_head()

		return TRUE //successful attack

/mob/living/carbon/send_item_attack_message(obj/item/I, mob/living/user, hit_area, obj/item/bodypart/hit_bodypart)
	var/message_verb = "attacked"
	if(length(I.attack_verb))
		message_verb = "[pick(I.attack_verb)]"
	else if(!I.force)
		return

	var/extra_wound_details = ""
	if(I.damtype == BRUTE && hit_bodypart.can_dismember())
		var/mangled_state = hit_bodypart.get_mangled_state()
		var/bio_state = get_biological_state()
		if(mangled_state == BODYPART_MANGLED_BOTH)
			extra_wound_details = ", threatening to sever it entirely"
		else if((mangled_state == BODYPART_MANGLED_FLESH && I.get_sharpness()) || (mangled_state & BODYPART_MANGLED_BONE && bio_state == BIO_JUST_BONE))
			extra_wound_details = ", [I.get_sharpness() == SHARP_EDGED ? "slicing" : "piercing"] through to the bone"
		else if((mangled_state == BODYPART_MANGLED_BONE && I.get_sharpness()) || (mangled_state & BODYPART_MANGLED_FLESH && bio_state == BIO_JUST_FLESH))
			extra_wound_details = ", [I.get_sharpness() == SHARP_EDGED ? "slicing" : "piercing"] at the remaining tissue"

	var/message_hit_area = ""
	if(hit_area)
		message_hit_area = " in the [hit_area]"
	var/attack_message = "[src] is [message_verb][message_hit_area] with [I][extra_wound_details]!"
	var/attack_message_local = "You're [message_verb][message_hit_area] with [I][extra_wound_details]!"
	if(user in viewers(src, null))
		attack_message = "[user] [message_verb] [src][message_hit_area] with [I][extra_wound_details]!"
		attack_message_local = "[user] [message_verb] you[message_hit_area] with [I][extra_wound_details]!"
	if(user == src)
		attack_message_local = "You [message_verb] yourself[message_hit_area] with [I][extra_wound_details]"
	visible_message(span_danger("[attack_message]"),\
		span_userdanger("[attack_message_local]"), null, COMBAT_MESSAGE_RANGE)
	return TRUE

/mob/living/carbon/attack_drone(mob/living/simple_animal/drone/user)
	return //so we don't call the carbon's attack_hand().

//ATTACK HAND IGNORING PARENT RETURN VALUE
/mob/living/carbon/attack_hand(mob/living/carbon/human/user, modifiers)

	for(var/thing in diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			user.ContactContractDisease(D)

	for(var/thing in user.diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			ContactContractDisease(D)

	for(var/datum/surgery/S in surgeries)
		if(!(mobility_flags & MOBILITY_STAND) || !S.lying_required)
			if((S.self_operable || user != src) && !user.combat_mode)
				if(S.next_step(user, modifiers))
					return TRUE

	for(var/datum/wound/W in all_wounds)
		if(W.try_handling(user))
			return TRUE

	return FALSE


/mob/living/carbon/attack_paw(mob/living/carbon/monkey/M, modifiers)

	if(can_inject(M, TRUE))
		for(var/thing in diseases)
			var/datum/disease/D = thing
			if((D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN) && prob(85))
				M.ContactContractDisease(D)

	for(var/thing in M.diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			ContactContractDisease(D)

	if(!M.combat_mode)
		help_shake_act(M)
		return FALSE

	if(..()) //successful monkey bite.
		for(var/thing in M.diseases)
			var/datum/disease/D = thing
			ForceContractDisease(D)
		return TRUE


/mob/living/carbon/attack_slime(mob/living/simple_animal/slime/M)
	. = ..()
	if(.) //successful slime attack
		if(M.powerlevel > 0)
			var/dazeprob = M.powerlevel * 10  // 10 at level 1, 100 at level 10
			if(!prob(dazeprob))
				return

			visible_message(span_danger("The [M.name] has dazed [src]!"), span_userdanger("The [M.name] has dazed [src]!"))

			var/power = M.powerlevel + rand(0,3)
			set_stutter_if_lower(power SECONDS)
			Daze(power SECONDS)
		return

/mob/living/carbon/proc/dismembering_strike(mob/living/attacker, dam_zone)
	if(!attacker.limb_destroyer)
		return dam_zone
	var/obj/item/bodypart/affecting
	if(dam_zone && attacker.client)
		affecting = get_bodypart(ran_zone(dam_zone))
	else
		var/list/things_to_ruin = shuffle(bodyparts.Copy())
		for(var/B in things_to_ruin)
			var/obj/item/bodypart/bodypart = B
			if(bodypart.body_zone == BODY_ZONE_HEAD || bodypart.body_zone == BODY_ZONE_CHEST)
				continue
			if(!affecting || ((affecting.get_damage() / affecting.max_damage) < (bodypart.get_damage() / bodypart.max_damage)))
				affecting = bodypart
	if(affecting)
		dam_zone = affecting.body_zone
		if(affecting.get_damage() >= affecting.max_damage)
			affecting.dismember()
			return null
		return affecting.body_zone
	return dam_zone


/mob/living/carbon/blob_act(obj/structure/blob/B)
	if (stat == DEAD)
		return
	else
		show_message(span_userdanger("The blob attacks!"))
		adjustBruteLoss(10)

/mob/living/carbon/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return

	if(dna?.species)
		severity *= dna.species.emp_mod
	if(severity < 1)
		return

	var/emp_message = TRUE
	for(var/obj/item/bodypart/BP as anything in get_damageable_bodyparts(BODYPART_ROBOTIC))
		if(!(BP.emp_act(severity, emp_message) & EMP_PROTECT_SELF))
			emp_message = FALSE // if the EMP was successful, don't spam the chat with more messages

/mob/living/carbon/electrocute_act(shock_damage, obj/source, siemens_coeff = 1, zone = HANDS, override = FALSE, tesla_shock = FALSE, illusion = FALSE, stun = TRUE)
	if(tesla_shock && HAS_TRAIT(src, TRAIT_TESLA_IGNORE))
		return FALSE
	if(HAS_TRAIT(src, TRAIT_SHOCKIMMUNE))
		return FALSE
	if(!override) // override variable bypasses protection
		siemens_coeff *= (100 - getarmor(zone, ELECTRIC)) / 100

	var/stuntime = 8*siemens_coeff SECONDS // do this before species adjustments or balancing will be a pain
	if(reagents.has_reagent(/datum/reagent/teslium))
		siemens_coeff *= 1.5 //If the mob has teslium in their body, shocks are 50% more damaging!

	if(SEND_SIGNAL(src, COMSIG_LIVING_ELECTROCUTE_ACT, shock_damage, source, siemens_coeff, zone, tesla_shock) & COMPONENT_NO_ELECTROCUTE_ACT)
		return FALSE

	shock_damage *= siemens_coeff
	if(dna && dna.species)
		shock_damage *= dna.species.siemens_coeff
		dna.species.spec_electrocute_act(src, shock_damage,source,siemens_coeff,zone,override,tesla_shock, illusion, stun)
	if(shock_damage<1 && !override)
		return FALSE

	if(illusion)
		adjustStaminaLoss(shock_damage)
	else
		take_overall_damage(0,shock_damage)
	visible_message(
		span_danger("[src] was shocked by \the [source]!"), \
		span_userdanger("You feel a powerful shock coursing through your body!"), \
		span_italics("You hear a heavy electrical crack.") \
		)
	do_jitter_animation(stuntime * 3)
	adjust_stutter(stuntime / 2)
	adjust_jitter(stuntime * 2)

	if(stun && (!tesla_shock || (tesla_shock && siemens_coeff > 0.5)))
		Paralyze(min(stuntime, 4 SECONDS))
		if(stuntime > 2 SECONDS)
			addtimer(CALLBACK(src, PROC_REF(Paralyze), stuntime - (2 SECONDS)), 2 SECONDS)

	if(stat == DEAD && can_defib()) //yogs: ZZAPP
		if(!illusion && (shock_damage * siemens_coeff >= 1) && prob(80))
			set_heartattack(FALSE)
			adjustOxyLoss(-50)
			adjustToxLoss(-50)
			revive()
			INVOKE_ASYNC(src, PROC_REF(emote), "gasp")
			adjust_jitter(10 SECONDS)
			adjustOrganLoss(ORGAN_SLOT_BRAIN, 100, 199)

	if(undergoing_cardiac_arrest() && !illusion)
		if(shock_damage * siemens_coeff >= 1 && prob(25))
			var/obj/item/organ/heart/heart = getorganslot(ORGAN_SLOT_HEART)
			heart.beating = TRUE
			if(stat == CONSCIOUS)
				to_chat(src, span_notice("You feel your heart beating again!"))

	if(override)
		return override
	else
		return shock_damage

/mob/living/carbon/proc/help_shake_act(mob/living/carbon/M)
	if(try_extinguish(M))
		return

	if(!(mobility_flags & MOBILITY_STAND))
		if(buckled)
			to_chat(M, span_warning("You need to unbuckle [src] first to do that!"))
			return
		M.visible_message(span_notice("[M] shakes [src] trying to get [p_them()] up!"), \
						span_notice("You shake [src] trying to get [p_them()] up!"))

	else if(check_zone(M.zone_selected) == BODY_ZONE_L_ARM || check_zone(M.zone_selected) == BODY_ZONE_R_ARM) //Headpats are too extreme, we have to pat shoulders on yogs
		M.visible_message(span_notice("[M] gives [src] a pat on the shoulder to make [p_them()] feel better!"), \
					span_notice("You give [src] a pat on the shoulder to make [p_them()] feel better!"))

	else
		M.visible_message(span_notice("[M] hugs [src] to make [p_them()] feel better!"), \
					span_notice("You hug [src] to make [p_them()] feel better!"))
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "hug", /datum/mood_event/hug)
		if(HAS_TRAIT(M, TRAIT_FRIENDLY))
			var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
			if (mood.sanity >= SANITY_GREAT)
				new /obj/effect/temp_visual/heart(loc)
				SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "friendly_hug", /datum/mood_event/besthug, M)
			else if (mood.sanity >= SANITY_DISTURBED)
				SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "friendly_hug", /datum/mood_event/betterhug, M)

			if(isethereal(src) && ismoth(M))
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "friendly_hug", /datum/mood_event/lamphug, src)
		for(var/datum/brain_trauma/trauma in M.get_traumas())
			trauma.on_hug(M, src)
		for(var/datum/brain_trauma/trauma in get_traumas())
			trauma.on_hug(M, src)

		var/averagestacks = (fire_stacks + M.fire_stacks)/2 //transfer firestacks between players
		if(averagestacks > 1)
			adjust_fire_stacks(averagestacks)
			M.adjust_fire_stacks(-averagestacks)
			to_chat(src, span_notice("The hug [M] gave covered you in some weird flammable stuff..."))
		else if(averagestacks < -1)
			adjust_wet_stacks(averagestacks)
			M.adjust_wet_stacks(-averagestacks)
			to_chat(src, span_notice("The hug [M] gave you was a little wet..."))

	adjust_status_effects_on_shake_up()

//	adjustStaminaLoss(-10) if you want hugs to recover stamina damage, uncomment this
	set_resting(FALSE)

	playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)

/mob/living/carbon/proc/try_extinguish(mob/living/carbon/C)
	if(!on_fire)
		return FALSE
	if(HAS_TRAIT(C, TRAIT_RESISTHEAT) || HAS_TRAIT(C, TRAIT_RESISTHEATHANDS) || HAS_TRAIT(C, TRAIT_NOFIRE))
		extinguish_mob()
		to_chat(C, span_notice("You extinguish [src]!"))
		to_chat(src, span_userdanger("[C] extinguishes you!"))
		return TRUE
	to_chat(C, span_warning("You can't put [p_them()] out with just your bare hands!"))
	return TRUE

/mob/living/carbon/flash_act(intensity = 1, override_blindness_check = 0, affect_silicon = 0, visual = 0)
	if(NOFLASH in dna?.species?.species_traits)
		return
	var/obj/item/organ/eyes/eyes = getorganslot(ORGAN_SLOT_EYES)
	if(!eyes) //can't flash what can't see!
		return

	. = ..()

	var/damage = intensity - get_eye_protection()
	if(.) // we've been flashed
		if(visual)
			return

		if (damage == 1)
			to_chat(src, span_warning("Your eyes sting a little."))
			if(prob(40))
				eyes.applyOrganDamage(1)

		else if (damage == 2)
			to_chat(src, span_warning("Your eyes burn."))
			eyes.applyOrganDamage(rand(2, 4))

		else if( damage >= 3)
			to_chat(src, span_warning("Your eyes itch and burn severely!"))
			eyes.applyOrganDamage(rand(12, 16))

		if(eyes.damage > 10)
			blind_eyes(damage)
			adjust_eye_blur(damage * rand(3, 6))

			if(eyes.damage > 20)
				if(prob(eyes.damage - 20))
					if(!HAS_TRAIT(src, TRAIT_NEARSIGHT))
						to_chat(src, span_warning("Your eyes start to burn badly!"))
					become_nearsighted(EYE_DAMAGE)

				else if(prob(eyes.damage - 25))
					if(!HAS_TRAIT(src, TRAIT_BLIND))
						to_chat(src, span_warning("You can't see anything!"))
					eyes.applyOrganDamage(eyes.maxHealth)

			else
				to_chat(src, span_warning("Your eyes are really starting to hurt. This can't be good for you!"))
		return TRUE
	else if(damage == 0) // just enough protection
		if(prob(20))
			to_chat(src, span_notice("Something bright flashes in the corner of your vision!"))


/mob/living/carbon/soundbang_act(intensity = 1, conf_pwr = 20, damage_pwr = 5, deafen_pwr = 15)
	var/list/reflist = list(intensity) // Need to wrap this in a list so we can pass a reference
	SEND_SIGNAL(src, COMSIG_CARBON_SOUNDBANG, reflist)
	intensity = reflist[1]
	var/ear_safety = get_ear_protection()
	var/obj/item/organ/ears/ears = getorganslot(ORGAN_SLOT_EARS)
	var/effect_amount = intensity - ear_safety
	if(effect_amount > 0)
		if(conf_pwr)
			adjust_confusion(conf_pwr*effect_amount)

		if(istype(ears) && (deafen_pwr || damage_pwr))
			var/ear_damage = damage_pwr * effect_amount
			var/deaf = deafen_pwr * effect_amount
			adjustEarDamage(ear_damage,deaf)

			if(ears.damage >= 15)
				to_chat(src, span_warning("Your ears start to ring badly!"))
				if(prob(ears.damage - 5))
					to_chat(src, span_userdanger("You can't hear anything!"))
					ears.damage = min(ears.damage, ears.maxHealth)
					// you need earmuffs, inacusiate, or replacement
			else if(ears.damage >= 5)
				to_chat(src, span_warning("Your ears start to ring!"))
			SEND_SOUND(src, sound('sound/weapons/flash_ring.ogg',0,1,0,250))
		return effect_amount //how soundbanged we are


/mob/living/carbon/damage_clothes(damage_amount, damage_type = BRUTE, damage_flag = 0, def_zone)
	if(damage_type != BRUTE && damage_type != BURN)
		return
	damage_amount *= 0.5 //0.5 multiplier for balance reason, we don't want clothes to be too easily destroyed
	if(!def_zone || def_zone == BODY_ZONE_HEAD)
		var/obj/item/clothing/hit_clothes
		if(wear_mask)
			hit_clothes = wear_mask
		if(wear_neck)
			hit_clothes = wear_neck
		if(head)
			hit_clothes = head
		if(hit_clothes)
			hit_clothes.take_damage(damage_amount, damage_type, damage_flag, 0)

/mob/living/carbon/can_hear()
	. = FALSE
	var/obj/item/organ/ears/ears = getorganslot(ORGAN_SLOT_EARS)
	if(istype(ears) && !ears.deaf)
		. = TRUE

/mob/living/carbon/grabbedby(mob/living/carbon/user, supress_message = FALSE)
	if(user != src)
		return ..()

	var/obj/item/bodypart/grasped_part = get_bodypart(zone_selected)
	if(!grasped_part?.get_bleed_rate())
		return
	var/starting_hand_index = active_hand_index
	if(starting_hand_index == grasped_part.held_index)
		to_chat(src, span_danger("You can't grasp your [grasped_part.name] with itself!"))
		return

	to_chat(src, span_warning("You grasp at your [grasped_part.name], trying to stop the bleeding..."))
	if(!do_after(src, 1.5 SECONDS, src))
		to_chat(src, span_danger("You can't get a good enough grip to slow the bleeding on [grasped_part.name]."))
		return

	var/obj/item/self_grasp/grasp = new
	if(starting_hand_index != active_hand_index || !put_in_active_hand(grasp))
		to_chat(src, span_danger("You fail to grasp your [grasped_part.name]."))
		QDEL_NULL(grasp)
		return
	grasp.grasp_limb(grasped_part)

/// an abstract item representing you holding your own limb to staunch the bleeding, see [/mob/living/carbon/proc/grabbedby] will probably need to find somewhere else to put this.
/obj/item/self_grasp
	name = "self-grasp"
	desc = "Sometimes all you can do is slow the bleeding."
	icon = 'icons/obj/weapons/hand.dmi'
	icon_state = "latexballon"
	item_state = "nothing"
	force = 0
	throwforce = 0
	slowdown = 1
	item_flags = DROPDEL | ABSTRACT | NOBLUDGEON | SLOWS_WHILE_IN_HAND | HAND_ITEM
	/// The bodypart we're staunching bleeding on, which also has a reference to us in [/obj/item/bodypart/var/grasped_by]
	var/obj/item/bodypart/grasped_part
	/// The carbon who owns all of this mess
	var/mob/living/carbon/user

/obj/item/self_grasp/Destroy()
	if(user)
		to_chat(user, span_warning("You stop holding onto your[grasped_part ? " [grasped_part.name]" : "self"]."))
		UnregisterSignal(user, COMSIG_QDELETING)
	if(grasped_part)
		UnregisterSignal(grasped_part, list(COMSIG_CARBON_REMOVE_LIMB, COMSIG_QDELETING))
		grasped_part.grasped_by = null
	grasped_part = null
	user = null
	return ..()

/// The limb or the whole damn person we were grasping got deleted or dismembered, so we don't care anymore
/obj/item/self_grasp/proc/qdel_void()
	qdel(src)

/// We've already cleared that the bodypart in question is bleeding in [the place we create this][/mob/living/carbon/proc/grabbedby], so set up the connections
/obj/item/self_grasp/proc/grasp_limb(obj/item/bodypart/grasping_part)
	user = grasping_part.owner
	if(!istype(user))
		stack_trace("[src] attempted to try_grasp() with [istype(user, /datum) ? user.type : isnull(user) ? "null" : user] user")
		qdel(src)
		return

	grasped_part = grasping_part
	grasped_part.grasped_by = src
	RegisterSignal(user, COMSIG_QDELETING, PROC_REF(qdel_void))
	RegisterSignals(grasped_part, list(COMSIG_CARBON_REMOVE_LIMB, COMSIG_QDELETING), PROC_REF(qdel_void))

	user.visible_message(span_danger("[user] grasps at [user.p_their()] [grasped_part.name], trying to stop the bleeding."), span_notice("You grab hold of your [grasped_part.name] tightly."), vision_distance=COMBAT_MESSAGE_RANGE)
	playsound(get_turf(src), 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)
	return TRUE

/* Gifts and wrapping paper
 * Contains:
 *		Gifts
 *		Wrapping Paper
 */

/*
 * Gifts
 */

GLOBAL_LIST_EMPTY(possible_gifts)

/obj/item/a_gift
	name = "gift"
	desc = "PRESENTS!!!! eek!"
	icon = 'icons/obj/storage.dmi'
	icon_state = "giftdeliverypackage3"
	item_state = "gift"
	resistance_flags = FLAMMABLE

	var/obj/item/contains_type

	var/should_have_victim = FALSE
	var/datum/weakref/victim

/obj/item/a_gift/Initialize(mapload)
	. = ..()
	pixel_x = rand(-10,10)
	pixel_y = rand(-10,10)
	icon_state = "giftdeliverypackage[rand(1,5)]"

	contains_type = get_gift_type()
	if(should_have_victim)
		var/list/eligible_victims = list()
		for(var/mob/player in GLOB.player_list)
			if(player.client && player.stat <= SOFT_CRIT && SSjob.GetJob(player.mind.assigned_role) && !HAS_TRAIT(player.mind, TRAIT_CANNOT_OPEN_PRESENTS))
				eligible_victims |= player
		if(eligible_victims.len > 0)
			victim = WEAKREF(pick(eligible_victims))

/obj/item/a_gift/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] peeks inside [src] and cries [user.p_them()]self to death! It looks like [user.p_they()] [user.p_were()] on the naughty list..."))
	return (BRUTELOSS)

/obj/item/a_gift/examine(mob/M)
	. = ..()
	var/mob/living/victim_ref = victim?.resolve()
	if(istype(victim_ref))
		. += span_notice("It has <b>[victim_ref]</b>'s name on it.")
	else
		. += span_notice("It lacks a name tag. Anyone can claim it!")
	if((M.mind && HAS_TRAIT(M.mind, TRAIT_PRESENT_VISION)) || isobserver(M))
		. += span_notice("It contains \a [initial(contains_type.name)].")

/obj/item/a_gift/attack_self(mob/M)
	if(M.mind && HAS_TRAIT(M.mind, TRAIT_CANNOT_OPEN_PRESENTS))
		to_chat(M, span_warning("You're supposed to be spreading gifts, not opening them yourself!"))
		return

	var/mob/living/victim_ref = victim?.resolve()
	if(istype(victim_ref) && victim_ref != M)
		to_chat(M, span_warning("This isn't your gift!"))
		return

	qdel(src)

	var/obj/item/I = new contains_type(get_turf(M))
	M.visible_message(span_notice("[M] unwraps \the [src], finding \a [I] inside!"))
	I.investigate_log("([I.type]) was found in a present by [key_name(M)].", INVESTIGATE_PRESENTS)
	M.put_in_hands(I)
	I.add_fingerprint(M)

/obj/item/a_gift/proc/get_gift_type()
	var/gift_type_list = list(/obj/item/sord,
		/obj/item/storage/wallet,
		/obj/item/storage/photo_album,
		/obj/item/storage/box/snappops,
		/obj/item/storage/crayons,
		/obj/item/storage/belt/champion,
		/obj/item/soap/deluxe,
		/obj/item/pickaxe/diamond,
		/obj/item/pen/invisible,
		/obj/item/lipstick/random,
		/obj/item/grenade/smokebomb,
		/obj/item/grown/corncob,
		/obj/item/poster/random_contraband,
		/obj/item/poster/random_official,
		/obj/item/book/manual/wiki/barman_recipes,
		/obj/item/book/manual/chef_recipes,
		/obj/item/bikehorn,
		/obj/item/toy/beach_ball,
		/obj/item/toy/beach_ball/holoball,
		/obj/item/reagent_containers/food/snacks/grown/ambrosia/deus,
		/obj/item/reagent_containers/food/snacks/grown/ambrosia/vulgaris,
		/obj/item/computer_hardware/paicard,
		/obj/item/instrument/violin,
		/obj/item/instrument/guitar,
		/obj/item/storage/belt/utility/full,
		/obj/item/clothing/neck/tie/horrible,
		/obj/item/clothing/suit/jacket/leather,
		/obj/item/clothing/suit/jacket/leather/overcoat,
		/obj/item/clothing/suit/poncho,
		/obj/item/clothing/suit/poncho/green,
		/obj/item/clothing/suit/poncho/red,
		/obj/item/clothing/suit/snowman,
		/obj/item/clothing/head/snowman,
		/obj/item/stack/sheet/mineral/coal)

	gift_type_list += subtypesof(/obj/item/clothing/head/collectable)
	gift_type_list += subtypesof(/obj/item/toy) - (((typesof(/obj/item/toy/cards) - /obj/item/toy/cards/deck) + /obj/item/toy/figure + /obj/item/toy/ammo + typesof(/obj/item/toy/plush/goatplushie/angry/kinggoat))) //All toys, except for abstract types and syndicate cards and the stupid fuckign goat.

	var/gift_type = pick(gift_type_list)

	return gift_type


/obj/item/a_gift/anything
	name = "christmas gift"
	desc = "It could be anything!"

/obj/item/a_gift/anything/get_gift_type()
	if(!GLOB.possible_gifts.len)
		var/list/gift_types_list = subtypesof(/obj/item)
		for(var/V in gift_types_list)
			var/obj/item/I = V
			if((!initial(I.icon_state)) || (!initial(I.item_state)) || (initial(I.item_flags) & ABSTRACT))
				gift_types_list -= V
		GLOB.possible_gifts = gift_types_list
	var/gift_type = pick(GLOB.possible_gifts)

	return gift_type

/obj/item/a_gift/anything/personal
	should_have_victim = TRUE

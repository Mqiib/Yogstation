#define PARTY_COOLDOWN_LENGTH_MIN 6 MINUTES
#define PARTY_COOLDOWN_LENGTH_MAX 12 MINUTES


/datum/station_trait/lucky_winner
	name = "Lucky winner"
	trait_type = STATION_TRAIT_POSITIVE
	weight = 1
	show_in_report = TRUE
	report_message = "Your station has won the grand prize of the annual station charity event. Free snacks will be delivered to the bar every now and then."
	trait_processes = TRUE
	COOLDOWN_DECLARE(party_cooldown)

/datum/station_trait/lucky_winner/on_round_start()
	. = ..()
	COOLDOWN_START(src, party_cooldown, rand(PARTY_COOLDOWN_LENGTH_MIN, PARTY_COOLDOWN_LENGTH_MAX))

/datum/station_trait/lucky_winner/process(delta_time)
	if(!COOLDOWN_FINISHED(src, party_cooldown))
		return

	COOLDOWN_START(src, party_cooldown, rand(PARTY_COOLDOWN_LENGTH_MIN, PARTY_COOLDOWN_LENGTH_MAX))

	var/area/area_to_spawn_in = pick(GLOB.bar_areas)
	var/turf/T = pick(area_to_spawn_in.contents)

	var/obj/structure/closet/supplypod/centcompod/toLaunch = new()
	var/obj/item/pizzabox/pizza_to_spawn = pick(list(/obj/item/pizzabox/margherita, /obj/item/pizzabox/mushroom, /obj/item/pizzabox/meat, /obj/item/pizzabox/vegetable, /obj/item/pizzabox/pineapple))
	new pizza_to_spawn(toLaunch)
	for(var/i in 1 to 6)
		new /obj/item/reagent_containers/food/drinks/beer(toLaunch)
	new /obj/effect/DPtarget(T, toLaunch)

/datum/station_trait/galactic_grant
	name = "Galactic grant"
	trait_type = STATION_TRAIT_POSITIVE
	weight = 5
	show_in_report = TRUE
	report_message = "Your station has been selected for a special grant. Some extra funds has been made available to your cargo department."

/datum/station_trait/galactic_grant/on_round_start()
	var/datum/bank_account/cargo_bank = SSeconomy.get_dep_account(ACCOUNT_CAR)
	cargo_bank.adjust_money(rand(2000, 5000))

/datum/station_trait/premium_internals_box
	name = "Premium internals boxes"
	trait_type = STATION_TRAIT_POSITIVE
	weight = 10
	show_in_report = TRUE
	report_message = "The internals boxes for your crew have been filled with bonus equipment."
	trait_to_give = STATION_TRAIT_PREMIUM_INTERNALS

/datum/station_trait/bountiful_bounties
	name = "Bountiful bounties"
	trait_type = STATION_TRAIT_POSITIVE
	weight = 5
	show_in_report = TRUE
	report_message = "It seems collectors in this system are extra keen to providing bounties, and will pay more to see their completion."

/datum/station_trait/bountiful_bounties/on_round_start()
	SSeconomy.bounty_modifier *= 1.2

/datum/station_trait/strong_supply_lines
	name = "Strong supply lines"
	trait_type = STATION_TRAIT_POSITIVE
	weight = 5
	show_in_report = TRUE
	report_message = "Prices are low in this system, BUY BUY BUY!"
	blacklist = list(/datum/station_trait/distant_supply_lines)


/datum/station_trait/strong_supply_lines/on_round_start()
	SSeconomy.pack_price_modifier *= 0.8

/datum/station_trait/scarves
	name = "Scarves"
	trait_type = STATION_TRAIT_POSITIVE
	weight = 5
	show_in_report = TRUE
	var/list/scarves

/datum/station_trait/scarves/New()
	. = ..()
	report_message = pick(
		"Nanotrasen is experimenting with seeing if neck warmth improves employee morale.",
		"After Space Fashion Week, scarves are the hot new accessory.",
		"Everyone was simultaneously a little bit cold when they packed to go to the station.",
		"The station is definitely not under attack by neck grappling aliens masquerading as wool. Definitely not.",
		"You all get free scarves. Don't ask why.",
		"A shipment of scarves was delivered to the station.",
	)
	scarves = typesof(/obj/item/clothing/neck/scarf) + list(
		/obj/item/clothing/neck/stripedredscarf,
		/obj/item/clothing/neck/stripedgreenscarf,
		/obj/item/clothing/neck/stripedbluescarf,
	)

	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_SPAWN, PROC_REF(on_job_after_spawn))

/datum/station_trait/scarves/proc/on_job_after_spawn(datum/source, datum/job/job, mob/living/living_mob, mob/M, joined_late)
	var/scarf_type = pick(scarves)

	living_mob.equip_to_slot_or_del(new scarf_type(living_mob), ITEM_SLOT_NECK)

/datum/station_trait/filled_maint
	name = "Filled up maintenance"
	trait_type = STATION_TRAIT_POSITIVE
	weight = 5
	show_in_report = TRUE
	report_message = "Our workers accidentaly forgot more of their personal belongings in the maintenance areas."
	blacklist = list(/datum/station_trait/empty_maint)
	trait_to_give = STATION_TRAIT_FILLED_MAINT

/datum/station_trait/quick_shuttle
	name = "Quick Shuttle"
	trait_type = STATION_TRAIT_NEUTRAL
	weight = 5
	show_in_report = TRUE
	report_message = "Due to proximity to our supply station, the cargo shuttle will have a quicker flight time to your cargo department."
	blacklist = list(/datum/station_trait/slow_shuttle)

/datum/station_trait/quick_shuttle/on_round_start()
	. = ..()
	SSshuttle.supply.callTime *= 0.5

/datum/station_trait/shuttle_sale
	name = "Shuttle Firesale"
	report_message = "The Nanotrasen Emergency Dispatch team is celebrating a record number of shuttle calls in the recent quarter. Some of your emergency shuttle options have been discounted!"
	trait_type = STATION_TRAIT_POSITIVE
	weight = 4
	trait_to_give = STATION_TRAIT_SHUTTLE_SALE
	show_in_report = TRUE

/datum/station_trait/cybernetic_revolution
	name = "Cybernetic Revolution"
	trait_type = STATION_TRAIT_POSITIVE
	weight = 1
	show_in_report = TRUE
	report_message = "The new trends in cybernetics have come to the station! Everyone has some form of cybernetic implant."
	trait_to_give = STATION_TRAIT_CYBERNETIC_REVOLUTION
	/// List of all job types with the cybernetics they should receive.
	// Should be themed around their job/department. If no theme is possible, a basic cybernetic organ is fine.
	var/static/list/job_to_cybernetic = list(
		/datum/job/assistant = /obj/item/organ/heart/cybernetic,
		/datum/job/artist = /obj/item/organ/heart/cybernetic,
		/datum/job/atmos = /obj/item/organ/cyberimp/mouth/breathing_tube, // Inhaling gases.
		/datum/job/bartender = /obj/item/organ/liver/cybernetic/upgraded, // Drinking their own drinks.
		/datum/job/brigphysician = /obj/item/organ/cyberimp/eyes/hud/medical,
		/datum/job/captain = /obj/item/organ/heart/cybernetic/upgraded,
		/datum/job/cargo_tech = /obj/item/organ/stomach/cybernetic,
		/datum/job/chaplain = /obj/item/organ/cyberimp/brain/anti_drop, // Preventing null rod loss.
		/datum/job/chemist = /obj/item/organ/cyberimp/eyes/hud/science, // For seeing reagents.
		/datum/job/chief_engineer = /obj/item/organ/cyberimp/chest/thrusters,
		/datum/job/clerk = /obj/item/organ/stomach/cybernetic,
		/datum/job/clown = /obj/item/organ/cyberimp/brain/anti_stun, // Funny.
		/datum/job/cmo = /obj/item/organ/cyberimp/chest/reviver,
		/datum/job/cook = /obj/item/organ/cyberimp/chest/nutriment/plus,
		/datum/job/curator = /obj/item/organ/eyes/robotic/glow, // Spookie.
		/datum/job/detective = /obj/item/organ/lungs/cybernetic/upgraded, // Smoker.
		/datum/job/doctor = /obj/item/organ/cyberimp/arm/toolset/surgery,
		/datum/job/engineer = /obj/item/organ/cyberimp/arm/toolset,
		/datum/job/geneticist = /obj/item/organ/stomach/fly,
		/datum/job/head_of_personnel = /obj/item/organ/eyes/robotic,
		/datum/job/hos = /obj/item/organ/cyberimp/brain/anti_drop,
		/datum/job/hydro = /obj/item/organ/cyberimp/chest/nutriment,
		/datum/job/janitor = /obj/item/organ/cyberimp/arm/toolset/janitor,
		/datum/job/lawyer = /obj/item/organ/heart/cybernetic/upgraded,
		/datum/job/mime = /obj/item/organ/tongue/robot, // ...
		/datum/job/mining = /obj/item/organ/cyberimp/chest/reviver, // Replace with a reusable mining-specific implant if one is added later.
		/datum/job/miningmedic = /obj/item/organ/cyberimp/eyes/hud/medical,
		/datum/job/network_admin = /obj/item/organ/cyberimp/arm/toolset,
		/datum/job/officer = /obj/item/organ/cyberimp/arm/flash,
		/datum/job/paramedic = /obj/item/organ/cyberimp/eyes/hud/medical,
		/datum/job/psych = /obj/item/organ/ears/cybernetic,
		/datum/job/qm = /obj/item/organ/stomach/cybernetic,
		/datum/job/rd = /obj/item/organ/cyberimp/eyes/hud/diagnostic, // Replace with a very cool science implant if one is added later.
		/datum/job/roboticist = /obj/item/organ/cyberimp/eyes/hud/diagnostic, // Robots and mechs.
		/datum/job/scientist = /obj/item/organ/cyberimp/eyes/hud/science, // Science, duh.
		/datum/job/tourist = /obj/item/organ/heart/cybernetic,
		/datum/job/virologist = /obj/item/organ/lungs/cybernetic/upgraded,
		/datum/job/warden = /obj/item/organ/cyberimp/eyes/hud/security,
	)

/datum/station_trait/cybernetic_revolution/New()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_SPAWN, PROC_REF(on_job_after_spawn))

/datum/station_trait/cybernetic_revolution/proc/on_job_after_spawn(datum/source, datum/job/job, mob/living/living_mob, mob/new_player_mob, joined_late)
	// Having the Body Purist quirk prevents the effects of this station trait from being applied to you.
	var/datum/quirk/body_purist/body_purist = /datum/quirk/body_purist
	if(initial(body_purist.name) in new_player_mob.client.prefs.all_quirks)
		return

	var/cybernetic_type = job_to_cybernetic[job.type]
	if(cybernetic_type)
		var/obj/item/organ/cybernetic = new cybernetic_type()
		// Timer is needed because doing it immediately doesn't REPLACE organs for some unknown reason, so got to do it next tick or whatever.
		addtimer(CALLBACK(cybernetic, TYPE_PROC_REF(/obj/item/organ, Insert), living_mob, 0, TRUE), 1)
		return

	if(isAI(living_mob))
		var/mob/living/silicon/ai/ai = living_mob
		ai.eyeobj.relay_speech = TRUE
		return

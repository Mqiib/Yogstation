/obj/machinery/vending/wallmed
	name = "\improper NanoMed"
	desc = "Wall-mounted Medical Equipment dispenser."
	icon = 'yogstation/icons/obj/vending.dmi'
	icon_state = "wallmed"
	icon_deny = "wallmed-deny"
	density = FALSE
	products = list(/obj/item/reagent_containers/syringe = 3,
					/obj/item/reagent_containers/pill/patch/styptic = 5,
					/obj/item/reagent_containers/pill/patch/silver_sulf = 5,
					/obj/item/reagent_containers/pill/charcoal = 2,
					/obj/item/healthanalyzer/wound = 2,
					/obj/item/stack/medical/bone_gel = 2)
	contraband = list(/obj/item/reagent_containers/pill/tox = 2,
					/obj/item/reagent_containers/pill/morphine = 2)
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 50, ELECTRIC = 100)
	resistance_flags = FIRE_PROOF
	refill_canister = /obj/item/vending_refill/wallmed
	default_price = 25
	extra_price = 100
	payment_department = ACCOUNT_MED
	tiltable = FALSE
	light_mask = "wall-light-mask"

/obj/item/vending_refill/wallmed
	machine_name = "NanoMed"
	icon_state = "refill_medical"

/obj/mecha/combat/gygax
	desc = "A lightweight, security exosuit. Popular among private and corporate security."
	name = "\improper Gygax"
	icon_state = "gygax"
	step_in = 3
	dir_in = 1 //Facing North.
	max_integrity = 500
	integrity_failure = 250
	deflect_chance = 5
	armor = list(MELEE = 25, BULLET = 20, LASER = 30, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 40, FIRE = 100, ACID = 100)
	max_temperature = 25000
	infra_luminosity = 6
	internal_damage_threshold = 35
	max_equip = 3

/obj/mecha/combat/gygax/dark
	desc = "A lightweight exosuit, painted in a dark scheme. This model appears to have some modifications."
	name = "\improper Dark Gygax"
	icon_state = "darkgygax"
	max_integrity = 300
	deflect_chance = 15
	armor = list(MELEE = 40, BULLET = 40, LASER = 50, ENERGY = 0, BOMB = 20, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	max_temperature = 35000
	operation_req_access = list(ACCESS_SYNDICATE)
	internals_req_access = list(ACCESS_SYNDICATE)
	max_equip = 7
	self_destruct = 4
	destruction_sleep_duration = 20

/obj/mecha/combat/gygax/dark/loaded/Initialize(mapload)
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/carbine
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/flashbang
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/melee_weapon/sword/rapier
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/teleporter
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/tesla_energy_relay
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/emergency_eject
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/thrusters/ion
	ME.attach(src)
	max_ammo()

/obj/mecha/combat/gygax/dark/add_cell(obj/item/stock_parts/cell/C=null)
	if(C)
		C.forceMove(src)
		cell = C
		return
	cell = new /obj/item/stock_parts/cell/hyper(src)


/obj/mecha/combat/gygax/GrantActions(mob/living/user, human_occupant = 0)
	..()
	overload_action.Grant(user, src)

/obj/mecha/combat/gygax/RemoveActions(mob/living/user, human_occupant = 0)
	..()
	overload_action.Remove(user)

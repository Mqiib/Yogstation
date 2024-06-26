/datum/team/kudzu
	name = "Plants"

//Lists the antags & greentext on end round report
/datum/team/kudzu/roundend_report()
	var/list/parts = list()
	//is kudzu alive? if yes, greentext
	var/succeeded = FALSE
	for(var/obj/structure/spacevine/V in world)
		if(is_station_level(V.z))
			succeeded = TRUE
			break
	parts += "<span class='header'>The [name] [succeeded ? "were [span_greentext("successful")]" : "have [span_redtext("failed")]"] in protecting the kudzu!</span>\n"
	parts += "The [name] were:"
	parts += printplayerlist(members)
	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/datum/antagonist/kudzu
	name = "Venus Human Trap"
	job_rank = ROLE_ALIEN
	show_in_antagpanel = FALSE
	show_to_ghosts = TRUE
	var/datum/team/kudzu/kudzu_team

/datum/antagonist/kudzu/create_team(datum/team/kudzu/new_team)
	if(!new_team)
		for(var/datum/antagonist/kudzu/X in GLOB.antagonists)
			if(!X.owner || !X.kudzu_team)
				continue
			kudzu_team = X.kudzu_team
			return
		kudzu_team = new
	else
		if(!istype(new_team))
			CRASH("Wrong kudzu team type provided to create_team")
		kudzu_team = new_team

/datum/antagonist/kudzu/get_team()
	return kudzu_team

//Gives antag datum to minded plants without it
/mob/living/simple_animal/hostile/venus_human_trap/mind_initialize()
	..()
	if(!mind.has_antag_datum(/datum/antagonist/kudzu))
		mind.add_antag_datum(/datum/antagonist/kudzu)

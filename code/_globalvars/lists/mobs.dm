GLOBAL_LIST_EMPTY(clients)							//all clients
GLOBAL_LIST_EMPTY(admins)							//all clients whom are admins
GLOBAL_PROTECT(admins)
GLOBAL_LIST_EMPTY(deadmins)							//all ckeys who have used the de-admin verb.
GLOBAL_LIST_EMPTY(mentors)
GLOBAL_PROTECT(mentors)

GLOBAL_LIST_EMPTY(directory)							//all ckeys with associated client
GLOBAL_LIST_EMPTY(stealthminID)						//reference list with IDs that store ckeys, for stealthmins

//Since it didn't really belong in any other category, I'm putting this here
//This is for procs to replace all the goddamn 'in world's that are chilling around the code

GLOBAL_LIST_EMPTY(player_list)				//all mobs **with clients attached**. Excludes /mob/dead/new_player
GLOBAL_LIST_EMPTY(mob_list)					//all mobs, including clientless
GLOBAL_LIST_EMPTY(mob_directory)            //mob_id -> mob
GLOBAL_LIST_EMPTY(living_mob_list)			//all alive mobs, including clientless. Excludes /mob/dead/new_player
GLOBAL_LIST_EMPTY(dead_mob_list)			//all dead mobs, including clientless. Excludes /mob/dead/new_player
GLOBAL_LIST_EMPTY(joined_player_list)   	//all clients that have joined the game at round-start or as a latejoin.
GLOBAL_LIST_EMPTY(silicon_mobs)				//all silicon mobs
GLOBAL_LIST_EMPTY(ai_list)
GLOBAL_LIST_EMPTY(pai_list)
GLOBAL_LIST_EMPTY(available_ai_shells)
GLOBAL_LIST_EMPTY(simple_animals)

GLOBAL_LIST_EMPTY(language_datum_instances)
GLOBAL_LIST_EMPTY(all_languages)

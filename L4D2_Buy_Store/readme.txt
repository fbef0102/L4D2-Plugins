L4D2 Human and Zombie Shop by HarryPoter
(Survivor) Killing zombies and infected to earn credits + 
(Infected) Doing Damage to survivors to earn credits

-Require-
1. Left 4 DHooks Direct: https://forums.alliedmods.net/showthread.php?p=2684862
2. [INC] Multi Colors: https://forums.alliedmods.net/showthread.php?t=247770
3. To unlock all melee weapons in all campaigns, you MUST use the [Mission and Weapons - Info Editor]("https://forums.alliedmods.net/showthread.php?t=310586") plugin which supersedes the extension.

-ChangeLog-
v4.6
AlliedModder Post: https://forums.alliedmods.net/showpost.php?p=2731889&postcount=18
* Remke code
* Translation Support
* Add The last stand two melee
* Unlock All weapons including M60, Grenade_Launcher, and CSS weapons
* Unlock All items including cola, gnome and fireworkcrate
* Add Infected Shop
* You can earn credits by doing damage to survivors as an infected.
* You can earn credits by helping each other as a survivor.
* Save player's money with Cookies, it means that money can be saved to database across client connections, map changes and even server restarts.
* Add short buy commands, directly buy item.
* Repeat purchase item you bought last time.
* Buy time cooldown, can't buy quickly.

v1.0
-original Post: https://forums.alliedmods.net/showthread.php?t=322108

-Newer Version-
Private: https://github.com/fbef0102/Game-Private_Plugin/tree/main/L4D2_Buy_Store
* Add Survivor/Infected Special items
* Support Database

-ConVar-
cfg\sourcemod\L4D2_Buy_Store.cfg
// If 1, use CookiesCached to save player money. Otherwise, the moeny will not be saved if player leaves the server.
sm_shop_CookiesCached_enable "1"

// Giving money for killing a boomer
sm_shop_boomkilled "10"

// Giving money for killing a charger
sm_shop_chargerkilled "30"

// Can not buy cola in these maps, separate by commas (no spaces). (0=All maps, Empty = none).
sm_shop_cola_map_off "c1m2_streets"

// Giving money for saving people with defibrillator
sm_shop_defi_save "200"

// Giving money to each alive survivor for mission accomplished award (final).
sm_shop_final_mission_complete "3000"

// Giving money to each infected player for wiping out survivors.
sm_shop_final_mission_lost "300"

// Can not buy gas can in these maps, separate by commas (no spaces). (0=All maps, Empty = none).
sm_shop_gascan_map_off "c1m4_atrium,c6m3_port,c14m2_lighthouse"

// Giving money for healing people with kit
sm_shop_heal_teammate "100"

// Giving money for saving incapacitated people. (No Hanging from legde)
sm_shop_help_teammate_save "30"

// Giving money for killing a hunter
sm_shop_hunterkilled "20"

// Cold Down Time in seconds an infected player can not buy again after player buys item. (0=off).
sm_shop_infected_cooltime_block "30.0"

// If 1, Enable shop for infected.
sm_shop_infected_enable "1"

// Giving money for incapacitating a survivor. (No Hanging from legde)
sm_shop_infected_survivor_incap "30"

// Giving money for killing a survivor.
sm_shop_infected_survivor_killed "100"

// Tank limit on the field before infected can buy a tank. (0=Can't buy Tank)
sm_shop_infected_tank_limit "1"

// Infected player must wait until survivors have left start safe area for at least X seconds to buy item. (0=Infected Shop available anytime)
sm_shop_infected_wait_time "10"

// Giving money for killing a jockey
sm_shop_jockeykilled "25"

// Changes how 'You got credits by killing infected' Message displays. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)
sm_shop_kill_infected_announce_type "1"

// Maximum money limit. (Money saved when map change/leaving server)
sm_shop_max_moeny_limit "32000"

// Numbers of real survivor and infected player require to active this plugin.
sm_shop_player_require "4"

// Giving money for killing a smoker
sm_shop_smokerkilled "20"

// Giving money for killing a spitter
sm_shop_spitterkilled "10"

// Giving money to each alive survivor for mission accomplished award (non-final).
sm_shop_stage_complete "400"

// If 1, decrease money if survivor friendly fire each other. (1 hp = 1 dollar)
sm_shop_survivor_TK_enable "1"

// Cold Down Time in seconds a survivor player can not buy again after player buys item. (0=off).
sm_shop_survivor_cooltime_block "5.0"

// Giving one dollar money for hurting tank per X hp
sm_shop_tank_hurt "40"

// Giving money for killing a witch
sm_shop_witchkilled "80"

// Giving money for killing a zombie
sm_shop_zombiekilled "1"

-Command-
**shop and buy (Short name available)
	say "b [item_name]"
	"sm_shop [item_name]"
	"sm_buy [item_name]"
	"sm_b [item_name]"
	"sm_money [item_name]"
	"sm_purchase [item_name]"
	"sm_market [item_name]"
	"sm_item [item_name]"
	"sm_items [item_name]"
	"sm_credit [item_name]"
	"sm_credits [item_name]"
	
	For example:
	say "!buy" or "b" to open shop menu
	say "!buy rifle_ak47" or "b rifle_ak47" to directly buy Ak47 weapon

	****short command list
	I won't add more short names to list, don't ask.
	Weapon
	{
		"!buy pistol" 			-> Pistol
		"!buy pistol_magnum"		-> Magnum
		"!buy pumpshotgun"		-> Pumpshotgun
		"!buy shotgun_chrome"		-> Chrome Shotgun
		"!buy smg"			-> Smg
		"!buy smg_silenced"		-> Silenced Smg
		"!buy smg_mp5"			-> MP5
		"!buy rifle"			-> Rifle
		"!buy rifle_ak47"		-> AK47
		"!buy rifle_desert"		-> Desert Rifle
		"!buy rifle_sg552"		-> SG552
		"!buy shotgun_spas"		-> Spas Shotgun
		"!buy autoshotgun"		-> Autoshotgun
		"!buy hunting_rifle"		-> Hunting Rifle
		"!buy sniper_military"		-> Military Sniper
		"!buy sniper_scout"		-> SCOUT
		"!buy sniper_awp"		-> AWP
		"!buy rifle_m60"		-> M60 Machine Gun
		"!buy grenade_launcher"		-> Grenade Launcher
	}

	Melee
	{
		"!buy chainsaw"			-> Chainsaw
		"!buy baseball_bat"		-> Baseball Bat
		"!buy cricket_bat"		-> Cricket Bat
		"!buy crowbar"			-> Crowbar
		"!buy electric_guitar"		-> Electric Guitar
		"!buy fireaxe"			-> Fire Axe
		"!buy frying_pan"		-> Frying Pan
		"!buy katana"			-> Katana
		"!buy machete"			-> Machete
		"!buy tonfa"			-> Tonfa
		"!buy golfclub"			-> Golf Club
		"!buy knife"			-> Knife
		"!buy pitchfork"		-> Pitchfork
		"!buy shovel"			-> Shovel
	}

	Medic and Throwable
	{
		"!buy health_100"		-> Health+100
		"!buy defibrillator"		-> Defibrillator
		"!buy first_aid_kit"		-> First Aid Kit
		"!buy pain_pills"		-> Pain Pill
		"!buy adrenaline"		-> Adrenaline
		"!buy pipe_bomb"		-> Pipe Bomb
		"!buy molotov"			-> Molotov
		"!buy vomitjar"			-> Vomitjar
	}

	Other
	{
		"!buy ammo"				-> Ammo
		"!buy laser_sight"			-> Laser Sight
		"!buy incendiary_ammo"			-> Incendiary Ammo
		"!buy explosive_ammo"			-> Explosive Ammo
		"!buy weapon_upgradepack_incendiary"	-> Incendiary Pack
		"!buy weapon_upgradepack_explosive"	-> Explosive Pack
		"!buy propanetank"			-> Propane Tank
		"!buy oxygentank"			-> Oxygen Tank
		"!buy fireworkcrate"			-> Firework Crate
		"!buy gascan"				-> Gascan
		"!buy cola_bottles"			-> Cola Bottles
		"!buy gnome"				-> Gnome
	}

	Infected Spawn
	{
		"!buy Suicide" 	-> Suicide
		"!buy Smoker" 	-> Smoker
		"!buy Boomer" 	-> Boomer
		"!buy Hunter" 	-> Hunter
		"!buy Spitter" 	-> Spitter
		"!buy Jockey" 	-> Jockey
		"!buy Charger" 	-> Charger
		"!buy Tank" 	-> Tank
	}

**repeat purchase item you bought last time
	"sm_repeatbuy"
	"sm_lastbuy"

**donate money to another player (Or use "Credits Transfer" in shop menu )
	"sm_pay <name> <money>"
	"sm_donate <name> <money>"
	
**See all players' or specific player's deposit
	"sm_inspectbank [name]"
	"sm_checkbank [name]"
	"sm_lookbank [name]"
	"sm_allbank [name]"

**Adm gives/reduces money (ADMFLAG_BAN)
	"sm_givemoney <name> <+-money>"
	"sm_givecredit <name> <+-money>"

**Adm removes player's all money (ADMFLAG_BAN)
	"sm_clearmoney <name>"
	"sm_deductmoney <name>"

-How to modify the item price-
in scripting\L4D2_Buy_Store.sp line 141
[code]
static char weaponsMenu[][][] = 
{
	{"pistol",		"Pistol", 		"50"},
	{"pistol_magnum",	"Magnum", 		"100"},
	{"pumpshotgun",		"Pumpshotgun", 		"180"},
	{"shotgun_chrome",	"Chrome Shotgun", 	"200"},
	{"smg",			"Smg", 			"180"},
	{"smg_silenced", 	"Silenced Smg", 	"200"},
	{"smg_mp5",		"MP5", 			"250"},
	{"rifle", 		"Rifle", 		"280"},
	{"rifle_ak47", 		"AK47", 		"300"},
	{"rifle_desert",	"Desert Rifle", 	"320"},
	{"rifle_sg552", 	"SG552", 		"350"},
	{"shotgun_spas",	"Spas Shotgun", 	"330"},
	{"autoshotgun", 	"Autoshotgun", 		"330"},
	{"hunting_rifle", 	"Hunting Rifle", 	"300"},
	{"sniper_military", 	"Military Sniper", 	"350"},
	{"sniper_scout", 	"SCOUT", 		"400"},
	{"sniper_awp", 		"AWP",			"500"},
	{"rifle_m60", 		"M60 Machine Gun", 	"1000"},
	{"grenade_launcher","Grenade Launcher",	"1250"}
};

static char meleeMenu[][][] = 
{
	{"chainsaw",		"Chainsaw", 		"300"},
	{"baseball_bat",	"Baseball Bat", 	"250"},
	{"cricket_bat", 	"Cricket Bat", 		"250"},
	{"crowbar", 		"Crowbar", 		"250"},
	{"electric_guitar", 	"Electric Guitar", 	"250"},
	{"fireaxe", 		"Fire Axe", 		"250"},
	{"frying_pan", 		"Frying Pan", 		"250"},
	{"katana", 		"Katana", 		"250"},
	{"machete", 		"Machete", 		"250"},
	{"tonfa", 		"Tonfa", 		"250"},
	{"golfclub", 		"Golf Club", 		"250"},
	{"knife", 		"Knife", 		"250"},
	{"pitchfork", 		"Pitchfork", 		"250"},
	{"shovel", 		"Shovel", 		"250"}
};

static char medicThrowableMenu[][][] =
{
	{"health_100", 		"Health+100", 		"350"},
	{"defibrillator",	"Defibrillator", 	"250"},
	{"first_aid_kit",	"First Aid Kit", 	"250"},
	{"pain_pills", 		"Pain Pill", 		"100"},
	{"adrenaline",	 	"Adrenaline", 		"125"},
	{"pipe_bomb", 		"Pipe Bomb", 		"150"},
	{"molotov", 		"Molotov", 		"200"},
	{"vomitjar", 		"Vomitjar", 		"225"}
};

static char otherMenu[][][] =
{
	{"ammo",		 		"Ammo", 	 		"250"},
	{"laser_sight",				"Laser Sight", 			"50"},
	{"incendiary_ammo",			"Incendiary Ammo", 		"75"},
	{"explosive_ammo",			"Explosive Ammo", 		"100"},
	{"weapon_upgradepack_incendiary",	"Incendiary Pack", 		"200"},
	{"weapon_upgradepack_explosive",	"Explosive Pack", 		"200"},
	{"propanetank", 	 		"Propane Tank", 		"80"},
	{"oxygentank",	 			"Oxygen Tank", 			"80"},
	{"fireworkcrate",			"Firework Crate", 		"300"},
	{"gascan",  				"Gascan",			"1000"},
	{"cola_bottles",  			"Cola Bottles",			"1500"},
	{"gnome",				"Gnome", 			"2000"},
};

static char infectedSpawnMenu[][][] =
{
	{"Suicide",		"Suicide", 			"0"},
	{"Smoker",		"Smoker", 			"350"},
	{"Boomer",		"Boomer", 			"250"},
	{"Hunter",		"Hunter", 			"200"},
	{"Spitter",		"Spitter", 			"400"},
	{"Jockey",		"Jockey", 			"300"},
	{"Charger",		"Charger", 			"350"},
	{"Tank",		"Tank", 			"2500"}
};
[/code]


-Special item list-
***Survivor Shop***
Removed

***Infected Shop***
Removed

(if you want SPECIAL ITEMS, click here: https://github.com/fbef0102/Game-Private_Plugin/tree/main/L4D2_Buy_Store)

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <clientprefs>
#include <left4dhooks>

public Plugin myinfo = 
{
	name = "L4D2 Survivor and Infected Buy Shop", 
	author = "Killing zombies and infected to earn points, Doing Damage to survivors to earn points", 
	description ="Shop by HarryPoter", 
	version = "3.5", 
	url = "https://steamcommunity.com/id/HarryPotter_TW/"
}
#define L4D_TEAM_SPECTATOR		1
#define L4D_TEAM_SURVIVORS 		2
#define L4D_TEAM_INFECTED 		3

#define ZC_SMOKER          1
#define ZC_BOOMER          2
#define ZC_HUNTER          3
#define ZC_SPITTER         4
#define ZC_JOCKEY          5
#define ZC_CHARGER         6
#define ZC_TANK            8

#define	MAX_WEAPONS2       29
#define X_REJUMPBOOST 		250.0
#define MAX_MONEY			16000
#define MODEL_GASCAN			"models/props_junk/gascan001a.mdl"

ConVar g_BoomerKilled,g_ChargerKilled,g_SmokerKilled,g_HunterKilled,g_JockeyKilled,g_SpitterKilled,
	g_WitchKilled,g_ZombieKilled, g_DecayDecay, g_MaxIncapCount, g_PlayerRequired,
	g_hHealTeammate, g_hDefiSave, g_hHelpTeammate, g_hTankHurt,  g_hIncapSurvivor, g_hKillSurvivor,
	g_hCookiesCachedEnable, g_hTKSurvivorEnable, g_hGascanMapOff, g_hColaMapOff, g_hMaxJumpLimit,
	g_hInfiniteAmmoTime, g_hStageComplete, g_hFinalMissionComplete, g_hWipeOutSurvivor, g_hDeadEyeTime,
	g_hInfectedShopEnable, g_hInfectedShopColdDown, g_hImmuneDamageTime, g_hInfectedShopTankLimit;
int g_iBoomerKilled, g_iChargerKilled, g_iSmokerKilled, g_iHunterKilled, g_iJockeyKilled, g_iSpitterKilled,
	g_iWitchKilled, g_iZombieKilled, g_iMaxIncapCount, g_iPlayerRequired, g_iHealTeammate,
	g_iDefiSave, g_iHelpTeammate, g_iTankHurt, g_iIncapSurvivor, g_iKillSurvivor, g_iMaxJumpLimit,
	g_iStageComplete, g_iFinalMissionComplete, g_iWipeOutSurvivor,
	g_iInfiniteAmmoTime, g_iDeadEyeTime, g_iImmuneDamageTime, g_iInfectedShopTankLimit;
bool g_bEnable, g_bTKSurvivorEnable, g_bInfectedShopEnable, g_bCookiesCachedEnable;
float g_fInfectedShopColdDown;

int ammoOffset;	
int g_iCredits[MAXPLAYERS + 1];
Menu g_hSurvivorMenu = null, g_hInfectedMenu = null;
Handle g_hMoneyCookie;
int g_iMenuWeaponPosition[MAXPLAYERS+1] = 0;
int g_iMenuMeleePosition[MAXPLAYERS+1] = 0;
int g_iMenuMedicThrowablePosition[MAXPLAYERS+1] = 0;
int g_iMenuOtherPosition[MAXPLAYERS+1] = 0;
int g_iMenuSpecialPosition[MAXPLAYERS+1] = 0;
int g_iCanJump[MAXPLAYERS+1]; //how many times player can jump on air
int g_iLastButtons[MAXPLAYERS+1];
int g_iJumps[MAXPLAYERS+1];
bool InfiniteAmmo[MAXPLAYERS+1]; //player can Infinite Ammo
bool InfectedImmuneDamage[MAXPLAYERS+1]; //infected player can immune damage
int g_iDamage[MAXPLAYERS+1][MAXPLAYERS+1]; //Used to temporarily store dmg to tank
bool g_bDied[MAXPLAYERS+1]; //tank already dead
int g_iLastHP[MAXPLAYERS+1]; //tank last hp before dead
bool bFinaleEscapeStarted = false, g_bDeadEyeEffect = false;
int g_iModelIndex[MAXPLAYERS+1];			// Player Model entity reference
int g_iTransferSelectPlayer[MAXPLAYERS+1]; //玩家選擇轉移金錢的對象
float g_fInfectedBuyTime[MAXPLAYERS+1];
int g_iLightIndex[MAXPLAYERS+1]; //無敵狀態的光輝

enum EMenuType
{
	eNoneMenu,
	eWeaponMenu,
	eMeleeMenu,
	eMedicThrowableMenu,
	eOtherMenu,
	eSpecialMenu,
	eTransferPlayerMenu,
	eTransferPointMenu,
	eInfectedSpawnMenu,
	eInfectedSpecialMenu
}

static char g_sWeaponModels2[MAX_WEAPONS2][] =
{
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	"models/w_models/weapons/w_pistol_a.mdl",
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/w_models/weapons/w_eq_pipebomb.mdl",
	"models/w_models/weapons/w_eq_medkit.mdl",
	"models/w_models/weapons/w_eq_painpills.mdl",

	"models/w_models/weapons/w_shotgun.mdl",
	"models/w_models/weapons/w_desert_rifle.mdl",
	"models/w_models/weapons/w_grenade_launcher.mdl",
	"models/w_models/weapons/w_m60.mdl",
	"models/w_models/weapons/w_rifle_ak47.mdl",
	"models/w_models/weapons/w_rifle_sg552.mdl",
	"models/w_models/weapons/w_shotgun_spas.mdl",
	"models/w_models/weapons/w_smg_a.mdl",
	"models/w_models/weapons/w_smg_mp5.mdl",
	"models/w_models/weapons/w_sniper_awp.mdl",
	"models/w_models/weapons/w_sniper_military.mdl",
	"models/w_models/weapons/w_sniper_scout.mdl",
	"models/weapons/melee/w_chainsaw.mdl",
	"models/w_models/weapons/w_desert_eagle.mdl",
	"models/w_models/weapons/w_eq_bile_flask.mdl",
	"models/w_models/weapons/w_eq_defibrillator.mdl",
	"models/w_models/weapons/w_eq_explosive_ammopack.mdl",
	"models/w_models/weapons/w_eq_incendiary_ammopack.mdl",
	"models/w_models/weapons/w_eq_adrenaline.mdl"
};

#define MODEL_COLA			"models/w_models/weapons/w_cola.mdl"
#define MODEL_GNOME			"models/props_junk/gnome.mdl"

#define BUY_Sound1 "ui/gift_pickup.wav"
#define BUY_Sound2 "ui/gift_drop.wav"
#define DEAD_EYES_Sound1 "ui/beep22.wav" 
#define DEAD_EYES_Sound2 "level/lowscore.wav" 
#define IMMUNE_EVERYTHING_Sound1 "physics/metal/metal_grate_impact_hard2.wav" 

static const char INFECTED_NAME[]	= "infected";
static const char WITCH_NAME[]		= "witch";

static char weaponsMenu[][][] = 
{
	{"pistol",			"Pistol", 			"100"},
	{"pistol_magnum",	"Magnum", 			"150"},
	{"pumpshotgun",		"Pumpshotgun", 		"200"},
	{"shotgun_chrome",	"Chrome Shotgun", 	"210"},
	{"smg",				"Smg", 				"200"},
	{"smg_silenced", 	"Silenced Smg", 	"210"},
	{"smg_mp5",			"MP5", 				"230"},
	{"rifle", 			"Rifle", 			"300"},
	{"rifle_ak47", 		"AK47", 			"320"},
	{"rifle_desert",	"Desert Rifle", 	"350"},
	{"rifle_sg552", 	"SG552", 			"350"},
	{"shotgun_spas",	"Spas Shotgun", 	"350"},
	{"autoshotgun", 	"Autoshotgun", 		"350"},
	{"hunting_rifle", 	"Hunting Rifle", 	"400"},
	{"sniper_military", "Military Sniper", 	"450"},
	{"sniper_scout", 	"SCOUT", 			"500"},
	{"sniper_awp", 		"AWP",				"600"},
	{"rifle_m60", 		"M60 Machine Gun", 	"1000"},
	{"grenade_launcher","Grenade Launcher",	"1500"}
};

static char meleeMenu[][][] = 
{
	{"chainsaw",		"Chainsaw", 		"300"},
	{"baseball_bat",	"Baseball Bat", 	"250"},
	{"cricket_bat", 	"Cricket Bat", 		"250"},
	{"crowbar", 		"Crowbar", 			"250"},
	{"electric_guitar", "Electric Guitar", 	"250"},
	{"fireaxe", 		"Fire Axe", 		"250"},
	{"frying_pan", 		"Frying Pan", 		"250"},
	{"katana", 			"Katana", 			"250"},
	{"machete", 		"Machete", 			"250"},
	{"tonfa", 			"Tonfa", 			"250"},
	{"golfclub", 		"Golf Club", 		"250"},
	{"knife", 			"Knife", 			"250"},
	{"pitchfork", 		"Pitchfork", 		"250"},
	{"shovel", 			"Shovel", 			"250"}
};

static char medicThrowableMenu[][][] =
{
	{"health_100", 		"Health+100", 		"350"},
	{"defibrillator",	"Defibrillator", 	"250"},
	{"first_aid_kit",	"First Aid Kit", 	"250"},
	{"pain_pills", 		"Pain Pill", 		"100"},
	{"adrenaline",	 	"Adrenaline", 		"150"},
	{"pipe_bomb", 		"Pipe Bomb", 		"150"},
	{"molotov", 		"Molotov", 			"200"},
	{"vomitjar", 		"Vomitjar", 		"300"}
};

static char otherMenu[][][] =
{
	{"ammo",		 					"Ammo", 	 			"250"},
	{"laser_sight",						"Laser Sight", 			"60"},
	{"incendiary_ammo",					"Incendiary Ammo", 		"100"},
	{"explosive_ammo",					"Explosive Ammo", 		"100"},
	{"weapon_upgradepack_incendiary",	"Incendiary Pack", 		"200"},
	{"weapon_upgradepack_explosive",	"Explosive Pack", 		"200"},
	{"propanetank", 	 				"Propane Tank", 		"80"},
	{"oxygentank",	 					"Oxygen Tank", 			"80"},
	{"fireworkcrate",					"Firework Crate", 		"300"},
	{"gascan",  						"Gascan",				"1000"},
	{"cola_bottles",  					"Cola Bottles",			"1500"},
	{"gnome",							"Gnome", 				"2000"},
};

static char specialMenu[][][] =
{
	{"Fire", 			"Fire Yourself", 				"500"},
	{"Fire Infeceted", 	"All Infected Gets On Fire", 	"750"},
	{"Teleport", 		"Teleport to teammate", 		"1000"},
	{"Infinite Ammo",	"Infinite Ammo", 				"1250"},
	{"Dead Eyes",		"Dead-Eyes", 					"1500"},
	{"Kill Commons", 	"Kill Commons", 				"1750"},
	{"Kill Witches", 	"Kill Witches", 				"2000"},
	{"Jump+1", 			"Jump+1", 						"2250"},
	{"Heal Survivors",	"Heal Survivors", 				"2500"},
	{"Slay Infected", 	"Slay Infected Attacker", 		"3000"},
};

static char infectedSpawnMenu[][][] =
{
	{"Suicide",		"Suicide", 			"0"},
	{"Smoker",		"Smoker", 			"400"},
	{"Boomer",		"Boomer", 			"250"},
	{"Hunter",		"Hunter", 			"200"},
	{"Spitter",		"Spitter", 			"450"},
	{"Jockey",		"Jockey", 			"300"},
	{"Charger",		"Charger", 			"350"},
	{"Tank",		"Tank", 			"3000"}
};

static char infectedSpecialMenu[][][] =
{
	{"Health",		"Full Health", 				"500"},
	{"Teleport",	"Teleport to survivor", 	"1000"},
	{"Immune",		"Immune Everything", 		"1250"}
};

static int g_iTransferPointList[] = 
{ 	5, 10, 15, 20, 25, 30, 40, 50, 
	100, 150, 200, 500, 750, 1000, 1500, 2000, 
	2500, 5000, 10000	};

//WeaponName/AmmoOffset/AmmoGive
static char weapon_ammo[][][] =
{
	{"weapon_smg",		 				"5", 	"400"},
	{"weapon_pumpshotgun",				"7", 	"64"},
	{"weapon_rifle",					"3", 	"250"},
	{"weapon_autoshotgun",				"8", 	"64"},
	{"weapon_hunting_rifle",			"9", 	"100"},
	{"weapon_smg_silenced",				"5", 	"400"},
	{"weapon_smg_mp5", 	 				"5", 	"400"},
	{"weapon_shotgun_chrome",	 		"7", 	"64"},
	{"weapon_rifle_ak47",  				"3",	"250"},
	{"weapon_rifle_desert",				"3", 	"250"},
	{"weapon_sniper_military",			"10", 	"100"},
	{"weapon_grenade_launcher", 	 	"17", 	"15"},
	{"weapon_rifle_sg552",	 			"3", 	"250"},
	{"weapon_rifle_m60",  				"6",	"200"},
	{"weapon_sniper_awp", 	 			"10", 	"100"},
	{"weapon_sniper_scout",	 			"10", 	"100"},
	{"weapon_shotgun_spas",  			"8",	"64"}
};

bool bLate;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	bLate = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("L4D2_Buy_Store.phrases");

	g_hMoneyCookie = RegClientCookie("l4d2_buy_store_money", "Money for L4D2_Buy_Store.smx", CookieAccess_Protected);
	ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");

	g_hSurvivorMenu = new Menu(ShopMenuHandler, MenuAction_DisplayItem);
	g_hSurvivorMenu.AddItem("instruction", "Instruction: Get points by killing common、infected or help teammate.");
	g_hSurvivorMenu.AddItem("weaponsMenu", "Gun Weapons");
	g_hSurvivorMenu.AddItem("meleeMenu", "Melee Weapons");
	g_hSurvivorMenu.AddItem("medicThrowableMenu", "Medic and Throwables");
	g_hSurvivorMenu.AddItem("othersMenu", "Others");
	g_hSurvivorMenu.AddItem("specialMenu", "Speials");
	g_hSurvivorMenu.AddItem("transfer", "Points Transfer");
	g_hSurvivorMenu.ExitButton = true;

	g_hInfectedMenu = new Menu(InfectedShopMenuHandler, MenuAction_DisplayItem);
	g_hInfectedMenu.AddItem("InfectedInstruction", "Instruction: Get points by doing damage to survivors.");
	g_hInfectedMenu.AddItem("InfectedSpawnMenu", "Infected Spawn");
	g_hInfectedMenu.AddItem("InfectedSpecialMenu", "Speials");
	g_hInfectedMenu.AddItem("transfer", "Points Transfer");
	g_hInfectedMenu.ExitButton = true;

	RegConsoleCmd("sm_shop", BuyShopCommand);
	RegConsoleCmd("sm_buy", BuyShopCommand);
	RegConsoleCmd("sm_b", BuyShopCommand);
	RegConsoleCmd("sm_points", BuyShopCommand);
	RegConsoleCmd("sm_point", BuyShopCommand);
	RegConsoleCmd("sm_skill", BuyShopCommand);
	RegConsoleCmd("sm_skills", BuyShopCommand);
	RegConsoleCmd("sm_money", BuyShopCommand);
	RegConsoleCmd("sm_purchase", BuyShopCommand);
	RegConsoleCmd("sm_itempointshelp", BuyShopCommand);
	RegConsoleCmd("sm_market", BuyShopCommand);
	RegConsoleCmd("sm_usepoint", BuyShopCommand);
	RegConsoleCmd("sm_usepoints", BuyShopCommand);

	RegConsoleCmd("sm_pay", PayCommand);
	RegConsoleCmd("sm_donate", PayCommand);
	
	RegAdminCmd("sm_inspectbank", CheckBankCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_checkbank", CheckBankCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_lookbank", CheckBankCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_allbank", CheckBankCommand, ADMFLAG_BAN);
	
	RegAdminCmd("sm_givemoney", GiveMoneyCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_givepoint", GiveMoneyCommand, ADMFLAG_BAN);
	
	RegAdminCmd("sm_clearmoney", ClearMoneyCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_clearpoint", ClearMoneyCommand, ADMFLAG_BAN);

	HookEvent("witch_killed", witch_killed);
	HookEvent("infected_death", infected_death);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", player_death);
	HookEvent("player_team", evtPlayerTeam);
	HookEvent("heal_success", evtHealSuccess);
	HookEvent("defibrillator_used", evtDefibrillatorSave);
	HookEvent("revive_success", evtReviveSuccess);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_start", OnFinaleStart_Event);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("map_transition", Event_MapTransition); //戰役過關到下一關的時候
	HookEvent("finale_vehicle_leaving", Event_FinalVehicleLeaving); //救援載具離開之時  (沒有觸發round_end)
	HookEvent("mission_lost", Event_MissionLost); //戰役滅團重來該關卡的時候 (之後有觸發round_end)

	//*****************//
	//  S E T T I N G S //
	//****************//
	g_PlayerRequired = CreateConVar("sm_shop_player_require", "4", "Numbers of real survivor and infected player require to active this plugin.", FCVAR_NOTIFY, true, 1.0);
	g_hCookiesCachedEnable = CreateConVar("sm_shop_CookiesCached_enable", "1", "If 1, use CookiesCached to save player money. Otherwise, the moeny will not be saved if player leaves the server.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_BoomerKilled = CreateConVar("sm_shop_boomkilled", "10", "Giving money for killing a boomer", FCVAR_NOTIFY, true, 1.0);
	g_ChargerKilled = CreateConVar("sm_shop_chargerkilled", "30", "Giving money for killing a charger", FCVAR_NOTIFY, true, 1.0);
	g_SmokerKilled = CreateConVar("sm_shop_smokerkilled", "20", "Giving money for killing a smoker", FCVAR_NOTIFY, true, 1.0);
	g_HunterKilled = CreateConVar("sm_shop_hunterkilled", "20", "Giving money for killing a hunter", FCVAR_NOTIFY, true, 1.0);
	g_JockeyKilled = CreateConVar("sm_shop_jockeykilled", "25", "Giving money for killing a jockey", FCVAR_NOTIFY, true, 1.0);
	g_SpitterKilled = CreateConVar("sm_shop_spitterkilled", "10", "Giving money for killing a spitter", FCVAR_NOTIFY, true, 1.0);
	g_hTankHurt = CreateConVar("sm_shop_tank_hurt", "40", "Giving one dollar money for hurting tank per X hp", FCVAR_NOTIFY, true, 1.0);
	g_WitchKilled = CreateConVar("sm_shop_witchkilled", "80", "Giving money for killing a witch", FCVAR_NOTIFY, true, 1.0);
	g_ZombieKilled = CreateConVar("sm_shop_zombiekilled", "1", "Giving money for killing a zombie", FCVAR_NOTIFY, true, 1.0);
	g_hHealTeammate = CreateConVar("sm_shop_heal_teammate", "100", "Giving money for healing people with kit", FCVAR_NOTIFY, true, 1.0);
	g_hDefiSave = CreateConVar("sm_shop_defi_save", "200", "Giving money for saving people with defibrillator", FCVAR_NOTIFY, true, 1.0);
	g_hHelpTeammate = CreateConVar("sm_shop_help_teammate_save", "30", "Giving money for saving incapacitated people. (No Hanging from legde)", FCVAR_NOTIFY, true, 1.0);
	g_hIncapSurvivor = CreateConVar("sm_shop_infected_survivor_incap", "30", "Giving money for incapacitating a survivor. (No Hanging from legde)", FCVAR_NOTIFY, true, 1.0);
	g_hKillSurvivor = CreateConVar("sm_shop_infected_survivor_killed", "100", "Giving money for killing a survivor.", FCVAR_NOTIFY, true, 1.0);
	g_hTKSurvivorEnable = CreateConVar("sm_shop_survivor_TK_enable", "1", "If 1, decrease money if survivor friendly fire each other.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hGascanMapOff = CreateConVar("sm_shop_gascan_map_off",	"c1m4_atrium,c6m3_port,c14m2_lighthouse",	"Can not buy gas can in these maps, separate by commas (no spaces). (0=All maps, Empty = none).", FCVAR_NOTIFY );
	g_hColaMapOff =	CreateConVar("sm_shop_cola_map_off",	"c1m2_streets",	"Can not buy cola in these maps, separate by commas (no spaces). (0=All maps, Empty = none).", FCVAR_NOTIFY );
	g_hMaxJumpLimit  =	CreateConVar("sm_shop_special_max_jump_limit",	"3",	"Max Air Jump Limit for special item.", FCVAR_NOTIFY, true, 1.0);
	g_hInfiniteAmmoTime  =	CreateConVar("sm_shop_special_infinite_ammo_time",	"15",	"How long could infinite ammo state last for special item.", FCVAR_NOTIFY, true, 1.0);
	g_hStageComplete =	CreateConVar("sm_shop_stage_complete", "400",	"Giving money to each alive survivor for mission accomplished award (non-final).", FCVAR_NOTIFY, true, 1.0);
	g_hFinalMissionComplete =	CreateConVar("sm_shop_final_mission_complete", "3000",	"Giving money to each alive survivor for mission accomplished award (final).", FCVAR_NOTIFY, true, 1.0);
	g_hWipeOutSurvivor =	CreateConVar("sm_shop_final_mission_lost", "300",	"Giving money to each infected player for wiping out survivors.", FCVAR_NOTIFY, true, 1.0);
	g_hDeadEyeTime  =	CreateConVar("sm_shop_special_dead_eyes_time",	"60",	"How long could Dead-Eyes state last for special item.", FCVAR_NOTIFY, true, 1.0);
	g_hInfectedShopEnable =	CreateConVar("sm_shop_infected_enable", "1",	"If 1, Enable shop for infected.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hInfectedShopColdDown =	CreateConVar("sm_shop_infected_cooltime_block", "30.0",	"Cold Down Time in seconds an infected player can not buy again after he buys item. (0=off).", FCVAR_NOTIFY, true, 0.0);
	g_hImmuneDamageTime =	CreateConVar("sm_shop_special_immune_everything_time",	"8",	"How long could Immune Everything last for infected special item.", FCVAR_NOTIFY, true, 1.0);
	g_hInfectedShopTankLimit =	CreateConVar("sm_shop_infected_tank_limit",	"1",	"Tank limit on the field before infected can buy a tank. (0=Can't buy Tank)", FCVAR_NOTIFY, true, 0.0);

	g_MaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	g_DecayDecay = FindConVar("pain_pills_decay_rate");

	GetCvars();
	g_PlayerRequired.AddChangeHook(ConVarChanged_Allow);
	g_BoomerKilled.AddChangeHook(ConVarChanged_Cvars);
	g_ChargerKilled.AddChangeHook(ConVarChanged_Cvars);
	g_SmokerKilled.AddChangeHook(ConVarChanged_Cvars);
	g_HunterKilled.AddChangeHook(ConVarChanged_Cvars);
	g_JockeyKilled.AddChangeHook(ConVarChanged_Cvars);
	g_SpitterKilled.AddChangeHook(ConVarChanged_Cvars);
	g_WitchKilled.AddChangeHook(ConVarChanged_Cvars);
	g_ZombieKilled.AddChangeHook(ConVarChanged_Cvars);
	g_hHealTeammate.AddChangeHook(ConVarChanged_Cvars);
	g_hDefiSave.AddChangeHook(ConVarChanged_Cvars);
	g_MaxIncapCount.AddChangeHook(ConVarChanged_Cvars);
	g_hCookiesCachedEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hHelpTeammate.AddChangeHook(ConVarChanged_Cvars);
	g_hTankHurt.AddChangeHook(ConVarChanged_Cvars);
	g_hIncapSurvivor.AddChangeHook(ConVarChanged_Cvars);
	g_hKillSurvivor.AddChangeHook(ConVarChanged_Cvars);
	g_hTKSurvivorEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hMaxJumpLimit.AddChangeHook(ConVarChanged_Cvars);
	g_hInfiniteAmmoTime.AddChangeHook(ConVarChanged_Cvars);
	g_hStageComplete.AddChangeHook(ConVarChanged_Cvars);
	g_hFinalMissionComplete.AddChangeHook(ConVarChanged_Cvars);
	g_hWipeOutSurvivor.AddChangeHook(ConVarChanged_Cvars);
	g_hDeadEyeTime.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedShopEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedShopColdDown.AddChangeHook(ConVarChanged_Cvars);
	g_hImmuneDamageTime.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedShopTankLimit.AddChangeHook(ConVarChanged_Cvars);

	//Autoconfig for plugin
	AutoExecConfig(true, "L4D2_Buy_Store");

	if (bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientCookiesCached(i);
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnPluginEnd()
{
	if(g_bCookiesCachedEnable) SaveAllMoney();
	delete g_hSurvivorMenu;
	g_bEnable = false;

	for( int i = 1; i <= MaxClients; i++ ) {
		g_iCredits[i] = 0;
		RemoveInfectedModelGlow(i);
		DeleteLight(i);
	}
}

bool g_bGascanMap, g_bColaMap;
public void OnMapStart()
{	
	g_bGascanMap = true;
	g_bColaMap = true;

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	Format(sMap, sizeof(sMap), ",%s,", sMap);

	char sCvar[512];
	g_hGascanMapOff.GetString(sCvar, sizeof(sCvar));
	if( sCvar[0] != '\0' )
	{
		if( strcmp(sCvar, "0") == 0 )
		{
			g_bGascanMap = false;
		} 
		else
		{
			Format(sCvar, sizeof(sCvar), ",%s,", sCvar);
			if( StrContains(sCvar, sMap, false) != -1 )
				g_bGascanMap = false;
		}
	}

	sCvar = "";
	g_hColaMapOff.GetString(sCvar, sizeof(sCvar));
	if( sCvar[0] != '\0' )
	{
		if( strcmp(sCvar, "0") == 0 )
		{
			g_bColaMap = false;
		} 
		else
		{
			Format(sCvar, sizeof(sCvar), ",%s,", sCvar);
			if( StrContains(sCvar, sMap, false) != -1 )
				g_bColaMap = false;
		}
	}

	int max = MAX_WEAPONS2;
	for( int i = 0; i < max; i++ )
	{
		PrecacheModel(g_sWeaponModels2[i], true);
	}
	PrecacheModel(MODEL_GNOME, true);
	if(g_bColaMap) PrecacheModel(MODEL_COLA, true);

	PrecacheModel(MODEL_GASCAN, true);

	PrecacheSound(BUY_Sound1);
	PrecacheSound(BUY_Sound2);
	PrecacheSound(DEAD_EYES_Sound1);
	PrecacheSound(DEAD_EYES_Sound2);
	PrecacheSound(IMMUNE_EVERYTHING_Sound1);
}

public void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
	CheckPlayers();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iPlayerRequired = g_PlayerRequired.IntValue;
	g_iBoomerKilled = g_BoomerKilled.IntValue;
	g_iChargerKilled = g_ChargerKilled.IntValue;
	g_iSmokerKilled = g_SmokerKilled.IntValue;
	g_iHunterKilled = g_HunterKilled.IntValue;
	g_iJockeyKilled = g_JockeyKilled.IntValue;
	g_iSpitterKilled = g_SpitterKilled.IntValue;
	g_iWitchKilled = g_WitchKilled.IntValue;
	g_iZombieKilled = g_ZombieKilled.IntValue;
	g_iHealTeammate = g_hHealTeammate.IntValue;
	g_iDefiSave = g_hDefiSave.IntValue;
	g_iHelpTeammate = g_hHelpTeammate.IntValue;
	g_iMaxIncapCount = g_MaxIncapCount.IntValue;
	g_bCookiesCachedEnable = g_hCookiesCachedEnable.BoolValue;
	g_iTankHurt = g_hTankHurt.IntValue;
	g_iIncapSurvivor = g_hIncapSurvivor.IntValue;
	g_iKillSurvivor = g_hKillSurvivor.IntValue;
	g_bTKSurvivorEnable = g_hTKSurvivorEnable.BoolValue;
	g_iMaxJumpLimit = g_hMaxJumpLimit.IntValue;
	g_iInfiniteAmmoTime = g_hInfiniteAmmoTime.IntValue;
	g_iStageComplete = g_hStageComplete.IntValue;
	g_iFinalMissionComplete = g_hFinalMissionComplete.IntValue;
	g_iWipeOutSurvivor = g_hWipeOutSurvivor.IntValue;
	g_iDeadEyeTime = g_hDeadEyeTime.IntValue;
	g_bInfectedShopEnable = g_hInfectedShopEnable.BoolValue;
	g_fInfectedShopColdDown = g_hInfectedShopColdDown.FloatValue;
	g_iImmuneDamageTime = g_hImmuneDamageTime.IntValue;
	g_iInfectedShopTankLimit = g_hInfectedShopTankLimit.IntValue;
}

public Action BuyShopCommand(int client, int args)
{
	if(g_bEnable == false) {
		ReplyToCommand(client, "[TS] %T", "Not enough players", client, g_iPlayerRequired);
		return Plugin_Handled;
	}

	if (client == 0)
	{
		PrintToServer("[TS] this command cannot be used by server.");
		return Plugin_Handled;
	}

	int team = GetClientTeam(client);
	if(team == L4D_TEAM_SPECTATOR)
	{
		ReplyToCommand(client, "[TS] %T", "Spectators can not buy", client);
		CPrintToChat(client, "%T", "Left Money", client, g_iCredits[client]);
	}
	else if(team == L4D_TEAM_SURVIVORS)
	{
		if(IsPlayerAlive(client) == false)
		{
			ReplyToCommand(client, "[TS] %T", "Death can't buy", client);
			CPrintToChat(client, "%T", "Left Money", client, g_iCredits[client]);
			return Plugin_Handled;
		}
		g_hSurvivorMenu.SetTitle("%T", "Shop Menu Title", client, g_iCredits[client]);
		g_hSurvivorMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if(team == L4D_TEAM_INFECTED)
	{
		if(g_bInfectedShopEnable == false)
		{
			ReplyToCommand(client, "[TS] %T", "Infected Shop is disabled", client);
			CPrintToChat(client, "%T", "Left Money", client, g_iCredits[client]);
			return Plugin_Handled;
		}
		g_hInfectedMenu.SetTitle("%T", "Infected Menu Title", client, g_iCredits[client]);
		g_hInfectedMenu.Display(client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}

public Action PayCommand(int client, int args)
{
	if(g_bEnable == false) {
		ReplyToCommand(client, "[TS] %T", "Not enough players", client, g_iPlayerRequired);
		return Plugin_Handled;
	}

	if (client == 0)
	{
		PrintToServer("[TS] this command cannot be used by server.");
		return Plugin_Handled;
	}
	if (args != 2)
	{
		ReplyToCommand(client, "[TS] usage: !pay <name> <money>");
		return Plugin_Handled;
	}

	char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true /*nobots*/, false /*immunity*/);
	if (target == -1)
	{
		return Plugin_Handled;
	}

	GetCmdArg(2, arg2, sizeof(arg2));
	int paymoney = StringToInt(arg2);
	if(paymoney <= 0)
	{
		ReplyToCommand(client, "[TS] %T", "No negative number", client);
		return Plugin_Handled;
	}

	if(g_iCredits[client] - paymoney < 0)
	{
		ReplyToCommand(client, "[TS] %T", "Not enough money to donate", client);
		return Plugin_Handled;
	}

	if(IsFakeClient(target) || GetClientTeam(target) != L4D_TEAM_SURVIVORS)
	{
		ReplyToCommand(client, "[TS] %T", "Only donate to survivor", client);
		return Plugin_Handled;
	}

	if(client == target)
	{
		ReplyToCommand(client, "[TS] %T", "Can't donate yourself", client);
		return Plugin_Handled;
	}

	char clientname[64], targetname[64];
	GetClientName(client, clientname, sizeof(clientname));
	GetClientName(target, targetname, sizeof(targetname));
	g_iCredits[target] += paymoney;
	g_iCredits[client] -= paymoney;
	CPrintToChat(target, "[{olive}TS{default}] %T", "Donate moeny to you", target, clientname, paymoney);
	CPrintToChat(client, "[{olive}TS{default}] %T", "You Donate moeny", client, paymoney, targetname);
	
	if(g_bCookiesCachedEnable)
	{
		SaveMoney(target);
		SaveMoney(client);
	}

	return Plugin_Handled;
}

public Action CheckBankCommand(int client, int args)
{
	if(g_bEnable == false) {
		ReplyToCommand(client, "[TS] %T", "Not enough players", client, g_iPlayerRequired);
		return Plugin_Handled;
	}

	if (client == 0)
	{
		PrintToServer("[TS] this command cannot be used by server.");
		return Plugin_Handled;
	}

	if (args > 1)
	{
		ReplyToCommand(client, "[TS] Usage: !checkmoney <player> or !checkmoney");
		return Plugin_Handled;
	}

	if(args == 0)
	{
		CPrintToChat(client, "{blue}{olive}{default}===================={olive}{default}{blue}");
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				if(GetClientTeam(i) == L4D_TEAM_SPECTATOR) 		CPrintToChat(client, "[{olive}TS{default}] {lightgreen}%N {olive}$ {green}%d", i, g_iCredits[i]);
				else if(GetClientTeam(i) == L4D_TEAM_SURVIVORS) CPrintToChat(client, "[{olive}TS{default}] {blue}%N {olive}$ {green}%d", i, g_iCredits[i]);
				else if(GetClientTeam(i) == L4D_TEAM_INFECTED) 	CPrintToChat(client, "[{olive}TS{default}] {red}%N {olive}$ {green}%d", i, g_iCredits[i]);
			}
		}
		CPrintToChat(client, "{blue}{olive}{default}===================={olive}{default}{blue}");
	}
	else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		int target = FindTarget(client, arg1, true /*nobots*/, false /*immunity*/);
		if(target == -1) return Plugin_Handled;	

		if(GetClientTeam(target) == L4D_TEAM_SPECTATOR) 		CPrintToChat(client, "[{olive}TS{default}] {lightgreen}%N {default}$ {green}%d", target, g_iCredits[target]);
		else if(GetClientTeam(target) == L4D_TEAM_SURVIVORS) 	CPrintToChat(client, "[{olive}TS{default}] {blue}%N {default}$ {green}%d", target, g_iCredits[target]);
		else if(GetClientTeam(target) == L4D_TEAM_INFECTED) 	CPrintToChat(client, "[{olive}TS{default}] {red}%N {default}$ {green}%d", target, g_iCredits[target]);
	}

	return Plugin_Handled;
}

public Action GiveMoneyCommand(int client, int args)
{
	if(g_bEnable == false) {
		ReplyToCommand(client, "[TS] %T", "Not enough players", client, g_iPlayerRequired);
		return Plugin_Handled;
	}

	if (client == 0)
	{
		PrintToServer("[TS] this command cannot be used by server.");
		return Plugin_Handled;
	}
	if (args != 2)
	{
		ReplyToCommand(client, "[TS] Usage: !givemoney <player> <money>");
		return Plugin_Handled;
	}

	// char arg1[32];
	// GetCmdArg(1, arg1, sizeof(arg1));
	// int target = FindTarget(client, arg1, true /*nobots*/, false /*immunity*/);
	// if(target == -1) return Plugin_Handled;	

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	int money = StringToInt(arg2);
	if(money==0)
	{
		ReplyToCommand(client, "[TS] %T", "Zero", client);
		return Plugin_Handled;
	}

	char clientname[64], targetname[64];
	int target;
	for (int i = 0; i < target_count; i++)
	{
		target = target_list[i];
		GetClientName(client, clientname, sizeof(clientname));
		GetClientName(target, targetname, sizeof(targetname));
		g_iCredits[target] += money;
		if(g_iCredits[target] < 0) g_iCredits[target] = 0;
		if(money < 0)
		{
			CPrintToChat(client, "[{olive}TS{default}] %T", "You reduce player moeny", client, targetname, money);
			if(client != target) CPrintToChat(target, "[{olive}TS{default}] %T", "Adm reduces your moeny", target, clientname, money);
		}
		else
		{
			CPrintToChat(client, "[{olive}TS{default}] %T", "You give player moeny", client, targetname, money);
			if(client != target) CPrintToChat(target, "[{olive}TS{default}] %T", "Adm gives your moeny", target, clientname, money);
		}
	}

	return Plugin_Handled;	
}

public Action ClearMoneyCommand(int client, int args)
{
	if(g_bEnable == false) {
		ReplyToCommand(client, "[TS] %T", "Not enough players", client, g_iPlayerRequired);
		return Plugin_Handled;
	}
	
	if (client == 0)
	{
		PrintToServer("[TS] this command cannot be used by server.");
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(client, "[TS] usage: !clearmoney <name>");
		return Plugin_Handled;
	}

	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true /*nobots*/, false /*immunity*/);
	if (target == -1)
	{
		return Plugin_Handled;
	}

	char clientname[64], targetname[64];
	GetClientName(client, clientname, sizeof(clientname));
	GetClientName(target, targetname, sizeof(targetname));
	CPrintToChat(client, "[{olive}TS{default}] %T","You deduct player moeny", client, targetname);
	if(client != target) CPrintToChat(target, "[{olive}TS{default}] %T", "Adm deducts your moeny", target, clientname);

	g_iCredits[target] = 0;
	if(g_bCookiesCachedEnable) SaveMoney(target);

	return Plugin_Handled;
}
//cache
//Called once a client's saved cookies have been loaded from the database.
public void OnClientCookiesCached(int client)
{
	if(g_bCookiesCachedEnable == true && !IsFakeClient(client))
	{
		char sMoney[11];
		GetClientCookie(client, g_hMoneyCookie, sMoney, sizeof(sMoney));
		g_iCredits[client] = StringToInt(sMoney);
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client)) return;
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	CheckPlayers();
	if(g_bCookiesCachedEnable == true && !IsFakeClient(client))
	{
		char sMoney[11];
		if(g_iCredits[client] > MAX_MONEY) g_iCredits[client] = MAX_MONEY;
		IntToString(g_iCredits[client], sMoney, sizeof(sMoney));
		SetClientCookie(client, g_hMoneyCookie, sMoney);
	}

	g_iCredits[client] = 0;
	g_iJumps[client] = 0;
	g_iLastButtons[client] = 0;
	g_iCanJump[client] = 0;
	InfiniteAmmo[client] = false;
	InfectedImmuneDamage[client] = false;
	DeleteLight(client);
} 

//event
public void evtHealSuccess(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int subject = GetClientOfUserId(event.GetInt("subject"));
	if (g_bEnable && client != subject && client && IsClientInGame(client) && !IsFakeClient(client))
	{
		g_iCredits[client] += g_iHealTeammate;
		PrintHintText(client, "[TS] %T", "Heal Teammate", client, g_iHealTeammate);
	}
}

public void evtDefibrillatorSave(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_bEnable && client && IsClientInGame(client) && !IsFakeClient(client))
	{
		g_iCredits[client] += g_iDefiSave;
		PrintHintText(client, "[TS] %T", "Revive Teammate", client, g_iDefiSave);
	}
}

public void evtReviveSuccess(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_bEnable && client && IsClientInGame(client) && !IsFakeClient(client) && event.GetBool("ledge_hang") == false ) //不是掛邊
	{
		g_iCredits[client] += g_iHelpTeammate;
		PrintHintText(client, "[TS] %T", "Help Teammate", client, g_iHelpTeammate);
	}
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damageDone = event.GetInt("dmg_health");
	if(!g_bEnable || damageDone <= 0.0 || attacker == victim) return;

	if (0 < victim && victim <= MaxClients && IsClientInGame(victim))
	{
		if(GetClientTeam(victim) == L4D_TEAM_INFECTED) //特感受傷
		{	
			if(GetEntProp(victim, Prop_Send, "m_zombieClass") == ZC_TANK) //特感是坦克
			{
				if( g_bDied[victim] || g_iLastHP[victim] - damageDone < 0) //坦克死亡動畫或是散彈槍重複計算
				{
					return;
				}
				
				if( GetEntProp(victim, Prop_Send, "m_isIncapacitated") ) //坦克死掉播放動畫，即使是玩家造成傷害，attacker還是0
				{
					g_bDied[victim] = true;
				}
				else
				{
					g_iLastHP[victim] = event.GetInt("health");
				}
				
				
				if( 0 < attacker <= MaxClients && IsClientInGame(attacker))
				{
					g_iDamage[attacker][victim] += damageDone;
				}
			}
		}

		if(0 < attacker && attacker <= MaxClients && IsClientInGame(attacker)) //真實玩家
		{
			if(GetClientTeam(attacker) == L4D_TEAM_INFECTED && GetClientTeam(victim) == L4D_TEAM_SURVIVORS) //特感打人類
			{
				if(!IsFakeClient(attacker) && !IsIncapacitated(victim) && !IsHandingFromLedge(victim))
				{
					g_iCredits[attacker] += damageDone;
				}
			}

			if(g_bTKSurvivorEnable && GetClientTeam(attacker) == L4D_TEAM_SURVIVORS && GetClientTeam(victim) == L4D_TEAM_SURVIVORS) //人類打人類
			{
				char WeaponName[64];
				event.GetString("weapon", WeaponName, sizeof(WeaponName));
				if(IsPipeBombExplode(WeaponName) || IsFire(WeaponName) || IsFireworkcrate(WeaponName))
				{
					return;
				}

				g_iCredits[attacker] -= damageDone;
				if(g_iCredits[attacker] < 0) g_iCredits[attacker] = 0;
			}
		}
	}
}

public Action Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(g_bEnable == false || !client || !IsClientInGame(client) || GetClientTeam(client) != L4D_TEAM_SURVIVORS) return;

	int attacker = L4D2_GetInfectedAttacker(client);
	if(attacker > 0 && !IsFakeClient(attacker))
	{
		g_iCredits[attacker] += g_iIncapSurvivor;
		PrintHintText(attacker, "[TS] %T", "Incap Survivor", attacker, g_iIncapSurvivor);
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	for( int i = 1; i <= MaxClients; i++ ) {
		InfiniteAmmo[i] = false;
		g_iJumps[i] = 0;
		g_iLastButtons[i] = 0;
		g_iCanJump[i] = 0;
		InfectedImmuneDamage[i] = false;
	}
	bFinaleEscapeStarted = false;
	g_bDeadEyeEffect = false;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_bCookiesCachedEnable) SaveAllMoney();

	for( int i = 1; i <= MaxClients; i++ )
	{
		DeleteLight(i);
	}
}

public Action OnFinaleStart_Event(Event event, const char[] name, bool dontBroadcast) 
{
	for( int i = 1; i <= MaxClients; i++ ) {
		g_iJumps[i] = 0;
		g_iLastButtons[i] = 0;
		g_iCanJump[i] = 0;
	}
	bFinaleEscapeStarted = true;
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == L4D_TEAM_SURVIVORS && InfiniteAmmo[client])
	{
		int weaponent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"); //抓人類目前拿的武器
		if (weaponent > 0 && IsValidEntity(weaponent) && HasEntProp(weaponent, Prop_Send, "m_iClip1"))
		{
			SetEntProp(weaponent, Prop_Send, "m_iClip1", GetWeaponClip(weaponent) + 1);
			if(HasEntProp(weaponent, Prop_Send, "m_upgradeBitVec"))
			{
				int upgradedammo = GetEntProp(weaponent, Prop_Send, "m_upgradeBitVec");
				if (upgradedammo == 1 || upgradedammo == 2 || upgradedammo == 5 || upgradedammo == 6)
					SetEntProp(weaponent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", GetWeaponSpecialClip(weaponent) + 1);
			}
		}
	}
}

public void evtPlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid");
	CreateTimer(1.0, PlayerChangeTeamCheck,userid);//延遲一秒檢查

	int client = GetClientOfUserId(userid);
	RemoveInfectedModelGlow(client);
	DeleteLight(client);
}

public Action PlayerChangeTeamCheck(Handle timer,int userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client))
	{
		CheckPlayers();
	}
}

public void witch_killed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(g_bEnable == false || !client || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != L4D_TEAM_SURVIVORS ) return;
	
	g_iCredits[client] += g_iWitchKilled;
	PrintHintText(client, "[TS] %T", "Kill Witch", client, g_iWitchKilled);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{ 
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(client && IsClientInGame(client) && GetClientTeam(client) == L4D_TEAM_INFECTED)
	{
		RemoveInfectedModelGlow(client); //有可能特感變成坦克復活
		CreateInfectedModelGlow(client);
		
		if (GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK)
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				g_bDied[client] = false;
				g_iLastHP[client] = GetEntProp(client, Prop_Data, "m_iHealth");
				g_iDamage[i][client] = 0;
			}
		}
	}
}

public void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(victim && IsClientInGame(victim) && GetClientTeam(victim) == L4D_TEAM_INFECTED)
	{
		RemoveInfectedModelGlow(victim);
		DeleteLight(victim);
	}

	if( g_bEnable && victim && IsClientInGame(victim) && GetClientTeam(victim) == L4D_TEAM_INFECTED && GetEntProp(victim, Prop_Send, "m_zombieClass") == ZC_TANK)
	{
		if(attacker != victim && attacker && IsClientInGame(attacker)) g_iDamage[attacker][victim] += g_iLastHP[victim];

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == L4D_TEAM_SURVIVORS)
			{
				g_iCredits[i] += g_iDamage[i][victim] / g_iTankHurt;
			}
		}
	}

	if (g_bEnable && 0 < victim && victim <= MaxClients && 0 < attacker && attacker <= MaxClients && IsClientInGame(attacker) && IsClientInGame(victim))
	{
		if(attacker != victim && GetClientTeam(attacker) == L4D_TEAM_SURVIVORS && GetClientTeam(victim) == L4D_TEAM_INFECTED) //人類殺死特感
		{
			if(!IsFakeClient(attacker))
			{
				int iZombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
				int money = 0;
				if (iZombieClass == ZC_TANK)
				{
					return;
				}
				else if (iZombieClass == ZC_BOOMER)
				{
					money = g_iBoomerKilled;
				}
				else if (iZombieClass == ZC_SMOKER)
				{
					money = g_iSmokerKilled;
				}
				else if (iZombieClass == ZC_CHARGER)
				{
					money = g_iChargerKilled;
				}
				else if (iZombieClass == ZC_HUNTER)
				{
					money = g_iHunterKilled;
				}
				else if (iZombieClass == ZC_JOCKEY)
				{
					money = g_iJockeyKilled;
				}
				else if (iZombieClass == ZC_SPITTER)
				{
					money = g_iSpitterKilled;
				}

				if(money > 0)
				{
					g_iCredits[attacker] += money;
					PrintHintText(attacker, "[TS] %T", "Kill Infected", attacker, money);
				}
			}
		}
		if(GetClientTeam(attacker) == L4D_TEAM_INFECTED && GetClientTeam(victim) == L4D_TEAM_SURVIVORS) //特感殺死人類
		{
			if(!IsFakeClient(attacker))
			{
				g_iCredits[attacker] += g_iKillSurvivor;
				PrintHintText(attacker, "[TS] %T", "Kill Survivor", attacker, g_iKillSurvivor);
			}
		}
	}
}

public void infected_death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(g_bEnable == false || !attacker || !IsClientInGame(attacker) || IsFakeClient(attacker) || GetClientTeam(attacker) != L4D_TEAM_SURVIVORS ) return;

	g_iCredits[attacker] += g_iZombieKilled;
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bEnable == false) return;

	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if(IsClientInGame(i) && GetClientTeam(i) == L4D_TEAM_SURVIVORS && IsPlayerAlive(i))
		{
			CPrintToChat(i, "[{olive}TS{default}] %T", "Stage Complete", i, g_iStageComplete);
			g_iCredits[i] += g_iStageComplete;
		}
	}
}

public void Event_FinalVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bEnable == false) return;

	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if(IsClientInGame(i) && GetClientTeam(i) == L4D_TEAM_SURVIVORS && IsPlayerAlive(i))
		{
			if(!IsHandingFromLedge(i) && !IsIncapacitated(i))
			{
				CPrintToChat(i, "[{olive}TS{default}] %T", "Final Mission Complete", i, g_iFinalMissionComplete);
				g_iCredits[i] += g_iFinalMissionComplete;
			}
		}
	}
}

public void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bEnable == false) return;

	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == L4D_TEAM_INFECTED)
			{
				CPrintToChat(i, "[{olive}TS{default}] %T", "Wipe Out Survivors (Infected)", i, g_iWipeOutSurvivor);
				g_iCredits[i] += g_iWipeOutSurvivor;
			}
			else if(GetClientTeam(i) == L4D_TEAM_SURVIVORS)
			{
				CPrintToChat(i, "[{olive}TS{default}] %T", "Wipe Out Survivors (Survivor)", i, g_iWipeOutSurvivor);
				g_iCredits[i] -= g_iWipeOutSurvivor;
				if(g_iCredits[i] < 0) g_iCredits[i] = 0;	
			}
		}
	}
}

public Action Timer_NoInfiniteAmmo(Handle timer, int client)
{
	InfiniteAmmo[client] = false;
	if(IsClientInGame(client))
	{
		PrintToChat(client, "%T", "InfiniteAmmo Timer",client);
		PlaySoundToClient(client, DEAD_EYES_Sound2);
	}
}

public int ShopMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			if (strcmp(item, "instruction") == 0)
			{
				g_hSurvivorMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hSurvivorMenu.Display(param1, MENU_TIME_FOREVER);
			}
			if (strcmp(item, "weaponsMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eWeaponMenu);
			}
			if (strcmp(item, "meleeMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eMeleeMenu);
			}
			if (strcmp(item, "medicThrowableMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eMedicThrowableMenu);
			}
			if (strcmp(item, "othersMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eOtherMenu);
			}
			if (strcmp(item, "specialMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eSpecialMenu);
			}
			if (strcmp(item, "transfer") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eTransferPlayerMenu);
			}
		}
		case MenuAction_DisplayItem:
		{
			static char info[64];
			static char display[128];
			menu.GetItem(param2, info, sizeof(info));	
			if (strcmp(info, "instruction") == 0)
			{
				Format(display, sizeof(display), "%T", "instruction", param1);
				return RedrawMenuItem(display);
			}
			else if (strcmp(info, "weaponsMenu") == 0)
			{
				Format(display, sizeof(display), "%T", "weaponsMenu", param1);
				return RedrawMenuItem(display);
			}
			else if (strcmp(info, "meleeMenu") == 0)
			{
				Format(display, sizeof(display), "%T", "meleeMenu", param1);
				return RedrawMenuItem(display);
			}	
			else if (strcmp(info, "medicThrowableMenu") == 0)
			{
				Format(display, sizeof(display), "%T", "medicThrowableMenu", param1);
				return RedrawMenuItem(display);
			}	
			else if (strcmp(info, "othersMenu") == 0)
			{
				Format(display, sizeof(display), "%T","othersMenu", param1);
				return RedrawMenuItem(display);
			}	
			else if (strcmp(info, "specialMenu") == 0)
			{
				Format(display, sizeof(display), "%T","specialMenu", param1);
				return RedrawMenuItem(display);
			}
			else if (strcmp(info, "transfer") == 0)
			{
				Format(display, sizeof(display), "%T","transferMenu", param1);
				return RedrawMenuItem(display);
			}
		}
	}

	return 0;
}

public int Weapon_Menu_Handle(Menu weaponmenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				g_hSurvivorMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hSurvivorMenu.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select:
		{
			if(CanClientBuy(param1) == true) 
			{
				char item[64];
				weaponmenu.GetItem(param2, item, sizeof(item));
				
				int index = StringToInt(item);
				
				int itemMoney = StringToInt(weaponsMenu[index][2]);
				if( g_iCredits[param1] - itemMoney < 0)
				{
					CPrintToChat(param1, "[{olive}TS{default}] %T", "Not enough money", param1, g_iCredits[param1], itemMoney);
				}
				else
				{
					GiveFunction(param1, weaponsMenu[index][0], weaponsMenu[index][1]);
					g_iCredits[param1] -= itemMoney;
				}
				g_iMenuWeaponPosition[param1] = weaponmenu.Selection; 
				DisplayShopMenu(param1, EMenuType:eWeaponMenu);
			}
		}
		case MenuAction_End:
			delete weaponmenu;
	}
}

public int Melee_Menu_Handle(Menu mmenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				g_hSurvivorMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hSurvivorMenu.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select:
		{
			if(CanClientBuy(param1) == true) 
			{
				char item[64];
				mmenu.GetItem(param2, item, sizeof(item));
				
				int index = StringToInt(item);
				int itemMoney = StringToInt(meleeMenu[index][2]);
				if( g_iCredits[param1] - itemMoney < 0)
				{
					CPrintToChat(param1, "[{olive}TS{default}] %T", "Not enough money", param1, g_iCredits[param1], itemMoney);
				}
				else
				{
					GiveFunction(param1, meleeMenu[index][0], meleeMenu[index][1]);
					g_iCredits[param1] -= itemMoney;
				}
				g_iMenuMeleePosition[param1] = mmenu.Selection; 
				DisplayShopMenu(param1, EMenuType:eMeleeMenu);
			}
		}
		case MenuAction_End:
			delete mmenu;
	}
}

public int Medic_Throwable_Menu_Handle(Menu omenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				g_hSurvivorMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hSurvivorMenu.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select:
		{
			if(CanClientBuy(param1) == true) 
			{
				char item[64];
				omenu.GetItem(param2, item, sizeof(item));
				
				int index = StringToInt(item);
				int itemMoney = StringToInt(medicThrowableMenu[index][2]);
				if( g_iCredits[param1] - itemMoney < 0)
				{
					CPrintToChat(param1, "[{olive}TS{default}] %T", "Not enough money", param1, g_iCredits[param1], itemMoney);
				}
				else
				{
					if(strcmp(medicThrowableMenu[index][0], "health_100") == 0)
					{
						GiveClientHealth(param1, 100, medicThrowableMenu[index][1]);
						g_iCredits[param1] -= itemMoney;
					}
					else
					{
						GiveFunction(param1, medicThrowableMenu[index][0], medicThrowableMenu[index][1]);
						g_iCredits[param1] -= itemMoney;
					}
				}
				g_iMenuMedicThrowablePosition[param1] = omenu.Selection; 
				DisplayShopMenu(param1, EMenuType:eMedicThrowableMenu);
			}
		}
		case MenuAction_End:
			delete omenu;
	}
}

public int Other_Menu_Handle(Menu othermenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				g_hSurvivorMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hSurvivorMenu.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select:
		{
			if(CanClientBuy(param1) == true) 
			{
				char item[64];
				othermenu.GetItem(param2, item, sizeof(item));
				
				int index = StringToInt(item);
				int itemMoney = StringToInt(otherMenu[index][2]);
				int iSlot0 = GetPlayerWeaponSlot(param1, 0);
				if( g_iCredits[param1] - itemMoney < 0)
				{
					CPrintToChat(param1, "[{olive}TS{default}] %T", "Not enough money", param1, g_iCredits[param1], itemMoney);
				}
				else
				{
					if(strcmp(otherMenu[index][0], "laser_sight") == 0 || strcmp(otherMenu[index][0], "incendiary_ammo") == 0 || strcmp(otherMenu[index][0], "explosive_ammo") == 0 )
					{
						if(iSlot0 <= 0 )
						{
							CPrintToChat(param1, "[{olive}TS{default}] %T", "Must have primary weapon", param1);
						}
						else
						{
							GiveUpgrade(param1, otherMenu[index][0], otherMenu[index][1]);
							g_iCredits[param1] -= itemMoney;
						}
					}
					else if(strcmp(otherMenu[index][0], "ammo") == 0)
					{
						if(iSlot0 <= 0 )
						{
							CPrintToChat(param1, "[{olive}TS{default}] %T", "Must have primary weapon", param1);
						}
						else
						{
							GiveClientAmmo(param1, iSlot0, otherMenu[index][1]);
							g_iCredits[param1] -= itemMoney;
						}
					}
					else if (strcmp(otherMenu[index][0], "gascan") == 0)
					{
						if(g_bGascanMap == false)
						{
							CPrintToChat(param1, "[{olive}TS{default}] %T", "Can't buy gascan in current map", param1);	
						}
						else
						{
							GiveFunction(param1, otherMenu[index][0], otherMenu[index][1]);
							g_iCredits[param1] -= itemMoney;
						}
					}
					else if (strcmp(otherMenu[index][0], "cola_bottles") == 0)
					{
						if(g_bColaMap == false)
						{
							CPrintToChat(param1, "[{olive}TS{default}] %T", "Can't buy cola in current map", param1);	
						}
						else
						{
							GiveFunction(param1, otherMenu[index][0], otherMenu[index][1]);
							g_iCredits[param1] -= itemMoney;
						}
					}
					else
					{
						GiveFunction(param1, otherMenu[index][0], otherMenu[index][1]);
						g_iCredits[param1] -= itemMoney;
					}
				}
				g_iMenuOtherPosition[param1] = othermenu.Selection; 
				DisplayShopMenu(param1, EMenuType:eOtherMenu);
			}
		}
		case MenuAction_End:
			delete othermenu;
	}
}

public int Special_Menu_Handle(Menu specialmenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				g_hSurvivorMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hSurvivorMenu.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select:
		{
			char item[64];
			specialmenu.GetItem(param2, item, sizeof(item));
			int index = StringToInt(item);
			if(CanClientBuy(param1, specialMenu[index][0]) == true) 
			{
				
				int itemMoney = StringToInt(specialMenu[index][2]);
				if( g_iCredits[param1] - itemMoney < 0)
				{
					CPrintToChat(param1, "[{olive}TS{default}] %T", "Not enough money", param1, g_iCredits[param1], itemMoney);
				}
				else
				{
					if(strcmp(specialMenu[index][0], "Fire") == 0)
					{
						CreateFires(param1, specialMenu[index][1]);
						g_iCredits[param1] -= itemMoney;
					}
					if(strcmp(specialMenu[index][0], "Teleport") == 0)
					{
						if (IsHandingFromLedge(param1))
						{
							PrintToChat(param1, "%T", "Can't buy when handing from ledge", param1);
						}
						else
						{
							if( TeleportToNearestTeammate(param1, specialMenu[index][1]))
							{
								g_iCredits[param1] -= itemMoney;
							}
							else
							{
								PrintToChat(param1, "%T", "No Any Other Survivors", param1);
							}
						}
					}
					else if(strcmp(specialMenu[index][0], "Kill Commons") == 0)
					{
						KillAllCommonInfected(param1, specialMenu[index][1]);
						g_iCredits[param1] -= itemMoney;
					}
					else if(strcmp(specialMenu[index][0], "Heal Survivors") == 0)
					{
						HealthAllSurvivors(param1, specialMenu[index][1]);
						g_iCredits[param1] -= itemMoney;
					}
					else if (strcmp(specialMenu[index][0], "Jump+1") == 0)
					{
						if(g_iCanJump[param1] >= g_iMaxJumpLimit)
						{
							PrintToChat(param1, "%T", "Jump Limit", param1);
						}
						else if (bFinaleEscapeStarted)
						{
							PrintToChat(param1, "%T", "Can't buy after final rescue starts", param1);
						}
						else
						{
							g_iCanJump[param1]++;
							PrintToTeam(param1, L4D_TEAM_SURVIVORS, specialMenu[index][1], true);
							g_iCredits[param1] -= itemMoney;
							PlaySound(param1, BUY_Sound2);
						}
					}
					else if (strcmp(specialMenu[index][0], "Infinite Ammo") == 0)
					{
						if(InfiniteAmmo[param1] == true)
						{
							PrintToChat(param1, "%T", "Already Buy", param1);
						}
						else
						{
							InfiniteAmmo[param1] = true;
							PrintToTeam(param1, L4D_TEAM_SURVIVORS, specialMenu[index][1], true);
							g_iCredits[param1] -= itemMoney;
							CreateTimer(float(g_iInfiniteAmmoTime), Timer_NoInfiniteAmmo, param1, TIMER_FLAG_NO_MAPCHANGE);
							PlaySound(param1, BUY_Sound2);
						}
					}
					else if (strcmp(specialMenu[index][0], "Fire Infeceted") == 0)
					{
						FireAllInfected(param1, specialMenu[index][1]);
						g_iCredits[param1] -= itemMoney;
					}
					else if (strcmp(specialMenu[index][0], "Kill Witches") == 0)
					{
						KillAllWitches(param1, specialMenu[index][1]);
						g_iCredits[param1] -= itemMoney;
					}	
					else if (strcmp(specialMenu[index][0], "Slay Infected") == 0)
					{
						int infectedattacker = L4D2_GetInfectedAttacker(param1);
						if(infectedattacker > 0)
						{
							ForcePlayerSuicide(infectedattacker);
							g_iCredits[param1] -= itemMoney;
							PrintToTeam(param1, 0, specialMenu[index][1], true);
							PlaySound(param1, BUY_Sound2);
						}
						else
						{
							PrintToChat(param1, "%T", "You are not being attacked", param1);
						}
					}
					else if (strcmp(specialMenu[index][0], "Dead Eyes") == 0)
					{
						if (g_bDeadEyeEffect == true)
						{
							PrintToChat(param1, "%T", "Someone Already Buy", param1);
						}
						else
						{
							CreateDeadEyesGlow(param1, specialMenu[index][1]);
							g_iCredits[param1] -= itemMoney;
						}
					}		
				}
				g_iMenuSpecialPosition[param1] = specialmenu.Selection; 
				//DisplayShopMenu(param1, EMenuType:eSpecialMenu);
			}
		}
		case MenuAction_End:
			delete specialmenu;
	}
}

public int InfectedShopMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			if (strcmp(item, "InfectedInstruction") == 0)
			{
				g_hInfectedMenu.SetTitle("%T", "Infected Menu Title", param1, g_iCredits[param1]);
				g_hInfectedMenu.Display(param1, MENU_TIME_FOREVER);
			}
			if (strcmp(item, "InfectedSpawnMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eInfectedSpawnMenu);
			}
			if (strcmp(item, "InfectedSpecialMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eInfectedSpecialMenu);
			}
			if (strcmp(item, "transfer") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eTransferPlayerMenu);
			}
		}
		case MenuAction_DisplayItem:
		{
			static char info[64];
			static char display[128];
			menu.GetItem(param2, info, sizeof(info));	
			if (strcmp(info, "InfectedInstruction") == 0)
			{
				Format(display, sizeof(display), "%T", "InfectedInstruction", param1);
				return RedrawMenuItem(display);
			}
			else if (strcmp(info, "InfectedSpawnMenu") == 0)
			{
				Format(display, sizeof(display), "%T", "InfectedSpawnMenu", param1);
				return RedrawMenuItem(display);
			}
			else if (strcmp(info, "InfectedSpecialMenu") == 0)
			{
				Format(display, sizeof(display), "%T", "InfectedSpecialMenu", param1);
				return RedrawMenuItem(display);
			}
			else if (strcmp(info, "transfer") == 0)
			{
				Format(display, sizeof(display), "%T","transferMenu", param1);
				return RedrawMenuItem(display);
			}
		}
	}

	return 0;
}

public int Infected_Spawn_Menu_Handle(Menu mmenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				g_hInfectedMenu.SetTitle("%T", "Infected Menu Title", param1, g_iCredits[param1]);
				g_hInfectedMenu.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select:
		{
			if(CanInfectedBuy(param1) == true) 
			{
				char item[64];
				mmenu.GetItem(param2, item, sizeof(item));
				
				int index = StringToInt(item);
				int itemMoney = StringToInt(infectedSpawnMenu[index][2]);
				if( g_iCredits[param1] - itemMoney < 0)
				{
					CPrintToChat(param1, "[{olive}TS{default}] %T", "Not enough money", param1, g_iCredits[param1], itemMoney);
					return;
				}
				if (strcmp(infectedSpawnMenu[index][0], "Suicide") == 0)
				{
					if (!IsPlayerAlive(param1))
					{
						CPrintToChat(param1, "%T", "Alive Infected First", param1);
						return;
					}

					ForcePlayerSuicide(param1);
					PrintToTeam(param1, L4D_TEAM_INFECTED, infectedSpawnMenu[index][1]);
					PlaySound(param1, BUY_Sound1);
					g_iCredits[param1] -= itemMoney;
					g_fInfectedBuyTime[param1] = GetEngineTime() + g_fInfectedShopColdDown;
					return;
				}
			
				if (IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "%T", "Dead Infected First", param1);
					return;
				}
				
				if (strcmp(infectedSpawnMenu[index][0], "Tank") == 0 && CountTankInServer() >= g_iInfectedShopTankLimit )
				{
					CPrintToChat(param1, "%T", "Tank Limit Reached", param1);
					return;
				}

				InfectedSpawnFunction(param1, infectedSpawnMenu[index][0]);
				if (!IsPlayerAlive(param1)) //fail to spawn
				{
					CPrintToChat(param1, "%T", "Can not Spawn Infected", param1);
					return;
				}
		
				PrintToTeam(param1, L4D_TEAM_INFECTED, infectedSpawnMenu[index][1]);
				PlaySound(param1, BUY_Sound1);
				g_iCredits[param1] -= itemMoney;
				g_fInfectedBuyTime[param1] = GetEngineTime() + g_fInfectedShopColdDown;
			}
		}
		case MenuAction_End:
			delete mmenu;
	}
}

public int Infected_Specials_Menu_Handle(Menu mmenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				g_hInfectedMenu.SetTitle("%T", "Infected Menu Title", param1, g_iCredits[param1]);
				g_hInfectedMenu.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select:
		{
			if(CanInfectedBuy(param1) == true) 
			{
				char item[64];
				mmenu.GetItem(param2, item, sizeof(item));
				
				int index = StringToInt(item);
				int itemMoney = StringToInt(infectedSpecialMenu[index][2]);
				if( g_iCredits[param1] - itemMoney < 0)
				{
					CPrintToChat(param1, "[{olive}TS{default}] %T", "Not enough money", param1, g_iCredits[param1], itemMoney);
				}
				else
				{
					if (IsPlayerAlive(param1) && GetEntProp(param1, Prop_Send, "m_zombieClass") != ZC_TANK)
					{
						if (strcmp(infectedSpecialMenu[index][0], "Health") == 0)
						{
							SetEntityHealth(param1, GetEntProp(param1, Prop_Data, "m_iMaxHealth"));
							PrintToTeam(param1, L4D_TEAM_INFECTED, infectedSpecialMenu[index][1], true);
							PlaySound(param1, BUY_Sound2);
							g_iCredits[param1] -= itemMoney;
							g_fInfectedBuyTime[param1] = GetEngineTime() + g_fInfectedShopColdDown;
						}
						else if (strcmp(infectedSpecialMenu[index][0], "Immune") == 0)
						{
							if(InfectedImmuneDamage[param1]) return;
							
							InfectedImmuneDamage[param1] = true;
							SetGodframedGlow(param1);
							TurnFlashlightOn(param1);
							CreateTimer(float(g_iImmuneDamageTime), Timer_NoImmuneDamage, param1, TIMER_FLAG_NO_MAPCHANGE);
							CPrintToChat(param1, "%T", "Immune Everything Now", param1, g_iImmuneDamageTime);
							PrintToTeam(param1, L4D_TEAM_INFECTED, infectedSpecialMenu[index][1], true);
							PlaySound(param1, BUY_Sound2);
							g_iCredits[param1] -= itemMoney;
							g_fInfectedBuyTime[param1] = GetEngineTime() + g_fInfectedShopColdDown;
						}
						else if (strcmp(infectedSpecialMenu[index][0], "Teleport") == 0)
						{
							if( TeleportToNearestSurvivor(param1, infectedSpecialMenu[index][1]))
							{
								g_iCredits[param1] -= itemMoney;
								g_fInfectedBuyTime[param1] = GetEngineTime() + g_fInfectedShopColdDown;
							}
							else
							{
								PrintToChat(param1, "%T", "No Any Other Survivors", param1);
							}
						}
					}
					else
					{
						CPrintToChat(param1, "%T", "Alive Infected Except Tank First", param1);
					}
				}
			}
		}
		case MenuAction_End:
			delete mmenu;
	}
}

void DisplayShopMenu(int client, EMenuType eMenutype)
{
	Menu menu = null;

	switch(eMenutype)
	{
		case (EMenutype:eWeaponMenu):
		{
			menu = new Menu(Weapon_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Weapon Menu Title", client, g_iCredits[client]);
		}
		case (EMenutype:eMeleeMenu):
		{
			menu = new Menu(Melee_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Melee Menu Title", client, g_iCredits[client]);
		}
		case (EMenutype:eMedicThrowableMenu):
		{
			menu = new Menu(Medic_Throwable_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "MedicThrowable Menu Title", client, g_iCredits[client]);
		}
		case (EMenutype:eOtherMenu):
		{
			menu = new Menu(Other_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Other Menu Title", client, g_iCredits[client]);
		}
		case (EMenuType:eSpecialMenu):
		{
			menu = new Menu(Special_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Special Menu Title", client, g_iCredits[client]);
		}
		case (EMenuType:eTransferPlayerMenu):
		{
			menu = new Menu(Transfer_Player_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Transfer Player Menu Title", client, g_iCredits[client]);
		}
		case (EMenuType:eTransferPointMenu):
		{
			menu = new Menu(Transfer_Point_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Transfer Point Menu Title", client, g_iCredits[client]);
		}
		case (EMenuType:eInfectedSpawnMenu):
		{
			menu = new Menu(Infected_Spawn_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Infected Spawn Menu Title", client, g_iCredits[client]);
		}
		case (EMenuType:eInfectedSpecialMenu):
		{
			menu = new Menu(Infected_Specials_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Infected Specials Menu Title", client, g_iCredits[client]);
		}
	}

	if ( menu == null ) return;

	menu.ExitBackButton = true;
	menu.ExitButton = true;

	switch(eMenutype)
	{
		case (EMenutype:eWeaponMenu):
		{
			DisplayShopMenuItem(client, menu, weaponsMenu, sizeof(weaponsMenu));
			menu.DisplayAt(client, g_iMenuWeaponPosition[client], MENU_TIME_FOREVER);
		}
		case (EMenutype:eMeleeMenu):
		{
			DisplayShopMenuItem(client, menu, meleeMenu, sizeof(meleeMenu));
			menu.DisplayAt(client, g_iMenuMeleePosition[client], MENU_TIME_FOREVER);
		}
		case (EMenutype:eMedicThrowableMenu):
		{
			DisplayShopMenuItem(client, menu, medicThrowableMenu, sizeof(medicThrowableMenu));
			menu.DisplayAt(client, g_iMenuMedicThrowablePosition[client], MENU_TIME_FOREVER);
		}
		case (EMenutype:eOtherMenu):
		{
			DisplayShopMenuItem(client, menu, otherMenu, sizeof(otherMenu));
			menu.DisplayAt(client, g_iMenuOtherPosition[client], MENU_TIME_FOREVER);
		}
		case (EMenutype:eSpecialMenu):
		{
			DisplayShopMenuItem(client, menu, specialMenu, sizeof(specialMenu));
			menu.DisplayAt(client, g_iMenuSpecialPosition[client], MENU_TIME_FOREVER);
		}
		case (EMenutype:eTransferPlayerMenu):
		{
			ShowMenuTransferPlayerList(client, menu);
			menu.Display(client, MENU_TIME_FOREVER);
		}
		case (EMenuType:eTransferPointMenu):
		{
			ShowMenuTransferPointList(client, menu);
			menu.Display(client, MENU_TIME_FOREVER);
		}
		case (EMenuType:eInfectedSpawnMenu):
		{
			DisplayShopMenuItem(client, menu, infectedSpawnMenu, sizeof(infectedSpawnMenu));
			menu.Display(client, MENU_TIME_FOREVER);
		}
		case (EMenuType:eInfectedSpecialMenu):
		{
			DisplayShopMenuItem(client, menu, infectedSpecialMenu, sizeof(infectedSpecialMenu));
			menu.Display(client, MENU_TIME_FOREVER);
		}
	}
}

void DisplayShopMenuItem (int client, Menu menu, const char [][][] array, const int size)
{
	char sItemName[32], sDisplayName[64];
	for( int index = 0 ; index < size ; ++index )
	{
		IntToString(index, sItemName, sizeof(sItemName));
		FormatEx(sDisplayName, sizeof(sDisplayName), "%T - %s%T", array[index][1], client, array[index][2], "Unit", client);
		menu.AddItem(sItemName, sDisplayName);
	}
}

public Action ShowMenuTransferPlayerList(int client, Menu menu)
{
	int players = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && i != client)
		{
			char clientid[32];
			char clientName[100];
			Format(clientid, sizeof(clientid), "%d", GetClientUserId(i));
			Format(clientName, sizeof(clientName), "%N (%d%T)", i, g_iCredits[i], "Unit", client);

			menu.AddItem(clientid, clientName);
			players++;
		}
	}
	
	if (players == 0)
	{
		char info[64];
		Format(info, sizeof(info), "%T", "There are no any players at this moment.", client);
		menu.AddItem("0", info);
	}
}

public int Transfer_Player_Menu_Handle(Menu transfermenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				if(GetClientTeam(param1) == L4D_TEAM_SURVIVORS)
				{
					g_hSurvivorMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
					g_hSurvivorMenu.Display(param1, MENU_TIME_FOREVER);
				}
				else if(GetClientTeam(param1) == L4D_TEAM_INFECTED)
				{
					g_hInfectedMenu.SetTitle("%T", "Infected Menu Title", param1, g_iCredits[param1]);
					g_hInfectedMenu.Display(param1, MENU_TIME_FOREVER);
				} 
			}
		}
		case MenuAction_Select:
		{
			char clientid[32];
			transfermenu.GetItem(param2, clientid, sizeof(clientid));
			int ChoosenClient = StringToInt(clientid);
			if (ChoosenClient != 0)
			{
				ChoosenClient = GetClientOfUserId(ChoosenClient);
				if(ChoosenClient && IsClientInGame(ChoosenClient)) 
				{
					g_iTransferSelectPlayer[param1] = GetClientUserId(ChoosenClient);
					DisplayShopMenu(param1, EMenuType:eTransferPointMenu);
				}
				else
				{
					CPrintToChat(param1, "[{olive}TS{default}] %T", "The chosen player is not in server now! Choose again!", param1);
					DisplayShopMenu(param1, EMenuType:eTransferPlayerMenu);
				}
			}
		}
		case MenuAction_End:
			delete transfermenu;
	}
}

public Action ShowMenuTransferPointList(int client, Menu menu)
{
	for(int i = 0; i < sizeof(g_iTransferPointList); i++)
	{
		char item [32];
		char itemName [64];
		Format(item, sizeof(item),"%d", i);
		Format(itemName, sizeof(itemName), "%d%T", g_iTransferPointList[i], "Unit", client);
		menu.AddItem(item, itemName);
	}
}

public int Transfer_Point_Menu_Handle(Menu transfermenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				if(GetClientTeam(param1) == L4D_TEAM_SURVIVORS)
				{
					g_hSurvivorMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
					g_hSurvivorMenu.Display(param1, MENU_TIME_FOREVER);
				}
				else if(GetClientTeam(param1) == L4D_TEAM_INFECTED)
				{
					g_hInfectedMenu.SetTitle("%T", "Infected Menu Title", param1, g_iCredits[param1]);
					g_hInfectedMenu.Display(param1, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Select:
		{
			char item[32];
			transfermenu.GetItem(param2, item, sizeof(item));
			int money = g_iTransferPointList[StringToInt(item)];
			if (g_iCredits[param1] - money > 0)
			{
				int ChoosenClient = GetClientOfUserId(g_iTransferSelectPlayer[param1]);
				if(ChoosenClient && IsClientInGame(ChoosenClient)) 
				{
					g_iCredits[param1] -= money;
					g_iCredits[ChoosenClient] += money;
					CPrintToChat(param1, "[{olive}TS{default}] %T", "Transfer point to player", param1, money, ChoosenClient);
					CPrintToChat(ChoosenClient, "[{olive}TS{default}] %T", "Player transfer point to you", ChoosenClient, param1, money);
				}
				else	
				{
					CPrintToChat(param1, "[{olive}TS{default}] %T", "The chosen player is not in server now! Choose again!", param1);
					DisplayShopMenu(param1, EMenuType:eTransferPlayerMenu);
				}
			}
			else
			{
				CPrintToChat(param1, "[{olive}TS{default}] %T", "Failed! Points balance is not enough to transfer.", param1);
				DisplayShopMenu(param1, EMenuType:eTransferPointMenu);
			}
		}
		case MenuAction_End:
			delete transfermenu;
	}	
}

void SaveAllMoney()
{
	for( int i = 1; i <= MaxClients; i++ ) {
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SaveMoney(i);
		}
	}
}

void SaveMoney(int client)
{
	char sMoney[11];
	if(g_iCredits[client] > MAX_MONEY) g_iCredits[client] = MAX_MONEY;
	IntToString(g_iCredits[client], sMoney, sizeof(sMoney));
	SetClientCookie(client, g_hMoneyCookie, sMoney);
}

stock void CreateFires(int client, char[] displayName)
{
	int entity = CreateEntityByName("prop_physics");
	if( entity != -1 )
	{
		SetEntityModel(entity, MODEL_GASCAN);

		static float vPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);
		vPos[2] += 10.0;
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(entity);

		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
		SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 0, 0, 0, 0);
		AcceptEntityInput(entity, "Break");
	}

	PrintToTeam(client, L4D_TEAM_SURVIVORS, displayName);
	
	PlaySound(client, BUY_Sound2);
}

stock void GiveFunction(int client, char[] name, char[] displayName)
{
	int flagsgive = GetCommandFlags("give");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", name);
	SetCommandFlags("give", flagsgive);

	PrintToTeam(client, L4D_TEAM_SURVIVORS, displayName);
	
	PlaySound(client, BUY_Sound1);
}

stock void GiveUpgrade(int client, char[] name, char[] displayName)
{
	char sBuf[32];
	int flags = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", flags & ~FCVAR_CHEAT);
	FormatEx(sBuf, sizeof (sBuf), "upgrade_add %s", name);
	FakeClientCommand(client, sBuf);
	SetCommandFlags("upgrade_add", flags);

	PrintToTeam(client, L4D_TEAM_SURVIVORS, displayName);

	PlaySound(client, BUY_Sound2);
}

stock void GiveClientAmmo(int client, int iSlot0, char[] displayName)
{
	char slot0ClassName[40];
	GetEdictClassname(iSlot0, slot0ClassName, sizeof(slot0ClassName));
	int weaponAmmoOffset, ammoMax;
	for( int i = 0 ; i < sizeof(weapon_ammo) ; ++i) {
		if (strcmp(slot0ClassName, weapon_ammo[i][0]) == 0)
		{
			weaponAmmoOffset = StringToInt(weapon_ammo[i][1]);
			ammoMax = GetEntData(client, ammoOffset+(weaponAmmoOffset*4)) + StringToInt(weapon_ammo[i][2]);
			if(ammoMax > 999) ammoMax = 999;
			SetEntData(client, ammoOffset+(weaponAmmoOffset*4), ammoMax);
		}
	}

	PrintToTeam(client, L4D_TEAM_SURVIVORS, displayName);

	PlaySound(client, BUY_Sound2);
}

stock void GiveClientHealth(int client, int iHealthAdd, char[] displayName, bool bPrint = true)
{
	if(IsIncapacitated(client) || IsHandingFromLedge(client))
	{
		int flagsgive = GetCommandFlags("give");
		SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give health");
		SetCommandFlags("give", flagsgive);
		SetTempHealth( client, 0.0 );
	}
	else
	{
		int iHealth = GetClientHealth( client );
		float fHealth = GetTempHealth( client );

		SetEntityHealth( client, iHealth + iHealthAdd );
		SetClientHealth( client, fHealth );
	}

	if(bPrint) PrintToTeam(client, L4D_TEAM_SURVIVORS, displayName);

	PlaySound(client, BUY_Sound2);
}

stock void KillAllCommonInfected(int client, char[] displayName)
{
	for (int i = MaxClients; i <= 2048; i++)
	{
		if (!IsValidEntity(i))
			continue;
		
		static char szClass[36];
		GetEntityClassname(i, szClass, sizeof szClass);
		
		if (strcmp(szClass, "infected") == 0)
			ForceDamageEntity(client, 1000, i);
	}

	PrintToTeam(client, 0, displayName, true);
	PlaySound(client, BUY_Sound2);
}

stock void KillAllWitches(int client, char[] displayName)
{
	int witch = -1;
	while((witch = FindEntityByClassname(witch, "witch")) != -1)
	{
		if (!IsValidEntity(witch))
		continue;	

		AcceptEntityInput(witch, "Kill");
	}

	PrintToTeam(client, 0, displayName, true);
	PlaySound(client, BUY_Sound2);
}

stock void FireAllInfected(int client, char[] displayName)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == L4D_TEAM_INFECTED)
			SDKHooks_TakeDamage(i, client, client, 1.0, DMG_BURN);
	}

	PrintToTeam(client, 0, displayName, true);
	PlaySound(client, BUY_Sound2);
}

stock void HealthAllSurvivors(int client, char[] displayName)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != L4D_TEAM_SURVIVORS || !IsPlayerAlive(i))
			continue;

		GiveClientHealth(i, 100, "", false);
	}

	PrintToTeam(client, 0, displayName, true);
}

stock void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth );
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

stock bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

stock bool IsHandingFromLedge(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

bool CanClientBuy(int client, char[] ShopItemName = "")
{
	if(!IsClientInGame(client)) return false;

	if(GetClientTeam(client) != L4D_TEAM_SURVIVORS || IsPlayerAlive(client) == false)
	{
		CPrintToChat(client, "%T", "Alive Survivor First", client);
		return false;
	}

	if(IsSurvivorPinned(client) && strcmp(ShopItemName, "Slay Infected") != 0)
	{
		CPrintToChat(client, "%T", "Can't buy when being attacked", client);
		return false;
	}

	return true;
}

bool CanInfectedBuy(int client)
{
	if (!IsClientInGame(client)) return false;
	
	if (GetClientTeam(client) != L4D_TEAM_INFECTED)
	{
		CPrintToChat(client, "%T", "You are not in infected team", client);
		return false;
	}
	if (g_fInfectedBuyTime[client] > GetEngineTime())
	{
		CPrintToChat(client, "%T", "Can not buy so quickly", client, g_fInfectedShopColdDown);
		return false;
	}
	
	return true;
}

bool IsSurvivorPinned(int client)
{
	int attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	int attacker2 = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	int attacker3 = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	int attacker4 = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	int attacker5 = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if ((attacker > 0 && attacker != client) || (attacker2 > 0 && attacker2 != client) || (attacker3 > 0 && attacker3 != client) || (attacker4 > 0 && attacker4 != client) || (attacker5 > 0 && attacker5 != client))
	{
		return true;
	}
	return false;
}

float GetTempHealth(int client)
{
	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * g_DecayDecay.FloatValue;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

void SetClientHealth(int client, float fHealth)
{	
	if( GetEntProp( client, Prop_Send, "m_currentReviveCount" ) >= 1 && g_iMaxIncapCount >= 1 ) 	// The client has been incompetent once.
	{
		int flagsgive = GetCommandFlags("give");
		SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give health");
		SetCommandFlags("give", flagsgive);
		
		SetEntPropFloat( client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth );
		SetEntPropFloat( client, Prop_Send, "m_healthBufferTime", GetGameTime() );
	}
}

void CheckPlayers()
{
	int count = 0;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) == L4D_TEAM_SURVIVORS || GetClientTeam(i) == L4D_TEAM_INFECTED))
			count++;
	}

	if(count >= g_iPlayerRequired) g_bEnable = true;
	else g_bEnable = false;
}

void PrintToTeam (int client, int team, char[] displayName, bool bSpecial = false)
{
	char clientname[64];
	GetClientName(client, clientname, sizeof(clientname));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && (team == 0 || (GetClientTeam(i) == team || GetClientTeam(i) == L4D_TEAM_SPECTATOR)))
		{
			if(bSpecial)
				CPrintToChat(i, "[{olive}TS{default}] %T", "Buy Special", i, clientname, displayName);	
			else
				CPrintToChat(i, "[{olive}TS{default}] %T", "Buy", i, clientname, displayName);	
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_bEnable && g_iCanJump[client] > 0)
	{
		int fCurFlags = GetEntityFlags(client);
		if(fCurFlags & FL_ONGROUND)
		{
			Landed(client);
		}
		else if(!(g_iLastButtons[client] & IN_JUMP) && (buttons & IN_JUMP) && !(fCurFlags & FL_ONGROUND))
		{
			ReJump(client);
		}
		
		g_iLastButtons[client] = buttons;
	}
}

void Landed(int client) {
	g_iJumps[client] = 0;	// reset jumps count
}

void ReJump(int client)
{
	if (g_iJumps[client] < g_iCanJump[client]) // has jumped at least once but hasn't exceeded max re-jumps
	{						
		g_iJumps[client]++;										// increment jump count
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);	// get current speeds
		
		vVel[2] = X_REJUMPBOOST;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);		// boost player
	}
}

int GetWeaponClip(int weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_iClip1");
} 

int GetWeaponSpecialClip(int weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") ;
} 

void ForceDamageEntity(int causer, int damage, int victim)
{
	float victim_origin[3];
	char rupture[32];
	char damage_victim[32];
	IntToString(damage, rupture, sizeof(rupture));
	Format(damage_victim, sizeof(damage_victim), "hurtme%d", victim);
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victim_origin);
	int entity = CreateEntityByName("point_hurt");
	DispatchKeyValue(victim, "targetname", damage_victim);
	DispatchKeyValue(entity, "DamageTarget", damage_victim);
	DispatchKeyValue(entity, "Damage", rupture);
	DispatchSpawn(entity);
	TeleportEntity(entity, victim_origin, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "Hurt", (causer > 0 && causer <= MaxClients) ? causer : -1);
	DispatchKeyValue(entity, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	AcceptEntityInput(entity, "Kill");
}

bool TeleportToNearestTeammate (int client, char[] displayName)
{
	int iTarget = 0; 
	float fMinDistance = 0.0;
	float clientOrigin[3];
	float targetOrigin[3];
	float fDistance = 0.0;
	GetClientAbsOrigin(client, clientOrigin);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(client != i && IsClientInGame(i) && GetClientTeam(i) == L4D_TEAM_SURVIVORS && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, targetOrigin);
			fDistance = GetVectorDistance(clientOrigin, targetOrigin, true);
			if (fDistance < fMinDistance || fMinDistance == 0.0)
			{
				iTarget = i;
				fMinDistance = fDistance;
			}
		}
	}

	if(iTarget == 0) return false;

	GetClientAbsOrigin(iTarget, targetOrigin);
	TeleportEntity( client, targetOrigin, NULL_VECTOR, NULL_VECTOR);

	PrintToTeam(client, L4D_TEAM_SURVIVORS, displayName, true);
	PlaySound(client, BUY_Sound2);

	return true;
}

bool IsFire(const char[] classname)
{
	return strcmp(classname, "inferno") == 0;
} 

bool IsPipeBombExplode(const char[] classname)
{
	return strcmp(classname, "pipe_bomb") == 0;
} 

bool IsFireworkcrate(const char[] classname)
{
	return strcmp(classname, "fire_cracker_blast") == 0;
} 

void CreateDeadEyesGlow(int client, char[] displayName)
{
	g_bDeadEyeEffect = true;

	for( int i = 1; i <= MaxClients; i++ ) 
		CreateInfectedModelGlow(i);

	int entity;
	entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, INFECTED_NAME)) != INVALID_ENT_REFERENCE)
	{
		RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
	}
	/*while ((entity = FindEntityByClassname(entity, WITCH_NAME)) != INVALID_ENT_REFERENCE)
	{
		RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
	}*/

	CreateTimer(float(g_iDeadEyeTime), Timer_DeadEyeOut, _ ,TIMER_FLAG_NO_MAPCHANGE);

	PrintToTeam(client, 0, displayName, true);
	CPrintToChatAll("[{olive}TS{default}] %t", "Dead-Eyes Effect", g_iDeadEyeTime);
	PlaySoundToAll(DEAD_EYES_Sound1);
}

public void CreateInfectedModelGlow(int client)
{
	if (g_bDeadEyeEffect == false ||
	!client || 
	!IsClientInGame(client) || 
	GetClientTeam(client) != L4D_TEAM_INFECTED ||
	!IsPlayerAlive(client)) return;
	
	///////設定發光物件//////////
	// Get Client Model
	char sModelName[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
	//PrintToChatAll("%N: %s",client,sModelName);
	
	// Spawn dynamic prop entity
	int entity = CreateEntityByName("prop_dynamic_ornament");
	if (entity == -1) return;

	// Set new fake model
	PrecacheModel(sModelName);
	SetEntityModel(entity, sModelName);
	DispatchSpawn(entity);

	// Set outline glow color
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", 4500);
	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	if(IsPlayerGhost(client))
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 255 + 255 * 256 + 255 * 65536);
	else
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 255 + 0 + 0);
	AcceptEntityInput(entity, "StartGlowing");

	// Set model invisible
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	
	// Set model attach to client, and always synchronize
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetAttached", client);
	AcceptEntityInput(entity, "TurnOn");
	///////發光物件完成//////////
	
	g_iModelIndex[client] = EntIndexToEntRef(entity);
		
	//model 只能給誰看?
	SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
}

public Action Hook_SetTransmit(int entity, int client)
{
	if( GetClientTeam(client) == L4D_TEAM_INFECTED)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

void RemoveInfectedModelGlow(int client)
{
	int entity = g_iModelIndex[client];
	g_iModelIndex[client] = 0;

	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "kill");
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE && entity!= -1 )
		return true;
	return false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!IsValidEntityIndex(entity))
		return;

	if (g_bDeadEyeEffect == false)
		return;

	if (StrEqual(classname, INFECTED_NAME) || StrEqual(classname, WITCH_NAME))
		RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

bool IsValidEntityIndex(int entity)
{
	return (MaxClients+1 <= entity <= GetMaxEntities());
}

public void OnNextFrame(int entityRef)
{
	int entity = EntRefToEntIndex(entityRef);

	if (entity == INVALID_ENT_REFERENCE)
		return;

	static char szClass[36];
	GetEntityClassname(entity, szClass, sizeof szClass);
	if (strcmp(szClass, INFECTED_NAME) == 0)
	{
		if(GetEntProp(entity, Prop_Data, "m_iHammerID") == 0)
		{	
			SetEntProp(entity, Prop_Send, "m_nGlowRange", 3000);
			SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", 200 + 200 * 256 + 0);
			AcceptEntityInput(entity, "StartGlowing");
		}
	}
	/*else if (strcmp(szClass, WITCH_NAME) == 0)
	{
			SetEntProp(entity, Prop_Send, "m_nGlowRange", 3000);
			SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", 255 + 0 + 0);
			AcceptEntityInput(entity, "StartGlowing");
	}*/
}

bool IsPlayerGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

public Action Timer_DeadEyeOut(Handle timer)
{
	g_bDeadEyeEffect = false;
	PlaySoundToAll(DEAD_EYES_Sound2);
	RemoveAllModelGlow();
	CPrintToChatAll("[{olive}TS{default}] %t", "Dead-Eyes Effect Time Out");
}


void RemoveAllModelGlow()
{
	for( int i = 1; i <= MaxClients; i++ )
		RemoveInfectedModelGlow(i);

	int entity;
	while ((entity = FindEntityByClassname(entity, INFECTED_NAME)) != INVALID_ENT_REFERENCE)
	{
		SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
	}

	/*while ((entity = FindEntityByClassname(entity, WITCH_NAME)) != INVALID_ENT_REFERENCE)
	{
		SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
	}*/
}

void PlaySoundToClient(int client, char[] sSoundName)
{
	EmitSoundToClient(client, sSoundName, _, SNDCHAN_AUTO, SNDLEVEL_CONVO, _, SNDVOL_NORMAL, _, _, _, _, _, _ );
}

void PlaySoundToAll(char[] sSoundName)
{
	EmitSoundToAll(sSoundName, _, SNDCHAN_AUTO, SNDLEVEL_CONVO, _, SNDVOL_NORMAL, _, _, _, _, _, _ );
}

void PlaySound(int client, char[] sSoundName)
{
	EmitSoundToAll(sSoundName, client, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

stock void InfectedSpawnFunction(int client, char[] infected_name)
{
	bool resetGhost[MAXPLAYERS+1];
	bool resetLife[MAXPLAYERS+1];
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && i != client)
		{
			if (GetClientTeam(i) == L4D_TEAM_INFECTED)
			{
				if (IsPlayerGhost(i))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
				}
				else if (!IsPlayerAlive(i))
				{
					resetLife[i] = true;
					SetLifeState(i, false);
				}
			}
		}
	}
	
	
	int anyclient = GetRandomClient();
	if(anyclient == 0)
	{
		return;
	}
	
	CheatCommand(anyclient, "z_spawn_old", infected_name, "auto");
	
	for (int i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i] == true)
			SetGhostStatus(i, true);
		if (resetLife[i] == true)
			SetLifeState(i, true);
	}
}

void SetGhostStatus (int client, bool ghost)
{
	if (ghost)
		SetEntProp(client, Prop_Send, "m_isGhost", 1, 1);
	else
		SetEntProp(client, Prop_Send, "m_isGhost", 0, 1);
}

void SetLifeState (int client, bool ready)
{
	if (ready)
		SetEntProp(client, Prop_Send,  "m_lifeState", 1, 1);
	else
		SetEntProp(client, Prop_Send, "m_lifeState", 0, 1);
}

int GetRandomClient()
{
	int iClientCount, iClients[MAXPLAYERS+1];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iClients[iClientCount++] = i;
		}
	}
	return (iClientCount == 0) ? 0 : iClients[GetRandomInt(0, iClientCount - 1)];
}

void CheatCommand(int client, char[] command, char[] arguments = "", char[] extra = "")
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, arguments, extra);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

public Action Timer_NoImmuneDamage(Handle timer, int client)
{
	InfectedImmuneDamage[client] = false;
	if(IsClientInGame(client))
	{
		PrintToChat(client, "%T", "Immune Everything Timer",client);
		DeleteLight(client);
		ResetGlow(client);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType)
{
	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim) || IsFakeClient(victim) || GetClientTeam(victim) != L4D_TEAM_INFECTED) return Plugin_Continue;
	if (InfectedImmuneDamage[victim] == true)
	{
		if (attacker && attacker <= MaxClients && IsClientInGame(attacker))
		{
			if (!IsFakeClient(attacker)) EmitSoundToClient(attacker, IMMUNE_EVERYTHING_Sound1);
			EmitSoundToClient(victim, IMMUNE_EVERYTHING_Sound1);
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

int CountTankInServer()
{
	int count = 0;
	for (int i = 1; i < MaxClients+1; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == L4D_TEAM_INFECTED && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == ZC_TANK)
		{
			count++;
		}
	}

	return count;
}

bool TeleportToNearestSurvivor (int client, char[] displayName)
{
	int iTarget = 0; 
	float fMinDistance = 0.0;
	float clientOrigin[3];
	float targetOrigin[3];
	float fDistance = 0.0;
	GetClientAbsOrigin(client, clientOrigin);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == L4D_TEAM_SURVIVORS && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, targetOrigin);
			fDistance = GetVectorDistance(clientOrigin, targetOrigin, true);
			if (fDistance < fMinDistance || fMinDistance == 0.0)
			{
				iTarget = i;
				fMinDistance = fDistance;
			}
		}
	}

	if(iTarget == 0) return false;

	GetClientAbsOrigin(iTarget, targetOrigin);
	TeleportEntity( client, targetOrigin, NULL_VECTOR, NULL_VECTOR);

	PrintToTeam(client, 0, displayName, true);
	PlaySound(client, BUY_Sound2);

	return true;
}

public Action L4D2_OnStagger(int target, int source)
{
	if (InfectedImmuneDamage[target] == true)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action L4D_OnShovedBySurvivor(int client, int victim, const float vecDir[3])
{
	if (IsClientInGame(victim) && GetClientTeam(victim) == L4D_TEAM_INFECTED && InfectedImmuneDamage[victim] == true)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action L4D2_OnEntityShoved(int client, int entity, int weapon, float vecDir[3], bool bIsHighPounce)
{
	if(entity > 0 && entity <= MaxClients && IsClientInGame(entity) && GetClientTeam(entity) == L4D_TEAM_INFECTED)
	{
		if (InfectedImmuneDamage[entity] == true)
			return Plugin_Handled;	
	}

	return Plugin_Continue;
}

void TurnFlashlightOn(int client)
{
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) != L4D_TEAM_INFECTED) return;
	if (!IsPlayerAlive(client)) return;
	if (IsFakeClient(client)) return;

	DeleteLight(client);

	// Declares
	int entity;
	float vOrigin[3], vAngles[3];

	// Position light
	vOrigin = view_as<float>(  { 0.5, -1.5, 50.0 });
	vAngles = view_as<float>(  { -45.0, -45.0, 90.0 });

	// Light_Dynamic
	entity = MakeLightDynamic(vOrigin, vAngles, client);
	if(entity == -1) return;
	g_iLightIndex[client] = EntIndexToEntRef(entity);
}

void DeleteLight(int client)
{
	int entity = g_iLightIndex[client];
	g_iLightIndex[client] = 0;
	DeleteEntity(entity);
}

void DeleteEntity(int entity)
{
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");
}

int MakeLightDynamic(const float vOrigin[3], const float vAngles[3], int client)
{
	int entity = CreateEntityByName("light_dynamic");
	if( entity == -1)
	{
		return -1;
	}

	char sTemp[16];
	Format(sTemp, sizeof(sTemp), "155 0 255 155");
	DispatchKeyValue(entity, "_light", sTemp);
	DispatchKeyValue(entity, "brightness", "1");
	DispatchKeyValueFloat(entity, "spotlight_radius", 0.0);
	DispatchKeyValueFloat(entity, "distance", 450.0);
	DispatchKeyValue(entity, "style", "0");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");

	// Attach to infected
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);

	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	return entity;
}

void ResetGlow(int client) {
	if(IsPlayerAlive(client))
	{
		SetEntityRenderMode(client, view_as<RenderMode>(0));
		SetEntityRenderColor(client, 255,255,255,255);
	}
}

void SetGodframedGlow(client) {	
	SetEntityRenderMode(client, view_as<RenderMode>(3) );
	SetEntityRenderColor(client, 155, 0, 255, 180);
}
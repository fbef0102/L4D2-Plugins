#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <clientprefs>

public Plugin myinfo = 
{
	name = "L4D2 Survivor Buy Shop", 
	author = "Killing zombies and infected to earn points, Buy Shop", 
	description ="Shop by HarryPoter", 
	version = "3.0", 
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
#define MAX_MONEY			32000
#define MODEL_GASCAN			"models/props_junk/gascan001a.mdl"

ConVar g_BoomerKilled,g_ChargerKilled,g_SmokerKilled,g_HunterKilled,g_JockeyKilled,g_SpitterKilled,
	g_WitchKilled,g_ZombieKilled, g_DecayDecay, g_MaxIncapCount, g_SurvivorRequired,
	g_hHealTeammate, g_hDefiSave, g_hHelpTeammate, g_hTankHurt,  g_hIncapSurvivor, g_hKillSurvivor,
	g_hCookiesCachedEnable, g_hTKSurvivorEnable, g_hGascanMapOff, g_hColaMapOff, g_hMaxJumpLimit,
	g_hInfiniteAmmoTime, g_hStageComplete, g_hFinalMissionComplete, g_hWipeOutSurvivor;
int g_iBoomerKilled, g_iChargerKilled, g_iSmokerKilled, g_iHunterKilled, g_iJockeyKilled, g_iSpitterKilled,
	g_iWitchKilled, g_iZombieKilled, g_iMaxIncapCount, g_iSurvivorRequired, g_iHealTeammate,
	g_iDefiSave, g_iHelpTeammate, g_iTankHurt, g_iIncapSurvivor, g_iKillSurvivor, g_iMaxJumpLimit,
	g_iStageComplete, g_iFinalMissionComplete, g_iWipeOutSurvivor;
float g_fInfiniteAmmoTime;

int ammoOffset;	
int g_iCredits[MAXPLAYERS + 1];
Menu g_hMainMenu = null;
Handle g_hMoneyCookie;
int g_iMenuWeaponPosition[MAXPLAYERS+1] = 0;
int g_iMenuMeleePosition[MAXPLAYERS+1] = 0;
int g_iMenuMedicThrowablePosition[MAXPLAYERS+1] = 0;
int g_iMenuOtherPosition[MAXPLAYERS+1] = 0;
int g_iMenuSpecialPosition[MAXPLAYERS+1] = 0;
int g_iOffset_Incapacitated;        // Used to check if tank is dying
bool g_bEnable, g_bCookiesCachedEnable, g_bTKSurvivorEnable;
int DamageCache[MAXPLAYERS+1]; //Used to temporarily store dmg
Handle DmgTimer[MAXPLAYERS+1];
int g_iCanJump[MAXPLAYERS+1]; //how many times player can jump on air
int g_iLastButtons[MAXPLAYERS+1];
int g_iJumps[MAXPLAYERS+1];
bool InfiniteAmmo[MAXPLAYERS+1]; //player can Infinite Ammo
bool bFinaleEscapeStarted = false;

enum EMenuType
{
	eNoneMenu,
	eWeaponMenu,
	eMeleeMenu,
	eMedicThrowableMenu,
	eotherMenu,
	especialMenu
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
	{"grenade_launcher","Grenade Launcher",	"1000"},
	{"rifle_m60", 		"M60 Machine Gun", 	"1000"}
};

static char meleeMenu[][][] = 
{
	{"chainsaw",		"Chainsaw", 		"350"},
	{"baseball_bat",	"Baseball Bat", 	"300"},
	{"cricket_bat", 	"Cricket Bat", 		"300"},
	{"crowbar", 		"Crowbar", 			"300"},
	{"electric_guitar", "Electric Guitar", 	"300"},
	{"fireaxe", 		"Fire Axe", 		"300"},
	{"frying_pan", 		"Frying Pan", 		"300"},
	{"katana", 			"Katana", 			"300"},
	{"machete", 		"Machete", 			"300"},
	{"tonfa", 			"Tonfa", 			"300"},
	{"golfclub", 		"Golf Club", 		"300"},
	{"knife", 			"Knife", 			"300"},
	{"pitchfork", 		"Pitchfork", 		"300"},
	{"shovel", 			"Shovel", 			"300"}
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
	{"gnome",							"Gnome", 				"1500"},
	{"cola_bottles",  					"Cola Bottles",			"1500"}
};

static char specialMenu[][][] =
{
	{"Fire", 			"Fire Yourself", 				"1000"},
	{"Teleport", 		"Teleport to teammate", 		"1500"},
	{"Kill Commons", 	"Kill Commons", 				"2000"},
	{"Infinite Ammo",	"Infinite Ammo", 				"2500"},
	{"Heal Survivors",	"Heal Survivors", 				"3000"},
	{"Jump+1", 			"Jump+1", 						"3500"},
	{"Fire Infeceted", 	"All Infected Gets On Fire", 	"4000"},
	{"Kill Witches", 	"Kill Witches", 				"4500"},
	{"Slay Infected", 	"Slay Infected Attacker", 		"5000"},
};

//WeaponName/AmmoOffset/AmmoGive
static char weapon_ammo[][][] =
{
	{"weapon_smg",		 				"5", 	"300"},
	{"weapon_pumpshotgun",				"7", 	"40"},
	{"weapon_rifle",					"3", 	"250"},
	{"weapon_autoshotgun",				"8", 	"60"},
	{"weapon_hunting_rifle",			"9", 	"100"},
	{"weapon_smg_silenced",				"5", 	"300"},
	{"weapon_smg_mp5", 	 				"5", 	"300"},
	{"weapon_shotgun_chrome",	 		"7", 	"40"},
	{"weapon_rifle_ak47",  				"3",	"250"},
	{"weapon_rifle_desert",				"3", 	"250"},
	{"weapon_sniper_military",			"10", 	"120"},
	{"weapon_grenade_launcher", 	 	"17", 	"15"},
	{"weapon_rifle_sg552",	 			"3", 	"250"},
	{"weapon_rifle_m60",  				"6",	"150"},
	{"weapon_sniper_awp", 	 			"10", 	"100"},
	{"weapon_sniper_scout",	 			"10", 	"100"},
	{"weapon_shotgun_spas",  			"8",	"60"}
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
	LoadTranslations("L4D2_Survivor_Store.phrases");

	g_iOffset_Incapacitated = FindSendPropInfo("Tank", "m_isIncapacitated");
	
	g_hMoneyCookie = RegClientCookie("l4d2_survivor_store_money", "Money for [L4D2]Survivor_Store.smx", CookieAccess_Protected);
	ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");

	g_hMainMenu = new Menu(ShopMenuHandler, MenuAction_DisplayItem);
	g_hMainMenu.AddItem("instruction", "Instruction: Get points by killing common、infected or help teammate.");
	g_hMainMenu.AddItem("weaponsMenu", "Gun Weapons");
	g_hMainMenu.AddItem("meleeMenu", "Melee Weapons");
	g_hMainMenu.AddItem("medicThrowableMenu", "Medic and Throwables");
	g_hMainMenu.AddItem("othersMenu", "Others");
	g_hMainMenu.AddItem("specialMenu", "Speials");
	g_hMainMenu.ExitButton = true;



	RegConsoleCmd("sm_shop", BuyShopCommand);
	RegConsoleCmd("sm_buy", BuyShopCommand);
	RegConsoleCmd("sm_b", BuyShopCommand);
	RegConsoleCmd("sm_points", BuyShopCommand);
	RegConsoleCmd("sm_point", BuyShopCommand);
	RegConsoleCmd("sm_skill", BuyShopCommand);
	RegConsoleCmd("sm_skills", BuyShopCommand);
	RegConsoleCmd("sm_money", BuyShopCommand);
	RegConsoleCmd("sm_purchase", BuyShopCommand);
	RegConsoleCmd("sm_pay", PayCommand);
	RegConsoleCmd("sm_donate", PayCommand);
	
	RegAdminCmd("sm_inspectbank", CheckBankCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_checkbank", CheckBankCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_lookbank", CheckBankCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_givemoney", GiveMoneyCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_clearmoney", ClearMoneyCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_deductmoney", ClearMoneyCommand, ADMFLAG_BAN);

	HookEvent("witch_killed", witch_killed);
	HookEvent("infected_death", infected_death);
	HookEvent("player_death", player_death);
	HookEvent("player_team", evtPlayerTeam);
	HookEvent("heal_success", evtHealSuccess);
	HookEvent("defibrillator_used", evtDefibrillatorSave);
	HookEvent("revive_success", evtReviveSuccess);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_escape_start", Finale_Escape_Start);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("map_transition", Event_MapTransition); //戰役過關到下一關的時候
	HookEvent("finale_vehicle_leaving", Event_FinalVehicleLeaving); //救援載具離開之時  (沒有觸發round_end)
	HookEvent("mission_lost", Event_MissionLost); //戰役滅團重來該關卡的時候 (之後有觸發round_end)

	//*****************//
	//  S E T T I N G S //
	//****************//
	g_SurvivorRequired = CreateConVar("sm_shop_survivor_player_require", "4", "Numbers of real survivor player require to active this plugin.", FCVAR_NOTIFY, true, 1.0);
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
	g_hInfiniteAmmoTime  =	CreateConVar("sm_shop_special_infinite_ammo_time",	"15.0",	"How long could infinite ammo stay for special item.", FCVAR_NOTIFY, true, 1.0);
	g_hStageComplete =	CreateConVar("sm_shop_stage_complete", "400",	"Giving money to each alive survivor for mission accomplished award (non-final).", FCVAR_NOTIFY, true, 1.0);
	g_hFinalMissionComplete =	CreateConVar("sm_shop_final_mission_complete", "3000",	"Giving money to each alive survivor for mission accomplished award (final).", FCVAR_NOTIFY, true, 1.0);
	g_hWipeOutSurvivor =	CreateConVar("sm_shop_final_mission_lost", "300",	"Giving money to each infected player for wiping out survivors.", FCVAR_NOTIFY, true, 1.0);

	g_MaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	g_DecayDecay = FindConVar("pain_pills_decay_rate");

	GetCvars();
	g_SurvivorRequired.AddChangeHook(ConVarChanged_Allow);
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

	//Autoconfig for plugin
	AutoExecConfig(true, "L4D2_Survivor_Store");

	if (bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}
}

public void OnPluginEnd()
{
	if(g_bCookiesCachedEnable) SaveAllMoney();
	delete g_hMainMenu;
	g_bEnable = false;

	for( int i = 1; i <= MaxClients; i++ ) {
		g_iCredits[i] = 0;
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
}

public void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
	CheckSurvivors();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iSurvivorRequired = g_SurvivorRequired.IntValue;
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
	g_fInfiniteAmmoTime = g_hInfiniteAmmoTime.FloatValue;
	g_iStageComplete = g_hStageComplete.IntValue;
	g_iFinalMissionComplete = g_hFinalMissionComplete.IntValue;
	g_iWipeOutSurvivor = g_hWipeOutSurvivor.IntValue;
}

public Action BuyShopCommand(int client, int args)
{
	if(g_bEnable == false) {
		ReplyToCommand(client, "[TS] %T", "Not enough players", client, g_iSurvivorRequired);
		return Plugin_Handled;
	}

	if (client == 0)
	{
		PrintToServer("[TS] this command cannot be used by server.");
		return Plugin_Handled;
	}

	if(GetClientTeam(client) != L4D_TEAM_SURVIVORS)
	{
		ReplyToCommand(client, "[TS] %T", "Only for survivors", client);
		CPrintToChat(client, "%T", "Left Money", client, g_iCredits[client]);
		return Plugin_Handled;
	}

	if(IsPlayerAlive(client) == false)
	{
		ReplyToCommand(client, "[TS] %T", "Death can't buy", client);
		CPrintToChat(client, "%T", "Left Money", client, g_iCredits[client]);
		return Plugin_Handled;
	}
	g_hMainMenu.SetTitle("%T", "Shop Menu Title", client, g_iCredits[client]);
	g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action PayCommand(int client, int args)
{
	if(g_bEnable == false) {
		ReplyToCommand(client, "[TS] %T", "Not enough players", client, g_iSurvivorRequired);
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
		ReplyToCommand(client, "[TS] %T", "Not enough players", client, g_iSurvivorRequired);
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
		ReplyToCommand(client, "[TS] %T", "Not enough players", client, g_iSurvivorRequired);
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

	char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true /*nobots*/, false /*immunity*/);
	if(target == -1) return Plugin_Handled;	

	GetCmdArg(2, arg2, sizeof(arg2));
	int money = StringToInt(arg2);
	if(money==0)
	{
		ReplyToCommand(client, "[TS] %T", "Zero", client);
		return Plugin_Handled;
	}

	char clientname[64], targetname[64];
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

	if(g_bCookiesCachedEnable) SaveMoney(target);

	return Plugin_Handled;	
}

public Action ClearMoneyCommand(int client, int args)
{
	if(g_bEnable == false) {
		ReplyToCommand(client, "[TS] %T", "Not enough players", client, g_iSurvivorRequired);
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

public void OnClientDisconnect(int client)
{
	if(g_bCookiesCachedEnable == true && !IsFakeClient(client))
	{
		char sMoney[11];
		if(g_iCredits[client] > MAX_MONEY) g_iCredits[client] = MAX_MONEY;
		IntToString(g_iCredits[client], sMoney, sizeof(sMoney));
		SetClientCookie(client, g_hMoneyCookie, sMoney);
	}
	g_iCredits[client] = 0;
	DmgTimer[client] = null;

	g_iJumps[client] = 0;
	g_iLastButtons[client] = 0;
	g_iCanJump[client] = 0;
	InfiniteAmmo[client] = false;
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

	if (0 < victim && victim <= MaxClients && 0 < attacker && attacker <= MaxClients && IsClientInGame(attacker) && IsClientInGame(victim))
	{
		if(GetClientTeam(attacker) == L4D_TEAM_SURVIVORS && GetClientTeam(victim) == L4D_TEAM_INFECTED) //人類打特感
		{	
			if(!IsFakeClient(attacker) && GetEntProp(victim, Prop_Send, "m_zombieClass") == ZC_TANK) //特感是坦克
			{
				if(!IsTankDying(victim))
				{
					//PrintToChatAll("attacker: %N - dmg: %d", attacker, damageDone);
					DamageCache[attacker] += damageDone;
					delete DmgTimer[attacker];
					DmgTimer[attacker] = CreateTimer(3.0, Dmg_Timer, attacker);
				}
			}
		}

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
	}
	bFinaleEscapeStarted = false;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_bCookiesCachedEnable) SaveAllMoney();
}

public Action Finale_Escape_Start(Event event, const char[] name, bool dontBroadcast) 
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
	if (g_bEnable == false) return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));

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
}

public Action PlayerChangeTeamCheck(Handle timer,int userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		CheckSurvivors();
	}
}

public void witch_killed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(g_bEnable == false || !client || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != L4D_TEAM_SURVIVORS ) return;
	
	g_iCredits[client] += g_iWitchKilled;
	PrintHintText(client, "[TS] %T", "Kill Witch", client, g_iWitchKilled);
}

public void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
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
		if(IsClientInGame(i) && GetClientTeam(i) == L4D_TEAM_INFECTED)
		{
			CPrintToChat(i, "[{olive}TS{default}] %T", "Wipe Out Survivors", i, g_iWipeOutSurvivor);
			g_iCredits[i] += g_iWipeOutSurvivor;
		}
	}
}

public Action Dmg_Timer(Handle timer, int attacker)
{
	g_iCredits[attacker] += DamageCache[attacker] / g_iTankHurt;
	DamageCache[attacker] = 0;
	DmgTimer[attacker] = null;
}

public Action Timer_NoInfiniteAmmo(Handle timer, int client)
{
	InfiniteAmmo[client] = false;
	if(IsClientInGame(client))
		PrintToChat(client, "%T", "InfiniteAmmo Timer",client);
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
				g_hMainMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hMainMenu.Display(param1, MENU_TIME_FOREVER);
			}
			if (strcmp(item, "weaponsMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eWeaponMenu, weaponsMenu, sizeof(weaponsMenu));
			}
			if (strcmp(item, "meleeMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eMeleeMenu, meleeMenu, sizeof(meleeMenu));
			}
			if (strcmp(item, "medicThrowableMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eMedicThrowableMenu, medicThrowableMenu, sizeof(medicThrowableMenu));
			}
			if (strcmp(item, "othersMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:eotherMenu, otherMenu, sizeof(otherMenu));
			}
			if (strcmp(item, "specialMenu") == 0)
			{
				DisplayShopMenu(param1, EMenuType:especialMenu, specialMenu, sizeof(specialMenu));
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
				g_hMainMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hMainMenu.Display(param1, MENU_TIME_FOREVER);
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
				DisplayShopMenu(param1, EMenuType:eWeaponMenu, weaponsMenu, sizeof(weaponsMenu));
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
				g_hMainMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hMainMenu.Display(param1, MENU_TIME_FOREVER);
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
				DisplayShopMenu(param1, EMenuType:eMeleeMenu, meleeMenu, sizeof(meleeMenu));
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
				g_hMainMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hMainMenu.Display(param1, MENU_TIME_FOREVER);
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
				DisplayShopMenu(param1, EMenuType:eMedicThrowableMenu, medicThrowableMenu, sizeof(medicThrowableMenu));
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
				g_hMainMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hMainMenu.Display(param1, MENU_TIME_FOREVER);
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
				DisplayShopMenu(param1, EMenuType:eotherMenu, otherMenu, sizeof(otherMenu));
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
				g_hMainMenu.SetTitle("%T", "Shop Menu Title", param1, g_iCredits[param1]);
				g_hMainMenu.Display(param1, MENU_TIME_FOREVER);
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
							CreateTimer(g_fInfiniteAmmoTime, Timer_NoInfiniteAmmo, param1, TIMER_FLAG_NO_MAPCHANGE);
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
						}
						else
						{
							PrintToChat(param1, "%T", "You are not being attacked", param1);
						}
					}			
				}
				g_iMenuSpecialPosition[param1] = specialmenu.Selection; 
				DisplayShopMenu(param1, EMenuType:especialMenu, specialMenu, sizeof(specialMenu));
			}
		}
		case MenuAction_End:
			delete specialmenu;
	}
}

void DisplayShopMenu(int client, EMenuType eMenutype, const char [][][] array, const int size)
{
	Menu menu = null;
	int index;
	char sItemName[32],sDisplayName[64];
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
		case (EMenutype:eotherMenu):
		{
			menu = new Menu(Other_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Other Menu Title", client, g_iCredits[client]);
		}
		case (EMenuType:especialMenu):
		{
			menu = new Menu(Special_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Special Menu Title", client, g_iCredits[client]);
		}
	}

	if ( menu == null ) return;

	menu.ExitBackButton = true;
	menu.ExitButton = true;

	for( index = 0 ; index < size ; ++index )
	{
		IntToString(index, sItemName, sizeof(sItemName));
		FormatEx(sDisplayName, sizeof(sDisplayName), "%T - %s%T", array[index][1], client, array[index][2], "Unit", client);
		menu.AddItem(sItemName, sDisplayName);
	}

	switch(eMenutype)
	{
		case (EMenutype:eWeaponMenu):
		{
			menu.DisplayAt(client, g_iMenuWeaponPosition[client], MENU_TIME_FOREVER);
		}
		case (EMenutype:eMeleeMenu):
		{
			menu.DisplayAt(client, g_iMenuMeleePosition[client], MENU_TIME_FOREVER);
		}
		case (EMenutype:eMedicThrowableMenu):
		{
			menu.DisplayAt(client, g_iMenuMedicThrowablePosition[client], MENU_TIME_FOREVER);
		}
		case (EMenutype:eotherMenu):
		{
			menu.DisplayAt(client, g_iMenuOtherPosition[client], MENU_TIME_FOREVER);
		}
		case (EMenutype:especialMenu):
		{
			menu.DisplayAt(client, g_iMenuSpecialPosition[client], MENU_TIME_FOREVER);
		}
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
}

stock void GiveFunction(int client, char[] name, char[] displayName)
{
	int flagsgive = GetCommandFlags("give");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", name);
	SetCommandFlags("give", flagsgive);

	PrintToTeam(client, L4D_TEAM_SURVIVORS, displayName);
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
}

stock void FireAllInfected(int client, char[] displayName)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == L4D_TEAM_INFECTED)
			SDKHooks_TakeDamage(i, client, client, 1.0, DMG_BURN);
	}

	PrintToTeam(client, 0, displayName, true);
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

void CheckSurvivors()
{
	int count = 0;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == L4D_TEAM_SURVIVORS)
			count++;
	}

	if(count >= g_iSurvivorRequired) g_bEnable = true;
	else g_bEnable = false;
}

void PlaySound(int client,char[] sSoundName)
{
	EmitSoundToAll(sSoundName, client, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
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

bool IsTankDying(int tankclient)
{
	return view_as<bool>(GetEntData(tankclient, g_iOffset_Incapacitated));
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

	return true;
}

stock int L4D2_GetInfectedAttacker(int client)
{
	int attacker;

	/* Charger */
	attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if (attacker > 0)
	{
		return attacker;
	}

	attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	if (attacker > 0)
	{
		return attacker;
	}
	/* Jockey */
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if (attacker > 0)
	{
		return attacker;
	}
	

	/* Hunter */
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if (attacker > 0)
	{
		return attacker;
	}

	/* Smoker */
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (attacker > 0)
	{
		return attacker;
	}

	return -1;
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
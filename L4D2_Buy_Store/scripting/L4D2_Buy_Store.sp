//Harry @ 2019-2022

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
	author = "(Survivor) Killing zombies and infected to earn credits + (Infected) Doing Damage to survivors to earn credits", 
	description ="Human and Zombie Shop by HarryPoter", 
	version = "4.6", 
	url = "http://steamcommunity.com/profiles/76561198026784913"
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
#define MODEL_GASCAN			"models/props_junk/gascan001a.mdl"

#define CBaseAbility "CBaseAbility"
#define m_nextActivationTimer "m_nextActivationTimer"

ConVar g_BoomerKilled,g_ChargerKilled,g_SmokerKilled,g_HunterKilled,g_JockeyKilled,g_SpitterKilled,
	g_WitchKilled,g_ZombieKilled, g_DecayDecay, g_MaxIncapCount, g_PlayerRequired,
	g_hHealTeammate, g_hDefiSave, g_hHelpTeammate, g_hTankHurt,  g_hIncapSurvivor, g_hKillSurvivor,
	g_hCookiesCachedEnable, g_hTKSurvivorEnable, g_hGascanMapOff, g_hColaMapOff,
	g_hStageComplete, g_hFinalMissionComplete, g_hWipeOutSurvivor,
	g_hInfectedShopEnable, g_hInfectedShopTime, g_hInfectedShopColdDown, g_hSurvivorShopColdDown, g_hInfectedShopTankLimit, 
	g_hMaxMoney,
	g_hNotifyKillInfectedType;
int g_iBoomerKilled, g_iChargerKilled, g_iSmokerKilled, g_iHunterKilled, g_iJockeyKilled, g_iSpitterKilled,
	g_iWitchKilled, g_iZombieKilled, g_iMaxIncapCount, g_iPlayerRequired, g_iHealTeammate,
	g_iDefiSave, g_iHelpTeammate, g_iTankHurt, g_iIncapSurvivor, g_iKillSurvivor,
	g_iStageComplete, g_iFinalMissionComplete, g_iWipeOutSurvivor, 
	g_iInfectedShopTime, g_iInfectedShopTankLimit,
	g_iMaxMoney, g_iNotifyKillInfectedType;
bool g_bEnable, g_bTKSurvivorEnable, g_bInfectedShopEnable, g_bCookiesCachedEnable;
float g_fInfectedShopColdDown, g_fSurvivorShopColdDown;

int ammoOffset;	
int g_iCredits[MAXPLAYERS + 1];
Menu g_hSurvivorMenu = null, g_hInfectedMenu = null, g_hSpectatorMenu = null;
Handle g_hMoneyCookie;
int g_iMenuWeaponPosition[MAXPLAYERS+1] = {0};
int g_iMenuMeleePosition[MAXPLAYERS+1] = {0};
int g_iMenuMedicThrowablePosition[MAXPLAYERS+1] = {0};
int g_iMenuOtherPosition[MAXPLAYERS+1] = {0};
int g_iDamage[MAXPLAYERS+1][MAXPLAYERS+1]; //Used to temporarily store dmg to tank
bool g_bDied[MAXPLAYERS+1]; //tank already dead
int g_iLastHP[MAXPLAYERS+1]; //tank last hp before dead
int g_iTransferSelectPlayer[MAXPLAYERS+1]; //玩家選擇轉移金錢的對象
float g_fInfectedBuyTime[MAXPLAYERS+1]; //特感玩家購買冷卻時間
float g_fSurvivorBuyTime[MAXPLAYERS+1]; //人類玩家購買冷卻時間
int g_iRoundStart, g_iPlayerSpawn;
bool bLimitInfectedBuy;

Handle PlayerLeftStartTimer, CountDownTimer;
StringMap g_smWeaponShortCut;
StringMap g_smMeleeShortCut;
StringMap g_smMedicThrowableShortCut;
StringMap g_smOtherShortCut;
StringMap g_smInfectedSpawnShortCut;

enum EMenuType
{
	eNoneMenu,
	eWeaponMenu,
	eMeleeMenu,
	eMedicThrowableMenu,
	eOtherMenu,
	eTransferPlayerMenu,
	eTransferPointMenu,
	eInfectedSpawnMenu,
}

EMenuType g_iLastBuyMenu[MAXPLAYERS+1]; //最後一次購買的介面
int g_iLastBuyIndex[MAXPLAYERS+1]; //最後一次購買的選項
char g_sLastBuyName[MAXPLAYERS+1][128]; //最後一次購買的商品名

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
#define FREEZE_Sound "physics/glass/glass_impact_bullet4.wav"

static char weaponsMenu[][][] = 
{
	{"pistol",			"Pistol", 			"50"},
	{"pistol_magnum",	"Magnum", 			"100"},
	{"pumpshotgun",		"Pumpshotgun", 		"180"},
	{"shotgun_chrome",	"Chrome Shotgun", 	"200"},
	{"smg",				"Smg", 				"180"},
	{"smg_silenced", 	"Silenced Smg", 	"200"},
	{"smg_mp5",			"MP5", 				"250"},
	{"rifle", 			"Rifle", 			"280"},
	{"rifle_ak47", 		"AK47", 			"300"},
	{"rifle_desert",	"Desert Rifle", 	"320"},
	{"rifle_sg552", 	"SG552", 			"350"},
	{"shotgun_spas",	"Spas Shotgun", 	"330"},
	{"autoshotgun", 	"Autoshotgun", 		"330"},
	{"hunting_rifle", 	"Hunting Rifle", 	"300"},
	{"sniper_military", "Military Sniper", 	"350"},
	{"sniper_scout", 	"SCOUT", 			"400"},
	{"sniper_awp", 		"AWP",				"500"},
	{"rifle_m60", 		"M60 Machine Gun", 	"1000"},
	{"grenade_launcher","Grenade Launcher",	"1250"}
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
	{"adrenaline",	 	"Adrenaline", 		"125"},
	{"pipe_bomb", 		"Pipe Bomb", 		"150"},
	{"molotov", 		"Molotov", 			"200"},
	{"vomitjar", 		"Vomitjar", 		"225"}
};

static char otherMenu[][][] =
{
	{"ammo",		 					"Ammo", 	 			"250"},
	{"laser_sight",						"Laser Sight", 			"50"},
	{"incendiary_ammo",					"Incendiary Ammo", 		"75"},
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
	{"weapon_grenade_launcher", 	 	"17", 	"20"},
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
	g_hSurvivorMenu.AddItem("instruction", "Instruction: Get credits by killing common、infected or help teammate.");
	g_hSurvivorMenu.AddItem("weaponsMenu", "Gun Weapons");
	g_hSurvivorMenu.AddItem("meleeMenu", "Melee Weapons");
	g_hSurvivorMenu.AddItem("medicThrowableMenu", "Medic and Throwables");
	g_hSurvivorMenu.AddItem("othersMenu", "Others");
	g_hSurvivorMenu.AddItem("transfer", "Credits Transfer");
	g_hSurvivorMenu.ExitButton = true;

	g_hInfectedMenu = new Menu(InfectedShopMenuHandler, MenuAction_DisplayItem);
	g_hInfectedMenu.AddItem("InfectedInstruction", "Instruction: Get credits by doing damage to survivors.");
	g_hInfectedMenu.AddItem("InfectedSpawnMenu", "Infected Spawn");
	g_hInfectedMenu.AddItem("transfer", "Credits Transfer");
	g_hInfectedMenu.ExitButton = true;

	g_hSpectatorMenu = new Menu(SpectatorShopMenuHandler, MenuAction_DisplayItem);
	g_hSpectatorMenu.AddItem("transfer", "Credits Transfer");
	g_hSpectatorMenu.ExitButton = true;

	RegConsoleCmd("sm_shop", BuyShopCommand);
	RegConsoleCmd("sm_buy", BuyShopCommand);
	RegConsoleCmd("sm_b", BuyShopCommand);
	RegConsoleCmd("sm_money", BuyShopCommand);
	RegConsoleCmd("sm_purchase", BuyShopCommand);
	RegConsoleCmd("sm_market", BuyShopCommand);
	RegConsoleCmd("sm_item", BuyShopCommand);
	RegConsoleCmd("sm_items", BuyShopCommand);
	RegConsoleCmd("sm_credit", BuyShopCommand);
	RegConsoleCmd("sm_credits", BuyShopCommand);

	RegConsoleCmd("sm_repeatbuy", HandleCmdRepeatBuy);
	RegConsoleCmd("sm_lastbuy", HandleCmdRepeatBuy);

	RegConsoleCmd("sm_pay", PayCommand);
	RegConsoleCmd("sm_donate", PayCommand);
	
	RegConsoleCmd("sm_inspectbank", CheckBankCommand);
	RegConsoleCmd("sm_checkbank", CheckBankCommand);
	RegConsoleCmd("sm_lookbank", CheckBankCommand);
	RegConsoleCmd("sm_allbank", CheckBankCommand);
	
	RegAdminCmd("sm_givemoney", GiveMoneyCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_givecredit", GiveMoneyCommand, ADMFLAG_BAN);
	
	RegAdminCmd("sm_clearmoney", ClearMoneyCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_clearcredit", ClearMoneyCommand, ADMFLAG_BAN);

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
	HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy); //trigger twice in versus mode, one when all survivors wipe out or make it to saferom, one when first round ends (second round_start begins).
	HookEvent("map_transition", 		Event_RoundEnd,		EventHookMode_PostNoCopy); //all survivors make it to saferoom, and server is about to change next level in coop mode (does not trigger round_end) 
	HookEvent("mission_lost", 			Event_RoundEnd,		EventHookMode_PostNoCopy); //all survivors wipe out in coop mode (also triggers round_end)
	HookEvent("finale_vehicle_leaving", Event_RoundEnd,		EventHookMode_PostNoCopy); //final map final rescue vehicle leaving  (does not trigger round_end)
	HookEvent("map_transition", Event_MapTransition); //戰役過關到下一關的時候
	HookEvent("finale_vehicle_leaving", Event_FinalVehicleLeaving); //救援載具離開之時  (沒有觸發round_end)
	HookEvent("mission_lost", Event_MissionLost); //戰役滅團重來該關卡的時候 (之後有觸發round_end)

	//*****************//
	//  ConVar //
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
	g_hTKSurvivorEnable = CreateConVar("sm_shop_survivor_TK_enable", "1", "If 1, decrease money if survivor friendly fire each other. (1 hp = 1 dollar)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hGascanMapOff = CreateConVar("sm_shop_gascan_map_off",	"c1m4_atrium,c6m3_port,c14m2_lighthouse",	"Can not buy gas can in these maps, separate by commas (no spaces). (0=All maps, Empty = none).", FCVAR_NOTIFY );
	g_hColaMapOff =	CreateConVar("sm_shop_cola_map_off",	"c1m2_streets",	"Can not buy cola in these maps, separate by commas (no spaces). (0=All maps, Empty = none).", FCVAR_NOTIFY );
	g_hStageComplete =	CreateConVar("sm_shop_stage_complete", "400",	"Giving money to each alive survivor for mission accomplished award (non-final).", FCVAR_NOTIFY, true, 1.0);
	g_hFinalMissionComplete =	CreateConVar("sm_shop_final_mission_complete", "3000",	"Giving money to each alive survivor for mission accomplished award (final).", FCVAR_NOTIFY, true, 1.0);
	g_hWipeOutSurvivor =	CreateConVar("sm_shop_final_mission_lost", "300",	"Giving money to each infected player for wiping out survivors.", FCVAR_NOTIFY, true, 1.0);
	g_hInfectedShopEnable =	CreateConVar("sm_shop_infected_enable", "1",	"If 1, Enable shop for infected.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hInfectedShopTime = CreateConVar("sm_shop_infected_wait_time", "10", "Infected player must wait until survivors have left start safe area for at least X seconds to buy item. (0=Infected Shop available anytime)", FCVAR_NOTIFY, true, 0.0);
	g_hInfectedShopColdDown =	CreateConVar("sm_shop_infected_cooltime_block", "30.0",	"Cold Down Time in seconds an infected player can not buy again after player buys item. (0=off).", FCVAR_NOTIFY, true, 0.0);
	g_hSurvivorShopColdDown =	CreateConVar("sm_shop_survivor_cooltime_block", "5.0",	"Cold Down Time in seconds a survivor player can not buy again after player buys item. (0=off).", FCVAR_NOTIFY, true, 0.0);
	g_hInfectedShopTankLimit =	CreateConVar("sm_shop_infected_tank_limit",	"1",	"Tank limit on the field before infected can buy a tank. (0=Can't buy Tank)", FCVAR_NOTIFY, true, 0.0);
	g_hMaxMoney =	CreateConVar("sm_shop_max_moeny_limit",	"32000",	"Maximum money limit. (Money saved when map change/leaving server)", FCVAR_NOTIFY, true, 1.0);
	g_hNotifyKillInfectedType = CreateConVar("sm_shop_kill_infected_announce_type",	"1", "Changes how 'You got credits by killing infected' Message displays. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)", FCVAR_NOTIFY, true, 0.0, true, 3.0);

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
	g_hStageComplete.AddChangeHook(ConVarChanged_Cvars);
	g_hFinalMissionComplete.AddChangeHook(ConVarChanged_Cvars);
	g_hWipeOutSurvivor.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedShopEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedShopTime.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedShopColdDown.AddChangeHook(ConVarChanged_Cvars);
	g_hSurvivorShopColdDown.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedShopTankLimit.AddChangeHook(ConVarChanged_Cvars);
	g_hMaxMoney.AddChangeHook(ConVarChanged_Cvars);
	g_hNotifyKillInfectedType.AddChangeHook(ConVarChanged_Cvars);

	CreateShortCutStringMap();

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

		CreateTimer(0.5, PluginStart);
	}
}

public void OnPluginEnd()
{
	ClearDefault();
	ResetTimer();

	SaveAllMoney();
	delete g_hSurvivorMenu;
	delete g_hInfectedMenu;
	delete g_hSpectatorMenu;
	delete g_hMoneyCookie;
	g_bEnable = false;

	for( int i = 1; i <= MaxClients; i++ ) {
		g_iCredits[i] = 0;
	}

	delete g_smWeaponShortCut;
	delete g_smMeleeShortCut;
	delete g_smMedicThrowableShortCut;
	delete g_smOtherShortCut;
	delete g_smInfectedSpawnShortCut;
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
	PrecacheSound(FREEZE_Sound);
}

public void OnMapEnd()
{
	ClearDefault();
	ResetTimer();
}

public void OnConfigsExecuted()
{
	GetCvars();
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
	g_iStageComplete = g_hStageComplete.IntValue;
	g_iFinalMissionComplete = g_hFinalMissionComplete.IntValue;
	g_iWipeOutSurvivor = g_hWipeOutSurvivor.IntValue;
	g_bInfectedShopEnable = g_hInfectedShopEnable.BoolValue;
	g_iInfectedShopTime = g_hInfectedShopTime.IntValue;
	g_fInfectedShopColdDown = g_hInfectedShopColdDown.FloatValue;
	g_fSurvivorShopColdDown = g_hSurvivorShopColdDown.FloatValue;
	g_iInfectedShopTankLimit = g_hInfectedShopTankLimit.IntValue;
	g_iMaxMoney = g_hMaxMoney.IntValue;
	g_iNotifyKillInfectedType = g_hNotifyKillInfectedType.IntValue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	
	if (client <= 0) return Plugin_Continue;

	char sTempArray[2][64];
	ExplodeString(sArgs, " ", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));
	if( strcmp(sTempArray[0], "b", false) == 0 //|| 
		//strcmp(sTempArray[0], "buy", false) == 0 || 
		//strcmp(sTempArray[0], "shop", false) == 0 ||
		//strcmp(sTempArray[0], "item", false) == 0 
		)
	{
		if(g_bEnable == false) {
			ReplyToCommand(client, "[TS] %T", "Not enough players", client, g_iPlayerRequired);
			return Plugin_Continue;
		}
		
		FakeClientCommand(client, "sm_buy %s", sTempArray[1]);
		//PrintToChatAll("sm_buy %s", sTempArray[1]);
		return Plugin_Stop;
	}

	return Plugin_Continue;
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

	if (args < 1)
	{
		GoMainMenu(client);
	}
	else if (args > 1)
	{
		ReplyToCommand(client, "[TS] Usage: sm_buy <item_name>");
		return Plugin_Handled;	
	}
	else //buy shortcut command
	{
		char item_name[64];
		GetCmdArg(1, item_name, sizeof(item_name));
		StringToLowerCase(item_name);
		//PrintToChatAll("buy %s", item_name);

		int index;
		int team = GetClientTeam(client);
		if(team == L4D_TEAM_SPECTATOR)
		{
			ReplyToCommand(client, "[TS] %T", "Spectators can not buy", client);
			CPrintToChat(client, "%T", "Left Money", client, g_iCredits[client]);
			return Plugin_Handled;
		}
		
		if(team == L4D_TEAM_SURVIVORS)
		{
			if( g_smWeaponShortCut.GetValue(item_name, index) )
			{
				BuyItem(client, L4D_TEAM_SURVIVORS, view_as<EMenuType>(eWeaponMenu), index);
			}
			else if( g_smMeleeShortCut.GetValue(item_name, index) )
			{
				BuyItem(client, L4D_TEAM_SURVIVORS, view_as<EMenuType>(eMeleeMenu), index);
			}
			else if( g_smMedicThrowableShortCut.GetValue(item_name, index) )
			{
				BuyItem(client, L4D_TEAM_SURVIVORS, view_as<EMenuType>(eMedicThrowableMenu), index);
			}
			else if( g_smOtherShortCut.GetValue(item_name, index) )
			{
				BuyItem(client, L4D_TEAM_SURVIVORS, view_as<EMenuType>(eOtherMenu), index);
			}
			else
			{
				CPrintToChat(client, "[{olive}TS{default}] %T", "Item name is not available or wrong team", client, item_name);
			}
		}
		else if(team == L4D_TEAM_INFECTED)
		{
			if( g_smInfectedSpawnShortCut.GetValue(item_name, index) )
			{
				BuyItem(client, L4D_TEAM_INFECTED, view_as<EMenuType>(eInfectedSpawnMenu), index);
			}
			else
			{
				CPrintToChat(client, "[{olive}TS{default}] %T", "Item name is not available or wrong team", client, item_name);
			}
		}
	}
	
	return Plugin_Handled;
}

// Repeat buy
public Action HandleCmdRepeatBuy(int client, int args)
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
	
	if(g_iLastBuyMenu[client] == view_as<EMenuType>(eNoneMenu) && g_iLastBuyIndex[client] == 0)
	{
		ReplyToCommand(client, "[TS] %T", "You didn't buy anything yet", client);
		return Plugin_Handled;
	}
	
	if(BuyItem(client, GetClientTeam(client), g_iLastBuyMenu[client], g_iLastBuyIndex[client]) & 4)
	{
		CPrintToChat(client, "[{olive}TS{default}] %T", "Last item you buy is not available", client, g_sLastBuyName[client]);
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
	
	SaveMoney(target);
	SaveMoney(client);

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
		ReplyToCommand(client, "[TS] Usage: !givemoney <player> <+-money>");
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
	SaveMoney(target);

	return Plugin_Handled;
}
//cache
//Called once a client's saved cookies have been loaded from the database.
public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client)) return;

	if(g_bCookiesCachedEnable == true)
	{
		char sMoney[11];
		GetClientCookie(client, g_hMoneyCookie, sMoney, sizeof(sMoney));
		g_iCredits[client] = StringToInt(sMoney);
	}
}

public void OnClientPutInServer(int client)
{
	g_iLastBuyMenu[client] = view_as<EMenuType>(eNoneMenu);
	g_iLastBuyIndex[client] = 0;
}

public void OnClientDisconnect(int client)
{
	CheckPlayers();
	SaveMoney(client);

	g_iCredits[client] = 0;
} 

//event
public void evtHealSuccess(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int subject = GetClientOfUserId(event.GetInt("subject"));
	if (g_bEnable && client != subject && client && IsClientInGame(client) && !IsFakeClient(client))
	{
		g_iCredits[client] += g_iHealTeammate;
		Notify_GetCredit(client, "Heal Teammate", g_iHealTeammate);
	}
}

public void evtDefibrillatorSave(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_bEnable && client && IsClientInGame(client) && !IsFakeClient(client))
	{
		g_iCredits[client] += g_iDefiSave;
		Notify_GetCredit(client, "Revive Teammate", g_iDefiSave);
	}
}

public void evtReviveSuccess(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_bEnable && client && IsClientInGame(client) && !IsFakeClient(client) && event.GetBool("ledge_hang") == false ) //不是掛邊
	{
		g_iCredits[client] += g_iHelpTeammate;
		Notify_GetCredit(client, "Help Teammate", g_iHelpTeammate);
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
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

public void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(g_bEnable == false || !client || !IsClientInGame(client) || GetClientTeam(client) != L4D_TEAM_SURVIVORS) return;

	int attacker = L4D2_GetInfectedAttacker(client);
	if(attacker > 0 && !IsFakeClient(attacker))
	{
		g_iCredits[attacker] += g_iIncapSurvivor;
		Notify_GetCredit(attacker, "Incap Survivor", g_iIncapSurvivor);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(0.5, PluginStart);
	g_iRoundStart = 1;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	ClearDefault();
	ResetTimer();

	SaveAllMoney();
}

public void evtPlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid");
	CreateTimer(1.0, PlayerChangeTeamCheck, userid);//延遲一秒檢查
}

public Action PlayerChangeTeamCheck(Handle timer,int userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client))
	{
		CheckPlayers();
	}

	return Plugin_Continue;
}

public void witch_killed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(g_bEnable == false || !client || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != L4D_TEAM_SURVIVORS ) return;
	
	Notify_GetCredit(client, "Kill Witch", g_iWitchKilled);
	g_iCredits[client] += g_iWitchKilled;
}

//playerspawn is triggered even when bot or human takes over each other (even they are already dead state) or a survivor is spawned
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{ 
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(0.5, PluginStart);
	g_iPlayerSpawn = 1;	

	int client = GetClientOfUserId(event.GetInt("userid"));
		
	if(client && IsClientInGame(client) && GetClientTeam(client) == L4D_TEAM_INFECTED)
	{
		if (GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK)
		{
			g_bDied[client] = false;
			g_iLastHP[client] = GetEntProp(client, Prop_Data, "m_iHealth");
			for( int i = 1; i <= MaxClients; i++ )
			{
				g_iDamage[i][client] = 0;
			}
		}
	}
}

public void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));

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
					Notify_GetCredit(attacker, "Kill Infected", money);
				}
			}
		}
		if(GetClientTeam(attacker) == L4D_TEAM_INFECTED && GetClientTeam(victim) == L4D_TEAM_SURVIVORS) //特感殺死人類
		{
			if(!IsFakeClient(attacker))
			{
				g_iCredits[attacker] += g_iKillSurvivor;
				Notify_GetCredit(attacker, "Kill Survivor", g_iKillSurvivor);
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
	if(IsClientInGame(client))
	{
		CPrintToChat(client, "%T", "InfiniteAmmo Timer",client);
		PlaySoundToClient(client, DEAD_EYES_Sound2);
	}

	return Plugin_Continue;
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
				GoMainMenu(param1);
			}
			if (strcmp(item, "weaponsMenu") == 0)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eWeaponMenu));
			}
			if (strcmp(item, "meleeMenu") == 0)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eMeleeMenu));
			}
			if (strcmp(item, "medicThrowableMenu") == 0)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eMedicThrowableMenu));
			}
			if (strcmp(item, "othersMenu") == 0)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eOtherMenu));
			}
			if (strcmp(item, "transfer") == 0)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eTransferPlayerMenu));
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
			else if (strcmp(info, "transfer") == 0)
			{
				Format(display, sizeof(display), "%T","transferMenu", param1);
				return RedrawMenuItem(display);
			}
		}
	}

	return 0;
}

public int Weapon_Menu_Handle(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				GoMainMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			int index = StringToInt(item);
			g_iMenuWeaponPosition[param1] = menu.Selection; 
			
			if(BuyItem(param1, L4D_TEAM_SURVIVORS, view_as<EMenuType>(eWeaponMenu), index) & 2)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eWeaponMenu));
			}
		}
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

public int Melee_Menu_Handle(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				GoMainMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			int index = StringToInt(item);
			g_iMenuMeleePosition[param1] = menu.Selection; 
			
			if(BuyItem(param1, L4D_TEAM_SURVIVORS, view_as<EMenuType>(eMeleeMenu), index) & 2)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eMeleeMenu));
			}
		}
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

public int Medic_Throwable_Menu_Handle(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				GoMainMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			int index = StringToInt(item);
			g_iMenuMedicThrowablePosition[param1] = menu.Selection; 
			
			if(BuyItem(param1, L4D_TEAM_SURVIVORS, view_as<EMenuType>(eMedicThrowableMenu), index) & 2)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eMedicThrowableMenu));
			}
		}
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

public int Other_Menu_Handle(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				GoMainMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			int index = StringToInt(item);
			g_iMenuOtherPosition[param1] = menu.Selection; 
			
			if(BuyItem(param1, L4D_TEAM_SURVIVORS, view_as<EMenuType>(eOtherMenu), index) & 2)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eOtherMenu));
			}
		}
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

public int SpectatorShopMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			if (strcmp(item, "transfer") == 0)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eTransferPlayerMenu));
			}
		}
		case MenuAction_DisplayItem:
		{
			static char info[64];
			static char display[128];
			menu.GetItem(param2, info, sizeof(info));	
			if (strcmp(info, "transfer") == 0)
			{
				Format(display, sizeof(display), "%T","transferMenu", param1);
				return RedrawMenuItem(display);
			}
		}
	}

	return 0;
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
				GoMainMenu(param1);
			}
			if (strcmp(item, "InfectedSpawnMenu") == 0)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eInfectedSpawnMenu));
			}
			if (strcmp(item, "transfer") == 0)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eTransferPlayerMenu));
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
			else if (strcmp(info, "transfer") == 0)
			{
				Format(display, sizeof(display), "%T","transferMenu", param1);
				return RedrawMenuItem(display);
			}
		}
	}

	return 0;
}

public int Infected_Spawn_Menu_Handle(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
			{
				GoMainMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			int index = StringToInt(item);
			
			if(BuyItem(param1, L4D_TEAM_INFECTED, view_as<EMenuType>(eInfectedSpawnMenu), index) & 2)
			{
				DisplayShopMenu(param1, view_as<EMenuType>(eInfectedSpawnMenu));
			}
		}
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void DisplayShopMenu(int client, EMenuType eMenutype)
{
	Menu menu = null;

	switch(eMenutype)
	{
		case (view_as<EMenuType>(eWeaponMenu)):
		{
			menu = new Menu(Weapon_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Weapon Menu Title", client, g_iCredits[client]);
		}
		case (view_as<EMenuType>(eMeleeMenu)):
		{
			menu = new Menu(Melee_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Melee Menu Title", client, g_iCredits[client]);
		}
		case (view_as<EMenuType>(eMedicThrowableMenu)):
		{
			menu = new Menu(Medic_Throwable_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "MedicThrowable Menu Title", client, g_iCredits[client]);
		}
		case (view_as<EMenuType>(eOtherMenu)):
		{
			menu = new Menu(Other_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Other Menu Title", client, g_iCredits[client]);
		}
		case (view_as<EMenuType>(eTransferPlayerMenu)):
		{
			menu = new Menu(Transfer_Player_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Transfer Player Menu Title", client, g_iCredits[client]);
		}
		case (view_as<EMenuType>(eTransferPointMenu)):
		{
			menu = new Menu(Transfer_Point_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Transfer Credit Menu Title", client, g_iCredits[client]);
		}
		case (view_as<EMenuType>(eInfectedSpawnMenu)):
		{
			menu = new Menu(Infected_Spawn_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("%T", "Infected Spawn Menu Title", client, g_iCredits[client]);
		}
	}

	if ( menu == null ) return;

	menu.ExitBackButton = true;
	menu.ExitButton = true;

	switch(eMenutype)
	{
		case (view_as<EMenuType>(eWeaponMenu)):
		{
			DisplayShopMenuItem(client, menu, weaponsMenu, sizeof(weaponsMenu));
			menu.DisplayAt(client, g_iMenuWeaponPosition[client], MENU_TIME_FOREVER);
		}
		case (view_as<EMenuType>(eMeleeMenu)):
		{
			DisplayShopMenuItem(client, menu, meleeMenu, sizeof(meleeMenu));
			menu.DisplayAt(client, g_iMenuMeleePosition[client], MENU_TIME_FOREVER);
		}
		case (view_as<EMenuType>(eMedicThrowableMenu)):
		{
			DisplayShopMenuItem(client, menu, medicThrowableMenu, sizeof(medicThrowableMenu));
			menu.DisplayAt(client, g_iMenuMedicThrowablePosition[client], MENU_TIME_FOREVER);
		}
		case (view_as<EMenuType>(eOtherMenu)):
		{
			DisplayShopMenuItem(client, menu, otherMenu, sizeof(otherMenu));
			menu.DisplayAt(client, g_iMenuOtherPosition[client], MENU_TIME_FOREVER);
		}
		case (view_as<EMenuType>(eTransferPlayerMenu)):
		{
			ShowMenuTransferPlayerList(client, menu);
			menu.Display(client, MENU_TIME_FOREVER);
		}
		case (view_as<EMenuType>(eTransferPointMenu)):
		{
			ShowMenuTransferPointList(client, menu);
			menu.Display(client, MENU_TIME_FOREVER);
		}
		case (view_as<EMenuType>(eInfectedSpawnMenu)):
		{
			DisplayShopMenuItem(client, menu, infectedSpawnMenu, sizeof(infectedSpawnMenu));
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

public void ShowMenuTransferPlayerList(int client, Menu menu)
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
				GoMainMenu(param1);
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
					DisplayShopMenu(param1, view_as<EMenuType>(eTransferPointMenu));
				}
				else
				{
					CPrintToChat(param1, "[{olive}TS{default}] %T", "The chosen player is not in server now! Choose again!", param1);
					DisplayShopMenu(param1, view_as<EMenuType>(eTransferPlayerMenu));
				}
			}
		}
		case MenuAction_End:
			delete transfermenu;
	}

	return 0;
}

public void ShowMenuTransferPointList(int client, Menu menu)
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
				GoMainMenu(param1);
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
					CPrintToChat(param1, "[{olive}TS{default}] %T", "Transfer credit to player", param1, money, ChoosenClient);
					CPrintToChat(ChoosenClient, "[{olive}TS{default}] %T", "Player transfer credit to you", ChoosenClient, param1, money);
				}
				else	
				{
					CPrintToChat(param1, "[{olive}TS{default}] %T", "The chosen player is not in server now! Choose again!", param1);
					DisplayShopMenu(param1, view_as<EMenuType>(eTransferPlayerMenu));
				}
			}
			else
			{
				CPrintToChat(param1, "[{olive}TS{default}] %T", "Failed! Credits balance is not enough to transfer.", param1);
				DisplayShopMenu(param1, view_as<EMenuType>(eTransferPointMenu));
			}
		}
		case MenuAction_End:
			delete transfermenu;
	}	

	return 0;
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
	if(IsFakeClient(client)) return;

	//PrintToChatAll("%N moeny: %s",client,sMoney);

	if(g_bCookiesCachedEnable)
	{
		char sMoney[11];
		if(g_iCredits[client] > g_iMaxMoney) g_iCredits[client] = g_iMaxMoney;
		IntToString(g_iCredits[client], sMoney, sizeof(sMoney));
		SetClientCookie(client, g_hMoneyCookie, sMoney);
	}
}

void GiveFunction(int client, char[] name, char[] displayName)
{
	int flagsgive = GetCommandFlags("give");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", name);
	SetCommandFlags("give", flagsgive);

	PrintToTeam(client, L4D_TEAM_SURVIVORS, displayName);
	
	PlaySound(client, BUY_Sound1);
}

void GiveUpgrade(int client, char[] name, char[] displayName)
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

void GiveClientAmmo(int client, int iSlot0, char[] displayName)
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

void GiveClientHealth(int client, int iHealthAdd, char[] displayName, bool bPrint = true)
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

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth );
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

bool IsHandingFromLedge(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

bool CanSurvivorBuy(int client, char[] ShopItemName = "")
{
	if(!IsClientInGame(client)) return false;


	if(GetClientTeam(client) != L4D_TEAM_SURVIVORS)
	{
		CPrintToChat(client, "%T", "You are not in survivor team", client);
		return false;
	}
	
	if(g_bEnable == false) 
	{
		CPrintToChat(client, "[TS] %T", "Not enough players", client, g_iPlayerRequired);
		return false;
	}
	
	if(IsPlayerAlive(client) == false && strcmp(ShopItemName, "Respawn", false) != 0)
	{
		CPrintToChat(client, "%T", "Death can't buy", client);
		return false;
	}

	if(IsSurvivorPinned(client) && (
		strcmp(ShopItemName, "Slay_Infected", false) != 0 &&
		strcmp(ShopItemName, "Freeze_Infected", false) != 0)
		)
	{
		CPrintToChat(client, "%T", "Can't buy when being attacked", client);
		return false;
	}
	
	if (g_fSurvivorBuyTime[client] > GetEngineTime())
	{
		CPrintToChat(client, "%T", "Survivor Can not buy so quickly", client, g_fSurvivorShopColdDown);
		return false;
	}

	return true;
}

bool CanInfectedBuy(int client)
{
	if (!IsClientInGame(client)) return false;
	
	if (GetClientTeam(client) != L4D_TEAM_INFECTED)
	{
		CPrintToChat(client, "%T", "You are not in Infected Ieam", client);
		return false;
	}

	if(g_bEnable == false) 
	{
		CPrintToChat(client, "[TS] %T", "Not enough players", client, g_iPlayerRequired);
		return false;
	}
	
	if (g_bInfectedShopEnable == false)
	{
		CPrintToChat(client, "[TS] %T", "Infected Shop is disabled", client);
		CPrintToChat(client, "%T", "Left Money", client, g_iCredits[client]);
		return false;
	}

	if ( g_iInfectedShopTime != 0 && bLimitInfectedBuy == true)
	{
		CPrintToChat(client, "[TS] %T", "Please wait until survivors leave the safe room.", client, g_iInfectedShopTime);
		return false;
	}

	if (g_fInfectedBuyTime[client] > GetEngineTime())
	{
		CPrintToChat(client, "%T", "Infected Can not buy so quickly", client, g_fInfectedShopColdDown);
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

bool IsPlayerGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

void PlaySoundToClient(int client, char[] sSoundName)
{
	EmitSoundToClient(client, sSoundName, _, SNDCHAN_AUTO, SNDLEVEL_CONVO, _, SNDVOL_NORMAL, _, _, _, _, _, _ );
}

void PlaySound(int client, char[] sSoundName)
{
	EmitSoundToAll(sSoundName, client, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

void InfectedSpawnFunction(int client, char[] infected_name)
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
	
	
	int anyclient = my_GetRandomClient();
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

int my_GetRandomClient()
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
	if(IsClientInGame(client))
	{
		CPrintToChat(client, "%T", "Immune Everything Timer",client);
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

/***
// 購買
// return: 1為關閉menu, 2為繼續顯示menu, 4代表不能購買
****/
int BuyItem(int client, int team, EMenuType eMenutype, int index)
{
	int itemMoney;
	if(team == L4D_TEAM_SURVIVORS)
	{
		if(!CanSurvivorBuy(client))
			return 6;
		
		switch(eMenutype)
		{
			case (view_as<EMenuType>(eWeaponMenu)):
			{
				itemMoney = StringToInt(weaponsMenu[index][2]);
				if( g_iCredits[client] - itemMoney < 0)
				{
					CPrintToChat(client, "[{olive}TS{default}] %T", "Not enough money", client, g_iCredits[client], itemMoney);
					return 6;
				}
				
				GiveFunction(client, weaponsMenu[index][0], weaponsMenu[index][1]);
				Checkout(client, L4D_TEAM_SURVIVORS, itemMoney, view_as<EMenuType>(eWeaponMenu), index, weaponsMenu[index][1]);
				return 2;
			}
			case (view_as<EMenuType>(eMeleeMenu)):
			{
				itemMoney = StringToInt(meleeMenu[index][2]);
				if( g_iCredits[client] - itemMoney < 0)
				{
					CPrintToChat(client, "[{olive}TS{default}] %T", "Not enough money", client, g_iCredits[client], itemMoney);
					return 6;
				}
				
				GiveFunction(client, meleeMenu[index][0], meleeMenu[index][1]);
				Checkout(client, L4D_TEAM_SURVIVORS, itemMoney, view_as<EMenuType>(eMeleeMenu), index, meleeMenu[index][1]);
				return 2;
			}
			case (view_as<EMenuType>(eMedicThrowableMenu)):
			{
				itemMoney = StringToInt(medicThrowableMenu[index][2]);
				if( g_iCredits[client] - itemMoney < 0)
				{
					CPrintToChat(client, "[{olive}TS{default}] %T", "Not enough money", client, g_iCredits[client], itemMoney);
					return 6;
				}
				
				if(strcmp(medicThrowableMenu[index][0], "health_100", false) == 0)
					GiveClientHealth(client, 100, medicThrowableMenu[index][1]);
				else
					GiveFunction(client, medicThrowableMenu[index][0], medicThrowableMenu[index][1]);
				
				Checkout(client, L4D_TEAM_SURVIVORS, itemMoney, view_as<EMenuType>(eMedicThrowableMenu), index, medicThrowableMenu[index][1]);
				return 2;
			}
			case (view_as<EMenuType>(eOtherMenu)):
			{
				itemMoney = StringToInt(otherMenu[index][2]);
				int iSlot0 = GetPlayerWeaponSlot(client, 0);
				if( g_iCredits[client] - itemMoney < 0)
				{
					CPrintToChat(client, "[{olive}TS{default}] %T", "Not enough money", client, g_iCredits[client], itemMoney);
					return 6;
				}
				
				if(strcmp(otherMenu[index][0], "laser_sight", false) == 0 || strcmp(otherMenu[index][0], "incendiary_ammo", false) == 0 || strcmp(otherMenu[index][0], "explosive_ammo", false) == 0 )
				{
					if(iSlot0 <= 0 )
					{
						CPrintToChat(client, "[{olive}TS{default}] %T", "Must have primary weapon", client);
						return 6;
					}
					
					GiveUpgrade(client, otherMenu[index][0], otherMenu[index][1]);
				}
				else if(strcmp(otherMenu[index][0], "ammo", false) == 0)
				{
					if(iSlot0 <= 0 )
					{
						CPrintToChat(client, "[{olive}TS{default}] %T", "Must have primary weapon", client);
						return 6;
					}
					
					GiveClientAmmo(client, iSlot0, otherMenu[index][1]);
				}
				else if (strcmp(otherMenu[index][0], "gascan", false) == 0)
				{
					if(g_bGascanMap == false)
					{
						CPrintToChat(client, "[{olive}TS{default}] %T", "Can't buy gascan in current map", client);	
						return 6;
					}
						
					GiveFunction(client, otherMenu[index][0], otherMenu[index][1]);
				}
				else if (strcmp(otherMenu[index][0], "cola_bottles", false) == 0)
				{
					if(g_bColaMap == false)
					{
						CPrintToChat(client, "[{olive}TS{default}] %T", "Can't buy cola in current map", client);	
						return 6;
					}
					
					GiveFunction(client, otherMenu[index][0], otherMenu[index][1]);
				}
				else
				{
					GiveFunction(client, otherMenu[index][0], otherMenu[index][1]);
				}
				
				Checkout(client, L4D_TEAM_SURVIVORS, itemMoney, view_as<EMenuType>(eOtherMenu), index, otherMenu[index][1]);
				return 2;
			}
			default:
			{
				return 5;
			}
		}
	}
	else if(team == L4D_TEAM_INFECTED)
	{
		if(!CanInfectedBuy(client))
			return 6;
		
		switch(eMenutype)
		{
			case (view_as<EMenuType>(eInfectedSpawnMenu)):
			{
				itemMoney = StringToInt(infectedSpawnMenu[index][2]);
				if( g_iCredits[client] - itemMoney < 0)
				{
					CPrintToChat(client, "[{olive}TS{default}] %T", "Not enough money", client, g_iCredits[client], itemMoney);
					return 6;
				}
				
				if (strcmp(infectedSpawnMenu[index][0], "Suicide", false) == 0)
				{
					if (!IsPlayerAlive(client) || IsPlayerGhost(client))
					{
						CPrintToChat(client, "%T", "Alive Infected First", client);
						return 6;
					}

					ForcePlayerSuicide(client);
					PrintToTeam(client, L4D_TEAM_INFECTED, infectedSpawnMenu[index][1]);
					PlaySound(client, BUY_Sound1);
				}
				else
				{
					if (IsPlayerAlive(client) && !IsPlayerGhost(client))
					{
						CPrintToChat(client, "%T", "Dead Infected First", client);
						return 6;
					}
					
					if (strcmp(infectedSpawnMenu[index][0], "Tank", false) == 0 && CountTankInServer() >= g_iInfectedShopTankLimit )
					{
						CPrintToChat(client, "%T", "Tank Limit Reached", client);
						return 6;
					}

					InfectedSpawnFunction(client, infectedSpawnMenu[index][0]);
					if (!IsPlayerAlive(client)) //fail to spawn
					{
						CPrintToChat(client, "%T", "Can not Spawn Infected", client);
						return 6;
					}
			
					PrintToTeam(client, L4D_TEAM_INFECTED, infectedSpawnMenu[index][1]);
					PlaySound(client, BUY_Sound1);
				}
				
				Checkout(client, L4D_TEAM_INFECTED, itemMoney, view_as<EMenuType>(eInfectedSpawnMenu), index, infectedSpawnMenu[index][1]);
				return 1;
			}
			default:
			{
				return 5;
			}
		}
	}
	
	return 5;
}

//結帳
void Checkout(int client, int team, int itemMoney, EMenuType eMenutype, int index, const char[] displayName)
{
	g_iCredits[client] -= itemMoney; //扣錢
	//冷卻
	if(team == L4D_TEAM_SURVIVORS) g_fSurvivorBuyTime[client] = GetEngineTime() + g_fSurvivorShopColdDown;
	else if(team == L4D_TEAM_INFECTED) g_fInfectedBuyTime[client] = GetEngineTime() + g_fInfectedShopColdDown;
	//紀錄
	g_iLastBuyMenu[client] = eMenutype;
	g_iLastBuyIndex[client] = index;
	strcopy(g_sLastBuyName[client], sizeof(g_sLastBuyName[]), displayName);
}

void GoMainMenu(int client)
{
	switch(GetClientTeam(client))
	{
		case L4D_TEAM_SPECTATOR:
		{
			g_hSpectatorMenu.SetTitle("%T", "Shop Menu Title", client, g_iCredits[client]);
			g_hSpectatorMenu.Display(client, MENU_TIME_FOREVER);
		}
		case L4D_TEAM_SURVIVORS:
		{
			g_hSurvivorMenu.SetTitle("%T", "Shop Menu Title", client, g_iCredits[client]);
			g_hSurvivorMenu.Display(client, MENU_TIME_FOREVER);
		}
		case L4D_TEAM_INFECTED:
		{
			g_hInfectedMenu.SetTitle("%T", "Infected Menu Title", client, g_iCredits[client]);
			g_hInfectedMenu.Display(client, MENU_TIME_FOREVER);
		}
	}
}

/**
 * Converts the string to lower case.
 *
 * @param input         Input string.
 */
void StringToLowerCase(char[] input)
{
	for (int i = 0; i < strlen(input); i++)
	{
		input[i] = CharToLower(input[i]);
	}
}

public Action PluginStart(Handle timer)
{
	ClearDefault();

	delete PlayerLeftStartTimer; PlayerLeftStartTimer = CreateTimer(1.0, Timer_PlayerLeftStart, _, TIMER_REPEAT);

	return Plugin_Continue;
}

int iCountDownTime;
public Action Timer_PlayerLeftStart(Handle Timer)
{
	if (L4D_HasAnySurvivorLeftSafeArea())
	{
		iCountDownTime = g_iInfectedShopTime;
		if(iCountDownTime > 0)
		{
			delete CountDownTimer; CountDownTimer = CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT);
		}
		
		PlayerLeftStartTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_CountDown(Handle timer)
{
	if(iCountDownTime <= 0) 
	{
		bLimitInfectedBuy = false;
		CountDownTimer = null;
		return Plugin_Stop;
	}
	iCountDownTime--;
	return Plugin_Continue;
}

void ClearDefault()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	bLimitInfectedBuy = true;
}

void ResetTimer()
{
	delete PlayerLeftStartTimer;
	delete CountDownTimer;
}

void CreateShortCutStringMap()
{
	int size;

	g_smWeaponShortCut = CreateTrie();
	size = sizeof(weaponsMenu);
	for( int index = 0 ; index < size ; ++index )
	{
		StringToLowerCase(weaponsMenu[index][0]);
		g_smWeaponShortCut.SetValue(weaponsMenu[index][0], index);
	}

	g_smMeleeShortCut = CreateTrie();
	size = sizeof(meleeMenu);
	for( int index = 0 ; index < size ; ++index )
	{
		StringToLowerCase(meleeMenu[index][0]);
		g_smMeleeShortCut.SetValue(meleeMenu[index][0], index);
	}

	g_smMedicThrowableShortCut = CreateTrie();
	size = sizeof(medicThrowableMenu);
	for( int index = 0 ; index < size ; ++index )
	{
		StringToLowerCase(medicThrowableMenu[index][0]);
		g_smMedicThrowableShortCut.SetValue(medicThrowableMenu[index][0], index);
	}

	g_smOtherShortCut = CreateTrie();
	size = sizeof(otherMenu);
	for( int index = 0 ; index < size ; ++index )
	{
		StringToLowerCase(otherMenu[index][0]);
		g_smOtherShortCut.SetValue(otherMenu[index][0], index);
	}

	g_smInfectedSpawnShortCut = CreateTrie();
	size = sizeof(infectedSpawnMenu);
	for( int index = 0 ; index < size ; ++index )
	{
		StringToLowerCase(infectedSpawnMenu[index][0]);
		g_smInfectedSpawnShortCut.SetValue(infectedSpawnMenu[index][0], index);
	}
}

void Notify_GetCredit(int client, const char[] sWord, int money)
{
	switch(g_iNotifyKillInfectedType)
	{
		case 0: {/*nothing*/}
		case 1: {
			CPrintToChat(client, "[{olive}TS{default}] %T", sWord, client, money);
		}
		case 2: {
			PrintHintText(client, "[TS] %T", sWord, client, money);
		}
		case 3: {
			PrintCenterText(client, "[TS] %T", sWord, client, money);
		}
	}
}
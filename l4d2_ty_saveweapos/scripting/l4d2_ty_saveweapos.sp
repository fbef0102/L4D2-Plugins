/**
 * =============================================================================
 * L4D2 coop save weapon
 * Copyright 2021 steamcommunity.com/profiles/76561198026784913
 * Copyright 2011 - 2021 steamcommunity.com/profiles/76561198025355822/
 * Fixed 2015 steamcommunity.com/id/Electr0n
 * Fixed 2016 steamcommunity.com/id/mixjayrus
 * Fixed 2016 user Merudo
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#pragma newdecls required
#define	MAX_WEAPONS2		29

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

static char survivor_names[8][] = { "Nick", "Rochelle", "Coach", "Ellis", "Bill", "Zoey", "Francis", "Louis"};
static char survivor_models[8][] =
{
	"models/survivors/survivor_gambler.mdl",
	"models/survivors/survivor_producer.mdl",
	"models/survivors/survivor_coach.mdl",
	"models/survivors/survivor_mechanic.mdl",
	"models/survivors/survivor_namvet.mdl",
	"models/survivors/survivor_teenangst.mdl",
	"models/survivors/survivor_biker.mdl",
	"models/survivors/survivor_manager.mdl"
};

ConVar g_hGameMode, g_hFullHealth, g_hGameTimeBlock, 
	g_hSaveBot, g_hSaveHealth, g_hSaveCharacter;

char sg_buffer0[64];
char sg_slot0[MAXPLAYERS+1][64];
char sg_slot1[MAXPLAYERS+1][64];
char sg_slot2[MAXPLAYERS+1][64];
char sg_slot3[MAXPLAYERS+1][64];
char sg_slot4[MAXPLAYERS+1][64];
int ig_prop0[MAXPLAYERS+1]; /* m_iClip1 */
int ig_prop1[MAXPLAYERS+1]; /* m_iClip1 saw */
int ig_prop2[MAXPLAYERS+1]; /* m_upgradeBitVec */
int ig_prop3[MAXPLAYERS+1]; /* m_nUpgradedPrimaryAmmoLoaded */
int ig_prop4[MAXPLAYERS+1]; /* slot 0 m_nSkin */
int ig_prop5[MAXPLAYERS+1]; /* slot 1 m_nSkin */
int ig_Ammo0[MAXPLAYERS+1]; /* slot 0 ammo*/
int ig_AmmoOffset0[MAXPLAYERS+1]; /* slot 0 ammo offset*/
int g_iSpawned[MAXPLAYERS+1];
int g_iRecorded[MAXPLAYERS+1];

enum Enum_Health
{
	iHealth,
	iHealthTemp,
	iHealthTime,
	iReviveCount,
	iGoingToDie,
	iThirdStrike,
	iHealthMAX,
	
}
int 	g_iHealthInfo[MAXPLAYERS+1][view_as<int>(iHealthMAX)]; //health
int 	g_iProp[MAXPLAYERS+1]; //character index
char 	g_sModelInfo[MAXPLAYERS+1][64]; //character model

bool ig_protection, g_bGiveWeaponBlock;
int ammoOffset, g_iCountDownTime;	
Handle PlayerLeftStartTimer = null, CountDownTimer = null;

public Plugin myinfo =
{
	name = "[L4D2] Save Weapon",
	author = "MAKS, HarryPotter",
	description = "L4D2 coop save weapon when map transition if more than 4 players",
	version = "5.3",
	url = "forums.alliedmods.net/showthread.php?p=2304407"
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
	ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");

	g_hFullHealth = 	CreateConVar("l4d2_ty_saveweapon_health", "1", "If 1, restore full health when end of chapter.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hGameTimeBlock = 	CreateConVar("l4d2_ty_saveweapon_game_seconds_block", "100", "Do not restore weapons and health to a player after survivors have left start safe area for at least x seconds. (0=Always restore)", FCVAR_NOTIFY, true, 0.0);
	g_hSaveBot = 		CreateConVar("l4d2_ty_saveweapon_save_bot", "1", "If 1, save weapons and health for bots as well.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hSaveHealth = 	CreateConVar("l4d2_ty_saveweapon_save_health",	"1", "If 1, save health and restore.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hSaveCharacter = 	CreateConVar("l4d2_ty_saveweapon_save_character",	"0", "If 1, save character model and restore.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true,	"l4d2_ty_saveweapon");
	
	g_hGameMode = FindConVar("mp_gamemode");
	g_hGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hFullHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hGameTimeBlock.AddChangeHook(ConVarChanged_Cvars);
	g_hSaveBot.AddChangeHook(ConVarChanged_Cvars);
	g_hSaveHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hSaveCharacter.AddChangeHook(ConVarChanged_Cvars);
	
	HookEvent("round_start",  			Event_RoundStart,	 	EventHookMode_PostNoCopy);
	HookEvent("player_spawn", 			Event_PlayerSpawn, 		EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,			EventHookMode_PostNoCopy);
	HookEvent("map_transition", 		Event_RoundEnd,			EventHookMode_PostNoCopy); //戰役過關到下一關的時候 (沒有觸發round_end)
	HookEvent("mission_lost", 			Event_RoundEnd,			EventHookMode_PostNoCopy); //戰役滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", Event_RoundEnd,			EventHookMode_PostNoCopy); //救援載具離開之時  (沒有觸發round_end)
	HookEvent("map_transition", 		Event_MapTransition, 	EventHookMode_PostNoCopy);
	HookEvent("finale_win", 			Event_FinaleWin);
	
	if (bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			HxCleaning(i);
		}
	}
}

public void OnPluginEnd()
{
	ResetPlugin();
	ResetTimer();
}

bool g_bMapStarted;
public void OnMapStart()
{
	g_bMapStarted = true;

	ig_protection = false;
	if (L4D_IsFirstMapInScenario())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			HxCleaning(i);
		}
	}
	
	for( int i = 0; i < MAX_WEAPONS2; i++ )
	{
		PrecacheModel(g_sWeaponModels2[i], true);
	}
	
	for( int i = 0; i < 8; i++ )
	{
		PrecacheModel(survivor_models[i], true);
	}
	
	PrecacheModel("models/weapons/melee/v_bat.mdl", true);
	PrecacheModel("models/weapons/melee/v_cricket_bat.mdl", true);
	PrecacheModel("models/weapons/melee/v_crowbar.mdl", true);
	PrecacheModel("models/weapons/melee/v_electric_guitar.mdl", true);
	PrecacheModel("models/weapons/melee/v_fireaxe.mdl", true);
	PrecacheModel("models/weapons/melee/v_frying_pan.mdl", true);
	PrecacheModel("models/weapons/melee/v_golfclub.mdl", true);
	PrecacheModel("models/weapons/melee/v_katana.mdl", true);
	PrecacheModel("models/weapons/melee/v_machete.mdl", true);
	PrecacheModel("models/weapons/melee/v_tonfa.mdl", true);
	PrecacheModel("models/weapons/melee/v_pitchfork.mdl", true);
	PrecacheModel("models/weapons/melee/v_shovel.mdl", true);
	PrecacheModel("models/v_models/v_knife_t.mdl", true);
	
	PrecacheModel("models/weapons/melee/w_bat.mdl", true);
	PrecacheModel("models/weapons/melee/w_cricket_bat.mdl", true);
	PrecacheModel("models/weapons/melee/w_crowbar.mdl", true);
	PrecacheModel("models/weapons/melee/w_electric_guitar.mdl", true);
	PrecacheModel("models/weapons/melee/w_fireaxe.mdl", true);
	PrecacheModel("models/weapons/melee/w_frying_pan.mdl", true);
	PrecacheModel("models/weapons/melee/w_golfclub.mdl", true);
	PrecacheModel("models/weapons/melee/w_katana.mdl", true);
	PrecacheModel("models/weapons/melee/w_machete.mdl", true);
	PrecacheModel("models/weapons/melee/w_tonfa.mdl", true);
	PrecacheModel("models/weapons/melee/w_pitchfork.mdl", true);
	PrecacheModel("models/weapons/melee/w_shovel.mdl", true);
	PrecacheModel("models/w_models/weapons/w_knife_t.mdl", true);

	PrecacheGeneric("scripts/melee/baseball_bat.txt", true);
	PrecacheGeneric("scripts/melee/cricket_bat.txt", true);
	PrecacheGeneric("scripts/melee/crowbar.txt", true);
	PrecacheGeneric("scripts/melee/electric_guitar.txt", true);
	PrecacheGeneric("scripts/melee/fireaxe.txt", true);
	PrecacheGeneric("scripts/melee/frying_pan.txt", true);
	PrecacheGeneric("scripts/melee/golfclub.txt", true);
	PrecacheGeneric("scripts/melee/katana.txt", true);
	PrecacheGeneric("scripts/melee/machete.txt", true);
	PrecacheGeneric("scripts/melee/tonfa.txt", true);
	PrecacheGeneric("scripts/melee/pitchfork.txt", true);
	PrecacheGeneric("scripts/melee/shovel.txt", true);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
	ResetTimer();
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

int g_iGameTimeBlock;
bool g_bFullhealth, g_bSaveBot, g_bSaveHealth, g_bSaveCharacter;
void GetCvars()
{
	g_bFullhealth = g_hFullHealth.BoolValue;
	g_iGameTimeBlock = g_hGameTimeBlock.IntValue;
	g_bSaveBot = g_hSaveBot.BoolValue;
	g_bSaveHealth = g_hSaveHealth.BoolValue;
	g_bSaveCharacter = g_hSaveCharacter.BoolValue;
}

void IsAllowed()
{
	GetCvars();
	CheckGameMode();
}

int g_iCurrentMode;
void CheckGameMode()
{
	if( g_hGameMode == null )
		return;

	if( g_bMapStarted == false )
		return;

	g_iCurrentMode = 0;

	int entity = CreateEntityByName("info_gamemode");
	if( IsValidEntity(entity) )
	{
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
			RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
	}
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}

public void OnClientPutInServer(int client)
{
	if (g_iCurrentMode == 1 && IsClientInGame(client))
	{
		if(IsFakeClient(client) && !g_bSaveBot) return;
		
		CreateTimer(2.5, HxTimerConnected, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

public void OnClientDisconnect(int client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		if (ig_protection == false)
		{
			//HxCleaning(client);
			g_iSpawned[client] = 1;
		}
	}
}


void HxCleaning(int client)
{
	ig_prop0[client] = 0;
	ig_prop1[client] = 0;
	ig_prop2[client] = 0;
	ig_prop3[client] = 0;
	ig_prop4[client] = 0;
	ig_prop5[client] = 0;
	ig_Ammo0[client] = 0;
	ig_AmmoOffset0[client] = 0;

	sg_slot0[client][0] = '\0';
	sg_slot1[client][0] = '\0';
	sg_slot2[client][0] = '\0';
	sg_slot3[client][0] = '\0';
	sg_slot4[client][0] = '\0';
	
	g_iHealthInfo[client][iHealth] = 100;
	g_iHealthInfo[client][iHealthTemp] = 0;
	g_iHealthInfo[client][iHealthTime] = 0;
	g_iHealthInfo[client][iReviveCount] = 0;
	g_iHealthInfo[client][iGoingToDie] = 0;
	g_iHealthInfo[client][iThirdStrike] = 0;
	
	g_iProp[client] = 0;
	g_sModelInfo[client][0] = '\0';
	g_iRecorded[client] = 0;
	
}

void HxGetSlot0Ammo (int client, const char[] sWeaponName)
{
	if (strcmp(sWeaponName, "weapon_smg", true) == 0)
	{
		ig_AmmoOffset0[client] = 5;
	}
	else if (strcmp(sWeaponName, "weapon_pumpshotgun", true) == 0)
	{
		ig_AmmoOffset0[client] = 7;
	}
	else if (strcmp(sWeaponName, "weapon_rifle", true) == 0)
	{
		ig_AmmoOffset0[client] = 3;
	}
	else if (strcmp(sWeaponName, "weapon_autoshotgun", true) == 0)
	{
		ig_AmmoOffset0[client] = 8;
	}
	else if (strcmp(sWeaponName, "weapon_hunting_rifle", true) == 0)
	{
		ig_AmmoOffset0[client] = 9;
	}
	else if (strcmp(sWeaponName, "weapon_smg_silenced", true) == 0)
	{
		ig_AmmoOffset0[client] = 5;
	}
	else if (strcmp(sWeaponName, "weapon_smg_mp5", true) == 0)
	{
		ig_AmmoOffset0[client] = 5;
	}
	else if (strcmp(sWeaponName, "weapon_shotgun_chrome", true) == 0)
	{
		ig_AmmoOffset0[client] = 7;
	}
	else if (strcmp(sWeaponName, "weapon_rifle_ak47", true) == 0)
	{
		ig_AmmoOffset0[client] = 3;
	}
	else if (strcmp(sWeaponName, "weapon_rifle_desert", true) == 0)
	{
		ig_AmmoOffset0[client] = 3;
	}
	else if (strcmp(sWeaponName, "weapon_sniper_military", true) == 0)
	{
		ig_AmmoOffset0[client] = 10;
	}
	else if (strcmp(sWeaponName, "weapon_grenade_launcher", true) == 0)
	{
		ig_AmmoOffset0[client] = 17;
	}
	else if (strcmp(sWeaponName, "weapon_rifle_sg552", true) == 0)
	{
		ig_AmmoOffset0[client] = 3;
	}
	else if (strcmp(sWeaponName, "weapon_rifle_m60", true) == 0)
	{
		ig_AmmoOffset0[client] = 6;
	}
	else if (strcmp(sWeaponName, "weapon_sniper_awp", true) == 0)
	{
		ig_AmmoOffset0[client] = 10;
	}
	else if (strcmp(sWeaponName, "weapon_sniper_scout", true) == 0)
	{
		ig_AmmoOffset0[client] = 10;
	}
	else if (strcmp(sWeaponName, "weapon_shotgun_spas", true) == 0)
	{
		ig_AmmoOffset0[client] = 8;
	}

	ig_Ammo0[client] = GetEntData(client, ammoOffset+(ig_AmmoOffset0[client]*4));
	//PrintToChatAll("%N - ammo: %d - offset: %d", client,ig_Ammo0[client],ig_AmmoOffset0[client]);
}

void HxGetSlot1(int client, int iSlot1)
{
	sg_buffer0[0] = '\0';
	GetEntPropString(iSlot1, Prop_Data, "m_ModelName", sg_buffer0, sizeof(sg_buffer0)-1);

	if (StrContains(sg_buffer0, "v_pistol", true) != -1) // v_pistolA.mdl
	{
		sg_slot1[client] = "pistol";
		ig_prop1[client] = GetEntProp(iSlot1, Prop_Send, "m_iClip1");
		return;
	}
	if (StrContains(sg_buffer0, "dual_pistol", true) != -1) //v_dual_pistolA.mdl
	{
		sg_slot1[client] = "dual_pistol";
		ig_prop1[client] = GetEntProp(iSlot1, Prop_Send, "m_iClip1");
		return;
	}
	if (StrContains(sg_buffer0, "eagle", true) != -1) //v_desert_eagle.mdl
	{
		sg_slot1[client] = "pistol_magnum";
		ig_prop1[client] = GetEntProp(iSlot1, Prop_Send, "m_iClip1");
		return;
	}
	if (StrContains(sg_buffer0, "v_bat", true) != -1) //v_bat.mdl
	{
		sg_slot1[client] = "baseball_bat";
		return;
	}
	if (StrContains(sg_buffer0, "cricket_bat", true) != -1) //v_cricket_bat.mdl
	{
		sg_slot1[client] = "cricket_bat";
		return;
	}
	if (StrContains(sg_buffer0, "crowbar", true) != -1) //v_crowbar.mdl
	{
		sg_slot1[client] = "crowbar";
		return;
	}
	if (StrContains(sg_buffer0, "fireaxe", true) != -1) //v_fireaxe.mdl
	{
		sg_slot1[client] = "fireaxe";
		return;
	}
	if (StrContains(sg_buffer0, "katana", true) != -1) //v_katana.mdl
	{
		sg_slot1[client] = "katana";
		return;
	}
	if (StrContains(sg_buffer0, "golfclub", true) != -1) //v_golfclub.mdl
	{
		sg_slot1[client] = "golfclub";
		return;
	}
	if (StrContains(sg_buffer0, "machete", true) != -1) //v_machete.mdl
	{
		sg_slot1[client] = "machete";
		return;
	}
	if (StrContains(sg_buffer0, "tonfa", true) != -1) //v_tonfa.mdl
	{
		sg_slot1[client] = "tonfa";
		return;
	}
	if (StrContains(sg_buffer0, "guitar", true) != -1) //v_electric_guitar.mdl
	{
		sg_slot1[client] = "electric_guitar";
		return;
	}
	if (StrContains(sg_buffer0, "frying_pan", true) != -1) //v_frying_pan.mdl
	{
		sg_slot1[client] = "frying_pan";
		return;
	}
	if (StrContains(sg_buffer0, "chainsaw", true) != -1) //v_chainsaw.mdl
	{
		ig_prop1[client] = GetEntProp(iSlot1, Prop_Send, "m_iClip1", 4);
		sg_slot1[client] = "chainsaw";
		return;
	}
	if (StrContains(sg_buffer0, "knife", true) != -1) //v_knife_t.mdl
	{
		sg_slot1[client] = "knife";
		return;
	}
	if (StrContains(sg_buffer0, "pitchfork", true) != -1) //v_pitchfork.mdl
	{
		sg_slot1[client] = "pitchfork";
		return;
	}
	if (StrContains(sg_buffer0, "shovel", true) != -1) //v_shovel.mdl
	{
		sg_slot1[client] = "shovel";
		return;
	}

	//GetEdictClassname(iSlot1, sg_slot1[client], 64);
	//LogError("m_ModelName(%s) %s", sg_buffer0, sg_slot1[client]);
}

void HxSaveC(int client)
{
	g_iRecorded[client] = 1;
	
	int iSlot0;
	int iSlot1;
	int iSlot2;
	int iSlot3;
	int iSlot4;

	if(g_bSaveCharacter)
	{
		// Store model
		GetClientModel(client, g_sModelInfo[client], 64);
		
		// Store prop
		g_iProp[client] = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	}
	
	if (g_bSaveHealth)
	{
		// Save health
		g_iHealthInfo[client][iReviveCount] =  GetEntProp(client, Prop_Send, "m_currentReviveCount");
		g_iHealthInfo[client][iThirdStrike] =  GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");

		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1) 
		{
			g_iHealthInfo[client][iHealth]       =  1;	
			g_iHealthInfo[client][iHealthTemp]   = 30;
			g_iHealthInfo[client][iHealthTime]   =  0;
			g_iHealthInfo[client][iGoingToDie]   =  1;
		}
		else 
		{
			g_iHealthInfo[client][iHealth]		= GetEntData(client, FindDataMapInfo(client, "m_iHealth"), 4);
			g_iHealthInfo[client][iHealthTemp]	= RoundToNearest( GetEntPropFloat(client, Prop_Send, "m_healthBuffer") );
			g_iHealthInfo[client][iHealthTime]  = RoundToNearest( GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime") );
			g_iHealthInfo[client][iGoingToDie]  = GetEntProp(client, Prop_Send, "m_isGoingToDie");
		}
	}
	
	iSlot0 = GetPlayerWeaponSlot(client, 0);
	iSlot1 = GetPlayerWeaponSlot(client, 1);
	iSlot2 = GetPlayerWeaponSlot(client, 2);
	iSlot3 = GetPlayerWeaponSlot(client, 3);
	iSlot4 = GetPlayerWeaponSlot(client, 4);

	if (iSlot0 > 0)
	{
		GetEdictClassname(iSlot0, sg_slot0[client], 64);
		ig_prop0[client] = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
		ig_prop2[client] = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", 4);
		ig_prop3[client] = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
		ig_prop4[client] = GetEntProp(iSlot0, Prop_Send, "m_nSkin", 4);
		HxGetSlot0Ammo(client, sg_slot0[client]);
	}
	if (iSlot1 > 0)
	{
		HxGetSlot1(client, iSlot1);
		ig_prop5[client] = GetEntProp(iSlot1, Prop_Send, "m_nSkin");
	}
	if (iSlot2 > 0)
	{
		GetEdictClassname(iSlot2, sg_slot2[client], 64);
	}
	if (iSlot3 > 0)
	{
		GetEdictClassname(iSlot3, sg_slot3[client], 64);
	}
	if (iSlot4 > 0)
	{
		GetEdictClassname(iSlot4, sg_slot4[client], 64);
	}
}

void HxFakeCHEAT(int client, const char[] sCmd, const char[] sArg)
{
	int iFlags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCmd, sArg);
	SetCommandFlags(sCmd, iFlags);
}

void HxGiveC(int client)
{
	if(g_iRecorded[client] == 0) return;
	
	// Update model & props
	if(g_bSaveCharacter)
	{
		SetEntProp(client, Prop_Send, "m_survivorCharacter", g_iProp[client]);  
		SetEntityModel(client, g_sModelInfo[client]);
		if (IsFakeClient(client))		// if bot, replace name
		{
			for (int i = 0; i < 8; i++)
			{
				if (StrEqual(g_sModelInfo[client], survivor_models[i])) SetClientInfo(client, "name", survivor_names[i]);
			}
		}
	}
	
	// Restore health
	if (g_bSaveHealth)
	{
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1) SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);	

		SetEntProp(client, Prop_Send, "m_currentReviveCount", g_iHealthInfo[client][iReviveCount]);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", g_iHealthInfo[client][iGoingToDie]);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", g_iHealthInfo[client][iThirdStrike]);
		
		SetEntProp(client, Prop_Send, "m_iHealth", g_iHealthInfo[client][iHealth], 1);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 1.0*g_iHealthInfo[client][iHealthTemp]);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime() - 1.0*g_iHealthInfo[client][iHealthTime]);
		
		// Disable heart beat sound if not B&W
		if (!g_iHealthInfo[client][iThirdStrike]) for (int i = 0; i <= 255; i++) StopSound(client, i, "player/heartbeatloop.wav");
	}
	
	int iSlot0;
	int iSlot1;
	int iSlot2;
	int iSlot3;
	int iSlot4;
		
	iSlot0 = GetPlayerWeaponSlot(client, 0);
	iSlot1 = GetPlayerWeaponSlot(client, 1);
	iSlot2 = GetPlayerWeaponSlot(client, 2);
	iSlot3 = GetPlayerWeaponSlot(client, 3);
	iSlot4 = GetPlayerWeaponSlot(client, 4);
	
	if (sg_slot0[client][0] != '\0' || sg_slot1[client][0] != '\0' || 
		sg_slot2[client][0] != '\0' || sg_slot3[client][0] != '\0' ||
		sg_slot4[client][0] != '\0') {
		if (iSlot0 > 0) HxRemoveWeapon(client, iSlot0);
		if (iSlot1 > 0) HxRemoveWeapon(client, iSlot1);
		if (iSlot2 > 0) HxRemoveWeapon(client, iSlot2);
		if (iSlot3 > 0) HxRemoveWeapon(client, iSlot3);
		if (iSlot4 > 0) HxRemoveWeapon(client, iSlot4);
	}
	else return;

	if (sg_slot0[client][0] != '\0')
	{
		HxFakeCHEAT(client, "give", sg_slot0[client]);
		iSlot0 = GetPlayerWeaponSlot(client, 0);
		if(iSlot0 > 0)
		{
			SetEntProp(iSlot0, Prop_Send, "m_iClip1", ig_prop0[client], 4);
			SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", ig_prop2[client], 4);
			SetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ig_prop3[client], 4);
			SetEntProp(iSlot0, Prop_Send, "m_nSkin", ig_prop4[client], 4);
			SetEntData(client, ammoOffset+(ig_AmmoOffset0[client]*4), ig_Ammo0[client]);
		}
	}

	if (sg_slot1[client][0] != '\0')
	{
		if (!strcmp(sg_slot1[client], "dual_pistol", true))
		{
			HxFakeCHEAT(client, "give", "pistol");
			HxFakeCHEAT(client, "give", "pistol");
			iSlot1 = GetPlayerWeaponSlot(client, 1);
			if(iSlot1 > 0)
			{
				SetEntProp(iSlot1, Prop_Send, "m_iClip1", ig_prop1[client]);
				SetEntProp(iSlot1, Prop_Send, "m_nSkin", ig_prop5[client]);
			}
		}
		else
		{
			HxFakeCHEAT(client, "give", sg_slot1[client]);
			iSlot1 = GetPlayerWeaponSlot(client, 1);
			if(iSlot1 > 0)
			{
				if (!strcmp(sg_slot1[client], "chainsaw", true) || !strcmp(sg_slot1[client], "pistol", true) || !strcmp(sg_slot1[client], "pistol_magnum", true))
				{
					SetEntProp(iSlot1, Prop_Send, "m_iClip1", ig_prop1[client]);
				}
				SetEntProp(iSlot1, Prop_Send, "m_nSkin", ig_prop5[client]);
			}
		}
	}

	if (sg_slot2[client][0] != '\0')
	{
		HxFakeCHEAT(client, "give", sg_slot2[client]);
	}
	if (sg_slot3[client][0] != '\0')
	{
		HxFakeCHEAT(client, "give", sg_slot3[client]);
	}
	if (sg_slot4[client][0] != '\0')
	{
		HxFakeCHEAT(client, "give", sg_slot4[client]);
	}
}

void HxRemoveWeapon(int client, int entity)
{
	if (RemovePlayerItem(client, entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public Action HxTimerConnected(Handle timer, int userid)
{
	if(g_bGiveWeaponBlock) return Plugin_Stop;

	int client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client))
	{
		int iTeam = GetClientTeam(client);
		if (iTeam == 2)
		{
			if (IsPlayerAlive(client) && g_iSpawned[client] == 0)
			{
				HxGiveC(client);
				//HxCleaning(client);
				g_iSpawned[client] = 1;
			}
			return Plugin_Stop;
		}
		else if(iTeam == 3 || iTeam == 4) //just in case
		{
			if (IsPlayerAlive(client))
			{
				//HxCleaning(client);
				g_iSpawned[client] = 1;
				return Plugin_Stop;
			}
		}
		
		if(iTeam == 1 && IsFakeClient(client)) return Plugin_Stop;
	}

	return Plugin_Continue;
}

int g_iRoundStart, g_iPlayerSpawn;
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++) g_iSpawned[i] = false;
	g_bGiveWeaponBlock = false;

	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action tmrStart(Handle timer)
{
	ResetPlugin();
	if (g_iCurrentMode == 1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && g_iSpawned[i] == 0)
			{
				HxGiveC(i);
				//HxCleaning(i);
				g_iSpawned[i] = 1;
			}
		}
	}

	if(PlayerLeftStartTimer == null) PlayerLeftStartTimer = CreateTimer(1.0, Timer_PlayerLeftStart, _, TIMER_REPEAT);
}

public Action Timer_PlayerLeftStart(Handle Timer)
{
	if (L4D_HasAnySurvivorLeftSafeArea())
	{
		g_iCountDownTime = g_iGameTimeBlock;
		if(g_iCountDownTime > 0)
		{
			if(CountDownTimer == null) CountDownTimer = CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT);
		}

		PlayerLeftStartTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue; 
}

public Action Timer_CountDown(Handle timer)
{
	if(g_iCountDownTime <= 0) 
	{
		g_bGiveWeaponBlock = true;
		CountDownTimer = null;
		return Plugin_Stop;
	}
	g_iCountDownTime--;
	return Plugin_Continue;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
	ResetTimer();
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	ig_protection = true;

	if (g_iCurrentMode == 1)
	{
		if (g_bFullhealth)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
				{
					HxFakeCHEAT(i, "give", "health");
					SetEntPropFloat(i, Prop_Send, "m_healthBufferTime", GetGameTime());
					SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0);
				}
			}
		}
		CreateTimer(1.0, Timer_Event_MapTransition, _, TIMER_FLAG_NO_MAPCHANGE); //delay is necessary for waiting all afk human players to take over bot
	}
}

public Action Timer_Event_MapTransition(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		HxCleaning(i);
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if(IsFakeClient(i) && !g_bSaveBot) continue;
				
			HxSaveC(i);
		}
	}
}

public void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		HxCleaning(i);
	}
}

void ResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

void ResetTimer()
{
	delete PlayerLeftStartTimer;
	delete CountDownTimer;
}
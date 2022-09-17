/**
 * -Relate Valve ConVar-
 * If true, survivor bots will be used as placeholders for survivors who are still changing levels
 * If false, prevent bots from moving, changing weapons, using kits while human survivors are still changing levels
 * need to write down in cfg/server.cfg
 * 
 * sm_cvar sb_transition 0 
 * 
 * =============================================================================
 * L4D2 coop save weapon
 * Copyright 2011 - 2021 steamcommunity.com/profiles/76561198025355822/
 * Fixed 2015 steamcommunity.com/id/Electr0n
 * Fixed 2016 steamcommunity.com/id/mixjayrus
 * Fixed 2016 user Merudo
 * Copyright 2022 steamcommunity.com/profiles/76561198026784913
*/
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define	MAX_WEAPONS2		29

static char g_sWeaponModels2[MAX_WEAPONS2][] =
{
	"models/w_models/weapons/w_pistol_B.mdl",
	"models/w_models/weapons/w_desert_eagle.mdl",
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_rifle_ak47.mdl",
	"models/w_models/weapons/w_rifle_sg552.mdl",
	"models/w_models/weapons/w_desert_rifle.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_shotgun_spas.mdl",
	"models/w_models/weapons/w_shotgun.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_smg_a.mdl",
	"models/w_models/weapons/w_smg_mp5.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_sniper_awp.mdl",
	"models/w_models/weapons/w_sniper_military.mdl",
	"models/w_models/weapons/w_sniper_scout.mdl",
	"models/w_models/weapons/w_m60.mdl",
	"models/w_models/weapons/w_grenade_launcher.mdl",
	"models/weapons/melee/w_chainsaw.mdl",
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/w_models/weapons/w_eq_pipebomb.mdl",
	"models/w_models/weapons/w_eq_bile_flask.mdl",
	"models/w_models/weapons/w_eq_painpills.mdl",
	"models/w_models/weapons/w_eq_adrenaline.mdl",
	"models/w_models/weapons/w_eq_Medkit.mdl",
	"models/w_models/weapons/w_eq_defibrillator.mdl",
	"models/w_models/weapons/w_eq_explosive_ammopack.mdl",
	"models/w_models/weapons/w_eq_incendiary_ammopack.mdl",
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
	g_hSaveBot, g_hSaveHealth, g_hSaveCharacter, g_hCvarReviveHealth, g_hSurvivorMaxInc;

char sg_slot0[MAXPLAYERS+1][64];			/* slot0 weapon */
char sg_slot1[MAXPLAYERS+1][64];			/* slot1 weapon*/
char sg_slot2[MAXPLAYERS+1][64];			/* slot2 weapon */
char sg_slot3[MAXPLAYERS+1][64];			/* slot3 weapon */
char sg_slot4[MAXPLAYERS+1][64];			/* slot4 weapon */
int ig_slots0_clip[MAXPLAYERS+1]; 			/* slot0 m_iClip */
int ig_slots1_clip[MAXPLAYERS+1]; 			/* slot1 m_iClip */
int ig_slots0_upgrade_bit[MAXPLAYERS+1]; 	/* slot0 m_upgradeBitVec */
int ig_slots0_upgraded_ammo[MAXPLAYERS+1]; 	/* slot0 m_nUpgradedPrimaryAmmoLoaded */
int ig_slots0_skin[MAXPLAYERS+1]; 			/* slot0 m_nSkin */
int ig_slots1_skin[MAXPLAYERS+1]; 			/* slot1 m_nSkin */
int ig_slots0_ammo[MAXPLAYERS+1]; 			/* slot0 ammo */
int ig_slots0_ammo_offest[MAXPLAYERS+1]; 	/* slot0 ammo offset */
bool g_bGiven[MAXPLAYERS+1];				/* client is already stored */
bool g_bRecorded[MAXPLAYERS+1];				/* client is recorded to save */
bool g_bSlot1_IsMelee[MAXPLAYERS+1];		/* slot1 is melee */

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
int 	g_iHealthInfo[MAXPLAYERS+1][view_as<int>(iHealthMAX)]; 	//client health
int 	g_iProp[MAXPLAYERS+1]; 									//client character index
char 	g_sModelInfo[MAXPLAYERS+1][64]; 						//client character model

bool g_bGiveWeaponBlock, g_bMapTransition;
int ammoOffset, g_iCountDownTime;	
Handle PlayerLeftStartTimer = null, CountDownTimer = null;
int g_iReviveTempHealth = 30, g_iSurvivorMaxInc;

public Plugin myinfo =
{
	name = "[L4D2] Save Weapon",
	author = "MAKS, HarryPotter",
	description = "L4D2 coop save weapon when map transition if more than 4 players",
	version = "5.9",
	url = "forums.alliedmods.net/showthread.php?p=2304407"
};

GlobalForward g_hForwardSaveWeaponGive;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_hForwardSaveWeaponGive = new GlobalForward("L4D2_OnSaveWeaponHxGiveC", ET_Ignore, Param_Cell);
	return APLRes_Success;
}

public void OnPluginStart()
{
	ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");

	g_hFullHealth = 	CreateConVar("l4d2_ty_saveweapons_health", "0", "If 1, restore 100 full health when end of chapter.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hGameTimeBlock = 	CreateConVar("l4d2_ty_saveweapons_game_seconds_block", "60", "Do not restore weapons and health after survivors have left start safe area for at least x seconds. (0=Always restore)", FCVAR_NOTIFY, true, 0.0);
	g_hSaveBot = 		CreateConVar("l4d2_ty_saveweapons_save_bot", "1", "If 1, save weapons and health for bots as well.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hSaveHealth = 	CreateConVar("l4d2_ty_saveweapons_save_health",	"1", "If 1, save health and restore. (can save >100 hp)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hSaveCharacter = 	CreateConVar("l4d2_ty_saveweapons_save_character",	"0", "If 1, save character model and restore.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true,	"l4d2_ty_saveweapons");
	
	g_hGameMode = FindConVar("mp_gamemode");
	g_hGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hFullHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hGameTimeBlock.AddChangeHook(ConVarChanged_Cvars);
	g_hSaveBot.AddChangeHook(ConVarChanged_Cvars);
	g_hSaveHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hSaveCharacter.AddChangeHook(ConVarChanged_Cvars);
	
	g_hCvarReviveHealth = FindConVar("survivor_revive_health");
	g_hSurvivorMaxInc = FindConVar("survivor_max_incapacitated_count");
	g_hCvarReviveHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hSurvivorMaxInc.AddChangeHook(ConVarChanged_Cvars);
	
	HookEvent("round_start",  			Event_RoundStart,	 	EventHookMode_PostNoCopy);
	HookEvent("player_spawn", 			Event_PlayerSpawn, 		EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,			EventHookMode_PostNoCopy);
	HookEvent("map_transition", 		Event_RoundEnd,			EventHookMode_PostNoCopy); //戰役過關到下一關的時候 (沒有觸發round_end)
	HookEvent("mission_lost", 			Event_RoundEnd,			EventHookMode_PostNoCopy); //戰役滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", Event_RoundEnd,			EventHookMode_PostNoCopy); //救援載具離開之時  (沒有觸發round_end)
	HookEvent("map_transition", 		Event_MapTransition, 	EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", evtBotReplacedPlayer);

	HxCleaningAll();
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
	
	if (L4D_IsFirstMapInScenario())
	{
		HxCleaningAll();
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

	if(g_bMapTransition == false)
	{
		HxCleaningAll();
	}
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
	g_iReviveTempHealth = g_hCvarReviveHealth.IntValue;
	g_iSurvivorMaxInc = g_hSurvivorMaxInc.IntValue;
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
	if (g_iCurrentMode == 1 && IsClientInGame(client) && g_bGiveWeaponBlock == false)
	{
		CreateTimer(0.5, HxTimerRestore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

public Action HxTimerRestore(Handle timer, int userid)
{
	if(g_bGiveWeaponBlock) return Plugin_Stop;

	int client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client))
	{
		if(g_bGiven[client]) return Plugin_Stop;

		int iTeam = GetClientTeam(client);
		bool fakebot = IsFakeClient(client);
		if (iTeam == 2)
		{
			if (IsPlayerAlive(client))
			{
				if(fakebot && !g_bSaveBot) return Plugin_Stop;
				if(fakebot && HasIdlePlayer(client)) return Plugin_Continue;

				HxGiveC(client);
				return Plugin_Stop;
			}
		}
		else if(iTeam == 3 || iTeam == 4) //just in case
		{
			if (fakebot || IsPlayerAlive(client))
			{
				return Plugin_Stop;
			}
		}
		
		if(iTeam == 1 && fakebot) 
			return Plugin_Stop;

		return Plugin_Continue;
	}

	return Plugin_Stop;
}


int g_iRoundStart, g_iPlayerSpawn;
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++) g_bGiven[i] = false;
	g_bGiveWeaponBlock = false;

	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(0.5, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(0.5, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action tmrStart(Handle timer)
{
	ResetPlugin();

	g_bMapTransition = false;
	if (g_iCurrentMode == 1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				CreateTimer(0.2, HxTimerRestore, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			}
		}
	}

	delete PlayerLeftStartTimer;
	PlayerLeftStartTimer = CreateTimer(1.0, Timer_PlayerLeftStart, _, TIMER_REPEAT);
	
	return Plugin_Continue;
}

public Action Timer_PlayerLeftStart(Handle Timer)
{
	if (L4D_HasAnySurvivorLeftSafeArea())
	{
		g_iCountDownTime = g_iGameTimeBlock;
		if(g_iCountDownTime > 0)
		{
			delete CountDownTimer;
			CountDownTimer = CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT);
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
	g_bMapTransition = true;
	if (g_iCurrentMode == 1)
	{
		if (g_bFullhealth)
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
				{
					if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1)
					{
						SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);	
						SetEntProp(client, Prop_Send, "m_iHealth", 100, 1);
						SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
						SetEntPropFloat(client, Prop_Send, "m_healthBufferTime",  GetGameTime());
					}
					else
					{
						if(GetEntProp(client, Prop_Send, "m_iHealth") + RoundToNearest( GetEntPropFloat(client, Prop_Send, "m_healthBuffer") ) < 100)
						{
							SetEntProp(client, Prop_Send, "m_iHealth", 100, 1);
							SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
							SetEntPropFloat(client, Prop_Send, "m_healthBufferTime",  GetGameTime());
						}
					}

					SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
					SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
					SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
					
					// Disable heart beat sound
					StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
					StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
					StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
					StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
				}
			}
		}
		else
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
				{
					if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1)
					{
						CreateTimer(0.1, Timer_AdjustHealth, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE); //fixed missing second slot weapon
					}
				}
			}
		}
		CreateTimer(1.5, Timer_Event_MapTransition, _, TIMER_FLAG_NO_MAPCHANGE); //delay is necessary for waiting all afk human players to take over bot or slot 2 throwable weapon is gone
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
	
	return Plugin_Continue;
}

public void evtBotReplacedPlayer(Event event, const char[] name, bool dontBroadcast) 
{
	int bot = GetClientOfUserId(event.GetInt("bot"));
	if(bot && IsClientInGame(bot) && GetClientTeam(bot) == 2 && IsPlayerAlive(bot)) g_bGiven[bot] = true;
}

void HxGiveC(int client)
{
	if(g_bRecorded[client] == false || g_bGiven[client] == true) return;
	g_bGiven[client] = true;

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
		if (!g_iHealthInfo[client][iThirdStrike])
		{
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
		}
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
		if (iSlot0 > MaxClients) HxRemoveWeapon(client, iSlot0);
		if (iSlot1 > MaxClients) HxRemoveWeapon(client, iSlot1);
		if (iSlot2 > MaxClients) HxRemoveWeapon(client, iSlot2);
		if (iSlot3 > MaxClients) HxRemoveWeapon(client, iSlot3);
		if (iSlot4 > MaxClients) HxRemoveWeapon(client, iSlot4);
	}

	int weapon;
	if (sg_slot1[client][0] != '\0')
	{
		if(g_bSlot1_IsMelee[client] == true)
		{
			weapon = HxCreateWeapon("weapon_melee", sg_slot1[client]);
			if (weapon != -1) EquipPlayerWeapon(client, weapon);
		}
		else
		{
			if (!strcmp(sg_slot1[client], "dual_pistol", true))
			{
				weapon = HxCreateWeapon("weapon_pistol");
				if (weapon != -1) AcceptEntityInput(weapon, "Use", client, weapon);

				weapon = HxCreateWeapon("weapon_pistol");
				if (weapon != -1) AcceptEntityInput(weapon, "Use", client, weapon);
			}
			else
			{
				weapon = HxCreateWeapon(sg_slot1[client]);
				if (weapon != -1) EquipPlayerWeapon(client, weapon);
			}
		}
		
		iSlot1 = GetPlayerWeaponSlot(client, 1);
		if(iSlot1 > MaxClients)
		{
			SetEntProp(iSlot1, Prop_Send, "m_nSkin", ig_slots1_skin[client]);
			if (StrContains(sg_slot1[client], "chainsaw", false) >= 0 || StrContains(sg_slot1[client], "pistol", false) >= 0)
			{
				SetEntProp(iSlot1, Prop_Send, "m_iClip1", ig_slots1_clip[client]);
			}
		}
	}

	if (sg_slot0[client][0] != '\0')
	{
		weapon = HxCreateWeapon(sg_slot0[client]);
		if (weapon != -1) EquipPlayerWeapon(client, weapon);
		
		iSlot0 = GetPlayerWeaponSlot(client, 0);
		if(iSlot0 > MaxClients)
		{
			SetEntProp(iSlot0, Prop_Send, "m_iClip1", ig_slots0_clip[client], 4);
			SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", ig_slots0_upgrade_bit[client], 4);
			SetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ig_slots0_upgraded_ammo[client], 4);
			SetEntProp(iSlot0, Prop_Send, "m_nSkin", ig_slots0_skin[client], 4);
			SetEntData(client, ammoOffset+(ig_slots0_ammo_offest[client]*4), ig_slots0_ammo[client]);
		}
	}

	if (sg_slot2[client][0] != '\0')
	{
		weapon = HxCreateWeapon(sg_slot2[client]);
		if (weapon != -1) EquipPlayerWeapon(client, weapon);
	}
	if (sg_slot3[client][0] != '\0')
	{
		weapon = HxCreateWeapon(sg_slot3[client]);
		if (weapon != -1) EquipPlayerWeapon(client, weapon);
	}
	if (sg_slot4[client][0] != '\0')
	{
		weapon = HxCreateWeapon(sg_slot4[client]);
		if (weapon != -1) EquipPlayerWeapon(client, weapon);
	}

	Call_StartForward(g_hForwardSaveWeaponGive);
	Call_PushCell(client);
	Call_Finish();
}

void HxRemoveWeapon(int client, int entity)
{
	if (RemovePlayerItem(client, entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

void HxSaveC(int client)
{
	g_bRecorded[client] = true;
	
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
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1) 
		{
			g_iHealthInfo[client][iHealth]      =  1;	
			g_iHealthInfo[client][iHealthTemp]  =  g_iReviveTempHealth;
			g_iHealthInfo[client][iHealthTime]  =  0;
			g_iHealthInfo[client][iGoingToDie]  =  1;
			g_iHealthInfo[client][iReviveCount] =  GetEntProp(client, Prop_Send, "m_currentReviveCount") + 1;
			g_iHealthInfo[client][iThirdStrike] =  g_iHealthInfo[client][iReviveCount] >= g_iSurvivorMaxInc ? 1 : 0;
		}
		else 
		{
			g_iHealthInfo[client][iHealth]		= GetEntProp(client, Prop_Send, "m_iHealth");
			g_iHealthInfo[client][iHealthTemp]	= RoundToNearest( GetEntPropFloat(client, Prop_Send, "m_healthBuffer") );
			g_iHealthInfo[client][iHealthTime]  = RoundToNearest( GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime") );
			g_iHealthInfo[client][iGoingToDie]  = GetEntProp(client, Prop_Send, "m_isGoingToDie");
			g_iHealthInfo[client][iReviveCount] = GetEntProp(client, Prop_Send, "m_currentReviveCount");
			g_iHealthInfo[client][iThirdStrike] = GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
		}
	}
	
	iSlot0 = GetPlayerWeaponSlot(client, 0);
	iSlot1 = GetPlayerWeaponSlot(client, 1);
	iSlot2 = GetPlayerWeaponSlot(client, 2);
	iSlot3 = GetPlayerWeaponSlot(client, 3);
	iSlot4 = GetPlayerWeaponSlot(client, 4);

	if (iSlot0 > MaxClients)
	{
		GetEntityClassname(iSlot0, sg_slot0[client], 64);
		ig_slots0_clip[client] = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
		ig_slots0_upgrade_bit[client] = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", 4);
		ig_slots0_upgraded_ammo[client] = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
		ig_slots0_skin[client] = GetEntProp(iSlot0, Prop_Send, "m_nSkin", 4);
		HxGetSlot0Ammo(client, sg_slot0[client]);
	}
	if (iSlot1 > MaxClients)
	{
		HxGetSlot1(client, iSlot1);
		ig_slots1_skin[client] = GetEntProp(iSlot1, Prop_Send, "m_nSkin", 4);
	}
	if (iSlot2 > MaxClients)
	{
		GetEntityClassname(iSlot2, sg_slot2[client], 64);
	}
	if (iSlot3 > MaxClients)
	{
		GetEntityClassname(iSlot3, sg_slot3[client], 64);
	}
	if (iSlot4 > MaxClients)
	{
		GetEntityClassname(iSlot4, sg_slot4[client], 64);
	}
}

void HxCleaning(int client)
{
	ig_slots0_clip[client] = 0;
	ig_slots1_clip[client] = 0;
	ig_slots0_upgrade_bit[client] = 0;
	ig_slots0_upgraded_ammo[client] = 0;
	ig_slots0_skin[client] = 0;
	ig_slots1_skin[client] = 0;
	ig_slots0_ammo[client] = 0;
	ig_slots0_ammo_offest[client] = 0;

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
	
	g_bRecorded[client] = false;
	g_bSlot1_IsMelee[client] = false;
}

void HxGetSlot0Ammo (int client, const char[] sWeaponName)
{
	if (strcmp(sWeaponName, "weapon_smg", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 5;
	}
	else if (strcmp(sWeaponName, "weapon_pumpshotgun", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 7;
	}
	else if (strcmp(sWeaponName, "weapon_rifle", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 3;
	}
	else if (strcmp(sWeaponName, "weapon_autoshotgun", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 8;
	}
	else if (strcmp(sWeaponName, "weapon_hunting_rifle", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 9;
	}
	else if (strcmp(sWeaponName, "weapon_smg_silenced", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 5;
	}
	else if (strcmp(sWeaponName, "weapon_smg_mp5", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 5;
	}
	else if (strcmp(sWeaponName, "weapon_shotgun_chrome", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 7;
	}
	else if (strcmp(sWeaponName, "weapon_rifle_ak47", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 3;
	}
	else if (strcmp(sWeaponName, "weapon_rifle_desert", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 3;
	}
	else if (strcmp(sWeaponName, "weapon_sniper_military", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 10;
	}
	else if (strcmp(sWeaponName, "weapon_grenade_launcher", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 17;
	}
	else if (strcmp(sWeaponName, "weapon_rifle_sg552", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 3;
	}
	else if (strcmp(sWeaponName, "weapon_rifle_m60", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 6;
	}
	else if (strcmp(sWeaponName, "weapon_sniper_awp", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 10;
	}
	else if (strcmp(sWeaponName, "weapon_sniper_scout", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 10;
	}
	else if (strcmp(sWeaponName, "weapon_shotgun_spas", true) == 0)
	{
		ig_slots0_ammo_offest[client] = 8;
	}

	ig_slots0_ammo[client] = GetEntData(client, ammoOffset+(ig_slots0_ammo_offest[client]*4));
	//PrintToChatAll("%N - ammo: %d - offset: %d", client,ig_slots0_ammo[client],ig_slots0_ammo_offest[client]);
}

void HxGetSlot1(int client, int iSlot1)
{
	char wep_name[64]; wep_name[0] = '\0';
	if (HasEntProp(iSlot1, Prop_Data, "m_strMapSetScriptName")) //support custom melee
	{
		GetEntPropString(iSlot1, Prop_Data, "m_strMapSetScriptName", wep_name, sizeof(wep_name));		
		g_bSlot1_IsMelee[client] = true;
	}
	else
	{
		g_bSlot1_IsMelee[client]= false;
		if (HasEntProp(iSlot1, Prop_Send, "m_isDualWielding") && 
		GetEntProp(iSlot1, Prop_Send, "m_isDualWielding") > 0) //dual pistol
		{
			strcopy(wep_name, sizeof(wep_name), "dual_pistol");
		}
		else
		{
			GetEntityClassname(iSlot1, wep_name, sizeof(wep_name));
		}
		
		if (StrContains(wep_name, "chainsaw", false) >= 0 || StrContains(wep_name, "pistol", false) >= 0) //chainsaw, pistol, dual_pistol, pistol_magnum
		{
			ig_slots1_clip[client] = GetEntProp(iSlot1, Prop_Send, "m_iClip1");
		}
	}
	
	if (wep_name[0] != '\0')
	{
		strcopy(sg_slot1[client], 64, wep_name);
	}
}

/*
void HxFakeCHEAT(int client, const char[] sCmd, const char[] sArg)
{
	int iFlags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCmd, sArg);
	SetCommandFlags(sCmd, iFlags);
}
*/

int HxCreateWeapon(const char[] class_name, const char[] melee_name = "")
{
	int weapon = -1;
	if(strcmp(class_name, "weapon_melee") == 0)
	{
		weapon = CreateEntityByName(class_name);
		if (!RealValidEntity(weapon)) weapon = -1;
		else
		{
			DispatchKeyValue(weapon, "solid", "6");
			DispatchKeyValue(weapon, "melee_script_name", melee_name);
			DispatchSpawn(weapon);
		}
	}
	else
	{
		char wep_str[128];
		strcopy(wep_str, sizeof(wep_str), class_name);
		if (StrContains(wep_str, "weapon_", false) < 0)
		{
			Format(wep_str, sizeof(wep_str), "weapon_%s", wep_str);
		}
		
		weapon = CreateEntityByName(wep_str);
		if (!RealValidEntity(weapon)) weapon = -1;
		else DispatchSpawn(weapon);
	}
	
	return weapon;
}

bool RealValidEntity(int entity)
{
	if (entity <= MaxClients || !IsValidEntity(entity)) return false;
	return true;
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

void HxCleaningAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		HxCleaning(i);
	}
}

public Action Timer_AdjustHealth(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if( client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1 )
	{
		SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);	

		SetEntProp(client, Prop_Send, "m_currentReviveCount", GetEntProp(client, Prop_Send, "m_currentReviveCount") + 1);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike",  GetEntProp(client, Prop_Send, "m_currentReviveCount") >= g_iSurvivorMaxInc ? 1 : 0);
		
		// Disable heart beat sound if not B&W
		if (!GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike"))
		{
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
		}
		
		SetEntProp(client, Prop_Send, "m_iHealth", 1, 1);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 1.0 * g_iReviveTempHealth);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime",  GetGameTime());
	}
	return Plugin_Continue;
}

bool HasIdlePlayer(int bot)
{
	if(HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
	{
		if(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID") > 0)
		{
			return true;
		}
	}
	
	return false;
}
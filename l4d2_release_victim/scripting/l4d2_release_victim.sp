//BHaType @ 2019~2022
//Shadowysn @ 2022 - No Gamedata Required
//Harry @ 2022-2024 - Can't use attack1 and attack2 for short time after release victim!!

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <multicolors>

public Plugin myinfo = 
{
	name = "[L4D2] Release Victim Extended version",
	author = "BHaType, HarryPotter",
	description = "Allow to release victim",
	version = "1.1h-2024/2/6"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	// Require Left 4 Dead 2
	EngineVersion test = GetEngineVersion();

	if (test != Engine_Left4Dead2)
	{
		Format(error, err_max, "Plugin only supports Left4Dead 2.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

bool g_bReset, g_bEffect;
int g_iZombieClass, g_iVelocity;
ConVar sm_release_distance, sm_release_height, sm_release_ability_reset, sm_release_effect,
	g_hConVar_JockeyAttackDelay, g_hConVar_HunterAttackDelay, g_hConVar_ChargerAttackDelay, g_hConVar_SmokerAttackDelay,
	g_hCvarAnnounceType;
float g_flDistance, g_flHeight, g_flCharger, g_flSmoker, g_flJockey,
	g_fJockeyAttackDelay, g_fHunterAttackDelay, g_fChargerAttackDelay, g_fSmokerAttackDelay;

int g_iCvarAnnounceType;

float g_fButtonDelay[MAXPLAYERS+1];

#define CBaseAbility "CBaseAbility"
#define m_nextActivationTimer "m_nextActivationTimer"

#define ZC_SMOKER		1
#define ZC_BOOMER		2
#define ZC_HUNTER		3
#define ZC_SPITTER		4
#define ZC_JOCKEY		5
#define ZC_CHARGER		6

public void OnPluginStart()
{
	LoadTranslations("l4d2_release_victim.phrases");

	g_flCharger = FindConVar("z_charge_interval").FloatValue;
	g_flSmoker = FindConVar("smoker_tongue_delay").FloatValue;
	g_flJockey = FindConVar("z_jockey_leap_again_timer").FloatValue;

	sm_release_distance 			= CreateConVar( "l4d2_release_victim_distance", 			"900.0", 	"Release distance", FCVAR_NOTIFY, true, 0.0);
	sm_release_height 				= CreateConVar( "l4d2_release_victim_height", 				"600.0", 	"Release height", FCVAR_NOTIFY, true, 0.0);
	sm_release_ability_reset 		= CreateConVar( "l4d2_release_victim_ability_reset", 		"1", 		"Reset ability", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_release_effect 				= CreateConVar( "l4d2_release_victim_effect", 				"1", 		"Show effect after release", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_hConVar_JockeyAttackDelay 	= CreateConVar( "l4d2_release_victim_jockey_attackdelay", 	"6.0", 		"After dismounting with the jockey, how long can the player not use attack1 and attack2", FCVAR_NOTIFY, true, 0.0);
	g_hConVar_HunterAttackDelay 	= CreateConVar( "l4d2_release_victim_hunter_attackdelay", 	"6.0", 		"After dismounting with the hunter, how long can the player not use attack1 and attack2", FCVAR_NOTIFY, true, 0.0);
	g_hConVar_ChargerAttackDelay 	= CreateConVar( "l4d2_release_victim_charger_attackdelay", 	"6.0", 		"After dismounting with the charger, how long can the player not use attack1 and attack2", FCVAR_NOTIFY, true, 0.0);
	g_hConVar_SmokerAttackDelay 	= CreateConVar( "l4d2_release_victim_smoker_attackdelay", 	"10.0", 	"After dismounting with the smoker, how long can the player not use attack1 and attack2", FCVAR_NOTIFY, true, 0.0);
	g_hCvarAnnounceType 			= CreateConVar( "l4d2_release_victim_announce_type", 		"1", 		"Changes how message displays. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	AutoExecConfig(true, 							"l4d2_release_victim");
	
	GetCvars();
	sm_release_ability_reset.AddChangeHook(OnConVarChanged);
	sm_release_distance.AddChangeHook(OnConVarChanged);
	sm_release_height.AddChangeHook(OnConVarChanged);
	sm_release_effect.AddChangeHook(OnConVarChanged);
	g_hConVar_JockeyAttackDelay.AddChangeHook(OnConVarChanged);
	g_hConVar_HunterAttackDelay.AddChangeHook(OnConVarChanged);
	g_hConVar_ChargerAttackDelay.AddChangeHook(OnConVarChanged);
	g_hConVar_SmokerAttackDelay.AddChangeHook(OnConVarChanged);
	g_hCvarAnnounceType.AddChangeHook(OnConVarChanged);
	
	g_iZombieClass = FindSendPropInfo("CTerrorPlayer", "m_zombieClass");
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	HookEvent("round_start", evtRoundStart);
}

public void OnMapStart()
{
	PrecacheParticle("gen_hit1_c");
}

void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_flDistance = sm_release_distance.FloatValue;
	g_flHeight = sm_release_height.FloatValue;
	g_bReset = sm_release_ability_reset.BoolValue;
	g_bEffect = sm_release_effect.BoolValue;
	g_fJockeyAttackDelay = g_hConVar_JockeyAttackDelay.FloatValue;
	g_fChargerAttackDelay = g_hConVar_ChargerAttackDelay.FloatValue;
	g_fHunterAttackDelay = g_hConVar_HunterAttackDelay.FloatValue;
	g_fSmokerAttackDelay = g_hConVar_SmokerAttackDelay.FloatValue;
	g_iCvarAnnounceType = g_hCvarAnnounceType.IntValue;
}

public void evtRoundStart(Event event, const char[] name, bool dontbroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_fButtonDelay[i] = 0.0;
	}
}

public Action OnPlayerRunCmd (int client, int &buttons)
{
	if (IsFakeClient(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client))
		return Plugin_Continue;

	if(g_fButtonDelay[client] - GetEngineTime() > 0.0)
	{
		if (buttons & IN_ATTACK) buttons &= ~IN_ATTACK;
		if (buttons & IN_ATTACK2) buttons &= ~IN_ATTACK2;
		if (buttons & IN_USE) buttons &= ~IN_USE;
		return Plugin_Continue;
	}

	if(!(buttons & IN_ATTACK2)) return Plugin_Continue;
	
	int iClass = GetEntData(client, g_iZombieClass), victim;
	
	switch (iClass)
	{
		case ZC_CHARGER: 
		{
			victim = L4D_GetVictimCharger(client);
		}
		case ZC_HUNTER: 
		{
			victim = L4D_GetVictimHunter(client);
		}
		case ZC_JOCKEY:
		{
			victim = L4D_GetVictimJockey(client);
		}
		case ZC_SMOKER: 
		{
			victim = L4D_GetVictimSmoker(client);
		}
		default:
		{
			return Plugin_Continue;
		}
	}

	if(victim <= 0) return Plugin_Continue;
	
	Release(client, victim, iClass);

	if (buttons & IN_ATTACK) buttons &= ~IN_ATTACK;
	if (buttons & IN_ATTACK2) buttons &= ~IN_ATTACK2;
	if (buttons & IN_USE) buttons &= ~IN_USE;

	return Plugin_Continue;
}

void Release (int client, int victim, int iClass)
{
	switch (iClass)
	{
		case ZC_CHARGER: 
		{
			L4D2_Charger_EndPummel(victim, client);
			L4D_StopMusic(client, "Event.ChargerSlam");

			// left4dhooks error bug
			SetEntPropEnt(client, Prop_Send, "m_pummelVictim", -1);
			SetEntPropEnt(victim, Prop_Send, "m_pummelAttacker", -1);
		}
		case ZC_HUNTER:
		{
			L4D_Hunter_ReleaseVictim(victim, client);
		}
		case ZC_JOCKEY:
		{
			L4D2_Jockey_EndRide(victim, client);
		}
		case ZC_SMOKER: 
		{
			L4D_Smoker_ReleaseVictim(victim, client);
		}
		default:
		{
			return;
		}
	}
	
	float vOrigin[3];
	GetClientAbsOrigin(client, vOrigin);
	vOrigin[2] += 5.0;
	
	if ( g_bEffect )
		SpoofEffect(vOrigin);
	
	if ( g_flDistance > 0 || g_flHeight > 0 )
		CreateTimer(0.05, tFly, GetClientUserId(client));
		
	CreateTimer(0.2, tReset, GetClientUserId(client)); 

	float fDelay = 0.0;
	switch (iClass)
	{
		case ZC_CHARGER:
		{
			fDelay = g_fChargerAttackDelay;
		}
		case ZC_HUNTER: 
		{
			fDelay = g_fHunterAttackDelay;
		}
		case ZC_JOCKEY: 
		{
			fDelay = g_fJockeyAttackDelay;
		}
		case ZC_SMOKER: 
		{
			fDelay = g_fSmokerAttackDelay;
		}
	}

	if(fDelay > 0.0)
	{
		g_fButtonDelay[client] = GetEngineTime() + fDelay;
		switch(g_iCvarAnnounceType)
		{
			case 1:{
				CPrintToChat(client, "%T", "Release (C)", client, fDelay);
			}
			case 2:{
				PrintHintText(client, "%T", "Release", client, fDelay);
			}
			case 3:{
				PrintCenterText(client, "%T", "Release", client, fDelay);
			}
		}
	}
}

Action tFly (Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || !IsClientInGame(client))
		return Plugin_Continue;
		
	StoreToAddress(GetEntityAddress(client) + view_as<Address>(11481), 1, NumberType_Int32);
	
	float vAngles[3], vDirection[3], vCurrent[3], vResult[3];
	
	GetClientEyeAngles(client, vAngles);
	
	GetAngleVectors(vAngles, vDirection, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vDirection, g_flDistance);
	GetEntDataVector(client, g_iVelocity, vCurrent);
	
	vResult[0] = vCurrent[0] + vDirection[0];
	vResult[1] = vCurrent[1] + vDirection[1];
	vResult[2] = g_flHeight;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vResult);
	
	CreateTimer(0.2, tReset, GetClientUserId(client));
	return Plugin_Continue;
}

Action tReset (Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || !IsClientInGame(client))
		return Plugin_Continue;
		
	StoreToAddress(GetEntityAddress(client) + view_as<Address>(11481), 0, NumberType_Int32);
	
	if (g_bReset)
	{
		int iEntity = GetEntPropEnt(client, Prop_Send, "m_customAbility");
		
		if (iEntity > MaxClients)
		{
			switch (GetEntData(client, g_iZombieClass))
			{
				case ZC_CHARGER: SetDTCountdownTimer(iEntity, CBaseAbility, m_nextActivationTimer, g_flCharger);
				case ZC_JOCKEY: SetDTCountdownTimer(iEntity, CBaseAbility, m_nextActivationTimer, g_flJockey);
				case ZC_SMOKER: SetDTCountdownTimer(iEntity, CBaseAbility, m_nextActivationTimer, g_flSmoker);
			}
		}
	}
	return Plugin_Continue;
}

void SetDTCountdownTimer(int entity, const char[] classname, const char[] timer_str, float duration)
{
	SetEntDataFloat(entity, (FindSendPropInfo(classname, timer_str)+4), duration, true);
	SetEntDataFloat(entity, (FindSendPropInfo(classname, timer_str)+8), GetGameTime()+duration, true);
}

void SpoofEffect(float vOrigin[3])
{
	int entity = CreateEntityByName("info_particle_system");
	
	if (entity == -1)
	{
		LogError("Invalid entity");
		return;
	}
	
	DispatchKeyValue(entity, "effect_name", "gen_hit1_c");
	//fireworks_flare_trail_01
	TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	ActivateEntity(entity);

	AcceptEntityInput(entity, "start");
	
	SetVariantString("OnUser1 !self:Kill::4.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}
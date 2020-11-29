#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <basecomm>
#include <glow>
#include <ThirdPersonShoulder_Detect>

#define UPDATESPEAKING_TIME_INTERVAL 0.5
#define Model_Head "models/extras/info_speech.mdl"

int g_iHatIndex[MAXPLAYERS+1];			// Player hat entity reference
bool ClientSpeakingTime[MAXPLAYERS+1];
bool g_bExternalCvar[MAXPLAYERS+1];		// If thirdperson view was detected (thirdperson_shoulder cvar)
bool g_bExternalState[MAXPLAYERS+1];	// If thirdperson view was detected
static char SpeakingPlayers[512];
ConVar hSV_Alltalk;
ConVar hSV_VoiceEnable;
int iSV_Alltalk;

public Plugin myinfo = 
{
	name = "[L4D2] Voice Announce + Show MIC Hat.",
	author = "SupermenCJ & Harry Potter ",
	description = "Voice Announce in centr text + create hat to Show Who is speaking.",
	version = "1.3",
	url = "https://steamcommunity.com/id/fbef0102/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}


public void OnPluginStart()
{
	LoadTranslations("show_mic.phrases");
	
	hSV_Alltalk = FindConVar("sv_alltalk");
	hSV_VoiceEnable = FindConVar("sv_voiceenable");

	GetCvars();
	hSV_Alltalk.AddChangeHook(ConVarChanged_Cvars);
	
	HookEvent("round_end", 			Event_RoundEnd);
	HookEvent("player_death", 		Event_PlayerDeath);
	HookEvent("player_team",		Event_PlayerTeam);
	
	CreateTimer(UPDATESPEAKING_TIME_INTERVAL, UpdateSpeaking, _, TIMER_REPEAT);
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	iSV_Alltalk = hSV_Alltalk.IntValue;
}

public void OnPluginEnd()
{
	for( int i = 1; i <= MaxClients; i++ )
		RemoveHat(i);
}

public void OnMapStart()
{
	PrecacheModel(Model_Head, true);
}

public void OnClientSpeakingStart(int client)
{
	if (BaseComm_IsClientMuted(client)) return;

	if (GetClientListeningFlags(client) == 1) return;

	if(hSV_VoiceEnable.BoolValue == false) return;
	
	CreateHat(client);
	ClientSpeakingTime[client] = true;
	
	return;
}

public void OnClientSpeakingEnd(int client)
{
	RemoveHat(client);
	ClientSpeakingTime[client] = false;
}

public Action UpdateSpeaking(Handle timer)
{
	int iCount;
	SpeakingPlayers[0] = '\0';
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (ClientSpeakingTime[i])
		{
			if(IsClientInGame(i))
			{
				Format(SpeakingPlayers, sizeof(SpeakingPlayers), "%s%N\n", SpeakingPlayers, i);
				iCount++;
			}
			else ClientSpeakingTime[i] = false;
		}
	}

	if (iCount > 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i)) PrintCenterText(i, "%T %s", "Players Speaking:", i, SpeakingPlayers);
		}
	}
}

void CreateHat(int client)
{
	if (IsValidEntRef(g_iHatIndex[client]) == true || IsValidClient(client) == false)
	{
		return;
	}
	
	float g_vAng[3];
	float g_vPos[3];
	g_vAng[0] = 0.0;
	g_vAng[1] = 0.0;
	g_vAng[2] = 0.0;
	g_vPos[0] = -3.5;
	g_vPos[1] = 0.0;
	g_vPos[2] = 18.5;
	
	int entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		SetEntityModel(entity, Model_Head);
		DispatchSpawn(entity);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.6, 0);
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);
		SetVariantString("eyes");
		AcceptEntityInput(entity, "SetParentAttachment");
		
		// Lux
		AcceptEntityInput(entity, "DisableCollision");
		SetEntProp(entity, Prop_Send, "m_noGhostCollision", 1, 1);
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0x0004);
		SetEntPropVector(entity, Prop_Send, "m_vecMins", view_as<float>({0.0, 0.0, 0.0}));
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", view_as<float>({0.0, 0.0, 0.0}));
		// Lux
		
		TeleportEntity(entity, g_vPos, g_vAng, NULL_VECTOR);
		SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
		
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 100);
		
		L4D2_SetEntGlow(entity, L4D2Glow_Constant, 2000, 1, {200, 200, 200}, false);
		
		g_iHatIndex[client] = EntIndexToEntRef(entity);
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

void RemoveHat(int client)
{
	int entity = g_iHatIndex[client];
	g_iHatIndex[client] = 0;

	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "kill");
}

public Action Hook_SetTransmit(int entity, int client)
{
	if( EntIndexToEntRef(entity) == g_iHatIndex[client] && g_bExternalCvar[client] == false ) //自己
		return Plugin_Handled;
		
	if(iSV_Alltalk == 0)
	{
		if( GetClientTeam(client) != 2 ) return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void TP_OnThirdPersonChanged(int client, bool bIsThirdPerson)
{
	if( bIsThirdPerson == true && g_bExternalCvar[client] == false )
	{
		g_bExternalCvar[client] = true;
		SetHatView(client, true);
	}
	else if( bIsThirdPerson == false && g_bExternalCvar[client] == true )
	{
		g_bExternalCvar[client] = false;
		SetHatView(client, false);
	}
}

void SetHatView(int client, bool bIsThirdPerson)
{
	if( bIsThirdPerson && !g_bExternalState[client] )
	{
		g_bExternalState[client] = true;

		int entity = g_iHatIndex[client];
		if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	}
	else if( !bIsThirdPerson && g_bExternalState[client] )
	{
		g_bExternalState[client] = false;

		int entity = g_iHatIndex[client];
		if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
		RemoveHat(i);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !client || GetClientTeam(client) != 2 )
		return;

	RemoveHat(client);
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	RemoveHat(client);
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

bool IsValidClient(int client)
{
	if( client && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		return true;
	return false;
}
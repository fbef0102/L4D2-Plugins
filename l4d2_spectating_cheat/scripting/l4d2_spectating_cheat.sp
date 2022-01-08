#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define ENTITY_SAFE_LIMIT 2000 //don't spawn boxes when it's index is above this

ConVar g_hCvarColor;
ConVar g_hCvarColor2;
int g_iCvarColor;
int g_iCvarColor2;

bool bSpecCheatActive[MAXPLAYERS + 1]; //spectatpr open watch
int g_iModelIndex[MAXPLAYERS+1];			// Player Model entity reference

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

public Plugin myinfo = 
{
    name = "l4d2 specating cheat",
    author = "Harry Potter",
    description = "A spectator who watching the survivor at first person view would see the infected model glows though the wall",
    version = "1.9",
    url = "https://steamcommunity.com/id/fbef0102/"
}

public void OnPluginStart()
{
	g_hCvarColor =	CreateConVar(	"l4d2_specting_cheat_ghost_color",		"255 255 255",		"Ghost SI glow color, Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_NOTIFY);
	g_hCvarColor2 =	CreateConVar(	"l4d2_specting_cheat_alive_color",		"255 0 0",			"Alive SI glow color, Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_NOTIFY);
	
	char sColor[16],sColor2[16];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	g_iCvarColor = GetColor(sColor);
	g_hCvarColor2.GetString(sColor2, sizeof(sColor2));
	g_iCvarColor2 = GetColor(sColor2);
	
	g_hCvarColor.AddChangeHook(ConVarChanged_Glow);
	g_hCvarColor2.AddChangeHook(ConVarChanged_Glow_2);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team",	Event_PlayerTeam);
	HookEvent("round_end",			Event_RoundEnd);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	RegConsoleCmd("sm_speccheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_watchcheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_lookcheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_seecheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_meetcheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_starecheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_hellocheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_areyoucheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_fuckyoucheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	
	Clear();
}

public void OnPluginEnd() //unload插件的時候
{
	UnhookEvent("player_spawn", Event_PlayerSpawn);
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_team",		Event_PlayerTeam);
	UnhookEvent("round_end",		Event_RoundEnd);
	
	UnhookEvent("player_disconnect", Event_PlayerDisconnect);
	
	Clear();
}

public Action ToggleSpecCheatCmd(int client, int args) 
{
	if(GetClientTeam(client)!= L4D_TEAM_SPECTATOR)
		return Plugin_Handled;

	bSpecCheatActive[client] = !bSpecCheatActive[client];
	PrintToChat(client, "\x01[\x04WatchMode\x01]\x03 Watch Cheater Mode \x01 is now \x05%s\x01.", (bSpecCheatActive[client] ? "On" : "Off"));

	return Plugin_Handled;
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) && !IsFakeClient(client))
	{
		bSpecCheatActive[client] = false;
	}
}

public void L4D_OnEnterGhostState(int client)
{
	CreateInfectedModelGlow(client);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{ 
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(client && IsClientInGame(client) && GetClientTeam(client) == L4D_TEAM_INFECTED)
	{
		CreateInfectedModelGlow(client);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{ 
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(client && IsClientInGame(client) && GetClientTeam(client) == L4D_TEAM_INFECTED)
	{
		RemoveInfectedModelGlow(client);
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	RemoveInfectedModelGlow(client);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
		RemoveInfectedModelGlow(i);
}

public void CreateInfectedModelGlow(int client)
{
	RemoveInfectedModelGlow(client); //有可能特感變成坦克復活

	if (!client || 
	!IsClientInGame(client) || 
	GetClientTeam(client) != L4D_TEAM_INFECTED || 
	!IsPlayerAlive(client)) return;

	///////設定發光物件//////////
	// Get Client Model
	char sModelName[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
	//PrintToChatAll("%N: %s",client,sModelName);
	
	// Spawn dynamic prop entity
	int entity = CreateEntityByName("prop_dynamic_override");
	if (CheckIfEntityMax( entity ) == false)
		return;

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
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColor);
	else
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColor2);
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

void RemoveInfectedModelGlow(int client)
{
	int entity = g_iModelIndex[client];
	g_iModelIndex[client] = 0;

	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "kill");
}

public Action Hook_SetTransmit(int entity, int client)
{
	if( bSpecCheatActive[client] && GetClientTeam(client) == L4D_TEAM_SPECTATOR)
		return Plugin_Continue;
	
	return Plugin_Handled;
}

int GetColor(char[] sTemp)
{
	if( StrEqual(sTemp, "") )
		return 0;

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

public void ConVarChanged_Glow(Handle convar, const char[] oldValue, const char[] newValue) {
	char sColor[16];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	g_iCvarColor = GetColor(sColor);
	
	int entity;
	for(int i=1; i<=MaxClients ; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==L4D_TEAM_INFECTED && IsPlayerGhost(i))
		{
			entity = g_iModelIndex[i];
			if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			{
				SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColor);
			}
		}
	}
}

public void ConVarChanged_Glow_2(Handle convar, const char[] oldValue, const char[] newValue) {
	char sColor2[16];
	g_hCvarColor2.GetString(sColor2, sizeof(sColor2));
	g_iCvarColor2 = GetColor(sColor2);
	
	int entity;
	for(int i=1; i<=MaxClients ; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==L4D_TEAM_INFECTED && IsPlayerAlive(i) && !IsPlayerGhost(i))
		{
			entity = g_iModelIndex[i];
			if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			{
				SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColor2);
			}
		}
	}
}

bool IsPlayerGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

bool IsValidEntRef(int entity)
{
	if( entity >0 && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE)
		return true;
	return false;
}

void Clear()
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		bSpecCheatActive[i] = false;  
		RemoveInfectedModelGlow(i);
	}
}

bool CheckIfEntityMax(int entity)
{
	if(entity == -1) return false;

	if(	entity > ENTITY_SAFE_LIMIT)
	{
		AcceptEntityInput(entity, "Kill");
		return false;
	}
	return true;
}
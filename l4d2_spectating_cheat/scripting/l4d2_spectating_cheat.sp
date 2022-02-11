#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define ENTITY_SAFE_LIMIT 2000 //don't create model glow when entity index is above this

ConVar g_hCvarColorGhost, g_hCvarColorAlive, g_hCommandAccess;

int g_iCvarColorGhost, g_iCvarColorAlive;
char g_sCommandAccesslvl[16];

bool g_bMapStarted;
static bool bSpecCheatActive[MAXPLAYERS + 1]; //spectatpr open watch
int g_iModelIndex[MAXPLAYERS+1];			// Player Model entity reference

bool g_bLateLoad;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	g_bLateLoad = late;
	return APLRes_Success; 
}

public Plugin myinfo = 
{
    name = "l4d2 specating cheat",
    author = "Harry Potter",
    description = "A spectator who watching the survivor at first person view would see the infected model glows though the wall",
    version = "2.1",
    url = "https://steamcommunity.com/id/fbef0102/"
}

public void OnPluginStart()
{
	g_hCvarColorGhost =	CreateConVar(	"l4d2_specting_cheat_ghost_color",		"255 255 255",		"Ghost SI glow color, Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_NOTIFY);
	g_hCvarColorAlive =	CreateConVar(	"l4d2_specting_cheat_alive_color",		"255 0 0",			"Alive SI glow color, Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_NOTIFY);
	g_hCommandAccess = 	CreateConVar(	"l4d2_specting_cheat_use_command_flag", "z", 				"Players with these flags have access to use command to toggle Speatator watching cheat. (Empty = Everyone, -1: Nobody)", FCVAR_NOTIFY);

	GetCvars();
	g_hCvarColorGhost.AddChangeHook(ConVarChanged_Glow_Ghost);
	g_hCvarColorAlive.AddChangeHook(ConVarChanged_Glow_Alive);
	g_hCommandAccess.AddChangeHook(ConVarChanged_Access);

	//Autoconfig for plugin
	AutoExecConfig(true, "l4d2_specting_cheat");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team",	Event_PlayerTeam);
	HookEvent("round_end",			Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_RoundEnd, EventHookMode_PostNoCopy); //戰役模式下過關到下一關的時候 (沒有觸發round_end)
	HookEvent("mission_lost", Event_RoundEnd, EventHookMode_PostNoCopy); //戰役模式下滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", Event_RoundEnd, EventHookMode_PostNoCopy); //救援載具離開之時  (沒有觸發round_end)
	
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		bSpecCheatActive[i] = false;
	}
	
	if(g_bLateLoad)
	{
		g_bMapStarted = true;
		CreateAllModelGlow();
	}
}

public void OnPluginEnd() //unload插件的時候
{
	RemoveAllModelGlow();
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public Action ToggleSpecCheatCmd(int client, int args) 
{
	if(client == 0 || GetClientTeam(client)!= L4D_TEAM_SPECTATOR)
		return Plugin_Handled;
	
	if(HasAccess(client, g_sCommandAccesslvl))
	{
		bSpecCheatActive[client] = !bSpecCheatActive[client];
		PrintToChat(client, "\x01[\x04WatchMode\x01]\x03 Watch Cheater Mode \x01 is now \x05%s\x01.", (bSpecCheatActive[client] ? "On" : "Off"));
		
		if(bSpecCheatActive[client] == false)
		{
			RemoveAllModelGlow();
			CreateAllModelGlow();
		}
	}
	else
	{
		PrintToChat(client, "\x01[\x04WatchMode\x01]\x03 You don't have access.");
	}

	return Plugin_Handled;
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	bSpecCheatActive[client] = false;
}

public void L4D_OnEnterGhostState(int client)
{
	CreateInfectedModelGlow(client);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{ 
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	RemoveInfectedModelGlow(client); //有可能特感變成坦克復活
	CreateInfectedModelGlow(client);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{ 
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	RemoveInfectedModelGlow(client);
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int oldteam = event.GetInt("oldteam");
	
	RemoveInfectedModelGlow(client);
	
	if(client && IsClientInGame(client) && !IsFakeClient(client) && oldteam == L4D_TEAM_SPECTATOR && bSpecCheatActive[client])
	{
		RemoveAllModelGlow();
		CreateAllModelGlow();
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	RemoveAllModelGlow();
}

public void CreateInfectedModelGlow(int client)
{
	if (!client || 
	!IsClientInGame(client) || 
	GetClientTeam(client) != L4D_TEAM_INFECTED || 
	!IsPlayerAlive(client) ||
	g_bMapStarted == false) return;

	///////設定發光物件//////////
	// Spawn dynamic prop entity
	int entity = CreateEntityByName("prop_dynamic_ornament");
	
	if (CheckIfEntityMax( entity ) == false)
		return;
		
	// Delete previous glow first just in case
	RemoveInfectedModelGlow(client);
	
	// Get Client Model
	char sModelName[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
	//PrintToChatAll("%N: %s",client,sModelName);

	// Set new fake model
	//PrecacheModel(sModelName);
	SetEntityModel(entity, sModelName);
	DispatchSpawn(entity);

	// Set outline glow color
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", 4500);
	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	if(IsPlayerGhost(client))
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColorGhost);
	else
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColorAlive);
	AcceptEntityInput(entity, "StartGlowing");

	// Set model invisible
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	
	// Set model attach to client, and always synchronize
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetAttached", client);
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

public void ConVarChanged_Glow_Ghost(Handle convar, const char[] oldValue, const char[] newValue) {
	GetCvars();

	int entity;
	for(int i=1; i<=MaxClients ; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==L4D_TEAM_INFECTED && IsPlayerGhost(i))
		{
			entity = g_iModelIndex[i];
			if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			{
				SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColorGhost);
			}
		}
	}
}

public void ConVarChanged_Glow_Alive(Handle convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
	
	int entity;
	for(int i=1; i<=MaxClients ; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==L4D_TEAM_INFECTED && IsPlayerAlive(i) && !IsPlayerGhost(i))
		{
			entity = g_iModelIndex[i];
			if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			{
				SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColorAlive);
			}
		}
	}
}

public void ConVarChanged_Access(Handle convar, const char[] oldValue, const char[] newValue) {
	GetCvars();

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			if(HasAccess(i, g_sCommandAccesslvl) == false) bSpecCheatActive[i] = false;
			
			
			RemoveAllModelGlow();
			CreateAllModelGlow();
		}
	}
}

void GetCvars()
{
	char sColor[16],sColor2[16];
	g_hCvarColorGhost.GetString(sColor, sizeof(sColor));
	g_iCvarColorGhost = GetColor(sColor);
	g_hCvarColorAlive.GetString(sColor2, sizeof(sColor2));
	g_iCvarColorAlive = GetColor(sColor2);
	g_hCommandAccess.GetString(g_sCommandAccesslvl,sizeof(g_sCommandAccesslvl));
}

bool IsPlayerGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE)
		return true;
	return false;
}

void RemoveAllModelGlow()
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		RemoveInfectedModelGlow(i);
	}
}

void CreateAllModelGlow()
{
	if (g_bMapStarted == false) return;
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		CreateInfectedModelGlow(i);
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

public bool HasAccess(int client, char[] g_sAcclvl)
{
	// no permissions set
	if (strlen(g_sAcclvl) == 0)
		return true;

	else if (StrEqual(g_sAcclvl, "-1"))
		return false;

	// check permissions
	if ( GetUserFlagBits(client) & ReadFlagString(g_sAcclvl) )
	{
		return true;
	}

	return false;
}
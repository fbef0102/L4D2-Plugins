#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>
#define DEBUG 0


#define Timer_KeepPlayerDeath_Seconds 1.0

//survivor
#define L4D_TEAM_SURVIVOR 2
enum ModelID
{
	MODEL_NONE,
	MODEL_NICK,
	MODEL_ROCHELLE,
	MODEL_COACH,
	MODEL_ELLIS,
	MODEL_BILL,
	MODEL_ZOEY,
	MODEL_FRANCIS,
	MODEL_LOUIS,
	MODEL_MAX
}

//cvars
ConVar hEnable;
bool g_bEnable;

//value
bool bDeath_Model[MODEL_MAX];
char sModel_Name[MODEL_MAX][PLATFORM_MAX_PATH];		
static bool b_LeftSaveRoom;
							
public Plugin:myinfo = 
{
	name = "L4D2 death survivor",
	author = "Harry Potter",
	description = "If a player die as a survivor, this model survior bot keep death until map change or server shutdown",
	version = "1.2",
	url = "Harry Potter myself,you bitch shit"
};

public void OnPluginStart()
{
	if(!IsL4D2Game())
		SetFailState("Use this Left 4 Dead 2 only.");
		
	hEnable	= CreateConVar("l4d2_enable_death_survivor", "1", 	"enable this plugin?[1-Enable,0-Disable]" , FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bEnable  = GetConVarBool(hEnable);
	HookConVarChange(hEnable, ConVarChange_hEnable);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_bot_replace", Event_OnBotSwap);
	HookEvent("bot_player_replace", Event_OnBotSwap);
	HookEvent("round_start", Event_RoundStart);
	
	SetCharacterName();
}

void SetCharacterName()
{
	b_LeftSaveRoom = false;
	sModel_Name[MODEL_NICK] = "models/survivors/survivor_gambler.mdl";
	sModel_Name[MODEL_ROCHELLE] = "models/survivors/survivor_producer.mdl";
	sModel_Name[MODEL_COACH] = "models/survivors/survivor_coach.mdl";
	sModel_Name[MODEL_ELLIS] = "models/survivors/survivor_mechanic.mdl";
	sModel_Name[MODEL_BILL] = "models/survivors/survivor_namvet.mdl";
	sModel_Name[MODEL_ZOEY] = "models/survivors/survivor_teenangst.mdl";
	sModel_Name[MODEL_FRANCIS] = "models/survivors/survivor_biker.mdl";
	sModel_Name[MODEL_LOUIS] = "models/survivors/survivor_manager.mdl";
	
	for(ModelID i = MODEL_NICK ; i < MODEL_MAX ; ++i)
	{
		bDeath_Model[i] = false;
	}
}

public OnMapStart()
{
	if(IsNewMission())
	{
		for(ModelID i = MODEL_NICK ; i < MODEL_MAX ; ++i)
		{
			bDeath_Model[i] = false;
		}
	}
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	b_LeftSaveRoom = false;
	
	CreateTimer(1.0, PlayerLeftStart, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action PlayerLeftStart(Handle Timer)
{
	if (LeftStartArea() || b_LeftSaveRoom) // We don't care who left, just that at least one did
	{	
		#if DEBUG
			PrintToChatAll("Player has Left SaveRoom");
		#endif
		if (!b_LeftSaveRoom)
		{
			b_LeftSaveRoom = true;
		}
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public OnRoundIsLive()
{
	if(g_bEnable == false) return;
	
	#if DEBUG
		PrintToChatAll("OnRoundIsLive");
	#endif	
	
	if (!b_LeftSaveRoom)
	{
		b_LeftSaveRoom = true;
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientSurvivorIndex(client)&&IsPlayerAlive(client))
		{
			CreateTimer(Timer_KeepPlayerDeath_Seconds,Timer_KeepPlayerDeath,client,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientSurvivorIndex(client)||
		g_bEnable == false || //disable this plugin
		b_LeftSaveRoom == false)
		return Plugin_Continue;

	CreateTimer(0.5,Timer_CheckPlayerDeath,client,TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action Timer_CheckPlayerDeath(Handle timer,int client)
{
	if (!IsClientSurvivorIndex(client)||
		IsPlayerAlive(client))
		return Plugin_Continue;
		
	char sModelName[PLATFORM_MAX_PATH];
	GetClientModel(client, sModelName, sizeof(sModelName));
	#if DEBUG
		PrintToChatAll("Event_PlayerDeath timer check: %N - sModelName: %s",client,sModelName);
	#endif
	
	ModelID modelId = GetModelID(sModelName);
	bDeath_Model[modelId] = true;
	
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientSurvivorIndex(client)||
		g_bEnable == false || //disable this plugin
		b_LeftSaveRoom == false)
		return Plugin_Continue;
		
	#if DEBUG
		PrintToChatAll("Event_PlayerSpawn: %N",client);
	#endif	
	
	CreateTimer(Timer_KeepPlayerDeath_Seconds,Timer_KeepPlayerDeath,client,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action Timer_KeepPlayerDeath(Handle timer,int client)
{
	if(!IsClientSurvivorIndex(client)) return Plugin_Stop;
	
	if(IsPlayerAlive(client))
	{
		char sModelName[PLATFORM_MAX_PATH];
		GetClientModel(client, sModelName, sizeof(sModelName));
		#if DEBUG
			PrintToChatAll("Timer_KeepPlayerDeath: %N - sModelName: %s",client,sModelName);
		#endif
		ModelID modelId = GetModelID(sModelName);
		if(bDeath_Model[modelId] == true)
		{
			ForcePlayerSuicide(client);
			//CPrintToChat(client,"[{olive}水仙摸魚{default}] {green}Surprise Dead, Mother Fucker!");
		}
		else
		{
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action Event_OnBotSwap(Handle event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
	int player = GetClientOfUserId(GetEventInt(event, "player"));
	int client;
	
	if (!IsClientSurvivorIndex(bot)||
		!IsClientSurvivorIndex(player)||
		g_bEnable == false || //disable this plugin
		b_LeftSaveRoom == false)
		return Plugin_Continue;
		
	char sModelName[PLATFORM_MAX_PATH];
	
	if (StrEqual(name, "player_bot_replace")) //When a bot replaces a player (i.e. player switches to spectate or infected)
	{
		GetClientModel(bot, sModelName, sizeof(sModelName));
		#if DEBUG
			PrintToChatAll("When a bot replaces a player: %N - sModelName: %s",bot,sModelName);
		#endif
		client = bot;
	}
	else // When a player replaces a bot (i.e. player joins survivors team)
	{
		GetClientModel(player, sModelName, sizeof(sModelName));
		#if DEBUG
			PrintToChatAll("player joins survivors team: %N - sModelName: %s",player,sModelName);
		#endif
		client = player;
	}
		
	CreateTimer(Timer_KeepPlayerDeath_Seconds,Timer_KeepPlayerDeath,client,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

stock ModelID GetModelID(const char[] model_name)
{
	for(ModelID i = MODEL_NICK ; i < MODEL_MAX ; ++i)
	{
		if(StrEqual(model_name,sModel_Name[i],false))
			return i;
	}
	return ModelID:MODEL_NONE;
}

stock bool IsClientSurvivorIndex(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == L4D_TEAM_SURVIVOR);
}

stock bool IsNewMission()
{
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);
	return StrContains(sMap, "m1_") != -1;
}

stock bool IsL4D2Game()
{
	decl String:sGameFolder[32];
	GetGameFolderName(sGameFolder, 32);
	return StrEqual(sGameFolder, "left4dead2");
}

bool LeftStartArea()
{
	int ent = -1, maxents = GetMaxEntities();
	for (int i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
		{
			return true;
		}
	}
	return false;
}

public void ConVarChange_hEnable(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_bEnable  = GetConVarBool(hEnable);
}
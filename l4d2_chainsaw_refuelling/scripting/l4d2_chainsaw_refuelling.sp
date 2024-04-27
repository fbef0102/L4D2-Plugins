#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <multicolors>

#define PLUGIN_VERSION "1.0h-2024/4/27"

public Plugin myinfo = 
{
	name = "Chainsaw Refuelling",
	author = "DJ_WEST, Lossy (Round Start Fix), Shao (downstate support), HarryPotter (Improve)",
	description = "Allow refuelling of a chainsaw",
	version = PLUGIN_VERSION,
	url = "https://github.com/fbef0102/L4D2-Plugins/tree/master/l4d2_chainsaw_refuelling"
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

#define CHAINSAW_DISTANCE 50.0
#define CHAINSAW "chainsaw"
#define CHAINSAW_CLASS "weapon_chainsaw"
#define CHAINSAW_SPAWN_CLASS "weapon_chainsaw_spawn"
#define GASCAN_CLASS "weapon_gascan"
#define GASCAN_SKIN 0
#define TEAM_SURVIVOR 2

ConVar g_hCvarEnable, g_hCvarRemove, g_hCvarMode, g_hCvarDrop, g_hCvarHint;
bool g_bCvarEnable, g_bCvarRemove, g_bCvarDrop, g_bCvarHint;
int g_iCvarMode;

bool 
	g_ClientInfo[MAXPLAYERS+1], g_b_IsSurvivor[MAXPLAYERS+1], g_b_AllowChecking[MAXPLAYERS+1], g_b_InAction[MAXPLAYERS+1];

Handle 
	g_Timer[MAXPLAYERS+1];

int 
	g_iChainsawMaxClip,
	g_ActiveWeaponOffset, 
	g_ShotsFiredOffset, 
	g_ClientPour[MAXPLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations("chainsaw_refuelling.phrases");

	g_hCvarEnable 	= CreateConVar( "l4d2_chainsaw_refuelling_enable", 		"1", "Chainsaw Refuelling plugin status (0 - Disable, 1 - Enable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarRemove 	= CreateConVar( "l4d2_chainsaw_refuelling_remove", 		"0", "If 1, Remove a chainsaw if it empty", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarMode 	= CreateConVar( "l4d2_chainsaw_refuelling_mode", 		"2", "Allow refuelling of a chainsaw (0 - On the ground, 1 - On players, 2 - Both)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_hCvarDrop 	= CreateConVar( "l4d2_chainsaw_refuelling_drop", 		"1", "If 1, Enable dropping a chainsaw with Reload button", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarHint		= CreateConVar( "l4d2_chainsaw_refuelling_hint", 		"1", "If 1, Enable hint message", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar(					"l4d2_chainsaw_refuelling_version", 	PLUGIN_VERSION, "Chainsaw Refuelling version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	AutoExecConfig(true, 			"l4d2_chainsaw_refuelling");
	
	GetCvars();
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRemove.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMode.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDrop.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHint.AddChangeHook(ConVarChanged_Cvars);

	HookEvent("gascan_pour_completed", EventPourCompleted);
	HookEvent("item_pickup", EventItemPickup);
	HookEvent("player_team", EventPlayerTeam);
	HookEvent("player_incapacitated", EventAllowChecking);
	HookEvent("lunge_pounce", EventNotAllowChecking);
	HookEvent("jockey_ride", EventNotAllowChecking);
	HookEvent("tongue_grab", EventNotAllowChecking);
	HookEvent("charger_carry_start", EventNotAllowChecking);
	HookEvent("charger_pummel_start", EventNotAllowChecking);
	HookEvent("player_ledge_grab", EventNotAllowChecking);
	HookEvent("player_death", EventNotAllowChecking);
	HookEvent("revive_success", EventAllowChecking);
	HookEvent("defibrillator_used", EventAllowChecking);
	HookEvent("pounce_stopped", EventAllowChecking);
	HookEvent("jockey_ride_end", EventAllowChecking);
	HookEvent("tongue_release", EventAllowChecking);
	HookEvent("charger_carry_end", EventAllowChecking);
	HookEvent("charger_pummel_end", EventAllowChecking);
	HookEvent("round_start", EventRoundStart);
	HookEvent("round_end", evtRoundEnd, EventHookMode_PostNoCopy); //對抗上下回合結束的時候觸發
	HookEvent("map_transition", evtRoundEnd, EventHookMode_PostNoCopy); //戰役過關到下一關的時候 (之後沒有觸發round_end)
	HookEvent("mission_lost", evtRoundEnd, EventHookMode_PostNoCopy); //戰役滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", evtRoundEnd, EventHookMode_PostNoCopy); //救援載具離開之時  (之後沒有觸發round_end)
	
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	g_ShotsFiredOffset = FindSendPropInfo("CCSPlayer", "m_iShotsFired");

	AddCommandListener(CmdListen_weapon_reparse_server, "weapon_reparse_server");
}

// Cvars-------------------------------

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarEnable = g_hCvarEnable.BoolValue;
	g_bCvarRemove = g_hCvarRemove.BoolValue;
	g_iCvarMode = g_hCvarMode.IntValue;
	g_bCvarDrop = g_hCvarDrop.BoolValue;
	g_bCvarHint = g_hCvarHint.BoolValue;
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_b_AllowChecking[i] = false;
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			g_b_AllowChecking[i] = true;
		}
	}
}

public void OnMapEnd()
{
	ResetTimer();
}

public void OnConfigsExecuted()
{
	GetChainsawMaxClip();
}

Action CmdListen_weapon_reparse_server(int client, const char[] command, int argc)
{
	RequestFrame(OnNextFrame_weapon_reparse_server);

	return Plugin_Continue;
}

void OnNextFrame_weapon_reparse_server()
{
	GetChainsawMaxClip();
}

void GetChainsawMaxClip()
{
	g_iChainsawMaxClip = L4D2_GetIntWeaponAttribute(CHAINSAW_CLASS, L4D2IWA_ClipSize);
}

void EventRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

void evtRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetTimer();
}

void EventNotAllowChecking(Event event, const char[] name, bool dontBroadcast) 
{
	int i_UserID, i_Client;
	
	if (event.GetInt("victim"))
		i_UserID = event.GetInt("victim");
	else
		i_UserID = event.GetInt("userid");
	
	i_Client = GetClientOfUserId(i_UserID);
	
	if (g_b_IsSurvivor[i_Client])
		g_b_AllowChecking[i_Client] = false;
}

void EventAllowChecking(Event event, const char[] name, bool dontBroadcast) 
{
	int i_UserID, i_Client;
	
	if (event.GetInt("victim"))
		i_UserID = event.GetInt("victim");
	else if (event.GetInt("subject"))
		i_UserID = event.GetInt("subject");
	else
		i_UserID = event.GetInt("userid");
	
	i_Client = GetClientOfUserId(i_UserID);
	
	if (g_b_IsSurvivor[i_Client])
		g_b_AllowChecking[i_Client] = true;
	
}

void EventPlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	if (!event.GetBool("isbot"))
	{
		int i_UserID, i_Client;
	
		i_UserID = event.GetInt("userid");
		i_Client = GetClientOfUserId(i_UserID);
		
		if (event.GetInt("team") == TEAM_SURVIVOR)
		{
			g_b_IsSurvivor[i_Client] = true;
			g_b_AllowChecking[i_Client] = true;
		}
		else
		{
			g_b_IsSurvivor[i_Client] = false;
			g_b_AllowChecking[i_Client] = false;
		}
	}
}

void EventItemPickup(Event event, const char[] name, bool dontBroadcast) 
{
	if(!g_bCvarEnable) return;

	int i_UserID, i_Client;
	char s_Weapon[16];
	
	i_UserID = event.GetInt("userid");
	i_Client = GetClientOfUserId(i_UserID);

	event.GetString("item", s_Weapon, sizeof(s_Weapon));

	if (StrEqual(s_Weapon, CHAINSAW))
	{
		if (!g_ClientInfo[i_Client])
		{
			if(g_bCvarHint)
			{
				CPrintToChat(i_Client, "{green}%t{default} %t.", "Information", "Refuelling");
				CPrintToChat(i_Client, "{green}%t{default} %t.", "Information", "Drop");
			}
			g_ClientInfo[i_Client] = true;
		}
	}
}

void EventPourCompleted(Event event, const char[] name, bool dontBroadcast) 
{
	if(!g_bCvarEnable) return;

	int i_UserID, i_Client, i_Ent;
	
	i_UserID = event.GetInt("userid");
	i_Client = GetClientOfUserId(i_UserID);
	
	if(IsValidEntRef(g_ClientPour[i_Client]))
	{	
		i_Ent = EntRefToEntIndex(g_ClientPour[i_Client]);
		SetEntProp(i_Ent, Prop_Data, "m_iClip1", g_iChainsawMaxClip);
	}
}

public void OnClientPutInServer(int i_Client)
{
	if (IsFakeClient(i_Client))
		return;
		
	g_ClientPour[i_Client] = 0;
	g_ClientInfo[i_Client] = false;
	g_b_IsSurvivor[i_Client] = false;
	g_b_AllowChecking[i_Client] = true;
	g_b_InAction[i_Client] = false;
}

public void OnClientDisconnect(int client)
{
	if(!IsClientInGame(client)) return;
	
	g_ClientPour[client] = 0;
	delete g_Timer[client];
}

void CheckTarget(int i_Client)
{
	int i_Ent;
	char s_Class[64];

	i_Ent = GetClientAimTarget(i_Client, false);
	
	if (i_Ent > 0 && IsValidEntity(i_Ent))
	{
		GetEntityClassname(i_Ent, s_Class, sizeof(s_Class));
		//PrintToChatAll("CheckTarget %s", s_Class);
		
		if (StrEqual(s_Class, CHAINSAW_SPAWN_CLASS) && g_iCvarMode != 1)
		{
			if(g_bCvarHint) CPrintToChat(i_Client, "{lightgreen}%t{default} %t.", "Information", "Full");
		}
		else if (StrEqual(s_Class, CHAINSAW_CLASS) && g_iCvarMode != 1)
		{
			CheckChainsaw(i_Client, i_Ent, -1);
		}
		else if (StrEqual(s_Class, "player") && g_iCvarMode != 0)
		{
			int i_Weapon;
			static char s_Weapon[64];
			
			i_Weapon = GetEntDataEnt2(i_Ent, g_ActiveWeaponOffset);
			if(IsValidEnt(i_Weapon))
			{
				GetEntityClassname(i_Weapon, s_Weapon, sizeof(s_Weapon));
				if (StrEqual(s_Weapon, CHAINSAW_CLASS))
					CheckChainsaw(i_Client, i_Weapon, i_Ent);
			}
		}
	}
}

void CheckChainsaw(int i_Client, int i_Weapon, int i_Ent)
{
	float f_EntPos[3], f_ClientPos[3];
	
	GetEntPropVector(i_Ent == -1 ? i_Weapon : i_Ent, Prop_Send, "m_vecOrigin", f_EntPos);
	GetClientAbsOrigin(i_Client, f_ClientPos);
			
	if (GetVectorDistance(f_EntPos, f_ClientPos) <= CHAINSAW_DISTANCE)
	{
		int i_PointEnt, i_ChainsawPointEnt, i_Clip;
				
		i_Clip = GetEntProp(i_Weapon, Prop_Data, "m_iClip1");
				
		if (i_Clip == g_iChainsawMaxClip)
		{
			if(g_bCvarHint) CPrintToChat(i_Client, "{lightgreen}%t{default} %t.", "Information", "Full");
			return;
		}
				
		i_ChainsawPointEnt = EntRefToEntIndex(GetEntProp(i_Weapon, Prop_Data, "m_iClip2"));
				
		if (i_ChainsawPointEnt == INVALID_ENT_REFERENCE || i_ChainsawPointEnt <= MaxClients)
		{
			i_PointEnt = (i_Ent == -1) ? CreatePointEntity(i_Weapon, 10.0) : CreatePointEntity(i_Ent, 50.0);
				
			if (IsValidEnt(i_PointEnt))
			{
				SetEntProp(i_Weapon, Prop_Data, "m_iClip2", EntIndexToEntRef(i_PointEnt));
				g_ClientPour[i_Client] = EntIndexToEntRef(i_Weapon);
					
				DataPack data;
				g_Timer[i_Client] = CreateDataTimer(0.5, Timer_CheckPourGascan, data, TIMER_REPEAT);
				data.WriteCell(GetClientUserId(i_Client));
				data.WriteCell(EntIndexToEntRef(i_Weapon));
			}
		}
	}
}

Action Timer_CheckPourGascan(Handle h_Timer, DataPack data)
{
	int i_Client, i_Ent, i_PointEnt, i_ShotsFired;

	data.Reset();
	i_Client = GetClientOfUserId(data.ReadCell());
	i_Ent = EntRefToEntIndex(data.ReadCell());
	
	if(!i_Client || !IsClientInGame(i_Client))
	{
		g_ClientPour[i_Client] = 0;
		g_Timer[i_Client] = null;
		return Plugin_Stop;
	}
	if(i_Ent == INVALID_ENT_REFERENCE)
	{
		g_ClientPour[i_Client] = 0;
		g_Timer[i_Client] = null;
		return Plugin_Stop;
	}
	
	i_PointEnt = GetEntProp(i_Ent, Prop_Data, "m_iClip2");
	i_ShotsFired = GetEntData(i_Client, g_ShotsFiredOffset);
	
	if (i_ShotsFired == 0)
	{
		if(IsValidEnt(i_PointEnt)) RemoveEdict(i_PointEnt);
		SetEntProp(i_Ent, Prop_Data, "m_iClip2", -1);
		
		g_ClientPour[i_Client] = 0;
		g_Timer[i_Client] = null;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

int CreatePointEntity(int i_Ent, float f_Add)
{
	float f_Position[3];
	int i_PointEnt;
	
	GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Position);
	f_Position[2] += f_Add;
	
	i_PointEnt = CreateEntityByName("point_prop_use_target");
	DispatchKeyValueVector(i_PointEnt, "origin", f_Position);
	DispatchKeyValue(i_PointEnt, "nozzle", "gas_nozzle");
	DispatchSpawn(i_PointEnt);
	
	return i_PointEnt;
}

public Action OnPlayerRunCmd(int i_Client, int &i_Buttons, int &i_Impulse, float f_Velocity[3], float f_Angles[3], int &i_Wpn)
{
	if (!g_bCvarEnable)
		return Plugin_Continue;
		
	if (!g_b_AllowChecking[i_Client])
		return Plugin_Continue;
		
	if (g_b_InAction[i_Client] && (i_Buttons & IN_ATTACK || i_Buttons & IN_USE || i_Buttons & IN_RELOAD))
		return Plugin_Continue;
	else if (g_b_InAction[i_Client])
		g_b_InAction[i_Client] = false;

	if (IsValidEntRef(g_ClientPour[i_Client]))
		return Plugin_Continue;
	
	int i_Weapon;
	
	if (i_Buttons & IN_ATTACK)
	{
		char s_Weapon[32];
		int i_Skin;
		
		i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset);
		
		if (!IsValidEnt(i_Weapon)) return Plugin_Continue;
		
		GetEntityClassname(i_Weapon, s_Weapon, sizeof(s_Weapon));
		i_Skin = GetEntProp(i_Weapon, Prop_Send, "m_nSkin");
		
		if (StrEqual(s_Weapon, GASCAN_CLASS) && i_Skin == GASCAN_SKIN)
		{
			CheckTarget(i_Client);
		}
		else if (StrEqual(s_Weapon, CHAINSAW_CLASS) && !g_bCvarRemove)
		{
			if (GetEntProp(i_Weapon, Prop_Data, "m_iClip1") <= 1)
			{
				i_Buttons &= ~IN_ATTACK;
				return Plugin_Changed;
			}
		}
		else
			g_b_InAction[i_Client] = true;
	}
	
	if (i_Buttons & IN_USE)
	{
		i_Weapon = GetClientAimTarget(i_Client, false);
		
		if (IsValidEnt(i_Weapon))
		{
			g_b_InAction[i_Client] = true;
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (g_ClientPour[i] && EntRefToEntIndex(g_ClientPour[i]) == i_Weapon)
				{
					i_Buttons &= ~IN_USE;
					return Plugin_Changed;
				}
			}
				
			return Plugin_Continue;
		}
	}
	
	if (i_Buttons & IN_RELOAD)
	{
		i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset);
		
		if (IsValidEnt(i_Weapon))
		{
			char s_Weapon[32];
			GetEntityClassname(i_Weapon, s_Weapon, sizeof(s_Weapon));
			if (StrEqual(s_Weapon, CHAINSAW_CLASS) && g_bCvarDrop)
			{
				SDKHooks_DropWeapon(i_Client, i_Weapon);
			}
		}
		
		g_b_InAction[i_Client] = true;
	}
	
	return Plugin_Continue;
}

bool IsValidEnt(int i_Ent)
{
	return (i_Ent > MaxClients && IsValidEntity(i_Ent));
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

void ResetTimer()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		delete g_Timer[i];
	}
}

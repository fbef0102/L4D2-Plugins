// 2010 @ DJ_WEST
// 2020 @ Lossy & Shao
// 2022 @ Harry

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1; // Force strict semicolon mode.
#pragma newdecls required; // Force new-style declarations.

#define PLUGIN_NAME "Chainsaw Refuelling"
#define PLUGIN_VERSION "1.6.3"
#define PLUGIN_AUTHOR "DJ_WEST, Lossy (Round Start Fix), Shao (downstate support), Harry (Improve)"

#define CHAINSAW_DISTANCE 50.0
#define CHAINSAW "chainsaw"
#define CHAINSAW_CLASS "weapon_chainsaw"
#define CHAINSAW_SPAWN_CLASS "weapon_chainsaw_spawn"
#define GASCAN_CLASS "weapon_gascan"
#define GASCAN_SKIN 0
#define TEAM_SURVIVOR 2

int g_ActiveWeaponOffset, g_ShotsFiredOffset, g_ClientPour[MAXPLAYERS+1], g_PlayerPistol[MAXPLAYERS+1];
Handle g_Timer[MAXPLAYERS+1], h_CvarEnabled, h_CvarRemove, h_CvarMode, h_CvarDrop;
bool g_ClientInfo[MAXPLAYERS+1], g_b_IsSurvivor[MAXPLAYERS+1], g_b_AllowChecking[MAXPLAYERS+1], g_b_InAction[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Allow refuelling of a chainsaw",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=121983"
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
	LoadTranslations("chainsaw_refuelling.phrases");
	
	//汉化者:心动
	// CreateConVar("refuelchainsaw_version", PLUGIN_VERSION, "插件版本", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// h_CvarEnabled = CreateConVar("l4d2_refuelchainsaw_enabled", "1", "开启/关闭 电锯加油", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	// h_CvarRemove = CreateConVar("l4d2_refuelchainsaw_remove", "0", "如果电锯没油了,是否会消失(0.不消失 1.消失)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	// h_CvarMode = CreateConVar("l4d2_refuelchainsaw_mode", "2", "允许电锯如何加油 (0 - 在地上, 1 - 在幸存者身上, 2 - 两者皆可)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	// h_CvarDrop = CreateConVar("l4d2_refuelchainsaw_drop", "1", "电锯是否可以扔下，按下Ｒ键 (0 - 关闭, 1 - 可以)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	CreateConVar("refuelchainsaw_version", PLUGIN_VERSION, "Chainsaw Refuelling version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_CvarEnabled = CreateConVar("l4d2_refuelchainsaw_enabled", "1", "Chainsaw Refuelling plugin status (0 - disable, 1 - enable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_CvarRemove = CreateConVar("l4d2_refuelchainsaw_remove", "0", "Remove a chainsaw if it empty (0 - don't remove, 1 - remove)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_CvarMode = CreateConVar("l4d2_refuelchainsaw_mode", "2", "Allow refuelling of a chainsaw (0 - on the ground, 1 - on players, 2 - both)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	h_CvarDrop = CreateConVar("l4d2_refuelchainsaw_drop", "1", "Enable dropping a chainsaw with Reload button (0 - disable, 1 - enable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "l4d2_chainsaw_refuelling");
	
	
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

public void EventRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

public void evtRoundEnd (Event event, const char[] name, bool dontBroadcast)
{
	ResetTimer();
}

public void EventNotAllowChecking(Handle h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int i_UserID, i_Client;
	
	if (GetEventInt(h_Event, "victim"))
		i_UserID = GetEventInt(h_Event, "victim");
	else
		i_UserID = GetEventInt(h_Event, "userid");
	
	i_Client = GetClientOfUserId(i_UserID);
	
	if (g_b_IsSurvivor[i_Client])
		g_b_AllowChecking[i_Client] = false;
}

public void EventAllowChecking(Handle h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int i_UserID, i_Client;
	
	if (GetEventInt(h_Event, "victim"))
		i_UserID = GetEventInt(h_Event, "victim");
	else if (GetEventInt(h_Event, "subject"))
		i_UserID = GetEventInt(h_Event, "subject");
	else
		i_UserID = GetEventInt(h_Event, "userid");
	
	i_Client = GetClientOfUserId(i_UserID);
	
	if (g_b_IsSurvivor[i_Client])
		g_b_AllowChecking[i_Client] = true;
	
}

public void EventPlayerTeam(Handle h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	if (!GetEventBool(h_Event, "isbot"))
	{
		int i_UserID, i_Client;
	
		i_UserID = GetEventInt(h_Event, "userid");
		i_Client = GetClientOfUserId(i_UserID);
		
		if (GetEventInt(h_Event, "team") == TEAM_SURVIVOR)
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

public void EventItemPickup(Handle h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int i_UserID, i_Client;
	char s_Weapon[16];
	
	i_UserID = GetEventInt(h_Event, "userid");
	i_Client = GetClientOfUserId(i_UserID);

	GetEventString(h_Event, "item", s_Weapon, sizeof(s_Weapon));

	if (StrEqual(s_Weapon, CHAINSAW))
	{
		if(IsValidEntRef(g_PlayerPistol[i_Client]))
		{
			int i_Pistol = EntRefToEntIndex(g_PlayerPistol[i_Client]);
			if (i_Pistol != INVALID_ENT_REFERENCE)
			{
				RemoveEdict(i_Pistol);
				g_PlayerPistol[i_Client] = 0;
			}
		}
		
		if (!g_ClientInfo[i_Client] && GetConVarBool(h_CvarEnabled))
		{
			PrintToChat(i_Client, "\x03[%t]\x01 %t.", "Information", "Refuelling");
			PrintToChat(i_Client, "\x03[%t]\x01 %t.", "Information", "Drop");
			g_ClientInfo[i_Client] = true;
		}
	}
}

public void EventPourCompleted(Handle h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int i_UserID, i_Client, i_Ent;
	
	i_UserID = GetEventInt(h_Event, "userid");
	i_Client = GetClientOfUserId(i_UserID);
	
	if(IsValidEntRef(g_ClientPour[i_Client]))
	{	
		i_Ent = EntRefToEntIndex(g_ClientPour[i_Client]);
		SetEntProp(i_Ent, Prop_Data, "m_iClip1", 30);
	}
}

public void OnClientPutInServer(int i_Client)
{
	if (IsFakeClient(i_Client))
		return;
		
	g_ClientPour[i_Client] = 0;
	g_PlayerPistol[i_Client] = 0;
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

public void CheckTarget(int i_Client)
{
	int i_Ent, i_Mode;
	char s_Class[64];

	i_Ent = GetClientAimTarget(i_Client, false);
	i_Mode = GetConVarInt(h_CvarMode);
	
	if (i_Ent > 0 && IsValidEntity(i_Ent))
	{
		GetEdictClassname(i_Ent, s_Class, sizeof(s_Class));
		//PrintToChatAll("CheckTarget %s", s_Class);
		
		if (StrEqual(s_Class, CHAINSAW_SPAWN_CLASS) && i_Mode != 1)
		{
			PrintToChat(i_Client, "\x03[%t]\x01 %t.", "Information", "Full");
		}
		else if (StrEqual(s_Class, CHAINSAW_CLASS) && i_Mode != 1)
		{
			CheckChainsaw(i_Client, i_Ent, -1);
		}
		else if (StrEqual(s_Class, "player") && i_Mode != 0)
		{
			int i_Weapon;
			char s_Weapon[64];
			
			i_Weapon = GetEntDataEnt2(i_Ent, g_ActiveWeaponOffset);
			if(IsValidEnt(i_Weapon))
			{
				GetEdictClassname(i_Weapon, s_Weapon, sizeof(s_Weapon));
				if (StrEqual(s_Weapon, CHAINSAW_CLASS))
					CheckChainsaw(i_Client, i_Weapon, i_Ent);
			}
		}
	}
}

public void CheckChainsaw(int i_Client, int i_Weapon, int i_Ent)
{
	float f_EntPos[3], f_ClientPos[3];
	
	GetEntPropVector(i_Ent == -1 ? i_Weapon : i_Ent, Prop_Send, "m_vecOrigin", f_EntPos);
	GetClientAbsOrigin(i_Client, f_ClientPos);
			
	if (GetVectorDistance(f_EntPos, f_ClientPos) <= CHAINSAW_DISTANCE)
	{
		int i_PointEnt, i_ChainsawPointEnt, i_Clip;
				
		i_Clip = GetEntProp(i_Weapon, Prop_Data, "m_iClip1");
				
		if (i_Clip == 30)
		{
			PrintToChat(i_Client, "\x03[%t]\x01 %t.", "Information", "Full");
			return;
		}
				
		i_ChainsawPointEnt = GetEntProp(i_Weapon, Prop_Data, "m_iClip2");
				
		if (i_ChainsawPointEnt == -1)
		{
			i_PointEnt = (i_Ent == -1) ? CreatePointEntity(i_Weapon, 10.0) : CreatePointEntity(i_Ent, 50.0);
				
			if (IsValidEnt(i_PointEnt))
			{
				SetEntProp(i_Weapon, Prop_Data, "m_iClip2", i_PointEnt);
				g_ClientPour[i_Client] = EntIndexToEntRef(i_Weapon);
					
				DataPack data = new DataPack();
				g_Timer[i_Client] = CreateTimer(0.5, Timer_CheckPourGascan, data, TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE);
				data.WriteCell(GetClientUserId(i_Client));
				data.WriteCell(EntIndexToEntRef(i_Weapon));
			}
		}
	}
}

public Action Timer_CheckPourGascan(Handle h_Timer, DataPack data)
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

public int CreatePointEntity(int i_Ent, float f_Add)
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
	if (!GetConVarBool(h_CvarEnabled))
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
		
		GetEdictClassname(i_Weapon, s_Weapon, sizeof(s_Weapon));
		i_Skin = GetEntProp(i_Weapon, Prop_Send, "m_nSkin");
		
		if (StrEqual(s_Weapon, GASCAN_CLASS) && i_Skin == GASCAN_SKIN)
		{
			CheckTarget(i_Client);
		}
		else if (StrEqual(s_Weapon, CHAINSAW_CLASS) && !GetConVarBool(h_CvarRemove))
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
		
		if (IsValidEntRef(g_PlayerPistol[i_Client]) && !IsValidEnt(i_Weapon))
			return Plugin_Continue;
		
		if (IsValidEnt(i_Weapon))
		{
			char s_Weapon[32];
			GetEdictClassname(i_Weapon, s_Weapon, sizeof(s_Weapon));
			if (StrEqual(s_Weapon, CHAINSAW_CLASS) && GetConVarBool(h_CvarDrop))
			{
				int i_Ent = CreateEntityByName("weapon_pistol");
				if(IsValidEnt(i_Ent))
				{
					DispatchSpawn(i_Ent);
					EquipPlayerWeapon(i_Client, i_Ent);
					g_PlayerPistol[i_Client] = EntIndexToEntRef(i_Ent);
					return Plugin_Continue;
				}
			}
		}
		
		g_b_InAction[i_Client] = true;
	}
	
	return Plugin_Continue;
}

bool IsValidEnt(int i_Ent)
{
	return (i_Ent > MaxClients && IsValidEdict(i_Ent) && IsValidEntity(i_Ent));
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

#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

static int g_PlayerSecondaryWeapons[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name		= "L4D2 Drop Secondary",
	author		= "Jahze, Visor, NoBody & HarryPotter",
	version		= "2.0",
	description	= "Survivor players will drop their secondary weapon when they die",
	url		= "https://steamcommunity.com/profiles/76561198026784913/"
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
	HookEvent("player_spawn",			Event_PlayerSpawn,	EventHookMode_PostNoCopy);
	HookEvent("player_death", 			OnPlayerDeath, EventHookMode_Pre);
	HookEvent("weapon_drop", 			OnWeaponDrop);

	if (bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnWeaponEquipPost(int client, int weapon)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return;

	if (IsIncapacitated(client)) //倒地不列入
		return;	

	int slot1_weapon = GetPlayerWeaponSlot(client, 1);

	//PrintToChatAll("%N OnWeaponEquipPost %d", client, slot1_weapon);

	g_PlayerSecondaryWeapons[client] = (slot1_weapon == -1 ? slot1_weapon : EntIndexToEntRef(slot1_weapon));
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		int weapon = GetPlayerWeaponSlot(client, 1);

		g_PlayerSecondaryWeapons[client] = (weapon == -1 ? weapon : EntIndexToEntRef(weapon));
	}
}

public void OnWeaponDrop(Event event, const char[] name, bool dontBroadcast) 
{
	CreateTimer(0.1, ColdDown, event.GetInt("userid"));
}

public Action ColdDown(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		int weapon = GetPlayerWeaponSlot(client, 1);
	
		g_PlayerSecondaryWeapons[client] = (weapon == -1 ? weapon : EntIndexToEntRef(weapon));	
	}

	return Plugin_Continue;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		g_PlayerSecondaryWeapons[client] = -1;
		return;
	}
	
	int weapon = EntRefToEntIndex(g_PlayerSecondaryWeapons[client]);
	
	if(weapon == INVALID_ENT_REFERENCE)
	{
		g_PlayerSecondaryWeapons[client] = -1;
		return;
	}
	
	char sWeapon[32];
	int clip;
	GetEdictClassname(weapon, sWeapon, 32);
	
	int entity = CreateEntityByName(sWeapon); 
	if(entity == -1)
	{
		g_PlayerSecondaryWeapons[client] = -1;
		return;
	}

	float origin[3];
	float ang[3];
	char melee_name[64];
	if (strcmp(sWeapon, "weapon_melee") == 0)
	{
		if (HasEntProp(weapon, Prop_Data, "m_strMapSetScriptName")) //support custom melee
		{
			GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", melee_name, sizeof(melee_name));
			DispatchKeyValue(entity, "solid", "6");
			DispatchKeyValue(entity, "melee_script_name", melee_name);
		}
		else
		{
			g_PlayerSecondaryWeapons[client] = -1;
			return;
		}
	}
	else if (strcmp(sWeapon, "weapon_chainsaw") == 0)
	{
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	}
	else if (strcmp(sWeapon, "weapon_pistol") == 0 && (GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0))
	{
		int entity2 = CreateEntityByName(sWeapon);
		if(entity2 == -1)
		{
			g_PlayerSecondaryWeapons[client] = -1;
			return;
		}

		GetClientEyePosition(client,origin);
		GetClientEyeAngles(client, ang);
		GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
		NormalizeVector(ang,ang);
		ScaleVector(ang, 90.0);
		
		DispatchSpawn(entity2);
		TeleportEntity(entity2, origin, NULL_VECTOR, ang);
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
		if(clip - 15 <= 0) SetEntProp(entity2, Prop_Send, "m_iClip1", 0);
		else clip = clip - 15;

		Event hEvent = CreateEvent("weapon_drop");
		if( hEvent != null )
		{
			hEvent.SetInt("userid", userid);
			hEvent.SetInt("propid", entity2);
			hEvent.Fire();
		}
	}
	else if (strcmp(sWeapon, "weapon_pistol_magnum") == 0)
	{
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	}

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
	
	GetClientEyePosition(client,origin);
	GetClientEyeAngles(client, ang);
	GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
	NormalizeVector(ang,ang);
	ScaleVector(ang, 90.0);
	
	DispatchSpawn(entity);
	TeleportEntity(entity, origin, NULL_VECTOR, ang);

	if (strcmp(sWeapon, "weapon_chainsaw") == 0 || strcmp(sWeapon, "weapon_pistol") == 0 || strcmp(sWeapon, "weapon_pistol_magnum") == 0)
	{
		SetEntProp(entity, Prop_Send, "m_iClip1", clip);
	}

	g_PlayerSecondaryWeapons[client] = -1;

	Event hEvent = CreateEvent("weapon_drop");
	if( hEvent != null )
	{
		hEvent.SetInt("userid", userid);
		hEvent.SetInt("propid", entity);
		hEvent.Fire();
	}
}

bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

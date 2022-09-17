#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int g_PlayerSecondaryWeapons[MAXPLAYERS + 1]; 		/* slot1 entity */
bool g_bSlot1_IsMelee[MAXPLAYERS+1];				/* slot1 is melee */
char g_sSlot1_MeleeName[MAXPLAYERS+1][64];			/* slot1 melee name */
int ig_slots1_skin[MAXPLAYERS+1]; 					/* slot1 m_nSkin */

public Plugin myinfo =
{
	name		= "L4D2 Drop Secondary",
	author		= "Jahze, Visor, NoBody & HarryPotter",
	version		= "2.1",
	description	= "Survivor players will drop their secondary weapon when they die",
	url			= "https://steamcommunity.com/profiles/76561198026784913/"
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

public void OnClientDisconnect(int client)
{
	if(!IsClientInGame(client)) return;

	clear(client);
}

public void OnWeaponEquipPost(int client, int weapon)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return;

	GetSlots1(client);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	CreateTimer(0.1, ColdDown, event.GetInt("userid"));
}

public void OnWeaponDrop(Event event, const char[] name, bool dontBroadcast) 
{
	CreateTimer(0.1, ColdDown, event.GetInt("userid"));
}

public Action ColdDown(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if(client && IsClientInGame(client))
	{
		GetSlots1(client);
	}

	return Plugin_Continue;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		clear(client);
		return;
	}
	
	int weapon = EntRefToEntIndex(g_PlayerSecondaryWeapons[client]);
	
	if(weapon == INVALID_ENT_REFERENCE)
	{
		clear(client);
		return;
	}
	
	char sWeapon[32];
	int clip;
	GetEntityClassname(weapon, sWeapon, 32);
	
	int entity; 
	float origin[3];
	float ang[3];
	GetClientEyePosition(client,origin);
	GetClientEyeAngles(client, ang);
	GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
	NormalizeVector(ang,ang);
	ScaleVector(ang, 90.0);
	if (g_bSlot1_IsMelee[client])
	{
		entity = CreateEntityByName("weapon_melee");
		if(entity == -1)
		{
			clear(client);
			return;
		}

		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "melee_script_name", g_sSlot1_MeleeName[client]);
	}
	else
	{
		if (strcmp(sWeapon, "weapon_chainsaw") == 0 ||
			strcmp(sWeapon, "weapon_pistol") == 0 ||
			strcmp(sWeapon, "weapon_pistol_magnum") == 0)
		{
			entity = CreateEntityByName(sWeapon);
			if(entity == -1)
			{
				clear(client);
				return;
			}

			if (strcmp(sWeapon, "weapon_chainsaw") == 0 ||
				strcmp(sWeapon, "weapon_pistol_magnum") == 0)
			{
				clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
			}
			else if (strcmp(sWeapon, "weapon_pistol") == 0 && (GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0))
			{
				int entity2 = CreateEntityByName(sWeapon); //second pistol
				if(entity2 == -1)
				{
					clear(client);
					return;
				}
				
				TeleportEntity(entity2, origin, NULL_VECTOR, ang);
				DispatchSpawn(entity2);
				clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
				if(clip - 15 <= 0) SetEntProp(entity2, Prop_Send, "m_iClip1", 0);
				else clip = clip - 15;

				//create weapon_drop event
				Event hEvent = CreateEvent("weapon_drop");
				if( hEvent != null )
				{
					hEvent.SetInt("userid", userid);
					hEvent.SetInt("propid", entity2);
					hEvent.Fire();
				}
			}
		}
		else	//unknow weapon
		{
			clear(client);
			LogError("%N has unknow secondary weapon: %s", client, sWeapon);
			return;
		}
	}

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
	
	TeleportEntity(entity, origin, NULL_VECTOR, ang);
	DispatchSpawn(entity);

	if (!g_bSlot1_IsMelee[client])
	{
		SetEntProp(entity, Prop_Send, "m_iClip1", clip);
	}

	SetEntProp(entity, Prop_Send, "m_nSkin", ig_slots1_skin[client]); //skin
	if (HasEntProp(entity, Prop_Data, "m_nWeaponSkin"))
	{
		SetEntProp(entity, Prop_Data, "m_nWeaponSkin", ig_slots1_skin[client]); 
	}

	clear(client);

	//create weapon_drop event
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

void clear(int client)
{
	g_PlayerSecondaryWeapons[client] = -1;
	g_bSlot1_IsMelee[client] = false;
	g_sSlot1_MeleeName[client][0] = '\0';
	ig_slots1_skin[client] = 0;
}

void GetSlots1(int client)
{
	if(GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		clear(client);
		return;
	}

	if (IsIncapacitated(client)) //倒地不列入
		return;

	int weapon = GetPlayerWeaponSlot(client, 1);
	if(weapon == -1)
	{
		clear(client);
		return;
	}

	if (HasEntProp(weapon, Prop_Data, "m_strMapSetScriptName")) //support custom melee
	{
		//PrintToChatAll("%d Is Melee", weapon);
		g_bSlot1_IsMelee[client] = true;
		GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", g_sSlot1_MeleeName[client], 64);
	}
	else
	{
		g_bSlot1_IsMelee[client] = false;
		g_sSlot1_MeleeName[client][0] = '\0';
	}

	g_PlayerSecondaryWeapons[client] = EntIndexToEntRef(weapon);
	ig_slots1_skin[client] = GetEntProp(weapon, Prop_Send, "m_nSkin", 4);
	//PrintToChatAll("%N slot 1 weapon is %d. skin %d", client, weapon, ig_slots1_skin[client]);
}
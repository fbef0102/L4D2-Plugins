/**
 * L4D2 Windows/Linux
 * CTerrorPlayer,m_knockdownTimer + 100 = 死前所持主武器weapon ID
 * CTerrorPlayer,m_knockdownTimer + 104 = 死前所持主武器ammo
 * CTerrorPlayer,m_knockdownTimer + 108 = 死前所持副武器weapon ID
 * CTerrorPlayer,m_knockdownTimer + 112 = 死前所持副武器是否双持
 * CTerrorPlayer,m_knockdownTimer + 116 = 死前所持非手枪副武器EHandle
 */

#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define WEPID_PISTOL 1

public Plugin myinfo =
{
	name		= "L4D2 Drop Secondary",
	author		= "HarryPotter",
	version		= "2.3",
	description	= "Survivor players will drop their secondary weapon when they die",
	url			= "https://steamcommunity.com/profiles/76561198026784913/"
};

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

static int iOffs_m_hSecondaryHiddenWeaponPreDead = -1;
static int iOffs_m_SecondaryWeaponDoublePistolPreDead = -1;
static int iOffs_m_SecondaryWeaponIDPreDead = -1;

public void OnPluginStart()
{
	iOffs_m_SecondaryWeaponIDPreDead = FindSendPropInfo("CTerrorPlayer", "m_knockdownTimer") + 108;
	iOffs_m_SecondaryWeaponDoublePistolPreDead = FindSendPropInfo("CTerrorPlayer", "m_knockdownTimer") + 112;
	iOffs_m_hSecondaryHiddenWeaponPreDead = FindSendPropInfo("CTerrorPlayer", "m_knockdownTimer") + 116;

	HookEvent("player_spawn", Event_PlayerSpawn,	EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, 		EventHookMode_Pre);
}

//playerspawn is triggered even when bot or human takes over each other (even they are already dead state) or a survivor is spawned
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		Clear(client);
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}

	int weapon = GetSecondaryHiddenWeaponPreDead(client);
	//PrintToChatAll("%N - %d, %d, %d - skin: %d", client, GetSecondaryWeaponIDPreDead(client), GetSecondaryWeaponDoublePistolPreDead(client), GetSecondaryHiddenWeaponPreDead(client), GetEntProp(weapon, Prop_Send, "m_nSkin", 4));
	if(weapon <= MaxClients || !IsValidEntity(weapon))
	{
		if(GetSecondaryWeaponIDPreDead(client) == WEPID_PISTOL)
		{
			float origin[3];
			float ang[3];
			GetClientEyePosition(client, origin);
			GetClientEyeAngles(client, ang);
			GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
			NormalizeVector(ang,ang);
			ScaleVector(ang, 90.0);
			
			int entity = CreateEntityByName("weapon_pistol");
			if(entity == -1) return;
				
			TeleportEntity(entity, origin, NULL_VECTOR, ang);
			DispatchSpawn(entity);

			//create weapon_drop event
			Event hEvent = CreateEvent("weapon_drop");
			if( hEvent != null )
			{
				hEvent.SetInt("userid", userid);
				hEvent.SetInt("propid", entity);
				hEvent.Fire();
			}

			if(GetSecondaryWeaponDoublePistolPreDead(client) == 1) //dual pistol
			{
				entity = CreateEntityByName("weapon_pistol");
				if(entity == -1) return;
					
				TeleportEntity(entity, origin, NULL_VECTOR, ang);
				DispatchSpawn(entity);

				//create weapon_drop event
				hEvent = CreateEvent("weapon_drop");
				if( hEvent != null )
				{
					hEvent.SetInt("userid", userid);
					hEvent.SetInt("propid", entity);
					hEvent.Fire();
				}
			}
		}

		Clear(client);
		return;
	}

	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

	int new_weapon, clip, skin;
	skin = GetEntProp(weapon, Prop_Send, "m_nSkin", 4);
	if (strcmp(sWeapon, "weapon_melee") == 0)
	{
		char sMeleeName[64];
		if (HasEntProp(weapon, Prop_Data, "m_strMapSetScriptName")) //support custom melee
		{
			GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", sMeleeName, sizeof(sMeleeName));

			// char sTime[32];
			// FormatTime(sTime, sizeof(sTime), "%H-%M", GetTime()); 
			// char sMap[64];
			// GetCurrentMap(sMap, sizeof(sMap));
			// char sModel[PLATFORM_MAX_PATH];
			// GetEntPropString(weapon, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			// LogMessage("%N drops melee %s (%s) on %s in time: %s", client, sMeleeName, sModel, sMap, sTime);

			TrimString(sMeleeName);
			if(strlen(sMeleeName) > 0)
			{
				new_weapon = CreateEntityByName(sWeapon);
				if(new_weapon == -1) return;

				DispatchKeyValue(new_weapon, "solid", "6");
				DispatchKeyValue(new_weapon, "melee_script_name", sMeleeName);
			}
			else
			{
				// LogMessage("%N drops empty melee weapon", client);
				Clear(client);
				return;
			}
		}
		else
		{
			// LogMessage("%N drops unknow melee weapon", client);
			Clear(client);
			return;
		}
	}
	else //chainsaw, magnum
	{
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1");

		new_weapon = CreateEntityByName(sWeapon);
		if(new_weapon == -1) return;
	}

	if(new_weapon > MaxClients && IsValidEntity(new_weapon))
	{
		float origin[3];
		float ang[3];
		GetClientEyePosition(client,origin);
		GetClientEyeAngles(client, ang);
		GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
		NormalizeVector(ang,ang);
		ScaleVector(ang, 90.0);
		
		DispatchSpawn(new_weapon);
		TeleportEntity(new_weapon, origin, NULL_VECTOR, ang);

		if (strcmp(sWeapon, "weapon_melee") != 0)
		{
			SetEntProp(new_weapon, Prop_Send, "m_iClip1", clip);
		}

		SetEntProp(new_weapon, Prop_Send, "m_nSkin", skin);

		if (HasEntProp(new_weapon, Prop_Data, "m_nWeaponSkin"))
			SetEntProp(new_weapon, Prop_Data, "m_nWeaponSkin", skin);

		RemovePlayerItem(client, weapon);
		RemoveEntity(weapon);

		Event hEvent = CreateEvent("weapon_drop");
		if( hEvent != null )
		{
			hEvent.SetInt("userid", userid);
			hEvent.SetInt("propid", new_weapon);
			hEvent.Fire();
		}
	}
	
	/*
	//倒地之前閒置=>等待自己的bot倒地=>取代bot=>接著死亡=>出現error
	//Exception reported: Weapon X is not owned by client X
	SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);

	float origin[3];
	GetClientEyePosition(client, origin);
	SDKHooks_DropWeapon(client, weapon, origin);

	if(IsFakeClient(client)) //真人玩家使用SDKHooks_DropWeapon 觸發"weapon_drop" event, 而AI bot不會
	{
		Event hEvent = CreateEvent("weapon_drop");
		if( hEvent != null )
		{
			hEvent.SetInt("userid", userid);
			hEvent.SetInt("propid", weapon);
			hEvent.Fire();
		}
	}
	*/

	Clear(client);
}

void Clear(int client)
{
	SetSecondaryWeaponIDPreDead(client, 1);
	SetSecondaryWeaponDoublePistolPreDead(client, 0);
	SetSecondaryHiddenWeapon(client, -1);
}

int GetSecondaryWeaponIDPreDead(int client)
{
	return GetEntData(client, iOffs_m_SecondaryWeaponIDPreDead);
}

void SetSecondaryWeaponIDPreDead(int client, int data)
{
	SetEntData(client, iOffs_m_SecondaryWeaponIDPreDead, data);
}

int GetSecondaryWeaponDoublePistolPreDead(int client)
{
	return GetEntData(client, iOffs_m_SecondaryWeaponDoublePistolPreDead);
}

void SetSecondaryWeaponDoublePistolPreDead(int client, int data)
{
	SetEntData(client, iOffs_m_SecondaryWeaponDoublePistolPreDead, data);
}

int GetSecondaryHiddenWeaponPreDead(int client)
{
	return GetEntDataEnt2(client, iOffs_m_hSecondaryHiddenWeaponPreDead);
}

void SetSecondaryHiddenWeapon(int client, int data)
{
	SetEntData(client, iOffs_m_hSecondaryHiddenWeaponPreDead, data);
}

stock int GetWeaponOwner(int weapon)
{
	return GetEntPropEnt(weapon, Prop_Data, "m_hOwner");
}
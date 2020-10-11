#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>

#define MODEL_V_FIREAXE "models/weapons/melee/v_fireaxe.mdl"
#define MODEL_V_FRYING_PAN "models/weapons/melee/v_frying_pan.mdl"
#define MODEL_V_MACHETE "models/weapons/melee/v_machete.mdl"
#define MODEL_V_BASEBALL_BAT "models/weapons/melee/v_bat.mdl"
#define MODEL_V_CROWBAR "models/weapons/melee/v_crowbar.mdl"
#define MODEL_V_CRICKET_BAT "models/weapons/melee/v_cricket_bat.mdl"
#define MODEL_V_TONFA "models/weapons/melee/v_tonfa.mdl"
#define MODEL_V_KATANA "models/weapons/melee/v_katana.mdl"
#define MODEL_V_ELECTRIC_GUITAR "models/weapons/melee/v_electric_guitar.mdl"
#define MODEL_V_GOLFCLUB "models/weapons/melee/v_golfclub.mdl"
#define MODEL_V_SHIELD "models/weapons/melee/v_riotshield.mdl"
#define MODEL_V_KNIFE "models/v_models/v_knife_t.mdl"
#define MODEL_V_SHOVEL "models/weapons/melee/v_shovel.mdl"
#define MODEL_V_PITCHFORK  "models/weapons/melee/v_pitchfork.mdl"

static g_PlayerSecondaryWeapons[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name		= "L4D2 Drop Secondary",
	author		= "Jahze, Visor, NoBody & HarryPotter",
	version		= "1.8",
	description	= "Survivor players will drop their secondary weapon when they die",
	url		= "https://github.com/Attano/Equilibrium"
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_use", OnPlayerUse, EventHookMode_Post);
	HookEvent("player_bot_replace", player_bot_replace);
	HookEvent("bot_player_replace", bot_player_replace);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("weapon_drop", OnWeaponDrop);
	HookEvent("item_pickup", OnItemPickUp);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	for (int i = 0; i <= MAXPLAYERS; i++) 
	{
		g_PlayerSecondaryWeapons[i] = -1;
	}
}

public Action OnPlayerUse(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	int weapon = GetPlayerWeaponSlot(client, 1);
	
	g_PlayerSecondaryWeapons[client] = (weapon == -1 ? weapon : EntIndexToEntRef(weapon));
}

public Action bot_player_replace(Event event, const char[] name, bool dontBroadcast) 
{
	int bot = GetClientOfUserId(event.GetInt("bot"));
	int client = GetClientOfUserId(event.GetInt("player"));

	g_PlayerSecondaryWeapons[client] = g_PlayerSecondaryWeapons[bot];
	g_PlayerSecondaryWeapons[bot] = -1;
}

public Action player_bot_replace(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	g_PlayerSecondaryWeapons[bot] = g_PlayerSecondaryWeapons[client];
	g_PlayerSecondaryWeapons[client] = -1;
}

public Action OnItemPickUp(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	int weapon = GetPlayerWeaponSlot(client, 1);
	
	g_PlayerSecondaryWeapons[client] = (weapon == -1 ? weapon : EntIndexToEntRef(weapon));
}

public Action OnWeaponDrop(Event event, const char[] name, bool dontBroadcast) 
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
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	int weapon = EntRefToEntIndex(g_PlayerSecondaryWeapons[client]);
	
	if(weapon == INVALID_ENT_REFERENCE)
	{
		return;
	}
	
	char sWeapon[32];
	int clip;
	GetEdictClassname(weapon, sWeapon, 32);
	
	int index = CreateEntityByName(sWeapon); 
	float origin[3];
	float ang[3];
	if (strcmp(sWeapon, "weapon_melee") == 0)
	{
		char melee[150];
		GetEntPropString(weapon , Prop_Data, "m_ModelName", melee, sizeof(melee));
		if (strcmp(melee, MODEL_V_FIREAXE) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "fireaxe");
		}
		else if (strcmp(melee, MODEL_V_FRYING_PAN) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "frying_pan");
		}
		else if (strcmp(melee, MODEL_V_MACHETE) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "machete");
		}
		else if (strcmp(melee, MODEL_V_BASEBALL_BAT) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "baseball_bat");
		}
		else if (strcmp(melee, MODEL_V_CROWBAR) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "crowbar");
		}
		else if (strcmp(melee, MODEL_V_CRICKET_BAT) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "cricket_bat");
		}
		else if (strcmp(melee, MODEL_V_TONFA) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "tonfa");
		}
		else if (strcmp(melee, MODEL_V_KATANA) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "katana");
		}
		else if (strcmp(melee, MODEL_V_ELECTRIC_GUITAR) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "electric_guitar");
		}
		else if (strcmp(melee, MODEL_V_GOLFCLUB) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "golfclub");
		}
		else if (strcmp(melee, MODEL_V_SHIELD) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "riotshield");
		}
		else if (strcmp(melee, MODEL_V_KNIFE) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "knife");
		}
		else if (strcmp(melee, MODEL_V_SHOVEL) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "shovel");
		}
		else if (strcmp(melee, MODEL_V_PITCHFORK) == 0)
		{
			DispatchKeyValue(index, "melee_script_name", "pitchfork");
		}
		else return;
	}
	else if (strcmp(sWeapon, "weapon_chainsaw") == 0)
	{
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	}
	else if (strcmp(sWeapon, "weapon_pistol") == 0 && (GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0))
	{
		int indexC = CreateEntityByName(sWeapon);
		GetClientEyePosition(client,origin);
		GetClientEyeAngles(client, ang);
		GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
		NormalizeVector(ang,ang);
		ScaleVector(ang, 90.0);
		
		DispatchSpawn(indexC);
		TeleportEntity(indexC, origin, NULL_VECTOR, ang);
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
	
	DispatchSpawn(index);
	TeleportEntity(index, origin, NULL_VECTOR, ang);

	if (strcmp(sWeapon, "weapon_chainsaw") == 0 || strcmp(sWeapon, "weapon_pistol") == 0 || strcmp(sWeapon, "weapon_pistol_magnum") == 0)
	{
		SetEntProp(index, Prop_Send, "m_iClip1", clip);
	}
}

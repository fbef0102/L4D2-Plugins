
#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.6"

int MODEL_DEFIB;
char WeaponNames[36][] =
{
	"weapon_pumpshotgun",
	"weapon_autoshotgun",
	"weapon_rifle",
	"weapon_smg",
	"weapon_hunting_rifle",
	"weapon_sniper_scout",
	"weapon_sniper_military",
	"weapon_sniper_awp",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_shotgun_spas",
	"weapon_shotgun_chrome",
	"weapon_rifle_sg552",
	"weapon_rifle_desert",
	"weapon_rifle_ak47",
	"weapon_grenade_launcher",
	"weapon_rifle_m60",
	"weapon_pistol",
	"weapon_pistol_magnum",
	"weapon_chainsaw",
	"weapon_melee",
	"weapon_pipe_bomb",
	"weapon_molotov",
	"weapon_vomitjar",
	"weapon_first_aid_kit",
	"weapon_defibrillator",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary",
	"weapon_pain_pills",
	"weapon_adrenaline",
	"weapon_gascan",
	"weapon_propanetank",
	"weapon_oxygentank",
	"weapon_gnome",
	"weapon_cola_bottles",
	"weapon_fireworkcrate"
};

public Plugin myinfo =
{
	name = "[L4D2] Weapon Drop",
	description = "Allows players to drop the weapon they are holding",
	author = "Machine, dcx2, Electr000999, Harry",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/TIGER_x_DRAGON/"
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

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_drop", Command_Drop, "Drop weapon", 0);
	RegConsoleCmd("sm_g", Command_Drop, "Drop weapon", 0);
	CreateConVar("sm_drop_version", PLUGIN_VERSION, "[L4D2] Weapon Drop Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnMapStart()
{
	MODEL_DEFIB = PrecacheModel("models/w_models/weapons/w_eq_defibrillator.mdl", true);
}

public Action Command_Drop(int client, int args)
{
	if (args == 1 || args > 2)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root))
		{
			ReplyToCommand(client, "[SM] Usage: sm_drop <#userid|name> <slot to drop>");
		}
	}
	else
	{
		if (args < 1)
		{
			int slot;
			char weapon[32];
			GetClientWeapon(client, weapon, 32);
			for (int count=0; count<=35; count++)
			{
				switch(count)
				{
					case 17: slot = 1;
					case 21: slot = 2;
					case 24: slot = 3;
					case 28: slot = 4;
					case 30: slot = 5;
				}
				if (StrEqual(weapon, WeaponNames[count], true))
				{
					DropSlot(client, slot);
				}
			}
		}
		if (args == 2)
		{
			if (GetAdminFlag(GetUserAdmin(client), Admin_Root))
			{
				char target[64];
				char arg[8];
				GetCmdArg(1, target, 64);
				GetCmdArg(2, arg, 8);
				int slot = StringToInt(arg, 10);
				int targetid = StringToInt(target, 10);
				if (targetid > 0 && IsClientInGame(targetid))
				{
					DropSlot(targetid, slot);
					return Plugin_Handled;
				}
				char target_name[64];
				int target_list[65];
				int target_count;
				bool tn_is_ml;
				if (0 >= (target_count = ProcessTargetString(target, client, target_list, 65, 0, target_name, 64, tn_is_ml)))
				{
					ReplyToTargetError(client, target_count);
					return Plugin_Handled;
				}
				int i;
				while (i < target_count)
				{
					DropSlot(target_list[i], slot);
					i++;
				}
			}
		}
	}
	return Plugin_Handled;
}

public void DropSlot(int client, int slot)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if (0 < GetPlayerWeaponSlot(client, slot))
		{
			int weapon = GetPlayerWeaponSlot(client, slot);
			SDKCallWeaponDrop(client, weapon);
		}
	}
}

void SDKCallWeaponDrop(int client, int weapon)
{
	char classname[32];
	float vecAngles[3];
	float vecTarget[3];
	float vecVelocity[3];
	if (GetPlayerEye(client, vecTarget))
	{
		GetClientEyeAngles(client, vecAngles);
		GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);
		vecVelocity[0] = vecVelocity[0] * 300.0;
		vecVelocity[1] *= 300.0;
		vecVelocity[2] *= 300.0;
		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(weapon, NULL_VECTOR, NULL_VECTOR, vecVelocity);
		GetEdictClassname(weapon, classname, 32);
		if (StrEqual(classname, "weapon_defibrillator", true))
		{
			SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", MODEL_DEFIB);
		}
	}
}

bool GetPlayerEye(int client, float vecTarget[3])
{
	float Origin[3];
	float Angles[3];
	GetClientEyePosition(client, Origin);
	GetClientEyeAngles(client, Angles);
	Handle trace = TR_TraceRayFilterEx(Origin, Angles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(vecTarget, trace);
		delete trace;
		return true;
	}
	delete trace;
	return false;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return (entity > MaxClients || !entity);
}

 
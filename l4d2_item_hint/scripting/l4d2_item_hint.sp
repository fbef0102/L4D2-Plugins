#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

Handle g_hUseEntity;
ConVar CvarFindRadius;

enum
{
	MODEL_NAME,
	WEP_NAME,
}

static const char g_sItems[][][] = 
{
	//MODEL_NAME, WEP_NAME
	{"models/w_models/weapons/w_eq_medkit.mdl", "First aid kit!"},
	{"models/w_models/weapons/w_eq_defibrillator.mdl", "Defibrillator!"},
	{"models/w_models/weapons/w_eq_painpills.mdl", "Pain pills!"},
	{"models/w_models/weapons/w_eq_adrenaline.mdl", "Adrenaline!"},
	{"models/w_models/weapons/w_eq_bile_flask.mdl", "Bile Bomb!"},
	{"models/w_models/weapons/w_eq_molotov.mdl", "Molotov!"},
	{"models/w_models/weapons/w_eq_pipebomb.mdl", "Pipe bomb!"},
	{"models/w_models/Weapons/w_laser_sights.mdl", "Laser Sight!"},
	{"models/w_models/weapons/w_eq_incendiary_ammopack.mdl", "Incendiary UpgradePack!"},
	{"models/w_models/weapons/w_eq_explosive_ammopack.mdl", "Explosive UpgradePack!"},
	{"models/props/terror/ammo_stack.mdl", "Ammo!"},
	{"models/props_unique/spawn_apartment/coffeeammo.mdl", "Ammo!"},
	{"models/props/de_prodigy/ammo_can_02.mdl", "Ammo!"},
	{"models/weapons/melee/w_chainsaw.mdl", "Chainsaw!"},
	{"models/w_models/weapons/w_pistol_B.mdl", "Pistol!"},
	{"models/w_models/weapons/w_desert_eagle.mdl", "Magnum!"},
	{"models/w_models/weapons/w_shotgun.mdl", "Pump Shotgun!"},
	{"models/w_models/weapons/w_pumpshotgun_A.mdl", "Shotgun Chrome!"},
	{"models/w_models/weapons/w_smg_uzi.mdl", "Uzi!"},
	{"models/w_models/weapons/w_smg_a.mdl", "Silenced Smg!"},
	{"models/w_models/weapons/w_smg_mp5.mdl", "MP5!"},
	{"models/w_models/weapons/w_rifle_m16a2.mdl", "Rifle!"},
	{"models/w_models/weapons/w_rifle_sg552.mdl", "SG552!"},
	{"models/w_models/weapons/w_rifle_ak47.mdl", "AK47!"},
	{"models/w_models/weapons/w_desert_rifle.mdl", "Desert Rifle!"},
	{"models/w_models/weapons/w_shotgun_spas.mdl", "Shotgun Spas!"},
	{"models/w_models/weapons/w_autoshot_m4super.mdl", "Auto Shotgun!"},
	{"models/w_models/weapons/w_sniper_mini14.mdl", "Hunting Rifle!"},
	{"models/w_models/weapons/w_sniper_military.mdl", "Military Sniper!"},
	{"models/w_models/weapons/w_sniper_scout.mdl", "Scout!"},
	{"models/w_models/weapons/w_sniper_awp.mdl", "AWP!"},
	{"models/w_models/weapons/w_grenade_launcher.mdl", "Grenade Launcher!"},
	{"models/w_models/weapons/w_m60.mdl", "M60!"},
	{"models/props_junk/gascan001a.mdl", "Gas Can!"},
	{"models/props_junk/explosive_box001.mdl", "Firework!"},
	{"models/props_junk/propanecanister001a.mdl", "Propane Tank!"},
	{"models/props_equipment/oxygentank01.mdl", "Oxygen Tank!"},
	{"models/props_junk/gnome.mdl", "Gnome!"},
	{"models/w_models/weapons/w_cola.mdl", "Cola!"},
	{"models/w_models/weapons/50cal.mdl", ".50 Cal Machine Gun here!"},
	{"models/w_models/weapons/w_minigun.mdl", "Minigun here!"},
	{"models/props/terror/exploding_ammo.mdl", "Explosive Ammo!"},
	{"models/props/terror/incendiary_ammo.mdl", "Incendiary Ammo!"},
    {"models/w_models/weapons/w_knife_t.mdl", "Knife!"},
    {"models/weapons/melee/w_bat.mdl", "Baseball Bat!"},
    {"models/weapons/melee/w_cricket_bat.mdl", "Cricket Bat!"},
    {"models/weapons/melee/w_crowbar.mdl", "Crowbar!"},
    {"models/weapons/melee/w_electric_guitar.mdl", "Electric Guitar!"},
    {"models/weapons/melee/w_fireaxe.mdl", "Fireaxe!"},
    {"models/weapons/melee/w_frying_pan.mdl", "Frying Pan!"},
    {"models/weapons/melee/w_katana.mdl", "Katana!"},
    {"models/weapons/melee/w_machete.mdl", "Machete!"},
    {"models/weapons/melee/w_tonfa.mdl", "Nightstick!"},
    {"models/weapons/melee/w_golfclub.mdl", "Golf Club!"},
    {"models/weapons/melee/w_pitchfork.mdl", "Pitckfork!"},
    {"models/weapons/melee/w_shovel.mdl", "Shovel!"}
};

float fCoolDownTime[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "L4D2 Item hint",
	author = "BHaType, fdxx, HarryPotter",
	description = "When using 'Look' in vocalize menu, print corresponding item to chat area.",
	version = "1.3",
	url = ""
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

ConVar CoolDown;
public void OnPluginStart()
{
	GameData hGameData = new GameData("l4d2_item_hint");
	if (hGameData != null)
	{
		int iOffset = hGameData.GetOffset("FindUseEntity");
		if (iOffset != -1)
		{
			//https://forums.alliedmods.net/showpost.php?p=2753773&postcount=2
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetVirtual(iOffset);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hUseEntity = EndPrepSDKCall();
		}
		else SetFailState("Failed to load offset");
	}
	else SetFailState("Failed to load l4d2_item_hint.txt file");
	delete hGameData;

	CvarFindRadius = FindConVar("player_use_radius");
	AddCommandListener(Vocalize_Listener, "vocalize");
	
	CoolDown = CreateConVar(	"l4d2_item_hint_cooldown_time",			"2.5",			"Cold Down Time in seconds a player can use 'Look' item chat again.", FCVAR_NOTIFY, true, 0.0 );
	AutoExecConfig(true,		"l4d2_item_hint");	

	HookEvent("round_start", Event_RoundStart);

	Clear();
}

public void OnPluginEnd()
{
	Clear();
}

public void OnMapEnd()
{
	Clear();
}

public void OnClientPutInServer(int client)
{
	Clear(client);
}

public void OnClientDisconnect(int client)
{
	Clear(client);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	Clear();
}

public Action Vocalize_Listener(int client, const char[] command, int argc)
{
	if (IsRealSur(client))
	{
		static char sCmdString[256];
		if (GetCmdArgString(sCmdString, sizeof(sCmdString)) > 1)
		{
			if (StrContains(sCmdString, "smartlook #") != -1 && GetEngineTime() > fCoolDownTime[client])
			{
				static int iEntity;
				iEntity = GetUseEntity(client, CvarFindRadius.FloatValue);
				if (MaxClients < iEntity <= GetMaxEntities() && IsValidEntity(iEntity))
				{
					if (HasEntProp(iEntity, Prop_Data, "m_ModelName"))
					{
						static char sEntModelName[PLATFORM_MAX_PATH];
						if (GetEntPropString(iEntity, Prop_Data, "m_ModelName", sEntModelName, sizeof(sEntModelName)) > 1)
						{
							//PrintToChatAll("m_ModelName: %s", sEntModelName);
							for (int i = 0; i < sizeof(g_sItems); i++)
							{
								if (strcmp(sEntModelName, g_sItems[i][MODEL_NAME], false) == 0)
								{
									PrintToChatAll("\x01(\x04Vocalize\x01) \x05%N\x01: %s", client, g_sItems[i][WEP_NAME]);
									fCoolDownTime[client] = GetEngineTime() + CoolDown.FloatValue;
									return Plugin_Continue;
								}
							}
							
							if (StrContains(sEntModelName, "/melee/") != -1) //custom melee weapon
							{
								PrintToChatAll("\x01(\x04Vocalize\x01) \x05%N\x01: Melee!", client);
								fCoolDownTime[client] = GetEngineTime() + CoolDown.FloatValue;
								return Plugin_Continue;
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

int GetUseEntity(int client, float fRadius)
{
	return SDKCall(g_hUseEntity, client, fRadius, 0.0, 0.0, 0, 0);
}

bool IsRealSur(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsFakeClient(client));
}

void Clear(int client = -1)
{
	if(client == -1)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			fCoolDownTime[i] = 0.0;
		}
	}	
	else
	{
		fCoolDownTime[client] = 0.0;
	}

}

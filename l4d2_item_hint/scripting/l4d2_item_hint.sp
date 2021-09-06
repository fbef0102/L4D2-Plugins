#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

Handle g_hUseEntity;
ConVar CvarFindRadius, CoolDown;
StringMap g_smModelToName;
float fCoolDownTime[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "L4D2 Item hint",
	author = "BHaType, fdxx, HarryPotter",
	description = "When using 'Look' in vocalize menu, print corresponding item to chat area.",
	version = "0.3",
	url = "https://forums.alliedmods.net/showthread.php?t=333669"
};

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

	CreateStringMap();
	
	CoolDown = CreateConVar(	"l4d2_item_hint_cooldown_time",			"2.5",			"Cold Down Time in seconds a player can use 'Look' item chat again.", FCVAR_NOTIFY, true, 0.0 );
	AutoExecConfig(true,		"l4d2_item_hint");	

	HookEvent("round_start", Event_RoundStart);

	Clear();
}

void CreateStringMap()
{
	g_smModelToName = new StringMap();

	//Case-sensitive
	g_smModelToName.SetString("models/w_models/weapons/w_eq_Medkit.mdl",				"First aid kit!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_defibrillator.mdl",			"Defibrillator!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_painpills.mdl",				"Pain pills!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_adrenaline.mdl",			"Adrenaline!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_bile_flask.mdl",			"Bile Bomb!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_molotov.mdl",				"Molotov!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_pipebomb.mdl",				"Pipe bomb!");
	g_smModelToName.SetString("models/w_models/Weapons/w_laser_sights.mdl",				"Laser Sight!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_incendiary_ammopack.mdl",	"Incendiary UpgradePack!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_explosive_ammopack.mdl",	"Explosive UpgradePack!");
	g_smModelToName.SetString("models/props/terror/ammo_stack.mdl", 					"Ammo!");
	g_smModelToName.SetString("models/props_unique/spawn_apartment/coffeeammo.mdl", 	"Ammo!");
	g_smModelToName.SetString("models/props/de_prodigy/ammo_can_02.mdl", 				"Ammo!");
	g_smModelToName.SetString("models/weapons/melee/w_chainsaw.mdl", 					"Chainsaw!");
	g_smModelToName.SetString("models/w_models/weapons/w_pistol_B.mdl", 				"Pistol!");
	g_smModelToName.SetString("models/w_models/weapons/w_desert_eagle.mdl", 			"Magnum!");
	g_smModelToName.SetString("models/w_models/weapons/w_shotgun.mdl", 					"Pump Shotgun!");
	g_smModelToName.SetString("models/w_models/weapons/w_pumpshotgun_A.mdl", 			"Shotgun Chrome!");
	g_smModelToName.SetString("models/w_models/weapons/w_smg_uzi.mdl", 					"Uzi!");
	g_smModelToName.SetString("models/w_models/weapons/w_smg_a.mdl", 					"Silenced Smg!");
	g_smModelToName.SetString("models/w_models/weapons/w_smg_mp5.mdl", 					"MP5!");
	g_smModelToName.SetString("models/w_models/weapons/w_rifle_m16a2.mdl", 				"Rifle!");
	g_smModelToName.SetString("models/w_models/weapons/w_rifle_sg552.mdl", 				"SG552!");
	g_smModelToName.SetString("models/w_models/weapons/w_rifle_ak47.mdl", 				"AK47!");
	g_smModelToName.SetString("models/w_models/weapons/w_desert_rifle.mdl", 			"Desert Rifle!");
	g_smModelToName.SetString("models/w_models/weapons/w_shotgun_spas.mdl", 			"Shotgun Spas!");
	g_smModelToName.SetString("models/w_models/weapons/w_autoshot_m4super.mdl", 		"Auto Shotgun!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_mini14.mdl", 			"Hunting Rifle!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_military.mdl", 			"Military Sniper!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_scout.mdl", 			"Scout!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_awp.mdl", 				"AWP!");
	g_smModelToName.SetString("models/w_models/weapons/w_grenade_launcher.mdl", 		"Grenade Launcher!");
	g_smModelToName.SetString("models/w_models/weapons/w_m60.mdl", 						"M60!");
	g_smModelToName.SetString("models/props_junk/gascan001a.mdl", 						"Gas Can!");
	g_smModelToName.SetString("models/props_junk/explosive_box001.mdl", 				"Firework!");
	g_smModelToName.SetString("models/props_junk/propanecanister001a.mdl", 				"Propane Tank!");
	g_smModelToName.SetString("models/props_equipment/oxygentank01.mdl", 				"Oxygen Tank!");
	g_smModelToName.SetString("models/props_junk/gnome.mdl", 							"Gnome!");
	g_smModelToName.SetString("models/w_models/weapons/w_cola.mdl", 					"Cola!");
	g_smModelToName.SetString("models/w_models/weapons/50cal.mdl",						".50 Cal Machine Gun here!");
	g_smModelToName.SetString("models/w_models/weapons/w_minigun.mdl", 					"Minigun here!");
	g_smModelToName.SetString("models/props/terror/exploding_ammo.mdl", 				"Explosive Ammo!");
	g_smModelToName.SetString("models/props/terror/incendiary_ammo.mdl", 				"Incendiary Ammo!");
	g_smModelToName.SetString("models/w_models/weapons/w_knife_t.mdl", 					"Knife!");
	g_smModelToName.SetString("models/weapons/melee/w_bat.mdl", 						"Baseball Bat!");
	g_smModelToName.SetString("models/weapons/melee/w_cricket_bat.mdl", 				"Cricket Bat!");
	g_smModelToName.SetString("models/weapons/melee/w_crowbar.mdl", 					"Crowbar!");
	g_smModelToName.SetString("models/weapons/melee/w_electric_guitar.mdl", 			"Electric Guitar!");
	g_smModelToName.SetString("models/weapons/melee/w_fireaxe.mdl", 					"Fireaxe!");
	g_smModelToName.SetString("models/weapons/melee/w_frying_pan.mdl", 					"Frying Pan!");
	g_smModelToName.SetString("models/weapons/melee/w_katana.mdl", 						"Katana!");
	g_smModelToName.SetString("models/weapons/melee/w_machete.mdl", 					"Machete!");
	g_smModelToName.SetString("models/weapons/melee/w_tonfa.mdl", 						"Nightstick!");
	g_smModelToName.SetString("models/weapons/melee/w_golfclub.mdl", 					"Golf Club!");
	g_smModelToName.SetString("models/weapons/melee/w_pitchfork.mdl", 					"Pitckfork!");
	g_smModelToName.SetString("models/weapons/melee/w_shovel.mdl", 						"Shovel!");
}

public void OnPluginEnd()
{
	delete g_smModelToName;
}

public void OnClientPutInServer(int client)
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
		static char sCmdString[32];
		if (GetCmdArgString(sCmdString, sizeof(sCmdString)) > 1)
		{
			if (strncmp(sCmdString, "smartlook #", 11) == 0 && GetEngineTime() > fCoolDownTime[client])
			{
				static int iEntity;
				iEntity = GetUseEntity(client, CvarFindRadius.FloatValue);
				if (MaxClients < iEntity <= GetMaxEntities())
				{
					if (HasEntProp(iEntity, Prop_Data, "m_ModelName"))
					{
						static char sEntModelName[PLATFORM_MAX_PATH];
						if (GetEntPropString(iEntity, Prop_Data, "m_ModelName", sEntModelName, sizeof(sEntModelName)) > 1)
						{
							static char sItemName[64];
							if (g_smModelToName.GetString(sEntModelName, sItemName, sizeof(sItemName)))
							{
								PrintToChatAll("\x01(\x04Vocalize\x01) \x05%N\x01: %s", client, sItemName);
								fCoolDownTime[client] = GetEngineTime() + CoolDown.FloatValue;
								return Plugin_Continue;
							}
							
							if (StrContains(sEntModelName, "/melee/") != -1) //custom 3rd party melee weapon
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

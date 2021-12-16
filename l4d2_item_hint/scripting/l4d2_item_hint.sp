#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ConVar CvarFindRadius, g_hColorGlowRange, g_hCvarColor, g_hGlowTimer, g_hCoolDown;
int g_iColorGlowRange, g_iCvarColor;
float g_fCoolDown, g_fGlowTimer;
float fCoolDownTime[MAXPLAYERS+1];

#define MAXENTITIES 2048
int g_iModelIndex[MAXENTITIES] = 0;
Handle g_iModelTimer[MAXENTITIES];
Handle g_hUseEntity;
StringMap g_smModelToName;

public Plugin myinfo =
{
	name = "L4D2 Item hint",
	author = "BHaType, fdxx, HarryPotter",
	description = "When using 'Look' in vocalize menu, print corresponding item to chat area and make item glow.",
	version = "0.5",
	url = "https://forums.alliedmods.net/showthread.php?t=333669"
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
	
	g_hCoolDown = CreateConVar(			"l4d2_item_hint_cooldown_time",	"2.5",	"Cold Down Time in seconds a player can use 'Look' item chat again.", FCVAR_NOTIFY, true, 0.0 );
	g_hGlowTimer = CreateConVar(		"l4d2_item_hint_glow_timer",	"15.0",	"Item Glow Time.", FCVAR_NOTIFY, true, 0.0 );
	g_hColorGlowRange = CreateConVar(	"l4d2_item_hint_glow_range",	"1000",	"Item Glow Range.", FCVAR_NOTIFY, true, 0.0 );
	g_hCvarColor = CreateConVar(		"l4d2_item_hint_glow_color",	"200 200 200",	"Item Glow Color, Three values between 0-255 separated by spaces. (Empty = Disable Glow)", FCVAR_NOTIFY);
	AutoExecConfig(true,		"l4d2_item_hint");

	GetCvars();
	g_hCoolDown.AddChangeHook(ConVarChanged_Cvars);
	g_hGlowTimer.AddChangeHook(ConVarChanged_Cvars);
	g_hColorGlowRange.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColor.AddChangeHook(ConVarChanged_Cvars);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_Round_End);
	HookEvent("map_transition", Event_Round_End); //戰役過關到下一關的時候 (沒有觸發round_end)
	HookEvent("mission_lost", Event_Round_End); //戰役滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", Event_Round_End); //救援載具離開之時  (沒有觸發round_end)
	HookEvent("spawner_give_item", Event_SpawnerGiveItem);

	CreateStringMap();
	Clear();

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

public void OnPluginEnd()
{
	delete g_smModelToName;
	RemoveItemGlow_Timer();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fCoolDown = g_hCoolDown.FloatValue;
	g_fGlowTimer = g_hGlowTimer.FloatValue;
	g_iColorGlowRange = g_hColorGlowRange.IntValue;

	char sColor[16];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	g_iCvarColor = GetColor(sColor);
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

bool g_bConfigLoaded;
public void OnConfigsExecuted()
{
    g_bConfigLoaded = true;
}

public void OnMapEnd()
{
	RemoveItemGlow_Timer();
	g_bConfigLoaded = false;
}

public void OnClientPutInServer(int client)
{
	Clear(client);
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnWeaponEquipPost(int client, int weapon)
{
	if (!IsValidEntity(weapon))
		return;

	RemoveEntityModelGlow(weapon);
	delete g_iModelTimer[weapon];
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	Clear();
}

public Action Event_Round_End(Event event, const char[] name, bool dontBroadcast)
{
	RemoveItemGlow_Timer();
}

public void Event_SpawnerGiveItem(Event event, const char[] name, bool dontBroadcast)
{
	int entity = event.GetInt("spawner");
	int count = GetEntProp(entity, Prop_Data, "m_itemCount");

	if(count <= 1)
	{
		RemoveEntityModelGlow(entity);
		delete g_iModelTimer[entity];
	}
}

public Action Vocalize_Listener(int client, const char[] command, int argc)
{
	bool bGlow = false;
	if (IsRealSur(client))
	{
		static char sCmdString[32];
		if (GetCmdArgString(sCmdString, sizeof(sCmdString)) > 1)
		{
			if (strncmp(sCmdString, "smartlook #", 11) == 0 && GetEngineTime() > fCoolDownTime[client])
			{
				static int iEntity;
				iEntity = GetUseEntity(client, CvarFindRadius.FloatValue);
				if (IsValidEntityIndex(iEntity) && IsValidEntity(iEntity))
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
								fCoolDownTime[client] = GetEngineTime() + g_fCoolDown;
								bGlow = true;
							}
							else if (StrContains(sEntModelName, "/melee/") != -1) //custom 3rd party melee weapon
							{
								PrintToChatAll("\x01(\x04Vocalize\x01) \x05%N\x01: Melee!", client);
								fCoolDownTime[client] = GetEngineTime() + g_fCoolDown;
								bGlow = true;
							}

							if(bGlow && g_iCvarColor != 0) 
							{
								// Spawn dynamic prop entity
								int entity = CreateEntityByName("prop_dynamic_override");
								if (entity == -1) return Plugin_Continue;
								
								// Set new fake model
								DispatchKeyValue(entity, "model", sEntModelName);
								DispatchSpawn(entity);

								float vPos[3], vAng[3];
								GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vPos);
								GetEntPropVector(iEntity, Prop_Send, "m_angRotation", vAng);
								TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

								// Set outline glow color
								SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
								SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
								SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iColorGlowRange);
								SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
								SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColor);
								AcceptEntityInput(entity, "StartGlowing");

								// Set model invisible
								SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
								SetEntityRenderColor(entity, 0, 0, 0, 0);

								// Set model attach to item, and always synchronize
								SetVariantString("!activator");
								AcceptEntityInput(entity, "SetParent", iEntity);

								g_iModelIndex[iEntity] = entity;

								delete g_iModelTimer[iEntity];
								g_iModelTimer[iEntity] = CreateTimer(g_fGlowTimer, ColdDown, iEntity);
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action ColdDown(Handle timer, int iEntity)
{		
	RemoveEntityModelGlow(iEntity);
	g_iModelTimer[iEntity] = null;
}

void RemoveEntityModelGlow(int iEntity)
{
	int entity = g_iModelIndex[iEntity];
	g_iModelIndex[iEntity] = 0;

	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "kill");
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

int GetColor(char[] sTemp)
{
	if( StrEqual(sTemp, "") )
		return 0;

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE && entity!= -1 )
		return true;
	return false;
}

public void OnEntityDestroyed(int entity)
{
	if (!g_bConfigLoaded)
		return;
		
	if (!IsValidEntityIndex(entity))
		return;

	RemoveEntityModelGlow(entity);
	delete g_iModelTimer[entity];
}

void RemoveItemGlow_Timer()
{
	for (int entity = 1; entity < MAXENTITIES; entity++)
	{
		RemoveEntityModelGlow(entity);
		delete g_iModelTimer[entity];
	}
}

bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}
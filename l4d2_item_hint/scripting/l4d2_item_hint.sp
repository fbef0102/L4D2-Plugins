#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#define MAXENTITIES 2048
#define MODEL_MARK_FIELD 	"materials/sprites/laserbeam.vmt"
#define MODEL_MARK_SPRITE 	"materials/vgui/icon_download.vmt"
#define CLASSNAME_INFO_TARGET         "info_target"
#define CLASSNAME_ENV_SPRITE          "env_sprite"
#define ENTITY_WORLDSPAWN             0

ConVar g_hCoolDown,
	g_hItemUseHintRange, g_hItemUseSound, g_hItemAnnounceType, g_hItemGlowTimer, g_hItemColorGlowRange, g_hItemCvarColor,
	g_hMarkUseRange, g_hMarkUseSound, g_hMarkGlowTimer, g_hMarkCvarColor;
int g_iItemAnnounceType, g_iItemColorGlowRange, g_iItemCvarColor,
	g_iMarkCvarColorArray[3];
float g_fCoolDown,
	g_fItemUseHintRange, g_fItemGlowTimer,
	g_fMarkUseRange, g_fMarkGlowTimer;
float       fCoolDownTime[MAXPLAYERS + 1];
static char g_sMarkCvarColor[12], g_sItemUseSound[100], g_sMarkUseSound[100], g_sKillDelay[32];


static bool   ge_bMoveUp[MAXENTITIES+1];
int       g_iModelIndex[MAXENTITIES] = 0;
Handle    g_iModelTimer[MAXENTITIES];
Handle    g_hUseEntity;
StringMap g_smModelToName;

public Plugin myinfo =
{
	name        = "L4D2 Item hint",
	author      = "BHaType, fdxx, HarryPotter",
	description = "When using 'Look' in vocalize menu, print corresponding item to chat area and make item glow or create spot marker like back 4 blood.",
	version     = "0.8",
	url         = "https://forums.alliedmods.net/showpost.php?p=2765332&postcount=30"
};

bool bLate;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if (test != Engine_Left4Dead2)
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
			// https://forums.alliedmods.net/showpost.php?p=2753773&postcount=2
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

	// g_hItemUseHintRange = FindConVar("player_use_radius");
	AddCommandListener(Vocalize_Listener, "vocalize");

	g_hCoolDown           = CreateConVar("l4d2_item_hint_cooldown_time", "2.5", "Cold Down Time in seconds a player can use 'Look' Item Hint/Spot Marker again.", FCVAR_NOTIFY, true, 0.0);
	g_hItemUseHintRange   = CreateConVar("l4d2_item_hint_use_range", "150", "How close can a player use 'Look' item hint.", FCVAR_NOTIFY, true, 1.0);
	g_hItemUseSound       = CreateConVar("l4d2_item_hint_use_sound", "buttons/blip1.wav", "Item Hint Sound. (Empty = OFF)", FCVAR_NOTIFY);
	g_hItemAnnounceType   = CreateConVar("l4d2_item_hint_announce_type", "1", "Changes how Item Hint displays. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_hItemGlowTimer      = CreateConVar("l4d2_item_hint_glow_timer", "15.0", "Item Glow Time.", FCVAR_NOTIFY, true, 0.0);
	g_hItemColorGlowRange = CreateConVar("l4d2_item_hint_glow_range", "1000", "Item Glow Range.", FCVAR_NOTIFY, true, 0.0);
	g_hItemCvarColor      = CreateConVar("l4d2_item_hint_glow_color", "0 255 255", "Item Glow Color, Three values between 0-255 separated by spaces. (Empty = Disable Item Glow)", FCVAR_NOTIFY);
	g_hMarkUseRange       = CreateConVar("l4d2_spot_marker_use_range", "900", "How far away can a player use 'Look' Spot Marker.", FCVAR_NOTIFY, true, 1.0);
	g_hMarkUseSound       = CreateConVar("l4d2_spot_marker_use_sound", "buttons/blip1.wav", "Spot Marker Sound. (Empty = OFF)", FCVAR_NOTIFY);
	g_hMarkGlowTimer      = CreateConVar("l4d2_spot_marker_duration", "10.0", "Spot Marker Duration.", FCVAR_NOTIFY, true, 0.0);
	g_hMarkCvarColor      = CreateConVar("l4d2_spot_marker_color", "200 200 200", "Spot Marker Glow Color, Three values between 0-255 separated by spaces. (Empty = Disable Spot Marker)", FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d2_item_hint");

	GetCvars();
	g_hCoolDown.AddChangeHook(ConVarChanged_Cvars);
	g_hItemUseHintRange.AddChangeHook(ConVarChanged_Cvars);
	g_hItemUseSound.AddChangeHook(ConVarChanged_Cvars);
	g_hItemAnnounceType.AddChangeHook(ConVarChanged_Cvars);
	g_hItemGlowTimer.AddChangeHook(ConVarChanged_Cvars);
	g_hItemColorGlowRange.AddChangeHook(ConVarChanged_Cvars);
	g_hItemCvarColor.AddChangeHook(ConVarChanged_Cvars);
	g_hMarkUseRange.AddChangeHook(ConVarChanged_Cvars);
	g_hMarkUseSound.AddChangeHook(ConVarChanged_Cvars);
	g_hMarkGlowTimer.AddChangeHook(ConVarChanged_Cvars);
	g_hMarkCvarColor.AddChangeHook(ConVarChanged_Cvars);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_Round_End);
	HookEvent("map_transition", Event_Round_End);            //戰役過關到下一關的時候 (沒有觸發round_end)
	HookEvent("mission_lost", Event_Round_End);              //戰役滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", Event_Round_End);    //救援載具離開之時  (沒有觸發round_end)
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
	RemoveAllMark();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fCoolDown         = g_hCoolDown.FloatValue;
	g_fItemUseHintRange = g_hItemUseHintRange.FloatValue;
	g_hItemUseSound.GetString(g_sItemUseSound, sizeof(g_sItemUseSound));
	g_iItemAnnounceType = g_hItemAnnounceType.IntValue;
	g_fItemGlowTimer      = g_hItemGlowTimer.FloatValue;
	g_iItemColorGlowRange = g_hItemColorGlowRange.IntValue;

	char sColor[16];
	g_hItemCvarColor.GetString(sColor, sizeof(sColor));
	g_iItemCvarColor = GetColor(sColor);

	g_fMarkUseRange = g_hMarkUseRange.FloatValue;
	g_hMarkUseSound.GetString(g_sMarkUseSound, sizeof(g_sMarkUseSound));
	g_fMarkGlowTimer      = g_hMarkGlowTimer.FloatValue;
	FormatEx(g_sKillDelay, sizeof(g_sKillDelay), "OnUser1 !self:Kill::%.2f:-1", g_fMarkGlowTimer);

	g_hMarkCvarColor.GetString(g_sMarkCvarColor, sizeof(g_sMarkCvarColor));
	TrimString(g_sMarkCvarColor);
	g_iMarkCvarColorArray = ConvertRGBToIntArray(g_sMarkCvarColor);
}

void CreateStringMap()
{
	g_smModelToName = new StringMap();

	// Case-sensitive
	g_smModelToName.SetString("models/w_models/weapons/w_eq_medkit.mdl", "First aid kit!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_defibrillator.mdl", "Defibrillator!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_painpills.mdl", "Pain pills!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_adrenaline.mdl", "Adrenaline!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_bile_flask.mdl", "Bile Bomb!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_molotov.mdl", "Molotov!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_pipebomb.mdl", "Pipe bomb!");
	g_smModelToName.SetString("models/w_models/weapons/w_laser_sights.mdl", "Laser Sight!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_incendiary_ammopack.mdl", "Incendiary UpgradePack!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_explosive_ammopack.mdl", "Explosive UpgradePack!");
	g_smModelToName.SetString("models/props/terror/ammo_stack.mdl", "Ammo!");
	g_smModelToName.SetString("models/props_unique/spawn_apartment/coffeeammo.mdl", "Ammo!");
	g_smModelToName.SetString("models/props/de_prodigy/ammo_can_02.mdl", "Ammo!");
	g_smModelToName.SetString("models/weapons/melee/w_chainsaw.mdl", "Chainsaw!");
	g_smModelToName.SetString("models/w_models/weapons/w_pistol_b.mdl", "Pistol!");
	g_smModelToName.SetString("models/w_models/weapons/w_pistol_a.mdl", "Pistol!");
	g_smModelToName.SetString("models/w_models/weapons/w_desert_eagle.mdl", "Magnum!");
	g_smModelToName.SetString("models/w_models/weapons/w_shotgun.mdl", "Pump Shotgun!");
	g_smModelToName.SetString("models/w_models/weapons/w_pumpshotgun_a.mdl", "Shotgun Chrome!");
	g_smModelToName.SetString("models/w_models/weapons/w_smg_uzi.mdl", "Uzi!");
	g_smModelToName.SetString("models/w_models/weapons/w_smg_a.mdl", "Silenced Smg!");
	g_smModelToName.SetString("models/w_models/weapons/w_smg_mp5.mdl", "MP5!");
	g_smModelToName.SetString("models/w_models/weapons/w_rifle_m16a2.mdl", "Rifle!");
	g_smModelToName.SetString("models/w_models/weapons/w_rifle_sg552.mdl", "SG552!");
	g_smModelToName.SetString("models/w_models/weapons/w_rifle_ak47.mdl", "AK47!");
	g_smModelToName.SetString("models/w_models/weapons/w_desert_rifle.mdl", "Desert Rifle!");
	g_smModelToName.SetString("models/w_models/weapons/w_shotgun_spas.mdl", "Shotgun Spas!");
	g_smModelToName.SetString("models/w_models/weapons/w_autoshot_m4super.mdl", "Auto Shotgun!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_mini14.mdl", "Hunting Rifle!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_military.mdl", "Military Sniper!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_scout.mdl", "Scout!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_awp.mdl", "AWP!");
	g_smModelToName.SetString("models/w_models/weapons/w_grenade_launcher.mdl", "Grenade Launcher!");
	g_smModelToName.SetString("models/w_models/weapons/w_m60.mdl", "M60!");
	g_smModelToName.SetString("models/props_junk/gascan001a.mdl", "Gas Can!");
	g_smModelToName.SetString("models/props_junk/explosive_box001.mdl", "Firework!");
	g_smModelToName.SetString("models/props_junk/propanecanister001a.mdl", "Propane Tank!");
	g_smModelToName.SetString("models/props_equipment/oxygentank01.mdl", "Oxygen Tank!");
	g_smModelToName.SetString("models/props_junk/gnome.mdl", "Gnome!");
	g_smModelToName.SetString("models/w_models/weapons/w_cola.mdl", "Cola!");
	g_smModelToName.SetString("models/w_models/weapons/50cal.mdl", ".50 Cal Machine Gun here!");
	g_smModelToName.SetString("models/w_models/weapons/w_minigun.mdl", "Minigun here!");
	g_smModelToName.SetString("models/props/terror/exploding_ammo.mdl", "Explosive Ammo!");
	g_smModelToName.SetString("models/props/terror/incendiary_ammo.mdl", "Incendiary Ammo!");
	g_smModelToName.SetString("models/w_models/weapons/w_knife_t.mdl", "Knife!");
	g_smModelToName.SetString("models/weapons/melee/w_bat.mdl", "Baseball Bat!");
	g_smModelToName.SetString("models/weapons/melee/w_cricket_bat.mdl", "Cricket Bat!");
	g_smModelToName.SetString("models/weapons/melee/w_crowbar.mdl", "Crowbar!");
	g_smModelToName.SetString("models/weapons/melee/w_electric_guitar.mdl", "Electric Guitar!");
	g_smModelToName.SetString("models/weapons/melee/w_fireaxe.mdl", "Fireaxe!");
	g_smModelToName.SetString("models/weapons/melee/w_frying_pan.mdl", "Frying Pan!");
	g_smModelToName.SetString("models/weapons/melee/w_katana.mdl", "Katana!");
	g_smModelToName.SetString("models/weapons/melee/w_machete.mdl", "Machete!");
	g_smModelToName.SetString("models/weapons/melee/w_tonfa.mdl", "Nightstick!");
	g_smModelToName.SetString("models/weapons/melee/w_golfclub.mdl", "Golf Club!");
	g_smModelToName.SetString("models/weapons/melee/w_pitchfork.mdl", "Pitckfork!");
	g_smModelToName.SetString("models/weapons/melee/w_shovel.mdl", "Shovel!");
}

int g_iFieldModelIndex;
public void OnMapStart()
{
	if (strlen(g_sItemUseSound) > 0) PrecacheSound(g_sItemUseSound);
	if (strlen(g_sMarkUseSound) > 0) PrecacheSound(g_sMarkUseSound);
	g_iFieldModelIndex = PrecacheModel(MODEL_MARK_FIELD, true);
	PrecacheModel(MODEL_MARK_SPRITE, true);
}

public void OnMapEnd()
{
	RemoveItemGlow_Timer();
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
	RemoveAllMark();
}

public void Event_SpawnerGiveItem(Event event, const char[] name, bool dontBroadcast)
{
	int entity = event.GetInt("spawner");
	int count  = GetEntProp(entity, Prop_Data, "m_itemCount");

	if (count <= 1)
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
			if (strncmp(sCmdString, "smartlook #", 11, false) == 0 && GetEngineTime() > fCoolDownTime[client])
			{
				static int iEntity;
				iEntity = GetUseEntity(client, g_fItemUseHintRange);
				if (IsValidEntityIndex(iEntity) && IsValidEntity(iEntity))
				{
					if (HasEntProp(iEntity, Prop_Data, "m_ModelName"))
					{
						static char sEntModelName[PLATFORM_MAX_PATH];
						if (GetEntPropString(iEntity, Prop_Data, "m_ModelName", sEntModelName, sizeof(sEntModelName)) > 1)
						{
							// PrintToChatAll("Model - %s", sEntModelName);
							StringToLowerCase(sEntModelName);
							static char sItemName[64];
							if (g_smModelToName.GetString(sEntModelName, sItemName, sizeof(sItemName)))
							{
								switch(g_iItemAnnounceType)
								{
									case 0: {/*nothing*/}
									case 1: {
										PrintToChatAll("\x01(\x04Vocalize\x01) \x05%N\x01: %s", client, sItemName);
									}
									case 2: {
										PrintHintTextToAll("(Vocalize) %N: %s", client, sItemName);
									}
									case 3: {
										PrintCenterTextAll("(Vocalize) %N: %s", client, sItemName);
									}
								}
								if (strlen(g_sItemUseSound) > 0) EmitSoundToAll(g_sItemUseSound, client);
								fCoolDownTime[client] = GetEngineTime() + g_fCoolDown;
								bGlow                 = true;
							}
							else if (StrContains(sEntModelName, "/melee/") != -1)    // custom 3rd party melee weapon
							{
								switch(g_iItemAnnounceType)
								{
									case 0: {/*nothing*/}
									case 1: {
										PrintToChatAll("\x01(\x04Vocalize\x01) \x05%N\x01: Melee!", client);
									}
									case 2: {
										PrintHintTextToAll("(Vocalize) %N: Melee!", client);
									}
									case 3: {
										PrintCenterTextAll("(Vocalize) %N: Melee!", client);
									}
								}
								if (strlen(g_sItemUseSound) > 0) EmitSoundToAll(g_sItemUseSound, client);
								fCoolDownTime[client] = GetEngineTime() + g_fCoolDown;
								bGlow                 = true;
							}

							if (bGlow && g_iItemCvarColor != 0)
							{
								CreateItemGlow(iEntity, sEntModelName);
							}
						}
					}
				}
				else // client / world / infected
				{
					CreateSpotMarker(client);
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
	int entity             = g_iModelIndex[iEntity];
	g_iModelIndex[iEntity] = 0;

	if (IsValidEntRef(entity))
		RemoveEntity(entity);
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
	if (client == -1)
	{
		for (int i = 1; i <= MaxClients; i++)
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
	if (StrEqual(sTemp, ""))
		return 0;

	char sColors[3][4];
	int  color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if (color != 3)
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

bool IsValidEntRef(int entity)
{
	if (entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE && entity != -1)
		return true;
	return false;
}

public void OnEntityDestroyed(int entity)
{
	if (!IsValidEntityIndex(entity))
		return;

	RemoveEntityModelGlow(entity);
	delete g_iModelTimer[entity];

	ge_bMoveUp[entity] = false;
}

void RemoveItemGlow_Timer()
{
	for (int entity = 1; entity < MAXENTITIES; entity++)
	{
		RemoveEntityModelGlow(entity);
		delete g_iModelTimer[entity];
	}
}

void RemoveAllMark()
{
    int entity;
    char targetname[16];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_INFO_TARGET)) != INVALID_ENT_REFERENCE)
    {
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
        if (StrEqual(targetname, "l4d_mark_hint"))
            AcceptEntityInput(entity, "Kill");
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_ENV_SPRITE)) != INVALID_ENT_REFERENCE)
    {
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
        if (StrEqual(targetname, "l4d_mark_hint"))
            AcceptEntityInput(entity, "Kill");
    }
}

bool IsValidEntityIndex(int entity)
{
	return (MaxClients + 1 <= entity <= GetMaxEntities());
}

public void CreateItemGlow(int iEntity, const char[] sEntModelName)
{
	// Spawn dynamic prop entity
	int entity = CreateEntityByName("prop_dynamic_override");
	if (entity == -1) return;
	
	// Delete previous glow first
	RemoveEntityModelGlow(iEntity);
	delete g_iModelTimer[iEntity];

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
	SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iItemColorGlowRange);
	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iItemCvarColor);
	AcceptEntityInput(entity, "StartGlowing");

	// Set model invisible
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);

	// Set model attach to item, and always synchronize
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", iEntity);

	g_iModelIndex[iEntity] = EntIndexToEntRef(entity);

	g_iModelTimer[iEntity] = CreateTimer(g_fItemGlowTimer, ColdDown, iEntity);
}

public void CreateSpotMarker(int client)
{
	if (g_iMarkCvarColorArray[0] == 0) return; //disable mark glow

	bool  hit;
	float vStartPos[3], vEndPos[3];

	int clientAim = GetClientAimTarget(client, true);
	GetClientAbsOrigin(client, vStartPos);

	if (1 <= clientAim <= MaxClients && IsClientInGame(clientAim))
	{
		hit = true;
		GetClientAbsOrigin(clientAim, vEndPos);
	}
	else
	{
		float vPos[3];
		GetClientEyePosition(client, vPos);

		float vAng[3];
		GetClientEyeAngles(client, vAng);

		Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_ALL, RayType_Infinite, TraceFilter, client);

		if (TR_DidHit(trace))
		{
			hit = true;
			TR_GetEndPosition(vEndPos, trace);
		}

		delete trace;
	}

	if (!hit)    // not hit
		return;

	if (GetVectorDistance(vStartPos, vEndPos, true) > g_fMarkUseRange * g_fMarkUseRange)    // over distance
		return;

	fCoolDownTime[client] = GetEngineTime() + g_fCoolDown;

	if (strlen(g_sMarkUseSound) > 0)
		EmitSoundToAll(g_sMarkUseSound, client);

	float vBeamPos[3];
	vBeamPos = vEndPos;
	vBeamPos[2] += (2.0 + 1.0);    // Change the Z pos to go up according with the width for better looking

	int color[4];
	color[0] = g_iMarkCvarColorArray[0];
	color[1] = g_iMarkCvarColorArray[1];
	color[2] = g_iMarkCvarColorArray[2];
	color[3] = 255;

	float timeLimit = GetGameTime() + g_fMarkGlowTimer;

	DataPack pack;
	CreateDataTimer(1.0, TimerField, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(color[0]);
	pack.WriteCell(color[1]);
	pack.WriteCell(color[2]);
	pack.WriteCell(color[3]);
	pack.WriteFloat(timeLimit);
	pack.WriteFloat(vBeamPos[0]);
	pack.WriteFloat(vBeamPos[1]);
	pack.WriteFloat(vBeamPos[2]);

	float fieldDuration = (timeLimit - GetGameTime() < g_fMarkGlowTimer ? timeLimit - GetGameTime() : g_fMarkGlowTimer);

	if (fieldDuration < 0.11)    // Prevent rounding to 0 which makes the beam don't disappear
		fieldDuration = 0.11;    // less than 0.11 reads as 0 in L4D1

	TE_SetupBeamRingPoint(vBeamPos, 75.0, 100.0, g_iFieldModelIndex, 0, 0, 0, fieldDuration, 2.0, 0.0, color, 0, 0);
	TE_SendToAll();

	float vSpritePos[3];
	vSpritePos = vEndPos;
	vSpritePos[2] += 50.0;

	char targetname[19];
	FormatEx(targetname, sizeof(targetname), "%s-%02i", "l4d_mark_hint", client);

	int infoTarget = CreateEntityByName(CLASSNAME_INFO_TARGET);
	DispatchKeyValue(infoTarget, "targetname", targetname);

	TeleportEntity(infoTarget, vSpritePos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(infoTarget);
	ActivateEntity(infoTarget);

	SetEntPropEnt(infoTarget, Prop_Send, "m_hOwnerEntity", client);

	SetVariantString(g_sKillDelay);
	AcceptEntityInput(infoTarget, "AddOutput");
	AcceptEntityInput(infoTarget, "FireUser1");

	int sprite       = CreateEntityByName(CLASSNAME_ENV_SPRITE);
	DispatchKeyValue(sprite, "targetname", targetname);
	DispatchKeyValue(sprite, "spawnflags", "1");

	DispatchKeyValue(sprite, "model", MODEL_MARK_SPRITE);
	DispatchKeyValue(sprite, "rendercolor", g_sMarkCvarColor);
	DispatchKeyValue(sprite, "renderamt", "255");    // If renderamt goes before rendercolor, it doesn't render
	DispatchKeyValue(sprite, "scale", "0.25");
	DispatchKeyValue(sprite, "fademindist", "-1");

	TeleportEntity(sprite, vSpritePos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(sprite);
	ActivateEntity(sprite);

	SetVariantString("!activator");
	AcceptEntityInput(sprite, "SetParent", infoTarget);    // We need parent the entity to an info_target, otherwise SetTransmit won't work

	SetEntPropEnt(sprite, Prop_Send, "m_hOwnerEntity", client);
	AcceptEntityInput(sprite, "ShowSprite");
	SetVariantString(g_sKillDelay);
	AcceptEntityInput(sprite, "AddOutput");
	AcceptEntityInput(sprite, "FireUser1");

	CreateTimer(0.1, TimerMoveSprite, EntIndexToEntRef(sprite), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerField(Handle timer, DataPack pack)
{
	int color[4];
	float timeLimit;
	float vBeamPos[3];

	pack.Reset();
	color[0] = pack.ReadCell();
	color[1] = pack.ReadCell();
	color[2] = pack.ReadCell();
	color[3] = pack.ReadCell();
	timeLimit = pack.ReadFloat();
	vBeamPos[0] = pack.ReadFloat();
	vBeamPos[1] = pack.ReadFloat();
	vBeamPos[2] = pack.ReadFloat();

	if (timeLimit < GetGameTime())
		return;

	float fieldDuration = (timeLimit - GetGameTime() < g_fMarkGlowTimer ? timeLimit - GetGameTime() : g_fMarkGlowTimer);

	if (fieldDuration < 0.11) // Prevent rounding to 0 which makes the beam don't disappear
		fieldDuration = 0.11; // less than 0.11 reads as 0 in L4D1
		
	TE_SetupBeamRingPoint(vBeamPos, 75.0, 100.0, g_iFieldModelIndex, 0, 0, 0, fieldDuration, 2.0, 0.0, color, 0, 0);
	TE_SendToAll();

	DataPack pack2;
	CreateDataTimer(1.0, TimerField, pack2, TIMER_FLAG_NO_MAPCHANGE);
	pack2.WriteCell(color[0]);
	pack2.WriteCell(color[1]);
	pack2.WriteCell(color[2]);
	pack2.WriteCell(color[3]);
	pack2.WriteFloat(timeLimit);
	pack2.WriteFloat(vBeamPos[0]);
	pack2.WriteFloat(vBeamPos[1]);
	pack2.WriteFloat(vBeamPos[2]);
}

public Action TimerMoveSprite(Handle timer, int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return Plugin_Stop;

    float vPos[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

    if (ge_bMoveUp[entity])
    {
        vPos[2] += 1.0;

        if (vPos[2] >= 4.0)
            ge_bMoveUp[entity] = false;
    }
    else
    {
        vPos[2] -= 1.0;

        if (vPos[2] <= -4.0)
            ge_bMoveUp[entity] = true;
    }

    TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

    return Plugin_Continue;
}

int[] ConvertRGBToIntArray(char[] sColor)
{
    int color[3];

    if (sColor[0] == 0)
        return color;

    char sColors[3][4];
    int count = ExplodeString(sColor, " ", sColors, sizeof(sColors), sizeof(sColors[]));

    switch (count)
    {
        case 1:
        {
            color[0] = StringToInt(sColors[0]);
        }
        case 2:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
        }
        case 3:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
            color[2] = StringToInt(sColors[2]);
        }
    }

    return color;
}

public bool TraceFilter(int entity, int contentsMask, int client)
{
    if (entity == client)
        return false;

    if (entity == ENTITY_WORLDSPAWN || 1 <= entity <= MaxClients)
        return true;

    return false;
}

void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define sDENY_SOUND "buttons/button11.wav"
int g_UpgradePackCanUseCount;
ArrayList usedUpgrades[MAXPLAYERS+1];
float lastSoundTime[MAXPLAYERS+1];
bool bUsingExplosive[MAXPLAYERS+1];
bool bDeleteEntity[2048];

ConVar cvarDeniedSound;
ConVar cvarIncendiaryMulti;
ConVar cvarExplosiveMulti;
ConVar cvarClearUpgradeTime;

bool cvarDeniedSoundValue;
float cvarIncendiaryMultiValue;
float cvarExplosiveMultiValue;
float cvarClearUpgradeTimeValue;

public Plugin myinfo =
{
	name = "Upgrade Pack Fixes",
	author = "bullet28, V10, Silvers, Harry",
	description = "Fixes upgrade packs pickup bug when using survivor model change + remove upgrade pack",
	version = "1.4",
	url = "https://steamcommunity.com/profiles/76561198026784913"
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

public void OnAllPluginsLoaded() {

	static char smxFileName[32] = "l4d2_upgradepackfix.smx";
	if ( FindPluginByFile(smxFileName) != null ) 
		SetFailState("Please remove '%s' before using this plugin", smxFileName);

	smxFileName = "l4d2_upgrade_block.smx";
	if ( FindPluginByFile(smxFileName) != null ) 
		SetFailState("Please remove '%s' before using this plugin", smxFileName);
}

public void OnPluginStart() {
	Handle hGameData = LoadGameConfigFile("upgradepackfix");
	g_UpgradePackCanUseCount = GameConfGetOffset(hGameData, "m_iUpgradePackCanUseCount");
	delete hGameData;

	ResetAllUsedUpgrades();

	cvarDeniedSound = CreateConVar("upgrade_denied_sound", "1", "Play sound when ammo already used", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarIncendiaryMulti = CreateConVar("upgrade_incendiary_multi", "1.0", "Incendiary ammo multiplier on pickup", FCVAR_NOTIFY, true, 1.0);
	cvarExplosiveMulti = CreateConVar("upgrade_explosive_multi", "1.0", "Explosive ammo multiplier on pickup", FCVAR_NOTIFY, true, 1.0);
	cvarClearUpgradeTime = CreateConVar("upgrade_clear_time", "100", "Time in seconds to remove upgradepack after first use. (0=off)", FCVAR_NOTIFY, true, 0.0);

	GetCvars();
	cvarDeniedSound.AddChangeHook(OnConVarChange);
	cvarIncendiaryMulti.AddChangeHook(OnConVarChange);
	cvarExplosiveMulti.AddChangeHook(OnConVarChange);
	cvarClearUpgradeTime.AddChangeHook(OnConVarChange);

	HookEvent("round_start", EventRoundStart);
	HookEvent("player_bot_replace", OnBotSwap);
	HookEvent("bot_player_replace", OnBotSwap);

	AutoExecConfig(true, "lfd_both_fixUpgradePack");
}

public void OnMapStart()
{
	PrecacheSound(sDENY_SOUND, true);
}

public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue) {
	GetCvars();
}

void GetCvars()
{
	cvarDeniedSoundValue = cvarDeniedSound.BoolValue;
	cvarIncendiaryMultiValue = cvarIncendiaryMulti.FloatValue;
	cvarExplosiveMultiValue = cvarExplosiveMulti.FloatValue;
	cvarClearUpgradeTimeValue = cvarClearUpgradeTime.FloatValue;
}

public void OnClientPostAdminCheck(int client) {
	ResetUsedUpgrades(client);
}

public void EventRoundStart(Event event, const char[] name, bool dontBroadcast) {
	ResetAllUsedUpgrades();
}

public void OnBotSwap(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
	int player = GetClientOfUserId(GetEventInt(event, "player"));
	int entity;
	if (bot > 0 && bot <= MaxClients && player > 0 && player<= MaxClients) 
	{
		if(usedUpgrades[player] != null && usedUpgrades[bot] != null)
		{
			if (strcmp(name, "player_bot_replace") == 0) 
			{
				for( int i=0 ; i < GetArraySize(usedUpgrades[player]) ; ++i )
				{
					entity = GetArrayCell(usedUpgrades[player], i);
					if(FindValueInArray(usedUpgrades[bot], entity) == -1)
					{
						PushArrayCell(usedUpgrades[bot], entity);
					}
				}		
			}
			else 
			{
				for( int i=0 ; i < GetArraySize(usedUpgrades[bot]) ; ++i )
				{
					entity = GetArrayCell(usedUpgrades[bot], i);
					if(FindValueInArray(usedUpgrades[player], entity) == -1)
					{
						PushArrayCell(usedUpgrades[player], entity);
					}
				}
			}
		}
	}
}

void ResetAllUsedUpgrades() {
	for (int client = 1; client <= MaxClients; client++) {
		ResetUsedUpgrades(client);
	}
}

void ResetUsedUpgrades(int client) {
	delete usedUpgrades[client];
	usedUpgrades[client] = new ArrayList();
}

public void OnEntityCreated(int entity, const char[] classname) {

	if (!IsValidEntityIndex(entity))
		return;

	switch(classname[0])
	{
		case 'u':
		{
			if (strcmp(classname, "upgrade_ammo_explosive") == 0 || strcmp(classname, "upgrade_ammo_incendiary") == 0)
			{
				SDKHook(entity, SDKHook_SpawnPost, SpawnPost);
			}
		}
	}
}

void SpawnPost(int entity)
{
    if( !IsValidEntity(entity) ) return;

    RequestFrame(nextFrame, EntIndexToEntRef(entity));
}

void nextFrame(int entity)
{
    // Validate
    if( (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
    {
		SDKHook(entity, SDKHook_Use, OnUpgradeUse);
    }
} 

public Action OnUpgradeUse(int entity, int activator, int caller, UseType type, float value) {
	
	static char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));

	SetEntData(entity, g_UpgradePackCanUseCount, 4, 1, true);

	int client = caller;
	if (!isPlayerSurvivor(client)) return Plugin_Continue;

	int primaryItem = GetPlayerWeaponSlot(client, 0);
	if (primaryItem == -1) return Plugin_Continue;

	bUsingExplosive[client] = strcmp(classname, "upgrade_ammo_explosive") == 0 ? true : false ;
	
	SetEntProp(entity, Prop_Send, "m_iUsedBySurvivorsMask", 0);
	
	if (FindValueInArray(usedUpgrades[client], entity) != -1) {
		PlayDenySound(client);
		CheckKillPackage(entity);
		return Plugin_Handled;
	} else {
		//PrintToChatAll("%f: First use of %N", GetGameTime(), client);
		PushArrayCell(usedUpgrades[client], entity);
		lastSoundTime[client] = GetEngineTime();
		SetUsedBySurvivor(client, entity);

		if ((bUsingExplosive[client] && cvarExplosiveMultiValue > 1.0) || (!bUsingExplosive[client] && cvarIncendiaryMultiValue > 1.0)) {
			SDKHook(client, SDKHook_PostThink, PostThinkMultiply);
		}
		CheckKillPackage(entity);
	}

	return Plugin_Continue;
}

public void PostThinkMultiply(int client) {
	if (isPlayerAliveSurvivor(client)) {
		int primaryItem = GetPlayerWeaponSlot(client, 0);
		if (primaryItem != -1) {
			int currentUpgradedAmmo = GetEntProp(primaryItem, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
			int targetUpgradedAmmo = RoundToFloor(currentUpgradedAmmo * (bUsingExplosive[client] ? cvarExplosiveMultiValue : cvarIncendiaryMultiValue));
			if (targetUpgradedAmmo > currentUpgradedAmmo) {
				SetEntProp(primaryItem, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", targetUpgradedAmmo);
			}
		}
	}

	SDKUnhook(client, SDKHook_PostThink, PostThinkMultiply);
}

void SetUsedBySurvivor(int client, int entity) {
	int usedMask = GetEntProp(entity, Prop_Send, "m_iUsedBySurvivorsMask");
	bool bAlreadyUsed = !(usedMask & (1 << client - 1));
	if (bAlreadyUsed) return;

	int newMask = usedMask | (1 << client - 1);
	SetEntProp(entity, Prop_Send, "m_iUsedBySurvivorsMask", newMask);
}

void PlayDenySound(int client) {
	if (cvarDeniedSoundValue) {
		float currentTime = GetEngineTime();
		if (currentTime > lastSoundTime[client] + 2.0) {
			if(!IsFakeClient(client)) EmitSoundToClient(client, sDENY_SOUND, client, 3);
			lastSoundTime[client] = currentTime;
		}
	}
}

void CheckKillPackage(int entity)
{
	bool bAllSurvivorPickUp = true;
	for(int i =1; i <= MaxClients;++i)
	{
		if(isPlayerSurvivor(i) && FindValueInArray(usedUpgrades[i], entity) == -1) //still someone didn't pick up package
		{
			bAllSurvivorPickUp = false;
			break;
		}
	}

	if(bAllSurvivorPickUp) 
	{
		int index;
		for (int i = 1; i <= MaxClients; i++) {
			if(isPlayerSurvivor(i) && (index = FindValueInArray(usedUpgrades[i], entity)) != -1)
				RemoveFromArray(usedUpgrades[i],index);
		}
		AcceptEntityInput(entity, "Kill");
		return;
	}
	
	if(bDeleteEntity[entity] == false)
	{
		bDeleteEntity[entity] = true;
		if(cvarClearUpgradeTimeValue > 0.0) CreateTimer(cvarClearUpgradeTimeValue, Timer_RemoveEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_RemoveEntity(Handle timer, int ref)
{
	int entity;
	if(ref && (entity = EntRefToEntIndex(ref)) != INVALID_ENT_REFERENCE )
	{
		RemoveEntity(entity);
	}
	return Plugin_Continue;
}

bool isPlayerValid(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool isPlayerSurvivor(int client) {
	return isPlayerValid(client) && GetClientTeam(client) == 2;
}

bool isPlayerAliveSurvivor(int client) {
	return isPlayerSurvivor(client) && IsPlayerAlive(client);
}


bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}
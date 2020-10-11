#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define TANK_ZOMBIE_CLASS   8
ConVar g_hCvartankPropsGlow,g_hCvarRange,g_hCvarColor,g_hCvarTankOnly,g_hCvarTankSpec;
int g_iCvarRange,g_iCvarColor;
bool g_iCvarTankOnly,g_iCvarTankSpec;

Handle hTankProps       = INVALID_HANDLE;
Handle hTankPropsHit    = INVALID_HANDLE;
int i_Ent[5000] = -1;
int iTankClient = -1;
bool tankSpawned;

public Plugin myinfo = {
    name        = "L4D2 Tank Hittable Glow",
    author      = "Harry Potter",
    version     = "1.7",
    description = "When a Tank punches a Hittable it adds a Glow to the hittable which all infected players can see."
};

public OnPluginStart() {
	g_hCvartankPropsGlow = CreateConVar("l4d_tank_props_glow", "1", "Show Hittable Glow for infected team while the tank is alive", FCVAR_NOTIFY);
	g_hCvarColor =	CreateConVar(	"l4d2_tank_prop_glow_color",		"255 255 255",			"Prop Glow Color, three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_NOTIFY);
	g_hCvarRange =	CreateConVar(	"l4d2_tank_prop_glow_range",		"4500",				"How near to props do players need to be to enable their glow.", FCVAR_NOTIFY);
	g_hCvarTankOnly =	CreateConVar(	"l4d2_tank_prop_glow_only",		"0",				"Only Tank can see the glow", FCVAR_NOTIFY);
	g_hCvarTankSpec =	CreateConVar(	"l4d2_tank_prop_glow_spectators",		"1",				"Spectators can see the glow too", FCVAR_NOTIFY);

	g_hCvartankPropsGlow.AddChangeHook(TankPropsGlowAllow);
	g_hCvarColor.AddChangeHook(ConVarChanged_Glow);
	g_hCvarRange.AddChangeHook(ConVarChanged_Range);
	g_hCvarTankOnly.AddChangeHook(ConVarChanged_TankOnly);
	g_hCvarTankSpec.AddChangeHook(ConVarChanged_TankSpec);

	AutoExecConfig(true, "l4d2_tank_props_glow");

	PluginEnable();
}

PluginEnable() {
	SetConVarBool(FindConVar("sv_tankpropfade"), false);

	hTankProps = CreateArray();
	hTankPropsHit = CreateArray();

	HookEvent("round_start", TankPropRoundReset);
	HookEvent("round_end", TankPropRoundReset);
	HookEvent("tank_spawn", TankPropTankSpawn);
	HookEvent("player_death", TankPropTankKilled);

	char sColor[16];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	g_iCvarColor = GetColor(sColor);
	g_iCvarRange = GetConVarInt(g_hCvarRange);
	g_iCvarTankOnly = GetConVarBool(g_hCvarTankOnly);
	
}

void PluginDisable() {
	SetConVarBool(FindConVar("sv_tankpropfade"), true);

	UnhookEvent("round_start", TankPropRoundReset);
	UnhookEvent("round_end", TankPropRoundReset);
	UnhookEvent("tank_spawn", TankPropTankSpawn);
	UnhookEvent("player_death", TankPropTankKilled);

	if(!tankSpawned) return;

	int entity;

	for ( int i = 0; i < GetArraySize(hTankPropsHit); i++ ) {
		if ( IsValidEdict(GetArrayCell(hTankPropsHit, i)) ) {
			entity = i_Ent[GetArrayCell(hTankPropsHit, i)];
			if(IsValidEntRef(entity))
				AcceptEntityInput(entity, "Kill");
		}
	}
	tankSpawned = false;

	CloseHandle(hTankProps);
	CloseHandle(hTankPropsHit);
}

public Action TankPropRoundReset( Handle event, const char[] name, bool dontBroadcast ) {
    tankSpawned = false;
    
    UnhookTankProps();
    ClearArray(hTankPropsHit);
}

public Action TankPropTankSpawn( Handle event, const char[] name, bool dontBroadcast ) {
    if ( !tankSpawned ) {
        UnhookTankProps();
        ClearArray(hTankPropsHit);
        
        HookTankProps();
        
        tankSpawned = true;
    }    
}

public Action PD_ev_EntityKilled( Handle event, const char[] name, bool dontBroadcast )
{
	decl client;
	if (tankSpawned && IsTank((client = GetEventInt(event, "entindex_killed"))))
	{
		CreateTimer(1.5, TankDeadCheck, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action TankPropTankKilled( Handle event, const char[] name, bool dontBroadcast ) {
    if ( !tankSpawned ) {
        return;
    }
	
    CreateTimer(0.5, TankDeadCheck);
}

public Action TankDeadCheck( Handle timer ) {
    if ( GetTankClient() == -1 ) {
        UnhookTankProps();
        tankSpawned = false;
    }
}

public void PropDamaged(int victim, int attacker, int inflictor, float damage, int damageType) {
	if ( attacker == GetTankClient() || FindValueInArray(hTankPropsHit, inflictor) != -1 ) {
		if ( FindValueInArray(hTankPropsHit, victim) == -1 ) {
			PushArrayCell(hTankPropsHit, victim);			
			CreateTankPropGlow(victim);
		}
	}
}

void CreateTankPropGlow(int target)
{
	// Get Client Model
	decl String:sModelName[64];
	GetEntPropString(target, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
	
	// Spawn dynamic prop entity
	i_Ent[target] = CreateEntityByName("prop_dynamic_ornament");
	if (i_Ent[target] == -1) return;
	
	// Set new fake model
	PrecacheModel(sModelName);
	SetEntityModel(i_Ent[target], sModelName);
	DispatchSpawn(i_Ent[target]);

	// Set outline glow color
	SetEntProp(i_Ent[target], Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(i_Ent[target], Prop_Send, "m_nSolidType", 0);
	SetEntProp(i_Ent[target], Prop_Send, "m_nGlowRange", g_iCvarRange);
	SetEntProp(i_Ent[target], Prop_Send, "m_iGlowType", 2);
	SetEntProp(i_Ent[target], Prop_Send, "m_glowColorOverride", g_iCvarColor);
	AcceptEntityInput(i_Ent[target], "StartGlowing");

	// Set model invisible
	SetEntityRenderMode(i_Ent[target], RENDER_TRANSCOLOR);
	SetEntityRenderColor(i_Ent[target], 0, 0, 0, 0);

	// Set model attach to client, and always synchronize
	SetVariantString("!activator");
	AcceptEntityInput(i_Ent[target], "SetAttached", target);
	AcceptEntityInput(i_Ent[target], "TurnOn");

	SDKHook(i_Ent[target], SDKHook_SetTransmit, OnTransmit);
	
}

public Action OnTransmit(int entity, int client)
{
	
	if ( GetClientTeam(client) == 3)
	{
		if(IsTank(client))
			return Plugin_Continue;
		else
		{
			if(g_iCvarTankOnly == false)
				return Plugin_Continue;
			else
				return Plugin_Handled;
		}
	}
	else if ( GetClientTeam(client) == 1 && g_iCvarTankSpec == true)
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

bool IsTankProp(int iEntity ) {
    if ( !IsValidEdict(iEntity) ) {
        return false;
    }
    
    char className[64];
    
    GetEdictClassname(iEntity, className, sizeof(className));
    if ( StrEqual(className, "prop_physics") ) {
        if ( GetEntProp(iEntity, Prop_Send, "m_hasTankGlow", 1) ) {
            return true;
        }
    }
    else if ( StrEqual(className, "prop_car_alarm") ) {
        return true;
    }
    
    return false;
}

void HookTankProps() {
    int iEntCount = GetMaxEntities();
    
    for ( int i = 1; i <= iEntCount; i++ ) {
        if ( IsTankProp(i) ) {
			SDKHook(i, SDKHook_OnTakeDamagePost, PropDamaged);
			PushArrayCell(hTankProps, i);
		}
    }
}

void UnhookTankProps() {
	for ( int i = 0; i < GetArraySize(hTankProps); i++ ) {
		SDKUnhook(GetArrayCell(hTankProps, i), SDKHook_OnTakeDamagePost, PropDamaged);
	}

	int entity;
	for ( int i = 0; i < GetArraySize(hTankPropsHit); i++ ) {
		if ( IsValidEdict(GetArrayCell(hTankPropsHit, i)) ) {
			entity = i_Ent[GetArrayCell(hTankPropsHit, i)];
			if(IsValidEntRef(entity))
				AcceptEntityInput(entity, "Kill");
		}
	}
	ClearArray(hTankProps);
	ClearArray(hTankPropsHit);
}

int GetTankClient() {
    if ( iTankClient == -1 || !IsTank(iTankClient) ) {
        iTankClient = FindTank();
    }
    
    return iTankClient;
}

int FindTank() {
    for ( int i = 1; i <= MaxClients; i++ ) {
        if ( IsTank(i) ) {
            return i;
        }
    }
    
    return -1;
}

bool IsTank( int client ) {
    if ( client < 0
    || !IsClientConnected(client)
    || !IsClientInGame(client)
    || GetClientTeam(client) != 3
    || !IsPlayerAlive(client) ) {
        return false;
    }
    
    int playerClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    
    if ( playerClass == TANK_ZOMBIE_CLASS ) {
        return true;
    }
    
    return false;
}

public void TankPropsGlowAllow(Handle convar, const char[] oldValue, const char[] newValue) {
    if ( StringToInt(newValue) == 0 ) {
        PluginDisable();
    }
    else {
        PluginEnable();
    }
}

public ConVarChanged_Glow( Handle cvar, const char[] oldValue, const char[] newValue ){
	char sColor[16];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	g_iCvarColor = GetColor(sColor);

	if(!tankSpawned) return;

	int entity;

	for ( int i = 0; i < GetArraySize(hTankPropsHit); i++ ) {
		if ( IsValidEdict(GetArrayCell(hTankPropsHit, i)) ) {
			entity = i_Ent[GetArrayCell(hTankPropsHit, i)];
			if( IsValidEntRef(entity) )
			{
				SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColor);
			}
		}
	}
}

public ConVarChanged_Range( Handle cvar, const char[] oldValue, const char[] newValue ) {

	g_iCvarRange = g_hCvarRange.IntValue;

	if(!tankSpawned) return;

	int entity;

	for ( int i = 0; i < GetArraySize(hTankPropsHit); i++ ) {
		if ( IsValidEdict(GetArrayCell(hTankPropsHit, i)) ) {
			entity = i_Ent[GetArrayCell(hTankPropsHit, i)];
			if( IsValidEntRef(entity) )
			{
				SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarRange);
			}
		} 
	}
}

public ConVarChanged_TankOnly( Handle cvar, const char[] oldValue, const char[] newValue ) {
	
	g_iCvarTankOnly = g_hCvarTankOnly.BoolValue;
}

public ConVarChanged_TankSpec( Handle cvar, const char[] oldValue, const char[] newValue ) {
	g_iCvarTankSpec	= g_hCvarTankSpec.BoolValue;
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
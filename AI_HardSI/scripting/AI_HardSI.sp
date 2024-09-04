#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <actions>

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

bool 
	g_bPluginEnd;

#include "AI_HardSI/AI_Smoker.sp"
#include "AI_HardSI/AI_Boomer.sp"
#include "AI_HardSI/AI_Hunter.sp"
#include "AI_HardSI/AI_Spitter.sp"
#include "AI_HardSI/AI_Charger.sp"
#include "AI_HardSI/AI_Jockey.sp"
#include "AI_HardSI/AI_Tank.sp"

#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

#define DEBUG_FLOW 0

#define TEAM_CLASS(%1) (%1 == ZC_SMOKER ? "smoker" : (%1 == ZC_BOOMER ? "boomer" : (%1 == ZC_HUNTER ? "hunter" :(%1 == ZC_SPITTER ? "spitter" : (%1 == ZC_JOCKEY ? "jockey" : (%1 == ZC_CHARGER ? "charger" : (%1 == ZC_WITCH ? "witch" : (%1 == ZC_TANK ? "tank" : "None"))))))))
#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))

#define L4D2Team_Spectator 1
#define L4D2Team_Survivor 2
#define L4D2Team_Infected 3

#define L4D2Infected_Smoker 1
#define L4D2Infected_Boomer 2
#define L4D2Infected_Hunter 3
#define L4D2Infected_Spitter 4
#define L4D2Infected_Jockey 5
#define L4D2Infected_Charger 6
#define L4D2Infected_Witch 7
#define L4D2Infected_Tank 8

// alternative enumeration
// Special infected classes
#define ZC_NONE 0
#define ZC_SMOKER 1
#define ZC_BOOMER 2
#define ZC_HUNTER 3
#define ZC_SPITTER 4
#define ZC_JOCKEY 5
#define ZC_CHARGER 6
#define ZC_WITCH 7
#define ZC_TANK 8
#define ZC_NOTINFECTED 9

// 0=Anywhere, 1=Behind, 2=IT, 3=Specials in front, 4=Specials anywhere, 5=Far Away, 6=Above
#define ANYWHERE 0
#define BEHIND 1
#define IT 2
#define SPECIALS_IN_FRONT 3
#define SPECIALS_ANYWHERE 4
#define FAR_AWAY 5
#define ABOVE 6

ConVar 
	g_hCvarEnable, g_hCvarAssaultReminderInterval;

bool 
	g_bCvarEnable;

float 
	g_fCvarAssaultReminderInterval;

int 
	g_iCurTarget[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "AI: Hard SI",
	author = "Breezy & HarryPotter",
	description = "Improves the AI behaviour of special infected",
	version = "1.9-2024/9/4",
	url = "github.com/breezyplease"
};

public void OnPluginStart() 
{ 
	// Cvars
	g_hCvarEnable 				 	= CreateConVar( "AI_HardSI_enable",        		"1",   	"0=Plugin off, 1=Plugin on.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarAssaultReminderInterval 	= CreateConVar( "ai_assault_reminder_interval", "2", 	"Frequency(sec) at which the 'nb_assault' command is fired to make SI attack" );

	GetCvars();
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAssaultReminderInterval.AddChangeHook(ConVarChanged_Cvars);

	// Event hooks
	HookEvent("player_spawn", player_spawn);
	HookEvent("ability_use", ability_use); 
	// Load modules
	Smoker_OnModuleStart();
	Hunter_OnModuleStart();
	Spitter_OnModuleStart();
	Boomer_OnModuleStart();
	Charger_OnModuleStart();
	Jockey_OnModuleStart();
	Tank_OnModuleStart();
	//Autoconfig for plugin
	AutoExecConfig(true, "AI_HardSI");

	if(bLate)
	{
		LateLoad();
	}
}

void LateLoad()
{
	if(L4D_HasAnySurvivorLeftSafeArea())
	{
		CreateTimer( g_fCvarAssaultReminderInterval, Timer_ForceInfectedAssault, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
	}
}

public void OnPluginEnd() 
{
	g_bPluginEnd = true;
	// Unload modules
	Smoker_OnModuleEnd();
	Hunter_OnModuleEnd();
	Spitter_OnModuleEnd();
	Boomer_OnModuleEnd();
	Charger_OnModuleEnd();
	Jockey_OnModuleEnd();
	Tank_OnModuleEnd();
}

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarEnable = g_hCvarEnable.BoolValue;
	g_fCvarAssaultReminderInterval = g_hCvarAssaultReminderInterval.FloatValue;
}

/***********************************************************************************************************************************************************************************

																	KEEP SI AGGRESSIVE
																	
***********************************************************************************************************************************************************************************/

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client) 
{
	CreateTimer( g_fCvarAssaultReminderInterval, Timer_ForceInfectedAssault, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
}

Action Timer_ForceInfectedAssault( Handle timer ) 
{
	if(!g_bCvarEnable) return Plugin_Continue;

	CheatServerCommand("nb_assault");

	return Plugin_Continue;
}

// Actions API--------------

public void OnActionCreated(BehaviorAction action, int actor, const char[] name)
{
	switch (name[0])
	{
		case 'S': { if (strncmp(name, "Smoker", 6)) return; }
		default: { return; }
	}

	//if (!strcmp(name[6], "Behavior"))
	//{
	//	action.InitialContainedAction = SmokerBehavior_InitialContainedAction;
	//	action.InitialContainedActionPost = SmokerBehavior_InitialContainedAction_Post;
	//}
	if (!strcmp(name[6], "Attack"))
	{
		action.OnCommandAssault = SmokerAttack_OnCommandAssault;
	}
}

Action SmokerAttack_OnCommandAssault(any action, int actor, ActionDesiredResult result)
{
	if(!g_bCvarEnable) return Plugin_Continue;

	// 保護smoker不受到nb_assault影響產生bug
	// 當Smoker的舌頭斷掉之後，站在原地不動不撤退 (nb_assault的bug)
	return Plugin_Handled;
}

/***********************************************************************************************************************************************************************************

																		SI MOVEMENT
																	
***********************************************************************************************************************************************************************************/

// Modify SI movement
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
	if(!g_bCvarEnable) return Plugin_Continue;
	
	if( IsBotInfected(client) && IsPlayerAlive(client) && !L4D_IsPlayerGhost(client) ) 
	{ 
		if (L4D_IsPlayerStaggering(client))
			return Plugin_Continue;

		switch( GetInfectedClass(client) ) {

			case (L4D2Infected_Boomer): {
				return Boomer_OnPlayerRunCmd( client, buttons, impulse, vel, angles, weapon );
			}
		
			case (L4D2Infected_Hunter): {
				return Hunter_OnPlayerRunCmd( client, buttons, impulse, vel, angles, weapon );
			}		

			case (L4D2Infected_Spitter): {
				return Spitter_OnPlayerRunCmd( client, buttons, impulse, vel, angles, weapon );
			}	
			
			case (L4D2Infected_Charger): {
				return Charger_OnPlayerRunCmd( client, buttons, impulse, vel, angles, weapon );
			}	
			
			case (L4D2Infected_Jockey): {
				return Jockey_OnPlayerRunCmd( client, buttons, impulse, vel, angles, weapon );
			}
				
			case (L4D2Infected_Tank): {
				return Tank_OnPlayerRunCmd( client, buttons, impulse, vel, angles, weapon );
			}
				
			default: {
				return Plugin_Continue;
			}		
		}
	}
	return Plugin_Continue;
}

/***********************************************************************************************************************************************************************************

																		EVENT HOOKS

***********************************************************************************************************************************************************************************/

// Initialise relevant module flags for SI when they spawn
void player_spawn(Event event, char[] name, bool dontBroadcast) {
	if(!g_bCvarEnable) return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if( IsBotInfected(client) ) {
		int botInfected = client;
		// Process for SI class
		switch( GetInfectedClass(botInfected) ) {
			
			case (L4D2Infected_Hunter): {
				Hunter_OnSpawn(botInfected);
			}

			case (L4D2Infected_Charger): {
				Charger_OnSpawn(botInfected);
			}
			
			case (L4D2Infected_Jockey): {
				Jockey_OnSpawn(botInfected);
			}
			
			default: {
				return;	
			}				
		}
	}
}

// Modify hunter lunges and block smokers/spitters from fleeing after using their ability
void ability_use(Event event, char[] name, bool dontBroadcast) {
	if(!g_bCvarEnable) return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if( IsBotInfected(client) ) {
		int bot = client;
		// Process for different SI
		char abilityName[32];
		event.GetString("ability", abilityName, sizeof(abilityName));
		if( strcmp(abilityName, "ability_lunge") == 0) {
			ability_use_OnPounce(bot);
		} else if( strcmp(abilityName, "ability_charge") == 0) {
			ability_use_OnCharge(bot);
		} else if( strcmp(abilityName, "ability_vomit") == 0) {
			ability_use_OnVomit(bot);
		}
	}
}

// Left 4 Dhooks API----------

public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget) {
	g_iCurTarget[specialInfected] = curTarget;
	return Plugin_Continue;
}

public Action L4D2_OnSelectTankAttack(int client, int &sequence) {
	if(!g_bCvarEnable) return Plugin_Continue;

	return Tank_OnSelectTankAttack(client, sequence);
}

// Other----------

void GetSurDistance(int client, float &curTargetDist, float &nearestSurDist) {
	static float vPos[3];
	static float vTar[3];

	GetClientAbsOrigin(client, vPos);
	if (!IsAliveSur(g_iCurTarget[client]))
		curTargetDist = -1.0;
	else {
		GetClientAbsOrigin(g_iCurTarget[client], vTar);
		curTargetDist = GetVectorDistance(vPos, vTar);
	}

	static int i;
	static float dist;

	nearestSurDist = -1.0;
	GetClientAbsOrigin(client, vPos);
	for (i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, vTar);
			dist = GetVectorDistance(vPos, vTar);
			if (nearestSurDist == -1.0 || dist < nearestSurDist)
				nearestSurDist = dist;
		}
	}
}

float CurTargetDistance(int client) {
	if (!IsAliveSur(g_iCurTarget[client]))
		return -1.0;

	static float vPos[3];
	static float vTar[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsOrigin(g_iCurTarget[client], vTar);
	return GetVectorDistance(vPos, vTar);
}

int GetCurTarget(int client)
{
	return g_iCurTarget[client];
}


/**
 * Returns true if the player is currently on the survivor team. 
 *
 * @param client: client ID
 * @return bool
 */
stock bool IsSurvivor(int client) {
	if( IsValidClient(client) && GetClientTeam(client) == L4D2Team_Survivor ) {
		return true;
	} else {
		return false;
	}
}

stock bool IsPinned(int client) {
	bool bIsPinned = false;
	if (IsSurvivor(client)) {
		// check if held by:
		if( GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 ) bIsPinned = true; // smoker
		if( GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 ) bIsPinned = true; // hunter
		if( GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 ) bIsPinned = true; // charger carry
		if( GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 ) bIsPinned = true; // charger pound
		if( GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 ) bIsPinned = true; // jockey
	}		
	return bIsPinned;
}

/**
 * @return: The highest %map completion held by a survivor at the current point in time
 */
stock int GetMaxSurvivorCompletion() {
	float flow = 0.0;
	float tmp_flow;
	float origin[3];
	for ( int client = 1; client <= MaxClients; client++ ) {
		if ( IsSurvivor(client) && IsPlayerAlive(client) ) {
			GetClientAbsOrigin(client, origin);
			tmp_flow = GetFlow(origin);
			flow = MAX(flow, tmp_flow);
		}
	}
	
	int current = RoundToNearest(flow * 100 / L4D2Direct_GetMapMaxFlowDistance());
		
		#if DEBUG_FLOW
			Client_PrintToChatAll( true, "Current: {G}%d%%", current );
		#endif
		
	return current;
}

/**
 * @return: the farthest flow distance currently held by a survivor
 */
stock float GetFarthestSurvivorFlow() {
	float farthest_flow = 0.0;
	float origin[3];
	for (int client = 1; client <= MaxClients; client++) {
        if ( IsSurvivor(client) && IsPlayerAlive(client) ) {
            GetClientAbsOrigin(client, origin);
            float flow = GetFlow(origin);
            if ( flow > farthest_flow ) {
            	farthest_flow = flow;
            }
        }
    }
	return farthest_flow;
}

/**
 * Returns the average flow distance covered by each survivor
 */
stock float GetAverageSurvivorFlow() {
    int survivor_count = 0;
    float total_flow = 0.0;
    float origin[3];
    for (int client = 1; client <= MaxClients; client++) {
        if ( IsSurvivor(client) && IsPlayerAlive(client) ) {
            survivor_count++;
            GetClientAbsOrigin(client, origin);
            if ( GetFlow(origin) != -1.0 ) {
            	total_flow++;
            }
        }
    }
    return (total_flow / float(survivor_count));
}

/**
 * Returns the flow distance from given point to closest alive survivor. 
 * Returns -1.0 if either the given point or the survivors as a whole are not upon a valid nav mesh
 */
stock float GetFlowDistToSurvivors(const float pos[3]) {
	float spawnpoint_flow;
	float lowest_flow_dist = -1.0;
	
	spawnpoint_flow = GetFlow(pos);
	if ( spawnpoint_flow < 0) {
		return -1.0;
	}
	
	for ( int j = 1; j <= MaxClients; j++ ) {
		if ( IsSurvivor(j) && IsPlayerAlive(j) ) {
			float origin[3];
			float flow_dist;
			
			GetClientAbsOrigin(j, origin);
			flow_dist = GetFlow(origin);
			
			// have we found a int valid(i.e. != -1) lowest flow_dist
			if ( flow_dist > 0.0 && FloatCompare(FloatAbs(flow_dist - spawnpoint_flow), lowest_flow_dist) == -1 ) {
				lowest_flow_dist = flow_dist;
			}
		}
	}
	
	return lowest_flow_dist;
}

/**
 * Returns the flow distance of a given point
 */
 stock float GetFlow(const float o[3]) {
 	float origin[3]; //non constant var
 	origin[0] = o[0];
 	origin[1] = o[1];
 	origin[2] = o[2];
 	Address pNavArea;
 	pNavArea = L4D2Direct_GetTerrorNavArea(origin);
 	if ( pNavArea != Address_Null ) {
 		return L4D2Direct_GetTerrorNavAreaFlow(pNavArea);
 	} else {
 		return -1.0;
 	}
 }
 
/**
 * Returns true if the player is incapacitated. 
 *
 * @param client client ID
 * @return bool
 */
stock bool IsIncapacitated(int client) {
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

/**
 * Finds the closest survivor excluding a given survivor 
 * @param referenceClient: compares survivor distances to this client
 * @param excludeSurvivor: ignores this survivor
 * @return: the entity index of the closest survivor
**/
stock int GetClosestSurvivor( float referencePos[3], int excludeSurvivor = -1 ) {
	float survivorPos[3];
	int closestSurvivor = GetRandomSurvivor(1, -1);	
	if (closestSurvivor <= 0) return -1;
	GetClientAbsOrigin( closestSurvivor, survivorPos );
	int iClosestAbsDisplacement = RoundToNearest( GetVectorDistance(referencePos, survivorPos) );
	for (int client = 1; client <= MaxClients; client++) {
		if( IsSurvivor(client) && IsPlayerAlive(client) && client != excludeSurvivor ) {
			GetClientAbsOrigin( client, survivorPos );
			int iAbsDisplacement = RoundToNearest( GetVectorDistance(referencePos, survivorPos) );			
			if( iClosestAbsDisplacement < 0 ) { // Start with the absolute displacement to the first survivor found:
				iClosestAbsDisplacement = iAbsDisplacement;
				closestSurvivor = client;
			} else if( iAbsDisplacement < iClosestAbsDisplacement ) { // closest survivor so far
				iClosestAbsDisplacement = iAbsDisplacement;
				closestSurvivor = client;
			}			
		}
	}
	return closestSurvivor;
}

/**
 * Returns the distance of the closest survivor or a specified survivor
 * @param referenceClient: the client from which to measure distance to survivor
 * @param specificSurvivor: the index of the survivor to be measured, -1 to search for distance to closest survivor
 * @return: the distance
 */
stock int GetSurvivorProximity( const float rp[3], int specificSurvivor = -1 ) {
	
	int targetSurvivor;
	float targetSurvivorPos[3];
	float referencePos[3]; // non constant var
	referencePos[0] = rp[0];
	referencePos[1] = rp[1];
	referencePos[2] = rp[2];
	

	if( specificSurvivor > 0 && IsSurvivor(specificSurvivor) ) { // specified survivor
		targetSurvivor = specificSurvivor;		
	} else { // closest survivor		
		targetSurvivor = GetClosestSurvivor( referencePos );
	}
	
	if (targetSurvivor <= 0) return -1;

	GetEntPropVector( targetSurvivor, Prop_Send, "m_vecOrigin", targetSurvivorPos );
	return RoundToNearest( GetVectorDistance(referencePos, targetSurvivorPos) );
}

/***********************************************************************************************************************************************************************************

                                                                   	SPECIAL INFECTED 
                                                                    
***********************************************************************************************************************************************************************************/

/**
 * @return: the special infected class of the client
 */
stock int GetInfectedClass(int client) {
    return GetEntProp(client, Prop_Send, "m_zombieClass");
}

stock bool IsInfected(int client) {
    if (!IsClientInGame(client) || GetClientTeam(client) != L4D2Team_Infected) {
        return false;
    }
    return true;
}

/**
 * @return: true if client is a special infected bot
 */
stock bool IsBotInfected(int client) {
    // Check the input is valid
    if (!IsValidClient(client))return false;
    
    // Check if player is a bot on the infected team
    if (IsInfected(client) && IsFakeClient(client)) {
        return true;
    }
    return false; // otherwise
}

stock bool IsBotHunter(int client) {
	return (IsBotInfected(client) && GetInfectedClass(client) == L4D2Infected_Hunter);
}

stock bool IsBotCharger(int client) {
	return (IsBotInfected(client) && GetInfectedClass(client) == L4D2Infected_Charger);
}

stock bool IsBotJockey(int client) {
	return (IsBotInfected(client) && GetInfectedClass(client) == L4D2Infected_Jockey);
}

// @return: the number of a particular special infected class alive in the game
stock int CountSpecialInfectedClass(int targetClass) {
    int count = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if ( IsBotInfected(i) && IsPlayerAlive(i) && !IsClientInKickQueue(i) ) {
            int playerClass = GetEntProp(i, Prop_Send, "m_zombieClass");
            if (playerClass == targetClass) {
                count++;
            }
        }
    }
    return count;
}

// @return: the total special infected bots alive in the game
stock int CountSpecialInfectedBots() {
    int count = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsBotInfected(i) && IsPlayerAlive(i)) {
            count++;
        }
    }
    return count;
}

/***********************************************************************************************************************************************************************************

                                                                       		TANK
                                                                    
***********************************************************************************************************************************************************************************/

/**
 *@return: true if client is a tank
 */
stock bool IsTank(int client) {
    return IsClientInGame(client)
        && GetClientTeam(client) == L4D2Team_Infected
        && GetInfectedClass(client) == L4D2Infected_Tank;
}

/**
 * Searches for a player who is in control of a tank.
 *
 * @param iTankClient client index to begin searching from
 * @return client ID or -1 if not found
 */
stock int FindTankClient(int iTankClient) {
    for (int i = iTankClient < 0 ? 1 : iTankClient+1; i <= MaxClients; i++) {
        if (IsTank(i)) {
            return i;
        }
    }
    
    return -1;
}

/**
 * Is there a tank currently in play?
 *
 * @return bool
 */
stock bool IsTankInPlay() {
	if(FindTankClient(-1) != -1)
	{
		return true;
	}
	return false;
}

stock bool IsBotTank(int client) {
	// Check the input is valid
	if (!IsValidClient(client)) return false;
	// Check if player is on the infected team, a hunter, and a bot
	if (GetClientTeam(client) == L4D2Team_Infected) {
		int zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (zombieClass == L4D2Infected_Tank) {
			if(IsFakeClient(client)) {
				return true;
			}
		}
	}
	return false; // otherwise
}

/***********************************************************************************************************************************************************************************

                                                                   			MISC
                                                                    
***********************************************************************************************************************************************************************************/


stock void CheatServerCommand(char[] command)
{
    int flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    ServerCommand("%s", command);
    ServerExecute();
    SetCommandFlags(command, flags);
}

/**
 * Returns true if the client ID is valid
 *
 * @param client: client ID
 * @return bool
 */
stock bool IsValidClient(int client) {
    if( client > 0 && client <= MaxClients && IsClientInGame(client) ) {
    	return true;
    } else {
    	return false;
    }    
}

stock bool IsGenericAdmin(int client) {
	return CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false); 
}

/**
	Determines whether an attacking SI is being watched by the survivor
	@return: true if the survivor's crosshair is within the specified radius
	@param attacker: the client number of the attacking SI
	@param offsetThreshold: the radius(degrees) of the cone of detection around the straight line from the attacked survivor to the SI
**/
stock bool IsTargetWatchingAttacker( int attacker, float offsetThreshold ) {
	bool isWatching = true;
	if( GetClientTeam(attacker) == 3 && IsPlayerAlive(attacker) ) { // SI continue to hold on to their targets for a few seconds after death
		int target = GetClientAimTarget(attacker);
		if( IsSurvivor(target) ) { 
			if( GetPlayerAimOffset(target, attacker) <= offsetThreshold ) {
				isWatching = true;
			} else {
				isWatching = false;
			}		
		} 
	}	
	return isWatching;
}

/**
	Calculates how much a player's aim is off another player
	@return: aim offset in degrees
	@attacker: considers this player's eye angles
	@target: considers this player's position
	Adapted from code written by Guren with help from Javalia
**/
stock float GetPlayerAimOffset( int attacker, int target ) {
	if( !IsClientConnected(attacker) || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) )
		ThrowError("Client is not Alive."); 
	if(!IsClientConnected(target) || !IsClientInGame(target) || !IsPlayerAlive(target) )
		ThrowError("Target is not Alive.");
		
	float attackerPos[3], targetPos[3];
	float aimVector[3], directVector[3];
	float resultAngle;
	
	// Get the unit vector representing the attacker's aim
	GetClientEyeAngles(attacker, aimVector);
	aimVector[0] = aimVector[2] = 0.0; // Restrict pitch and roll, consider yaw only (angles on horizontal plane)
	GetAngleVectors(aimVector, aimVector, NULL_VECTOR, NULL_VECTOR); // extract the forward vector[3]
	NormalizeVector(aimVector, aimVector); // convert into unit vector
	
	// Get the unit vector representing the vector between target and attacker
	GetClientAbsOrigin(target, targetPos); 
	GetClientAbsOrigin(attacker, attackerPos);
	attackerPos[2] = targetPos[2] = 0.0; // Restrict to XY coordinates
	MakeVectorFromPoints(attackerPos, targetPos, directVector);
	NormalizeVector(directVector, directVector);
	
	// Calculate the angle between the two unit vectors
	resultAngle = RadToDeg(ArcCosine(GetVectorDotProduct(aimVector, directVector)));
	return resultAngle;
}

stock bool IsGrounded(int client) {
	return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1;
}

stock bool TargetSur(int client) {
	return IsAliveSur(GetClientAimTarget(client, true));
}

stock bool CheckPlayerMove(int client, float vel) {
	return vel > 0.9 * GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") > 0.0;
}

stock bool CheckHopVel(int client, const float vAng[3], const float vVel[3]) {
	static float vMins[3];
	static float vMaxs[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);

	static float vPos[3];
	static float vEnd[3];
	GetClientAbsOrigin(client, vPos);
	float vel = GetVectorLength(vVel);
	NormalizeVector(vVel, vEnd);
	ScaleVector(vEnd, vel + FloatAbs(vMaxs[0] - vMins[0]) + 3.0);
	AddVectors(vPos, vEnd, vEnd);

	static bool hit;
	static Handle hndl;
	static float vVec[3];
	static float vNor[3];
	static float vPlane[3];

	hit = false;
	vPos[2] += 10.0;
	vEnd[2] += 10.0;
	hndl = TR_TraceHullFilterEx(vPos, vEnd, vMins, vMaxs, MASK_PLAYERSOLID, TraceEntityFilter);
	if (TR_DidHit(hndl)) {
		hit = true;
		TR_GetEndPosition(vVec, hndl);

		NormalizeVector(vVel, vNor);
		TR_GetPlaneNormal(hndl, vPlane);
		if (RadToDeg(ArcCosine(GetVectorDotProduct(vNor, vPlane))) > 165.0) {
			delete hndl;
			return false;
		}

		vNor[1] = vAng[1];
		vNor[0] = vNor[2] = 0.0;
		GetAngleVectors(vNor, vNor, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vNor, vNor);
		if (RadToDeg(ArcCosine(GetVectorDotProduct(vNor, vPlane))) > 165.0) {
			delete hndl;
			return false;
		}
	}
	else {
		vNor[1] = vAng[1];
		vNor[0] = vNor[2] = 0.0;
		GetAngleVectors(vNor, vNor, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vNor, vNor);
		vPlane = vNor;
		ScaleVector(vPlane, 128.0);
		AddVectors(vPos, vPlane, vPlane);
		delete hndl;
		hndl = TR_TraceHullFilterEx(vPos, vPlane, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 33.0}), MASK_PLAYERSOLID, TraceWallFilter, client);
		if (TR_DidHit(hndl)) {
			TR_GetPlaneNormal(hndl, vPlane);
			if (RadToDeg(ArcCosine(GetVectorDotProduct(vNor, vPlane))) > 165.0) {
				delete hndl;
				return false;
			}
		}

		delete hndl;
	}

	delete hndl;
	if (!hit)
		vVec = vEnd;

	static float vDown[3];
	vDown[0] = vVec[0];
	vDown[1] = vVec[1];
	vDown[2] = vVec[2] - 100000.0;

	hndl = TR_TraceHullFilterEx(vVec, vDown, vMins, vMaxs, MASK_PLAYERSOLID, TraceSelfFilter, client);
	if (!TR_DidHit(hndl)) {
		delete hndl;
		return false;
	}

	TR_GetEndPosition(vEnd, hndl);
	delete hndl;
	return vVec[2] - vEnd[2] < 104.0;
}

stock bool TraceSelfFilter(int entity, int contentsMask, any data) {
	return entity != data;
}

stock bool TraceWallFilter(int entity, int contentsMask, any data) {
	if (entity != data) {
		static char cls[5];
		GetEdictClassname(entity, cls, sizeof cls);
		return cls[3] != 'e' && cls[3] != 'c';
	}

	return false;
}

stock bool TraceEntityFilter(int entity, int contentsMask) {
	if (!entity || entity > MaxClients) {
		static char cls[5];
		GetEdictClassname(entity, cls, sizeof cls);
		return cls[3] != 'e' && cls[3] != 'c';
	}

	return false;
}

stock float NearestSurDistance(int client) {
	static int i;
	static float vPos[3];
	static float vTar[3];
	static float dist;
	static float minDist;

	minDist = -1.0;
	GetClientAbsOrigin(client, vPos);
	for (i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, vTar);
			dist = GetVectorDistance(vPos, vTar);
			if (minDist == -1.0 || dist < minDist)
				minDist = dist;
		}
	}

	return minDist;
}

stock bool IsAliveSur(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

stock void ResetAbilityTime(int charger, float time) {
	static int ent;
	ent = GetEntPropEnt(charger, Prop_Send, "m_customAbility");
	if (ent > MaxClients)
		SetEntPropFloat(ent, Prop_Send, "m_timestamp", GetGameTime() + time);
}

stock bool entHitWall(int client, int target) {
	static float vPos[3];
	static float vTar[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsOrigin(target, vTar);
	vPos[2] += 10.0;
	vTar[2] += 10.0;

	MakeVectorFromPoints(vPos, vTar, vTar);
	static float dist;
	dist = GetVectorLength(vTar);
	NormalizeVector(vTar, vTar);
	ScaleVector(vTar, dist);
	AddVectors(vPos, vTar, vTar);

	static float vMins[3];
	static float vMaxs[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);
	vMins[2] += dist > 49.0 ? 10.0 : 44.0;
	vMaxs[2] -= 10.0;

	static bool hit;
	static Handle hndl;
	hndl = TR_TraceHullFilterEx(vPos, vTar, vMins, vMaxs, MASK_PLAYERSOLID, TraceEntityFilter);
	hit = TR_DidHit(hndl);
	delete hndl;
	return hit;
}

stock bool vecHitWall(int client, float vPos[3], float vTar[3]) {
	vPos[2] += 10.0;
	vTar[2] += 10.0;
	MakeVectorFromPoints(vPos, vTar, vTar);
	static float dist;
	dist = GetVectorLength(vTar);
	NormalizeVector(vTar, vTar);
	ScaleVector(vTar, dist);
	AddVectors(vPos, vTar, vTar);

	static float vMins[3];
	static float vMaxs[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);
	vMins[2] += 10.0;
	vMaxs[2] -= 10.0;

	static bool hit;
	static Handle hndl;
	hndl = TR_TraceHullFilterEx(vPos, vTar, vMins, vMaxs, MASK_PLAYERSOLID, TraceEntityFilter);
	hit = TR_DidHit(hndl);
	delete hndl;
	return hit;
}

stock bool WithinViewAngle(int client, float offsetThreshold) {
	static int target;
	target = GetClientAimTarget(client);
	if (!IsAliveSur(target))
		return true;
	
	static float vSrc[3];
	static float vTar[3];
	static float vAng[3];
	GetClientEyePosition(target, vSrc);
	GetClientEyePosition(client, vTar);
	if (IsVisibleTo(vSrc, vTar)) {
		GetClientEyeAngles(target, vAng);
		return PointWithinViewAngle(vSrc, vTar, vAng, GetFOVDotProduct(offsetThreshold));
	}

	return false;
}

stock bool WithinViewAngle2(int client, int viewer, float offsetThreshold) {
	static float vSrc[3];
	static float vTar[3];
	static float vAng[3];
	GetClientEyePosition(viewer, vSrc);
	GetClientEyePosition(client, vTar);
	if (IsVisibleTo(vSrc, vTar)) {
		GetClientEyeAngles(viewer, vAng);
		return PointWithinViewAngle(vSrc, vTar, vAng, GetFOVDotProduct(offsetThreshold));
	}

	return false;
}

stock int Math_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();

	if (random == 0) {
		random++;
	}

	return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}

// credits = "AtomicStryker"
stock bool IsVisibleTo(const float vPos[3], const float vTarget[3]) {
	static float vLookAt[3];
	MakeVectorFromPoints(vPos, vTarget, vLookAt);
	GetVectorAngles(vLookAt, vLookAt);

	static Handle hndl;
	hndl = TR_TraceRayFilterEx(vPos, vLookAt, MASK_VISIBLE, RayType_Infinite, TraceEntityFilter);

	static bool isVisible;
	isVisible = false;
	if (TR_DidHit(hndl)) {
		static float vStart[3];
		TR_GetEndPosition(vStart, hndl);

		if ((GetVectorDistance(vPos, vStart, false) + 25.0) >= GetVectorDistance(vPos, vTarget))
			isVisible = true;
	}

	delete hndl;
	return isVisible;
}

stock bool PointWithinViewAngle(const float vecSrcPosition[3], const float vecTargetPosition[3], const float vecLookDirection[3], float flCosHalfFOV) {
	static float vecDelta[3];
	SubtractVectors(vecTargetPosition, vecSrcPosition, vecDelta);
	static float cosDiff;
	cosDiff = GetVectorDotProduct(vecLookDirection, vecDelta);
	if (cosDiff < 0.0)
		return false;

	// a/sqrt(b) > c  == a^2 > b * c ^2
	return cosDiff * cosDiff >= GetVectorLength(vecDelta, true) * flCosHalfFOV * flCosHalfFOV;
}

stock float GetFOVDotProduct(float angle) {
	return Cosine(DegToRad(angle) / 2.0);
}
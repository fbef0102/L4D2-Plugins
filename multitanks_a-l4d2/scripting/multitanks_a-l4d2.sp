/*	The Last Stand Gamedate signature fix
*	(Thanks to Shadowysn's work, [L4D1/2] Direct Infected Spawn (Limit-Bypass), https://forums.alliedmods.net/showthread.php?t=320849)
*	(Stupid IDIOT TLS team, pushing unuseful updates no one really cares or asks for. Come on! Value)
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "2.1"
#define NAME_CreateTank "NextBotCreatePlayerBot<Tank>"

enum GameModeStatus
{
	GMS_UNKNOWN = 0,
	GMS_COOP = 1,
	GMS_VERSUS = 2,
	GMS_SURVIVAL = 3,
	GMS_SCAVENGE = 4
};

enum MapStatus
{
	MS_UNKNOWN = 0,
	MS_REGULAR = 1,
	MS_FINALE = 2,
	MS_ESCAPE = 3,
	MS_LEAVING = 4,
	MS_ROUNDEND = 5
};

char sLabels[5][] =
{
	"regular", "finale", "1stwave", "2ndwave", "escape"
};

GameModeStatus gmsBase;
MapStatus msBase;
int iFrustration[MAXPLAYERS+1], iTSHealthCoop[5], iTSHealthVersus[5], iTSHealthSurvival,
	iTSHealthScavenge, iTSCountCoop[5], iTSCountVersus[5], iTSCountSurvival, iTSCountScavenge,
	iFinaleWave, iTankHP, iMaxTankCount;

bool bRoundBegan, bRoundFinished, bIsTank[MAXPLAYERS+1], bTSOn, bTSAnnounce,
	bTSDisplay;

float fTSSpawnDelay[2];
ConVar hTSOn, hTSHealthCoop[5], hTSHealthVersus[5], hTSHealthSurvival, hTSHealthScavenge, hTSCountCoop[5],
	hTSCountVersus[5], hTSCountSurvival, hTSCountScavenge, hTSAnnounce, hTSSpawnDelay[2],
	hTSDisplay, hGameMode;

Panel pTSList;
static Handle hCreateTank;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (StrEqual(sGameName, "left4dead2", false))
	{
		return APLRes_Success;
	}
	
	strcopy(error, err_max, "[TS] Plugin Supports L4D2 Only!");
	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = "MultiTanks - Improved",
	author = "Red Alex, cravenge, Harry Potter",
	description = "This Time, Let All Hell Break Loose!",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/forumdisplay.php?f=108"
};

public void OnPluginStart()
{
	GetGameData();

	hGameMode = FindConVar("mp_gamemode");
	hGameMode.AddChangeHook(OnTSCVarsChanged);
	
	gmsBase = GetGameModeInfo();

	CreateConVar("multitanks_version", PLUGIN_VERSION, "MultiTanks Version.", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hTSOn = CreateConVar("multitanks_on", "1", "Enable/Disable Plugin.", FCVAR_NOTIFY|FCVAR_SPONLY);
	hTSHealthSurvival = CreateConVar("multitanks_health_survival", "10000", "Health Of Tanks (Survival), 0=off.", FCVAR_NOTIFY|FCVAR_SPONLY);
	hTSCountSurvival = CreateConVar("multitanks_count_survival", "2", "Total Count Of Tanks (Survival)", FCVAR_NOTIFY|FCVAR_SPONLY);
	hTSHealthScavenge = CreateConVar("multitanks_health_scavenge", "10000", "Health Of Tanks (Scavenge), 0=off.", FCVAR_NOTIFY|FCVAR_SPONLY);
	hTSCountScavenge = CreateConVar("multitanks_count_scavenge", "2", "Total Count Of Tanks (Scavenge)", FCVAR_NOTIFY|FCVAR_SPONLY);
	hTSAnnounce = CreateConVar("multitanks_announce", "0", "Enable/Disable Announcements when tank spawns.", FCVAR_NOTIFY|FCVAR_SPONLY);
	hTSDisplay = CreateConVar("multitanks_display", "0", "Enable/Disable Tank HUD Display", FCVAR_NOTIFY|FCVAR_SPONLY);
	
	iTSHealthSurvival = hTSHealthSurvival.IntValue;
	iTSCountSurvival = hTSCountSurvival.IntValue;
	iTSHealthScavenge = hTSHealthScavenge.IntValue;
	iTSCountScavenge = hTSCountScavenge.IntValue;
	
	bTSOn = hTSOn.BoolValue;
	bTSAnnounce = hTSAnnounce.BoolValue;
	bTSDisplay = hTSDisplay.BoolValue;
	
	hTSOn.AddChangeHook(OnTSCVarsChanged);
	hTSHealthSurvival.AddChangeHook(OnTSCVarsChanged);
	hTSCountSurvival.AddChangeHook(OnTSCVarsChanged);
	hTSHealthScavenge.AddChangeHook(OnTSCVarsChanged);
	hTSCountScavenge.AddChangeHook(OnTSCVarsChanged);
	hTSAnnounce.AddChangeHook(OnTSCVarsChanged);
	hTSDisplay.AddChangeHook(OnTSCVarsChanged);
	
	char sDescriptions[3][128];
	for (int i = 0; i < 2; i++)
	{
		StripQuotes(sLabels[i]);
		
		Format(sDescriptions[0], 128, "multitanks_spawn_delay_%s", sLabels[(i == 0) ? i : i + 3]);
		switch (i)
		{
			case 0:
			{
				strcopy(sDescriptions[1], 128, "5.0");
				strcopy(sDescriptions[2], 128, "Delay Of Spawning Tanks");
			}
			case 1:
			{
				strcopy(sDescriptions[1], 128, "2.5");
				strcopy(sDescriptions[2], 128, "Delay Of Spawning Tanks In Finale Escapes");
			}
		}
		
		hTSSpawnDelay[i] = CreateConVar(sDescriptions[0], sDescriptions[1], sDescriptions[2], FCVAR_NOTIFY|FCVAR_SPONLY);
		fTSSpawnDelay[i] = hTSSpawnDelay[i].FloatValue;
		hTSSpawnDelay[i].AddChangeHook(OnTSCVarsChanged);
	}
	
	for (int i = 0; i < 5; i++)
	{
		StripQuotes(sLabels[i]);
		
		Format(sDescriptions[0], 128, "multitanks_health_coop_%s", sLabels[i]);
		switch (i)
		{
			case 0:
			{
				strcopy(sDescriptions[1], 128, "0");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Regular Maps, 0=off.");
			}
			case 1:
			{
				strcopy(sDescriptions[1], 128, "0");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Finale Maps, 0=off.");
			}
			case 2:
			{
				strcopy(sDescriptions[1], 128, "0");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In First Wave Finales, 0=off.");
			}
			case 3:
			{
				strcopy(sDescriptions[1], 128, "0");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Second Wave Finales, 0=off.");
			}
			case 4:
			{
				strcopy(sDescriptions[1], 128, "0");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Finale Escapes, 0=off.");
			}
		}
		
		hTSHealthCoop[i] = CreateConVar(sDescriptions[0], sDescriptions[1], sDescriptions[2], FCVAR_NOTIFY|FCVAR_SPONLY);
		
		Format(sDescriptions[0], 128, "multitanks_count_coop_%s", sLabels[i]);
		strcopy(sDescriptions[1], 128, "1");
		switch (i)
		{
			case 0: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Regular Maps");
			case 1: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Finale Maps");
			case 2: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In First Wave Finales");
			case 3: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Second Wave Finales");
			case 4: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Finale Escapes");
		}
		
		hTSCountCoop[i] = CreateConVar(sDescriptions[0], sDescriptions[1], sDescriptions[2], FCVAR_NOTIFY|FCVAR_SPONLY);
		
		iTSHealthCoop[i] = hTSHealthCoop[i].IntValue;
		iTSCountCoop[i] = hTSCountCoop[i].IntValue;
		
		hTSHealthCoop[i].AddChangeHook(OnTSCVarsChanged);
		hTSCountCoop[i].AddChangeHook(OnTSCVarsChanged);
		
		Format(sDescriptions[0], 128, "multitanks_health_versus_%s", sLabels[i]);
		switch (i)
		{
			case 0:
			{
				strcopy(sDescriptions[1], 128, "8000");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Regular Maps (Versus), 0=off.");
			}
			case 1:
			{
				strcopy(sDescriptions[1], 128, "10000");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Finale Maps (Versus), 0=off.");
			}
			case 2:
			{
				strcopy(sDescriptions[1], 128, "12500");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In First Wave Finales (Versus), 0=off.");
			}
			case 3:
			{
				strcopy(sDescriptions[1], 128, "15000");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Second Wave Finales (Versus), 0=off.");
			}
			case 4:
			{
				strcopy(sDescriptions[1], 128, "20000");
				strcopy(sDescriptions[2], 128, "Health Of Tanks In Finale Escapes (Versus), 0=off.");
			}
		}
		
		hTSHealthVersus[i] = CreateConVar(sDescriptions[0], sDescriptions[1], sDescriptions[2], FCVAR_NOTIFY|FCVAR_SPONLY);
		
		Format(sDescriptions[0], 128, "multitanks_count_versus_%s", sLabels[i]);
		strcopy(sDescriptions[1], 128, "2");
		switch (i)
		{
			case 0: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Regular Maps (Versus)");
			case 1: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Finale Maps (Versus)");
			case 2: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In First Wave Finales (Versus)");
			case 3: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Second Wave Finales (Versus)");
			case 4: strcopy(sDescriptions[2], 128, "Total Count Of Tanks In Finale Escapes (Versus)");
		}
		
		hTSCountVersus[i] = CreateConVar(sDescriptions[0], sDescriptions[1], sDescriptions[2], FCVAR_NOTIFY|FCVAR_SPONLY);
		
		iTSHealthVersus[i] = hTSHealthVersus[i].IntValue;
		iTSCountVersus[i] = hTSCountVersus[i].IntValue;
		
		hTSHealthVersus[i].AddChangeHook(OnTSCVarsChanged);
		hTSCountVersus[i].AddChangeHook(OnTSCVarsChanged);
		
	}
	
	AutoExecConfig(true, "multitanks_a");
	
	HookEvent("round_start", OnRoundEvents);
	HookEvent("round_end", OnRoundEvents);
	
	HookEvent("finale_start", 			OnFinaleEvents, EventHookMode_PostNoCopy); //final starts, some of final maps won't trigger
	HookEvent("finale_radio_start", 	OnFinaleEvents, EventHookMode_PostNoCopy); //final starts, all final maps trigger
	HookEvent("gauntlet_finale_start", 	OnFinaleEvents, EventHookMode_PostNoCopy); //final starts, only rushing maps trigger (C5M5, C13M4)
	
	HookEvent("finale_escape_start", OnFinaleEvents);
	HookEvent("finale_vehicle_leaving", OnFinaleEvents);
	
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("tank_spawn", OnTankSpawn);
}

public void OnTSCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	bTSOn = hTSOn.BoolValue;
	bTSAnnounce = hTSAnnounce.BoolValue;
	bTSDisplay = hTSDisplay.BoolValue;
	
	for (int i = 0; i < 5; i++)
	{
		
		iTSHealthCoop[i] = hTSHealthCoop[i].IntValue;
		iTSCountCoop[i] = hTSCountCoop[i].IntValue;
		
		iTSHealthVersus[i] = hTSHealthVersus[i].IntValue;
		iTSCountVersus[i] = hTSCountVersus[i].IntValue;
	}
	
	iTSHealthSurvival = hTSHealthSurvival.IntValue;
	iTSCountSurvival = hTSCountSurvival.IntValue;
	iTSHealthScavenge = hTSHealthScavenge.IntValue;
	iTSCountScavenge = hTSCountScavenge.IntValue;
	
	for (int i = 0; i < 2; i++)
	{
		fTSSpawnDelay[i] = hTSSpawnDelay[i].FloatValue;
	}
	if (bTSOn)
	{
		gmsBase = GetGameModeInfo();
		LaunchTSParameters();
	}
}

public void OnPluginEnd()
{
	hTSOn.RemoveChangeHook(OnTSCVarsChanged);
	hTSHealthSurvival.RemoveChangeHook(OnTSCVarsChanged);
	hTSCountSurvival.RemoveChangeHook(OnTSCVarsChanged);
	hTSHealthScavenge.RemoveChangeHook(OnTSCVarsChanged);
	hTSCountScavenge.RemoveChangeHook(OnTSCVarsChanged);
	hTSAnnounce.RemoveChangeHook(OnTSCVarsChanged);
	hTSDisplay.RemoveChangeHook(OnTSCVarsChanged);
	for (int i = 0; i < 2; i++)
	{
		hTSSpawnDelay[i].RemoveChangeHook(OnTSCVarsChanged);
	}
	
	for (int i = 0; i < 5; i++)
	{
		hTSHealthCoop[i].RemoveChangeHook(OnTSCVarsChanged);
		hTSCountCoop[i].RemoveChangeHook(OnTSCVarsChanged);
		
		hTSHealthVersus[i].RemoveChangeHook(OnTSCVarsChanged);
		hTSCountVersus[i].RemoveChangeHook(OnTSCVarsChanged);
	}
	
	UnhookEvent("round_start", OnRoundEvents);
	UnhookEvent("round_end", OnRoundEvents);
	
	UnhookEvent("finale_start", 			OnFinaleEvents, EventHookMode_PostNoCopy); //final starts, some of final maps won't trigger
	UnhookEvent("finale_radio_start", 	OnFinaleEvents, EventHookMode_PostNoCopy); //final starts, all final maps trigger
	UnhookEvent("gauntlet_finale_start", 	OnFinaleEvents, EventHookMode_PostNoCopy); //final starts, only rushing maps trigger (C5M5, C13M4)

	UnhookEvent("finale_escape_start", OnFinaleEvents);
	UnhookEvent("finale_vehicle_leaving", OnFinaleEvents);
	
	UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	UnhookEvent("tank_spawn", OnTankSpawn);
}

public void OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
	if (!bTSOn)
	{
		return;
	}
	
	if (StrEqual(name, "round_start"))
	{
		bRoundBegan = true;
		bRoundFinished = false;
		
		msBase = MS_REGULAR;
	}
	else if (StrEqual(name, "round_end"))
	{
		bRoundBegan = false;
		bRoundFinished = true;
		
		msBase = MS_ROUNDEND;
	}
	LaunchTSParameters();
	
	iFinaleWave = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iFrustration[i] = 0;
			
			bIsTank[i] = false;
		}
	}
}

public void OnFinaleEvents(Event event, const char[] name, bool dontBroadcast)
{
	if (!bTSOn)
	{
		return;
	}
	
	if (StrEqual(name, "finale_start") || StrEqual(name, "finale_radio_start") || StrEqual(name, "gauntlet_finale_start") ||  StrEqual(name, "finale_vehicle_leaving"))
	{
		iFinaleWave = 0;
	}
	
	if (StrEqual(name, "finale_start"))
	{
		msBase = MS_FINALE;
	}
	else if (StrEqual(name, "finale_escape_start"))
	{
		msBase = MS_ESCAPE;
	}
	else if (StrEqual(name, "finale_vehicle_leaving"))
	{
		msBase = MS_LEAVING;
	}
	LaunchTSParameters();
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!bTSOn)
	{
		return Plugin_Continue;
	}
	
	int died = GetClientOfUserId(event.GetInt("userid"));
	if (!IsTank(died))
	{
		return Plugin_Continue;
	}
	
	bIsTank[died] = false;
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (!bTSOn)
	{
		return;
	}
	
	if (!IsTank(client))
	{
		return;
	}
	
	bIsTank[client] = false;
}

public void OnTankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!bTSOn)
	{
		return;
	}
	
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (!tank)
	{
		return;
	}
	
	if (!bIsTank[tank])
	{
		bIsTank[tank] = true;
		
		if (msBase == MS_FINALE)
		{
			iFinaleWave += 1;
			LaunchTSParameters();
		}
		
		if (iTankHP > 0)
		{
			SetEntProp(tank, Prop_Send, "m_iHealth", iTankHP, 1);
			SetEntProp(tank, Prop_Send, "m_iMaxHealth", iTankHP, 1);
		}
		
		if (GetTankCount() < iMaxTankCount)
		{
			CreateTimer((msBase != MS_ESCAPE) ? fTSSpawnDelay[0] : fTSSpawnDelay[1], SpawnMoreTank);
		}

		if (bTSAnnounce && msBase != MS_ROUNDEND)
		{
			if (IsFakeClient(tank))
			{
				PrintToChatAll("\x01[\x05TS\x01] New Tank Spawning (\x04%i\x01 HP) [AI]", GetEntProp(tank, Prop_Send, "m_iHealth"));
			}
			else
			{
				PrintToChatAll("\x01[\x05TS\x01] New Tank Spawning (\x04%i\x01 HP) [\04%N\01]", GetEntProp(tank, Prop_Send, "m_iHealth"), tank);
			}
		}
	}
	else
	{
		if (iTankHP > 0) SetEntProp(tank, Prop_Send, "m_iMaxHealth", iTankHP, 1);
	}
	
	if (bTSDisplay)
	{
		pTSList = new Panel();
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(i) && !GetEntProp(i, Prop_Send, "m_isIncapacitated", 1))
			{
				char sText[128];
				if (IsPlayerBurning(i))
				{
					Format(sText, sizeof(sText), "%N: %i HP (FIRE)", i, GetEntProp(i, Prop_Send, "m_iHealth"));
				}
				else
				{
					Format(sText, sizeof(sText), "%N: %i HP, Control: %i％", i, GetEntProp(i, Prop_Send, "m_iHealth"), 100 - GetEntProp(i, Prop_Send, "m_frustration"));
				}
				pTSList.DrawText(sText);
			}
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) != 2 && !IsFakeClient(i))
			{
				pTSList.Send(i, TSListHandler, 1);
			}
		}
		delete pTSList;
	}
}

public Action SpawnMoreTank(Handle timer)
{
	if (!bTSOn || !bRoundBegan || bRoundFinished)
	{
		return Plugin_Continue;
	}
	
	int iCommandExecuter = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			iCommandExecuter = i;
			break;
		}
	}
	
	if(iCommandExecuter == 0) return Plugin_Continue;

	if(RealFreePlayersOnInfected()) {
		CheatCommand(iCommandExecuter, "z_spawn_old", "tank auto");
		return Plugin_Continue;
	}
	
	float vecPos[3];
	if(L4D_GetRandomPZSpawnPosition(iCommandExecuter,8,5,vecPos) == true)
	{
		int bot = SDKCall(hCreateTank, "MultiTank"); //召喚坦克
		if (bot > 0 && bot <= MaxClients && IsClientInGame(bot))
		{
			SetEntityModel(bot, "models/infected/hulk.mdl");
			ChangeClientTeam(bot, 3);
			SetEntProp(bot, Prop_Send, "m_usSolidFlags", 16);
			SetEntProp(bot, Prop_Send, "movetype", 2);
			SetEntProp(bot, Prop_Send, "deadflag", 0);
			SetEntProp(bot, Prop_Send, "m_lifeState", 0);
			SetEntProp(bot, Prop_Send, "m_iObserverMode", 0);
			SetEntProp(bot, Prop_Send, "m_iPlayerState", 0);
			SetEntProp(bot, Prop_Send, "m_zombieState", 0);
			DispatchSpawn(bot);
			ActivateEntity(bot);
			TeleportEntity(bot, vecPos, NULL_VECTOR, NULL_VECTOR); //移動到相同位置
		}
	}
	
	return Plugin_Continue;
}

public int TSListHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		if (bTSDisplay)
		{
			pTSList = new Panel();
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(i) && !GetEntProp(i, Prop_Send, "m_isIncapacitated", 1))
				{
					char sText[128];
					if (IsPlayerBurning(i))
					{
						Format(sText, sizeof(sText), "%N: %i HP (FIRE)", i, GetEntProp(i, Prop_Send, "m_iHealth"));
					}
					else
					{
						Format(sText, sizeof(sText), "%N: %i HP, Control: %i％", i, GetEntProp(i, Prop_Send, "m_iHealth"), 100 - GetEntProp(i, Prop_Send, "m_frustration"));
					}
					pTSList.DrawText(sText);
				}
			}
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) != 2 && !IsFakeClient(i))
				{
					pTSList.Send(i, TSListHandler, 1);
				}
			}
			delete pTSList;
		}
	}

	return 0;
}

GameModeStatus GetGameModeInfo()
{
	char sGameMode[16];
	hGameMode.GetString(sGameMode, sizeof(sGameMode));
	if (StrEqual(sGameMode, "coop", false) || StrEqual(sGameMode, "realism", false))
	{
		return GMS_COOP;
	}
	else if (StrEqual(sGameMode, "versus", false) || StrEqual(sGameMode, "teamversus", false))
	{
		return GMS_VERSUS;
	}
	else if (StrEqual(sGameMode, "survival", false))
	{
		return GMS_SURVIVAL;
	}
	else if (StrEqual(sGameMode, "scavenge", false) || StrEqual(sGameMode, "teamscavenge", false))
	{
		return GMS_SCAVENGE;
	}
	else
	{
		return GMS_UNKNOWN;
	}
}

void LaunchTSParameters()
{
	switch (gmsBase)
	{
		case GMS_COOP:
		{
			switch (msBase)
			{
				case MS_REGULAR:
				{
					iTankHP = (L4D_IsMissionFinalMap()) ? iTSHealthCoop[1] : iTSHealthCoop[0];
					iMaxTankCount = (L4D_IsMissionFinalMap()) ? iTSCountCoop[1] : iTSCountCoop[0];
				}
				case MS_FINALE:
				{
					iTankHP = (iFinaleWave > 1) ? iTSHealthCoop[3] : iTSHealthCoop[2];
					iMaxTankCount = (iFinaleWave > 1) ? iTSCountCoop[3] : iTSCountCoop[2];
				}
				case MS_ESCAPE:
				{
					iTankHP = iTSHealthCoop[4];
					iMaxTankCount = iTSCountCoop[4];
				}
				case MS_LEAVING: iMaxTankCount = 0;
				case MS_ROUNDEND: iMaxTankCount = 0;
			}
		}
		case GMS_VERSUS: 
		{
			switch (msBase)
			{
				case MS_REGULAR:
				{
					iTankHP = (L4D_IsMissionFinalMap()) ? iTSHealthVersus[1] : iTSHealthVersus[0]; 	
					iMaxTankCount = (L4D_IsMissionFinalMap()) ? iTSCountVersus[1] : iTSCountVersus[0];
				}
				case MS_FINALE:
				{
					iTankHP = (iFinaleWave > 1) ? iTSHealthVersus[3] : iTSHealthVersus[2];
					iMaxTankCount = (iFinaleWave > 1) ? iTSCountVersus[3] : iTSCountVersus[2];
				}
				case MS_ESCAPE:
				{
					iTankHP = iTSHealthVersus[4];
					iMaxTankCount = iTSCountVersus[4];
				}
				case MS_LEAVING: iMaxTankCount = 0;
				case MS_ROUNDEND: iMaxTankCount = 0;
			}
		}
		case GMS_SURVIVAL: 
		{
			iTankHP = iTSHealthSurvival;
			iMaxTankCount = iTSCountSurvival;
		}
		case GMS_SCAVENGE: 
		{
			iTankHP = iTSHealthScavenge;
			iMaxTankCount = iTSCountScavenge;
		}
		case GMS_UNKNOWN: 
		{
			iTankHP = 0;
			iMaxTankCount = 1;
		}
	}
}

bool IsTank(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

bool IsPlayerBurning(int client)
{
	float fBurning = GetEntDataFloat(client, FindSendPropInfo("CTerrorPlayer", "m_burnPercent"));
	return (fBurning > 0.0) ? true : false;
}

Handle hGameConf;
void GetGameData()
{
	hGameConf = LoadGameConfigFile("multitanks_a");
	if( hGameConf != null )
	{
		PrepSDKCall();
	}
	else
	{
		SetFailState("Unable to find multitanks_a.txt gamedata file.");
	}
	delete hGameConf;
}

void PrepSDKCall()
{
	//find create bot signature
	Address replaceWithBot = GameConfGetAddress(hGameConf, "NextBotCreatePlayerBot.jumptable");
	if (replaceWithBot != Address_Null && LoadFromAddress(replaceWithBot, NumberType_Int8) == 0x68) {
		// We're on L4D2 and linux
		PrepWindowsCreateBotCalls(replaceWithBot);
	}
	else
	{
		PrepCreateTankBotCalls();
	}
}

void LoadStringFromAdddress(Address addr, char[] buffer, int maxlength) {
	int i = 0;
	while(i < maxlength) {
		char val = LoadFromAddress(addr + view_as<Address>(i), NumberType_Int8);
		if(val == 0) {
			buffer[i] = 0;
			break;
		}
		buffer[i] = val;
		i++;
	}
	buffer[maxlength - 1] = 0;
}

Handle PrepCreateBotCallFromAddress(Handle hSiFuncTrie, const char[] siName) {
	Address addr;
	StartPrepSDKCall(SDKCall_Static);
	if (!GetTrieValue(hSiFuncTrie, siName, addr) || !PrepSDKCall_SetAddress(addr))
	{
		SetFailState("Unable to find NextBotCreatePlayer<%s> address in memory.", siName);
		return null;
	}
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	return EndPrepSDKCall();	
}

void PrepWindowsCreateBotCalls(Address jumpTableAddr) {
	Handle hInfectedFuncs = CreateTrie();
	// We have the address of the jump table, starting at the first PUSH instruction of the
	// PUSH mem32 (5 bytes)
	// CALL rel32 (5 bytes)
	// JUMP rel8 (2 bytes)
	// repeated pattern.
	
	// Each push is pushing the address of a string onto the stack. Let's grab these strings to identify each case.
	// "Hunter" / "Smoker" / etc.
	for(int i = 0; i < 7; i++) {
		// 12 bytes in PUSH32, CALL32, JMP8.
		Address caseBase = jumpTableAddr + view_as<Address>(i * 12);
		Address siStringAddr = view_as<Address>(LoadFromAddress(caseBase + view_as<Address>(1), NumberType_Int32));
		static char siName[32];
		LoadStringFromAdddress(siStringAddr, siName, sizeof(siName));

		Address funcRefAddr = caseBase + view_as<Address>(6); // 2nd byte of call, 5+1 byte offset.
		int funcRelOffset = LoadFromAddress(funcRefAddr, NumberType_Int32);
		Address callOffsetBase = caseBase + view_as<Address>(10); // first byte of next instruction after the CALL instruction
		Address nextBotCreatePlayerBotTAddr = callOffsetBase + view_as<Address>(funcRelOffset);
		//PrintToServer("Found NextBotCreatePlayerBot<%s>() @ %08x", siName, nextBotCreatePlayerBotTAddr);
		SetTrieValue(hInfectedFuncs, siName, nextBotCreatePlayerBotTAddr);
	}

	hCreateTank = PrepCreateBotCallFromAddress(hInfectedFuncs, "Tank");
	if (hCreateTank == null)
	{ SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateTank); return; }
}

void PrepCreateTankBotCalls() {
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, NAME_CreateTank))
	{ SetFailState("Unable to find %s signature in gamedata file.", NAME_CreateTank); return; }
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	hCreateTank = EndPrepSDKCall();
	if (hCreateTank == null)
	{ SetFailState("Cannot initialize %s SDKCall, signature is broken.", NAME_CreateTank); return; }
}

bool RealFreePlayersOnInfected ()
{
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3 && (IsPlayerGhost(i) || !IsPlayerAlive(i)))
			return true;
	}
	return false;
}

stock void CheatCommand(int client,  char[] command, char[] arguments = "")
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

stock bool IsPlayerGhost(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	return false;
}

int GetTankCount()
{
	int tanks = 0;
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(i))
		{
			tanks++;	
		}
	}
	return tanks;
}
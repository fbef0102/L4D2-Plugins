#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <multicolors>
//#include <l4d2_changelevel>
#include <left4dhooks>

#define Version "2.3"
#define MAX_ARRAY_LINE 50
#define MAX_MAPNAME_LEN 64
#define MAX_CREC_LEN 2
#define MAX_REBFl_LEN 8

#define NEXTLEVEL_Seconds 6.0

ConVar DefM = null;
ConVar CheckRoundCounterCoop = null;
ConVar CheckRoundCounterCoopFinal = null;
ConVar ChDelayVS = null;
ConVar ChDelayCOOPFinal = null;
ConVar cvarAnnounce = null;
ConVar h_GameMode;

int iGameMode;
char FMC_FileSettings[128];
char current_map[64];
char announce_map[64];
char next_mission_def[64];
char next_mission_force[64];
char force_mission_name[64];
char sNextStageMapName[64];
int RoundEndCounter = 0;
bool RoundEndBlock, cvarAnnounceValue;
float ChDelayVSValue, ChDelayCOOPFinalValue;
int CoopRoundEndCounter = 0;
int CheckRoundCounterCoopFinalValue, CheckRoundCounterCoopValue;

Handle hKVSettings = null;

public Plugin myinfo = 
{
	name = "L4D2 Force Mission Changer",
	author = "Dionys, Harry, Jeremy Villanueva",
	description = "Force change to next mission when current mission end.",
	version = Version,
	url = "https://steamcommunity.com/id/fbef0102/"
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
	LoadTranslations("sm_l4d_mapchanger.phrases");

	hKVSettings=CreateKeyValues("ForceMissionChangerSettings");

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("mission_lost", Event_MissionLost);
	
	DefM = CreateConVar("sm_l4d_fmc_def", "c2m1_highway", "Mission for change by default.", FCVAR_NOTIFY);
	CheckRoundCounterCoop = CreateConVar("sm_l4d_fmc_crec_coop_map", "3", "Quantity of rounds (tries) events survivors wipe out before force of changelevel on non-final maps in coop/realism (0=off)", FCVAR_NOTIFY, true, 0.0);
	CheckRoundCounterCoopFinal = CreateConVar("sm_l4d_fmc_crec_coop_final", "3", "Quantity of rounds (tries) events survivors wipe out before force of changelevel on final maps in coop/realism (0=off)", FCVAR_NOTIFY, true, 0.0);
	ChDelayVS = CreateConVar("sm_l4d_fmc_chdelayvs", "1.0", "After final map finishes, delay before force of changelevel in versus. (0=off)", FCVAR_NOTIFY, true, 0.0);
	ChDelayCOOPFinal = CreateConVar("sm_l4d_fmc_ChDelayCOOP_final", "10.0", "After final rescue vehicle leaving, delay before force of changelevel in coop/realism. (0=off)", FCVAR_NOTIFY, true, 0.0);
	cvarAnnounce = CreateConVar("sm_l4d_fmc_announce", "1", "Enables next mission and how many chances left to advertise to players.", FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	h_GameMode = FindConVar("mp_gamemode");

	GetCvars();
	GameModeCheck();
	h_GameMode.AddChangeHook(ConVarGameMode);
	DefM.AddChangeHook(ConVarChanged_Cvars);
	CheckRoundCounterCoop.AddChangeHook(ConVarChanged_Cvars);
	CheckRoundCounterCoopFinal.AddChangeHook(ConVarChanged_Cvars);
	ChDelayVS.AddChangeHook(ConVarChanged_Cvars);
	ChDelayCOOPFinal.AddChangeHook(ConVarChanged_Cvars);
	cvarAnnounce.AddChangeHook(ConVarChanged_Cvars);

	AutoExecConfig(true, "sm_l4d_mapchanger");
}
public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	DefM.GetString(next_mission_def, 64);
	CheckRoundCounterCoopValue = CheckRoundCounterCoop.IntValue;
	CheckRoundCounterCoopFinalValue = CheckRoundCounterCoopFinal.IntValue;
	ChDelayVSValue = ChDelayVS.FloatValue;
	ChDelayCOOPFinalValue = ChDelayCOOPFinal.FloatValue;
	cvarAnnounceValue = cvarAnnounce.BoolValue;
}

public void ConVarGameMode(ConVar cvar, const char[] sOldValue, const char[] sintValue)
{
	GameModeCheck();
}

bool g_bMapStarted;
public void OnMapStart()
{
	g_bMapStarted = true;
	AutoExecConfig(true, "sm_l4d_mapchanger");
	
	CoopRoundEndCounter = 0;
	RoundEndCounter = 0;
	RoundEndBlock= false;

	PluginInitialization();
}

public void OnConfigsExecuted()
{
	if(g_bMapStarted) PluginInitialization();
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnClientPutInServer(int client)
{
	// Make the announcement in 20 seconds unless announcements are turned off
	if(client && !IsFakeClient(client) && cvarAnnounceValue)
		CreateTimer(15.0, TimerAnnounce, client);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if(iGameMode == 1)
	{
		int left;
		if(L4D_IsMissionFinalMap())
		{
			if(CheckRoundCounterCoopFinalValue > 0 && CoopRoundEndCounter > 0) 
			{
				left = CheckRoundCounterCoopFinalValue-CoopRoundEndCounter;//Intentos - Intentos Realizados
				if(left > 0 && cvarAnnounceValue) CPrintToChatAll("%t","Finale Tries Left",left);
				if(left == 1)
				{
					if(cvarAnnounceValue) CPrintToChatAll("%t","Finale 1 Try Left",announce_map);
				}
			}
		}
		else
		{
			if(CheckRoundCounterCoopValue > 0 && CoopRoundEndCounter > 0) 
			{
				left = CheckRoundCounterCoopValue - CoopRoundEndCounter;
				if(left > 0 && cvarAnnounceValue) CPrintToChatAll("%t","Tries Left", left);
			}
		}
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	if (RoundEndBlock == false)
	{
		RoundEndCounter += 1;
		RoundEndBlock = true;
		CreateTimer(0.5, TimerRoundEndBlock);
	}

	if( ChDelayVSValue > 0 && iGameMode == 2 && StrEqual(next_mission_force, "none") != true && RoundEndCounter >= 4 && L4D_IsMissionFinalMap())
	{
		CreateTimer(ChDelayVSValue, TimerChDelayVS);
		RoundEndCounter = 0;
	}
}


public Action Event_FinalWin(Event event, const char[] name, bool dontBroadcast) 
{
	if(ChDelayCOOPFinalValue > 0 && iGameMode == 1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(ChDelayCOOPFinalValue, TimerChDelayCOOPFinal);
}

public Action Event_MissionLost(Event event, const char[] name, bool dontBroadcast) 
{
	if(iGameMode == 1)
	{
		CoopRoundEndCounter += 1;//Intentos Realizados +1
		if(L4D_IsMissionFinalMap())
		{
			if(StrEqual(next_mission_force, "none") != true && CheckRoundCounterCoopFinalValue > 0 && CoopRoundEndCounter >= CheckRoundCounterCoopFinalValue)
			{
				CPrintToChatAll("%t","Force Pass Campaign No Tries Left", CheckRoundCounterCoopFinalValue);
				CreateTimer(NEXTLEVEL_Seconds, TimerChDelayCOOPFinal);
			}
		}
		else
		{
			if(CheckRoundCounterCoopValue > 0 && CoopRoundEndCounter >= CheckRoundCounterCoopValue)
			{
				CPrintToChatAll("%t","Force Pass Map No Tries Left", CheckRoundCounterCoopValue);
				CreateTimer(NEXTLEVEL_Seconds, TimerChDelayCOOPMap);
			}		
		}
	}
}

public Action TimerAnnounce(Handle timer, any client)
{
	if(IsClientInGame(client))
	{
		if (L4D_IsMissionFinalMap())
		{
			CPrintToChat(client, "%t","Announce Map", announce_map);
		}
	}
}

public Action TimerRoundEndBlock(Handle timer)
{
	RoundEndBlock = false;
}

public Action TimerChDelayVS(Handle timer)
{
	ServerCommand("changelevel %s", next_mission_force);
	//L4D2_ChangeLevel(next_mission_force);
}

public Action TimerChDelayCOOPFinal(Handle timer)
{
	ServerCommand("changelevel %s", next_mission_force);
	//L4D2_ChangeLevel(next_mission_force);
}

public Action TimerChDelayCOOPMap(Handle timer)
{
	ServerCommand("changelevel %s", sNextStageMapName);
	//L4D2_ChangeLevel(sNextStageMapName);
}

void ClearKV(Handle kvhandle)
{
	KvRewind(kvhandle);
	if (KvGotoFirstSubKey(kvhandle))
	{
		do
		{
			KvDeleteThis(kvhandle);
			KvRewind(kvhandle);
		}
		while (KvGotoFirstSubKey(kvhandle));
		KvRewind(kvhandle);
	}
}

void PluginInitialization()
{
	ClearKV(hKVSettings);
	
	BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4d_mapchanger.txt");

	if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		SetFailState("Force Mission Changer settings not found! Shutdown.");
	
	next_mission_force = "none";
	GetCurrentMap(current_map, 64);

	KvRewind(hKVSettings);
	if(KvJumpToKey(hKVSettings, current_map))
	{
		KvGetString(hKVSettings, "next mission map", next_mission_force, 64, next_mission_def);//Force Next Campaign,Def Next Map
		//LogMessage("next_mission map: %s",next_mission_force);
		KvGetString(hKVSettings, "next mission name", force_mission_name, 64, "none");
		//LogMessage("next mission name: %s",force_mission_name);
	}
	KvRewind(hKVSettings);
		
	if (StrEqual(next_mission_force, "none") != true)
	{
		if (!IsMapValid(next_mission_force))
			next_mission_force = next_mission_def;

		if (StrEqual(force_mission_name, "none") != true)
			announce_map = force_mission_name;
		else
			announce_map = next_mission_force;
	}
	else
	{
		announce_map = next_mission_def;
		next_mission_force = next_mission_def;
	}

	if(L4D_IsMissionFinalMap() == false && iGameMode == 1)
	{
		int ent = FindEntityByClassname(-1, "info_changelevel");
		if(ent == -1)
		{
			ent = FindEntityByClassname(-1, "trigger_changelevel");
		}

		if(ent == -1)
			sNextStageMapName = next_mission_def;
		else
			GetEntPropString(ent, Prop_Data, "m_mapName", sNextStageMapName, sizeof(sNextStageMapName)); // Get Prop Name
		//LogMessage("sm_l4d_mapchanger: Next stage: %s", sNextStageMapName);
	}
}

void GameModeCheck()
{
	static char GameName[16];
	h_GameMode.GetString(GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		iGameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false) || StrEqual(GameName, "mutation12", false) || StrEqual(GameName, "mutation13", false) || StrEqual(GameName, "mutation15", false) || StrEqual(GameName, "mutation11", false))
		iGameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false) || StrEqual(GameName, "mutation3", false) || StrEqual(GameName, "mutation9", false) || StrEqual(GameName, "mutation1", false) || StrEqual(GameName, "mutation7", false) || StrEqual(GameName, "mutation10", false) || StrEqual(GameName, "mutation2", false) || StrEqual(GameName, "mutation4", false) || StrEqual(GameName, "mutation5", false) || StrEqual(GameName, "mutation14", false))
		iGameMode = 1;
	else
		iGameMode = 1;
}
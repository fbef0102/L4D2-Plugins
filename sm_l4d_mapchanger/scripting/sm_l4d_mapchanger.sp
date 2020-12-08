#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <l4d2_changelevel>
#include <left4dhooks>

#define Version "1.8"
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

char GameName[16];
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
	author = "Dionys, Harry",
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
	hKVSettings=CreateKeyValues("ForceMissionChangerSettings");

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("mission_lost", Event_MissionLost);
	
	DefM = CreateConVar("sm_l4d_fmc_def", "c2m1_highway", "Mission for change by default.", FCVAR_NOTIFY);
	CheckRoundCounterCoop = CreateConVar("sm_l4d_fmc_crec_coop_map", "3", "Quantity of events survivors wipe out before force of changelevel on non-final maps in coop (0=off)", FCVAR_NOTIFY, true, 0.0);
	CheckRoundCounterCoopFinal = CreateConVar("sm_l4d_fmc_crec_coop_final", "3", "Quantity of events survivors wipe out before force of changelevel on final maps in coop (0=off)", FCVAR_NOTIFY, true, 0.0);
	ChDelayVS = CreateConVar("sm_l4d_fmc_chdelayvs", "1.0", "After final map finishes, delay before force of changelevel in versus. (0=off)", FCVAR_NOTIFY, true, 0.0);
	ChDelayCOOPFinal = CreateConVar("sm_l4d_fmc_ChDelayCOOP_final", "10.0", "After final rescue vehicle leaving, delay before force of changelevel in coop. (0=off)", FCVAR_NOTIFY, true, 0.0);
	cvarAnnounce = CreateConVar("sm_l4d_fmc_announce", "1", "Enables next mission and how many chances left to advertise to players.", FCVAR_NOTIFY, true, 0.0, true, 1.0 );

	GetCvars();
	h_GameMode = FindConVar("mp_gamemode");
	h_GameMode.GetString(GameName, sizeof(GameName));
	h_GameMode.AddChangeHook(ConVarGameMode);
	DefM.AddChangeHook(ConVarChanged_Cvars);
	CheckRoundCounterCoop.AddChangeHook(ConVarChanged_Cvars);
	CheckRoundCounterCoopFinal.AddChangeHook(ConVarChanged_Cvars);
	ChDelayVS.AddChangeHook(ConVarChanged_Cvars);
	ChDelayCOOPFinal.AddChangeHook(ConVarChanged_Cvars);
	cvarAnnounce.AddChangeHook(ConVarChanged_Cvars);

	AutoExecConfig(true, "sm_l4d_mapchanger");

	PluginInitialization();
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
	h_GameMode.GetString(GameName, sizeof(GameName));
}
public void OnMapStart()
{
	AutoExecConfig(true, "sm_l4d_mapchanger");
	
	CoopRoundEndCounter = 0;
	RoundEndCounter = 0;
	RoundEndBlock= false;

	PluginInitialization();
}

public void OnClientPutInServer(int client)
{
	// Make the announcement in 20 seconds unless announcements are turned off
	if(client && !IsFakeClient(client) && cvarAnnounceValue)
		CreateTimer(15.0, TimerAnnounce, client);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if(StrEqual(GameName,"coop"))
	{
		int left;
		if(L4D_IsMissionFinalMap())
		{
			if(CheckRoundCounterCoopFinalValue > 0 && CoopRoundEndCounter > 0) 
			{
				left = CheckRoundCounterCoopFinalValue-CoopRoundEndCounter;
				if(left > 0 && cvarAnnounceValue) CPrintToChatAll("{default}[{olive}TS{default}]{default} 還剩下 {green}%d {default}次機會挑戰 {lightgreen}最後關卡{default}.", left);
				if(left == 1)
				{
					if(cvarAnnounceValue) CPrintToChatAll("下一張圖 Next Map{default}: {blue}%s{default}.", announce_map);
				}
			}
		}
		else
		{
			if(CheckRoundCounterCoopValue > 0 && CoopRoundEndCounter > 0) 
			{
				left = CheckRoundCounterCoopValue - CoopRoundEndCounter;
				if(left > 0 && cvarAnnounceValue) CPrintToChatAll("{default}[{olive}TS{default}]{default} 還剩下 {green}%d {default}次機會挑戰 {lightgreen}本關卡{default}.", left);
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

	if( ChDelayVSValue > 0 && StrEqual(GameName,"versus") && StrEqual(next_mission_force, "none") != true && RoundEndCounter >= 4)
	{
		CreateTimer(ChDelayVSValue, TimerChDelayVS);
		RoundEndCounter = 0;
	}
}


public Action Event_FinalWin(Event event, const char[] name, bool dontBroadcast) 
{
	if(ChDelayCOOPFinalValue > 0 && StrEqual(GameName,"coop") && StrEqual(next_mission_force, "none") != true)
		CreateTimer(ChDelayCOOPFinalValue, TimerChDelayCOOPFinal);
}

public Action Event_MissionLost(Event event, const char[] name, bool dontBroadcast) 
{
	if(StrEqual(GameName,"coop"))
	{
		CoopRoundEndCounter += 1;
		if(L4D_IsMissionFinalMap())
		{
			if(StrEqual(next_mission_force, "none") != true && CheckRoundCounterCoopFinalValue > 0 && CoopRoundEndCounter >= CheckRoundCounterCoopFinalValue)
			{
				CPrintToChatAll("{default}[{olive}TS{default}]{default} 滅團失敗已達 {green}%d {default}次，正在切換{blue}下一張地圖{default}.", CheckRoundCounterCoopFinalValue);
				CreateTimer(NEXTLEVEL_Seconds, TimerChDelayCOOPFinal);
			}
		}
		else
		{
			if(CheckRoundCounterCoopValue > 0 && CoopRoundEndCounter >= CheckRoundCounterCoopValue)
			{
				CPrintToChatAll("{default}[{olive}TS{default}]{default} 滅團失敗已達 {green}%d {default}次，正在切換{lightgreen}下一關卡{default}.", CheckRoundCounterCoopValue);
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
			CPrintToChat(client, "{default}[{olive}TS{default}]{default} 下一張圖 Next Map{default}: {blue}%s{default}.", announce_map);
		}
	}
}

public Action TimerRoundEndBlock(Handle timer)
{
	RoundEndBlock = false;
}

public Action TimerChDelayVS(Handle timer)
{
	L4D2_ChangeLevel(next_mission_force);
}

public Action TimerChDelayCOOPFinal(Handle timer)
{
	L4D2_ChangeLevel(next_mission_force);
}

public Action TimerChDelayCOOPMap(Handle timer)
{
	L4D2_ChangeLevel(sNextStageMapName);
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
		KvGetString(hKVSettings, "next mission map", next_mission_force, 64, next_mission_def);
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

	if(L4D_IsMissionFinalMap() == false)
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
#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <l4d2_changelevel>
#include <left4dhooks>

#define Version "1.7"
#define MAX_ARRAY_LINE 50
#define MAX_MAPNAME_LEN 64
#define MAX_CREC_LEN 2
#define MAX_REBFl_LEN 8

ConVar cvarAnnounce = null;
ConVar Allowed = null;
ConVar AllowedDie = null;
ConVar DefM = null;
ConVar CheckRoundCounter = null;
ConVar ChDelayVS = null;
ConVar ChDelayCOOP = null;

Handle hKVSettings = null;

char FMC_FileSettings[128];
char current_map[64];
char announce_map[64];
char next_mission_def[64];
char next_mission_force[64];
char force_mission_name[64];
int RoundEndCounter = 0;
int RoundEndBlock = 0;
float RoundEndBlockValue = 0.0;
int CoopRoundEndCounter = 0;
int CoopRoundEndCounterValue = 0;

char MapNameArrayLine[MAX_ARRAY_LINE][MAX_MAPNAME_LEN];
char CrecNumArrayLine[MAX_ARRAY_LINE][MAX_CREC_LEN];
char reBlkFlArrayLine[MAX_ARRAY_LINE][MAX_REBFl_LEN];
int g_ArrayCount = 0;
ConVar h_GameMode;
char GameName[16];

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
	h_GameMode = FindConVar("mp_gamemode");
	h_GameMode.GetString(GameName, sizeof(GameName));
	h_GameMode.AddChangeHook(ConVarGameMode);

	hKVSettings=CreateKeyValues("ForceMissionChangerSettings");

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("mission_lost", Event_FinalLost);
	
	CreateConVar("sm_l4d_fmc_version", Version, "Version of L4D Force Mission Changer plugin.", FCVAR_NOTIFY);
	Allowed = CreateConVar("sm_l4d_fmc", "1", "Enables Force changelevel when mission end.");
	AllowedDie = CreateConVar("sm_l4d_fmc_ifdie", "0", "Enables Force changelevel when all player die on final map in coop gamemode.");
	DefM = CreateConVar("sm_l4d_fmc_def", "c2m1_highway", "Mission for change by default.");
	CheckRoundCounter = CreateConVar("sm_l4d_fmc_crec", "3", "Quantity of events RoundEnd before force of changelevel in coop");
	ChDelayVS = CreateConVar("sm_l4d_fmc_chdelayvs", "1.0", "Delay before versus mission change (float in sec).");
	ChDelayCOOP = CreateConVar("sm_l4d_fmc_chdelaycoop", "10.0", "Delay before coop mission change (float in sec).");
	cvarAnnounce = CreateConVar("sm_l4d_fmc_announce", "1", "Enables next mission to advertise to players.");
	
	//For custom crec
	RegServerCmd("sm_l4d_fmc_crec_add", Command_CrecAdd, "Add custom value sm_l4d_fmc_crec and sm_l4d_fmc_re_timer_block for the specified map. Max 50.");
	RegServerCmd("sm_l4d_fmc_crec_clear", Command_CrecClear, "Clear all custom value sm_l4d_fmc_crec and sm_l4d_fmc_re_timer_block.");
	RegServerCmd("sm_l4d_fmc_crec_list", Command_CrecList, "Show all custom value sm_l4d_fmc_crec and sm_l4d_fmc_re_timer_block.");

	AutoExecConfig(true, "sm_l4d_mapchanger");
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
	RoundEndBlock = 0;

	if(L4D_IsMissionFinalMap() && Allowed.BoolValue)
	{
		PluginInitialization();
	}
}

public void OnClientPutInServer(int client)
{
	// Make the announcement in 20 seconds unless announcements are turned off
	if(client && !IsFakeClient(client) && cvarAnnounce.BoolValue)
		CreateTimer(15.0, TimerAnnounce, client);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if(Allowed.BoolValue && StrEqual(GameName,"coop") && L4D_IsMissionFinalMap())
	{
		if(CoopRoundEndCounterValue > 0 && CoopRoundEndCounter > 0) 
		{
			CPrintToChatAll("{default}[{olive}TS{default}]{default} 還剩 {green}%d {default}次機會挑戰 {lightgreen}最後關卡{default}.",CoopRoundEndCounterValue-CoopRoundEndCounter);
		}
		if(CoopRoundEndCounterValue-CoopRoundEndCounter == 1)
		{
			CPrintToChatAll("下一張圖 Next Map{default}: {blue}%s{default}.", announce_map);
		}
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	if (RoundEndBlock == 0)
	{
		RoundEndCounter += 1;
		RoundEndBlock = 1;
		CreateTimer(0.5, TimerRoundEndBlock);
	}

	if(Allowed.BoolValue && StrEqual(GameName,"versus") && StrEqual(next_mission_force, "none") != true && CheckRoundCounter.IntValue != 0 && RoundEndCounter >= 4)
	{

		CreateTimer(RoundEndBlockValue, TimerChDelayVS);
		RoundEndCounter = 0;
	}
}


public Action Event_FinalWin(Event event, const char[] name, bool dontBroadcast) 
{
	if(Allowed.BoolValue && StrEqual(GameName,"coop") && StrEqual(next_mission_force, "none") != true)
		CreateTimer(ChDelayCOOP.FloatValue, TimerChDelayCOOP);
}

public Action Event_FinalLost(Event event, const char[] name, bool dontBroadcast) 
{
	if(L4D_IsMissionFinalMap() && Allowed.BoolValue && StrEqual(GameName,"coop") && StrEqual(next_mission_force, "none") != true)
	{
		CoopRoundEndCounter += 1;
		if(AllowedDie.BoolValue || CoopRoundEndCounter>=CoopRoundEndCounterValue)
			CreateTimer(ChDelayCOOP.FloatValue, TimerChDelayCOOP);
	}
}

public Action TimerAnnounce(Handle timer, any:client)
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
	RoundEndBlock = 0;
}

public Action TimerChDelayVS(Handle timer)
{
	L4D2_ChangeLevel(next_mission_force);
}

public Action TimerChDelayCOOP(Handle timer)
{
	L4D2_ChangeLevel(next_mission_force);
}

public Action Command_CrecClear(int args)
{
	g_ArrayCount = 0;
	PrintToServer("[FMC] Custom value sm_l4d_fmc_crec now is clear.");
}

public Action Command_CrecAdd(int args)
{
	if (g_ArrayCount == MAX_ARRAY_LINE)
	{
		PrintToServer("[FMC] Max number of array line for sm_l4d_fmc_crec_add reached.");
		return;
	}

	decl String:cmdarg1[MAX_MAPNAME_LEN];
	GetCmdArg(1, cmdarg1, sizeof(cmdarg1));
	decl String:cmdarg2[MAX_CREC_LEN];
	GetCmdArg(2, cmdarg2, sizeof(cmdarg2));
	decl String:cmdarg3[MAX_REBFl_LEN];
	GetCmdArg(3, cmdarg3, sizeof(cmdarg3));

	// Check for doubles
	bool isDouble = false;
	for (int i = 0; i < g_ArrayCount; i++)
	{
		if (StrEqual(cmdarg1, MapNameArrayLine[i]) == true)
		{
			isDouble = true;
			break;
		}
	}

	if (IsMapValid(cmdarg1) && StringToInt(cmdarg2) != 0 && StringToFloat(cmdarg3) != 0.0)
	{
		if (!isDouble)
		{
			strcopy(MapNameArrayLine[g_ArrayCount], MAX_MAPNAME_LEN, cmdarg1);
			strcopy(CrecNumArrayLine[g_ArrayCount], MAX_CREC_LEN, cmdarg2);
			strcopy(reBlkFlArrayLine[g_ArrayCount], MAX_REBFl_LEN, cmdarg3);
			g_ArrayCount++;
		}
	}
	else
		PrintToServer("[FMC] Error command. Use: sm_l4d_fmc_crec_add <existing custom map> <custom sm_l4d_fmc_crec integer value (max 99)> <custom sm_l4d_fmc_re_timer_block float value>.");
}

public Action Command_CrecList(int args)
{
	PrintToServer("[FMC] Custom value sm_l4d_fmc_crec and sm_l4d_fmc_re_timer_block list:");
	for (int i = 0; i < g_ArrayCount; i++)
	{
		PrintToServer("[%d] %s - %s - %s", i, MapNameArrayLine[i], CrecNumArrayLine[i], reBlkFlArrayLine[i]);
	}
	PrintToServer("[FMC] Custom value sm_l4d_fmc_crec and sm_l4d_fmc_re_timer_block list end.");
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
	//PrintToServer("[FMC] Discovered versus gamemode. Link to sm_l4d_mapchanger.");
	
	if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		SetFailState("Force Mission Changer settings not found! Shutdown.");
	
	next_mission_force = "none";
	GetCurrentMap(current_map, 64);
	//LogMessage("current map: %s",current_map);
	DefM.GetString(next_mission_def, 64);

	KvRewind(hKVSettings);
	if(KvJumpToKey(hKVSettings, current_map))
	{
		KvGetString(hKVSettings, "next mission map", next_mission_force, 64, next_mission_def);
		//LogMessage("next_mission map: %s",next_mission_force);
		KvGetString(hKVSettings, "next mission name", force_mission_name, 64, "none");
		//LogMessage("next mission name: %s",force_mission_name);
	}
	KvRewind(hKVSettings);

	CoopRoundEndCounterValue = 0;
	RoundEndBlockValue = 0.0;	
	for (int i = 0; i < g_ArrayCount; i++)
	{
		if (StrEqual(current_map, MapNameArrayLine[i]) == true)
		{
			CoopRoundEndCounterValue = StringToInt(CrecNumArrayLine[g_ArrayCount]);
			RoundEndBlockValue = StringToFloat(reBlkFlArrayLine[g_ArrayCount]);
			break;
		}
	}
	if (CoopRoundEndCounterValue == 0)
		CoopRoundEndCounterValue = CheckRoundCounter.IntValue;
	if (RoundEndBlockValue == 0.0)
		RoundEndBlockValue = ChDelayVS.FloatValue;
		
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
}
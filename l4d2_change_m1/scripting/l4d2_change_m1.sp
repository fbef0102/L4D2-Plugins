#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <multicolors>
#include <left4dhooks>
#include <l4d2_changelevel>
#define DEBUG 0

//const
#define RestartCampaign_Seconds 6.0

//cvars
ConVar hEnable, DefM;
bool g_bEnable;
char sMapNameM1[64] = "";		
char sDefaultMap[64];

public Plugin myinfo = 
{
	name = "L4D2 change m1",
	author = "Harry Potter",
	description = "If all Survivors die and wipe out, change level to the current map m1",
	version = "1.1",
	url = "Harry Potter myself, you bitch shit"
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
	hEnable	= CreateConVar("l4d2_change_m1_enable", "1", 	"Enable this plugin? (1-Enable, 0-Disable)" , FCVAR_NOTIFY, true, 0.0, true, 1.0);
	DefM = CreateConVar("l4d2_change_m1_def", "c2m1_highway", "M1 for change by default.", FCVAR_NOTIFY);
	
	GetCvars();
	hEnable.AddChangeHook(ConVarChanged_Cvars);
	DefM.AddChangeHook(ConVarChanged_Cvars);

	HookEvent("mission_lost", Event_MissionLost, EventHookMode_PostNoCopy); //戰役滅團重來該關卡的時候
	
	//Autoconfig for plugin
	AutoExecConfig(true, "l4d2_change_m1");
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnable = hEnable.BoolValue;
	DefM.GetString(sDefaultMap, sizeof(sDefaultMap));
}

public void OnMapStart()
{	
	if(L4D_IsFirstMapInScenario())
	{
		GetCurrentMap(sMapNameM1, sizeof(sMapNameM1));
	}
}

public Action Event_MissionLost(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnable) return Plugin_Continue;
	
	CPrintToChatAll("[{olive}摸魚{default}] {green}滅團了，{olive}%.0f{green} 秒後重新加載地圖!",RestartCampaign_Seconds);	
	CreateTimer(RestartCampaign_Seconds,Timer_RestartCampaign,_,TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action Timer_RestartCampaign(Handle timer)
{
	if( sMapNameM1[0] != '\0' )
	{
		L4D2_ChangeLevel(sMapNameM1);
		sMapNameM1 = "";
	}
	else
	{
		L4D2_ChangeLevel(sDefaultMap);
	}
}

public void ConVarChange_hEnable(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_bEnable  = GetConVarBool(hEnable);
}
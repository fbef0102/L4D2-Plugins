#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>
#define DEBUG 0

//const
#define RestartCampaign_Seconds 6.0

//cvars
ConVar hEnable;
bool g_bEnable;
char sMapNameM1[64];		
			
public Plugin:myinfo = 
{
	name = "L4D2 change m1",
	author = "Harry Potter",
	description = "If all Survivors die, change level to the current map m1",
	version = "1.0",
	url = "Harry Potter myself,you bitch shit"
};

public void OnPluginStart()
{
	if(!IsL4D2Game())
		SetFailState("Use this Left 4 Dead 2 only.");
		
	hEnable	= CreateConVar("l4d2_enable_change_m1", "1", 	"Enable this plugin?[1-Enable,0-Disable]" , FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bEnable  = GetConVarBool(hEnable);
	HookConVarChange(hEnable, ConVarChange_hEnable);

	HookEvent("mission_lost", Event_MissionLost, EventHookMode_PostNoCopy); //戰役滅團重來該關卡的時候
	
	SetDefault_MapNameM1("c1m1_hotel");
}

void SetDefault_MapNameM1(const char[] sMapName)
{
	Format(sMapNameM1, sizeof(sMapNameM1), "%s", sMapName);
}

public OnMapStart()
{	
	if(IsNewMission())
		GetCurrentMap(sMapNameM1, sizeof(sMapNameM1));
}

public Action Event_MissionLost(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnable) return Plugin_Continue;
	
	CPrintToChatAll("[{olive}水仙摸魚{default}] {green}滅團了，{olive}%.0f{green} 秒後重新加載地圖!",RestartCampaign_Seconds);	
	CreateTimer(RestartCampaign_Seconds,Timer_RestartCampaign,_,TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action Timer_RestartCampaign(Handle timer)
{
	/*if(CheckRealPlayer_InSV())*/ ServerCommand("changelevel %s", sMapNameM1);
}

public void ConVarChange_hEnable(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_bEnable  = GetConVarBool(hEnable);
}
/*
bool CheckRealPlayer_InSV()
{
	for (new i = 1; i < MaxClients+1; i++)
		if(IsClientInGame(i)&&!IsFakeClient(i))
			return true;
	return false;
}
*/
stock bool IsL4D2Game()
{
	decl String:sGameFolder[32];
	GetGameFolderName(sGameFolder, 32);
	return StrEqual(sGameFolder, "left4dead2");
}

stock bool IsNewMission()
{
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);
	return StrContains(sMap, "m1_") != -1;
}
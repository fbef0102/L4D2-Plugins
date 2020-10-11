#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define CLASSNAME_LENGTH 	64
#define DEBUG 0

enum WeaponID
{
	ID_NONE,
	ID_PISTOL,
	ID_DUAL_PISTOL,
	ID_SMG,
	//ID_PUMPSHOTGUN,
	ID_RIFLE,
	//ID_AUTOSHOTGUN,
	ID_HUNTING_RIFLE,
	ID_SMG_SILENCED,
	ID_SMG_MP5,
	//ID_CHROMESHOTGUN,
	ID_MAGNUM,
	ID_AK47,
	ID_RIFLE_DESERT,
	ID_SNIPER_MILITARY,
	ID_GRENADE,
	ID_SG552,
	//ID_M60,
	ID_AWP,
	ID_SCOUT,
	//ID_SPASSHOTGUN,
	ID_WEAPON_MAX
}
#define PISTOL_RELOAD_INCAP_MULTIPLY 1.25
char Weapon_Name[view_as<int>(ID_WEAPON_MAX)][CLASSNAME_LENGTH];
int WeaponAmmoOffest[view_as<int>(ID_WEAPON_MAX)];
int WeaponMaxClip[view_as<int>(ID_WEAPON_MAX)];

//cvars
ConVar hEnableReloadClipCvar, hEnableClipRecoverCvar, hSmgTimeCvar, hRifleTimeCvar, hHuntingRifleTimeCvar,
	hPistolTimeCvar, hDualPistolTimeCvar, hSmgSilencedTimeCvar, hSmgMP5TimeCvar, hAK47TimeCvar, hRifleDesertTimeCvar,
	hSniperMilitaryTimeCvar, hGrenadeTimeCvar, hSG552TimeCvar, hAWPTimeCvar, hScoutTimeCvar, hMangumTimeCvar;
ConVar hSmgClipCvar, hRifleClipCvar, hHuntingRifleClipCvar, hPistolClipCvar, hDualPistolClipCvar, hSmgSilencedClipCvar,
	hSmgMP5ClipCvar, hAK47ClipCvar, hRifleDesertClipCvar, hSniperMilitaryClipCvar, hGrenadeClipCvar, hSG552ClipCvar,
	hAWPClipCvar, hScoutClipCvar, hMangumClipCvar;

bool g_EnableReloadClipCvar;
bool g_EnableClipRecoverCvar;
float g_SmgTimeCvar;
float g_RifleTimeCvar;
float g_HuntingRifleTimeCvar;
float g_PistolTimeCvar;
float g_DualPistolTimeCvar;
float g_SmgSilencedTimeCvar;
float g_SmgMP5TimeCvar;
float g_AK47TimeCvar;
float g_RifleDesertTimeCvar;
float g_SniperMilitaryTimeCvar;
float g_GrenadeTimeCvar;
float g_SG552TimeCvar;
float g_AWPTimeCvar;
float g_ScoutTimeCvar;
float g_MangumTimeCvar;

//value
float g_hClientReload_Time[MAXPLAYERS+1]	= {0.0};	

//offest
int ammoOffset;	
									
public Plugin myinfo = 
{
	name = "L4D2 weapon csgo reload",
	author = "Harry Potter",
	description = "reload like csgo weapon",
	version = "1.9",
	url = "Harry Potter myself,you bitch shit"
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
	ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");

	hEnableReloadClipCvar	= CreateConVar("l4d2_weapon_csgo_reload_allow", 		"1", 	"0=off plugin, 1=on plugin" 			  , FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hEnableClipRecoverCvar	= CreateConVar("l4d2_weapon_csgo_reload_clip_recover", 	"1", 	"enable previous clip recover?"			  , FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hSmgTimeCvar			= CreateConVar("l4d2_smg_reload_clip_time", 			"1.04", "reload time for smg clip"				  , FCVAR_NOTIFY, true, 0.0);
	hRifleTimeCvar			= CreateConVar("l4d2_rifle_reload_clip_time", 			"1.2",  "reload time for rifle clip"			  , FCVAR_NOTIFY, true, 0.0);
	hHuntingRifleTimeCvar   = CreateConVar("l4d2_huntingrifle_reload_clip_time", 	"2.6",  "reload time for hunting rifle clip"	  , FCVAR_NOTIFY, true, 0.0);
	hPistolTimeCvar 		= CreateConVar("l4d2_pistol_reload_clip_time", 			"1.2",  "reload time for pistol clip"		      , FCVAR_NOTIFY, true, 0.0);
	hDualPistolTimeCvar 	= CreateConVar("l4d2_dualpistol_reload_clip_time", 		"1.75", "reload time for dual pistol clip"        , FCVAR_NOTIFY, true, 0.0);
	hSmgSilencedTimeCvar	= CreateConVar("l4d2_smgsilenced_reload_clip_time", 	"1.05", "reload time for smg silenced clip"       , FCVAR_NOTIFY, true, 0.0);
	hSmgMP5TimeCvar			= CreateConVar("l4d2_smgmp5_reload_clip_time", 			"1.7",  "reload time for smg mp5 clip"      	  , FCVAR_NOTIFY, true, 0.0);
	hAK47TimeCvar			= CreateConVar("l4d2_ak47_reload_clip_time", 			"1.2",  "reload time for ak47 clip"      		  , FCVAR_NOTIFY, true, 0.0);
	hRifleDesertTimeCvar	= CreateConVar("l4d2_desertrifle_reload_clip_time", 	"1.8",  "reload time for desert rifle clip"       , FCVAR_NOTIFY, true, 0.0);
	hSniperMilitaryTimeCvar	= CreateConVar("l4d2_snipermilitary_reload_clip_time", 	"1.8",  "reload time for sniper military clip"    , FCVAR_NOTIFY, true, 0.0);
	hGrenadeTimeCvar		= CreateConVar("l4d2_grenade_reload_clip_time", 		"2.5",  "reload time for grenade clip"  		  , FCVAR_NOTIFY, true, 0.0);
	hSG552TimeCvar			= CreateConVar("l4d2_sg552_reload_clip_time", 			"1.6",  "reload time for sg552 clip" 			  , FCVAR_NOTIFY, true, 0.0);
	hAWPTimeCvar			= CreateConVar("l4d2_awp_reload_clip_time", 			"2.0",  "reload time for awp clip" 				  , FCVAR_NOTIFY, true, 0.0);
	hScoutTimeCvar			= CreateConVar("l4d2_scout_reload_clip_time", 			"1.45", "reload time for scout clip"  			  , FCVAR_NOTIFY, true, 0.0);
	hMangumTimeCvar			= CreateConVar("l4d2_mangum_reload_clip_time", 			"1.18", "reload time for mangum clip"  			  , FCVAR_NOTIFY, true, 0.0);
	hSmgClipCvar			= CreateConVar("l4d2_smg_reload_clip", 					"50", 	"smg max clip"							  , FCVAR_NOTIFY, true, 1.0);
	hRifleClipCvar			= CreateConVar("l4d2_rifle_reload_clip", 				"50", 	"rifle max clip"						  , FCVAR_NOTIFY, true, 1.0);
	hHuntingRifleClipCvar	= CreateConVar("l4d2_huntingrifle_reload_clip", 		"15", 	"huntingrifle max clip"					  , FCVAR_NOTIFY, true, 1.0);
	hPistolClipCvar			= CreateConVar("l4d2_pistol_clip", 						"15", 	"pistol max clip"					  	  , FCVAR_NOTIFY, true, 1.0);
	hDualPistolClipCvar		= CreateConVar("l4d2_dualpistol_clip", 					"30", 	"dual pistol max clip"					  , FCVAR_NOTIFY, true, 1.0);
	hSmgSilencedClipCvar	= CreateConVar("l4d2_smgsilenced_clip", 				"50", 	"smg silenced max clip"					  , FCVAR_NOTIFY, true, 1.0);
	hSmgMP5ClipCvar			= CreateConVar("l4d2_smgmp5_clip", 						"50", 	"smg mp5 max clip"					 	  , FCVAR_NOTIFY, true, 1.0);
	hAK47ClipCvar			= CreateConVar("l4d2_ak47_clip", 						"40", 	"ak47 max clip"					 	  	  , FCVAR_NOTIFY, true, 1.0);
	hRifleDesertClipCvar	= CreateConVar("l4d2_desertrifle_clip", 				"60", 	"desert rifle max clip"					  , FCVAR_NOTIFY, true, 1.0);
	hSniperMilitaryClipCvar	= CreateConVar("l4d2_snipermilitary_clip", 				"30", 	"sniper military max clip"				  , FCVAR_NOTIFY, true, 1.0);
	hGrenadeClipCvar		= CreateConVar("l4d2_grenade_clip", 					"1", 	"grenade max clip"				  		  , FCVAR_NOTIFY, true, 1.0);
	hSG552ClipCvar			= CreateConVar("l4d2_sg552_clip", 						"50", 	"sg552 max clip"				  		  , FCVAR_NOTIFY, true, 1.0);
	hAWPClipCvar			= CreateConVar("l4d2_awp_clip", 						"20", 	"awp max clip"				 	 		  , FCVAR_NOTIFY, true, 1.0);
	hScoutClipCvar			= CreateConVar("l4d2_scout_clip", 						"15", 	"scout max clip"				  		  , FCVAR_NOTIFY, true, 1.0);
	hMangumClipCvar			= CreateConVar("l4d2_mangum_clip", 						"8", 	"mangum max clip"				  		  , FCVAR_NOTIFY, true, 1.0);

	GetCvars();
	
	hEnableReloadClipCvar.AddChangeHook(ConVarChange_CvarChanged);
	hEnableClipRecoverCvar.AddChangeHook(ConVarChange_CvarChanged);
	hSmgTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hRifleTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hHuntingRifleTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hPistolTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hDualPistolTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hSmgSilencedTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hSmgMP5TimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hAK47TimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hRifleDesertTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hSniperMilitaryTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hGrenadeTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hSG552TimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hAWPTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hScoutTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hMangumTimeCvar.AddChangeHook(ConVarChange_CvarChanged);
	hSmgClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hRifleClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hHuntingRifleClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hPistolClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hDualPistolClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hSmgSilencedClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hSmgMP5ClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hAK47ClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hRifleDesertClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hSniperMilitaryClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hGrenadeClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hSG552ClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hAWPClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hScoutClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);
	hMangumClipCvar.AddChangeHook(ConVarChange_MaxClipChanged);

	HookEvent("weapon_reload", OnWeaponReload_Event, EventHookMode_Post);
	HookEvent("round_start", RoundStart_Event);
	
	SetWeapon();
	SetWeaponMaxClip();
	
	AutoExecConfig(true, "l4d2_weapon_csgo_reload");
}

public Action RoundStart_Event(Event event, const char[] name, bool dontBroadcast) 
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_hClientReload_Time[i] = 0.0;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(g_EnableReloadClipCvar == false || g_EnableClipRecoverCvar == false)	return Plugin_Continue;
	
	if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && buttons & IN_RELOAD) //If survivor alive player is holding weapon and wants to reload
	{
		int iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"); //抓人類目前裝彈的武器
		if (iCurrentWeapon == -1 || !IsValidEntity(iCurrentWeapon))
		{
			return Plugin_Continue;
		}
		int previousclip = GetWeaponClip(iCurrentWeapon);
		if(GetEntProp(iCurrentWeapon, Prop_Send, "m_bInReload") == 0)
		{
			char sWeaponName[32];
			GetClientWeapon(client, sWeaponName, sizeof(sWeaponName));
			#if DEBUG
				PrintToChatAll("%N - %s clip:%d",client,sWeaponName,previousclip);
			#endif
			WeaponID weaponid = GetWeaponID(iCurrentWeapon,sWeaponName);
			int MaxClip = WeaponMaxClip[weaponid];
			
			switch(weaponid)
			{
				case ID_SMG,ID_RIFLE,ID_HUNTING_RIFLE,ID_SMG_SILENCED,ID_SMG_MP5,
				ID_AK47,ID_RIFLE_DESERT,ID_AWP,ID_GRENADE,ID_SCOUT,ID_SG552,
				ID_SNIPER_MILITARY:
				{
					if (0 < previousclip && previousclip < MaxClip)	//If the his current mag equals the maximum allowed, remove reload from buttons
					{
						DataPack data = new DataPack();
						data.WriteCell(client);
						data.WriteCell(iCurrentWeapon);
						data.WriteCell(previousclip);
						data.WriteCell(weaponid);
						data.Reset();
						RequestFrame(RecoverWeaponClip, data);

						/*Handle pack = new DataPack();
						CreateDataTimer(0.1, RecoverWeaponClip, pack, TIMER_FLAG_NO_MAPCHANGE);
						WritePackCell(pack, client);
						WritePackCell(pack, iCurrentWeapon);
						WritePackCell(pack, previousclip);
						WritePackCell(pack, weaponid);*/
					}
				}
				default:
					return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}

public void RecoverWeaponClip(DataPack data) { 
	int client = data.ReadCell();
	int CurrentWeapon = data.ReadCell();
	int previousclip = data.ReadCell();
	WeaponID weaponid = data.ReadCell();
	int nowweaponclip;
	
	if ((nowweaponclip = GetWeaponClip(CurrentWeapon)) == WeaponMaxClip[weaponid] || //CurrentWeapon complete reload finished
	nowweaponclip == previousclip //CurrentWeapon clip has been recovered
	)
	{
		return;
	}
	
	if (nowweaponclip < WeaponMaxClip[weaponid] && nowweaponclip == 0)
	{
		int ammo = GetWeaponAmmo(client, WeaponAmmoOffest[weaponid]);
		ammo -= previousclip;
		#if DEBUG
			PrintToChatAll("CurrentWeapon clip recovered");
		#endif
		SetWeaponAmmo(client,WeaponAmmoOffest[weaponid],ammo);
		SetWeaponClip(CurrentWeapon,previousclip);
	}

	data.Close();
} 

/*
public Action RecoverWeaponClip(Handle timer, Handle pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	int CurrentWeapon = ReadPackCell(pack);
	int previousclip = ReadPackCell(pack);
	WeaponID weaponid = ReadPackCell(pack);
	int nowweaponclip;
	
	if (CurrentWeapon == -1 || //CurrentWeapon drop
	!IsValidEntity(CurrentWeapon) ||
	client == 0 || //client disconnected
	!IsClientInGame(client) || 
	!IsPlayerAlive(client) ||
	GetClientTeam(client)!=2 ||
	!HasEntProp(CurrentWeapon, Prop_Send, "m_bInReload") ||
	GetEntProp(CurrentWeapon, Prop_Send, "m_bInReload") == 0 || //reload interrupted
	(nowweaponclip = GetWeaponClip(CurrentWeapon)) == WeaponMaxClip[weaponid] || //CurrentWeapon complete reload finished
	nowweaponclip == previousclip //CurrentWeapon clip has been recovered
	)
	{
		return Plugin_Handled;
	}
	
	if (nowweaponclip < WeaponMaxClip[weaponid] && nowweaponclip == 0)
	{
		int ammo = GetWeaponAmmo(client, WeaponAmmoOffest[weaponid]);
		ammo -= previousclip;
		#if DEBUG
			PrintToChatAll("CurrentWeapon clip recovered");
		#endif
		SetWeaponAmmo(client,WeaponAmmoOffest[weaponid],ammo);
		SetWeaponClip(CurrentWeapon,previousclip);
	}
	return Plugin_Handled;
}
*/
public Action OnWeaponReload_Event(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client < 1 || 
		client > MaxClients ||
		!IsClientInGame(client) ||
		IsFakeClient(client) ||
		GetClientTeam(client) != 2 ||
		g_EnableReloadClipCvar == false) //disable this plugin
		return Plugin_Continue;
		
	int iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"); //抓人類目前裝彈的武器
	if (iCurrentWeapon == -1 || !IsValidEntity(iCurrentWeapon))
	{
		return Plugin_Continue;
	}
	
	g_hClientReload_Time[client] = GetEngineTime();
	
	char sWeaponName[32];
	GetClientWeapon(client, sWeaponName, sizeof(sWeaponName));
	WeaponID weaponid = GetWeaponID(iCurrentWeapon,sWeaponName);
	#if DEBUG
		PrintToChatAll("%N - %s - weaponid: %d",client,sWeaponName,weaponid);
		for (int i = 0; i < 32; i++)
		{
			PrintToConsole(client, "Offset: %i - Count: %i", i, GetEntData(client, ammoOffset+(i*4)));
		} 
	#endif
	
	Handle pack;
	switch(weaponid)
	{
		case ID_SMG: CreateDataTimer(g_SmgTimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		case ID_RIFLE: CreateDataTimer(g_RifleTimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		case ID_HUNTING_RIFLE: CreateDataTimer(g_HuntingRifleTimeCvar, WeaponReloadClip, pack,TIMER_FLAG_NO_MAPCHANGE);
		case ID_PISTOL: 
		{
			if(IsIncapacitated(client))
				CreateDataTimer(g_PistolTimeCvar * PISTOL_RELOAD_INCAP_MULTIPLY, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
			else
				CreateDataTimer(g_PistolTimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		}
		case ID_DUAL_PISTOL:
		{
			if(IsIncapacitated(client))
				CreateDataTimer(g_DualPistolTimeCvar * PISTOL_RELOAD_INCAP_MULTIPLY, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
			else
				CreateDataTimer(g_DualPistolTimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		}
		case ID_SMG_SILENCED: CreateDataTimer(g_SmgSilencedTimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		case ID_SMG_MP5: CreateDataTimer(g_SmgMP5TimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		case ID_AK47: CreateDataTimer(g_AK47TimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		case ID_RIFLE_DESERT: CreateDataTimer(g_RifleDesertTimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		case ID_AWP: CreateDataTimer(g_AWPTimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		case ID_SCOUT: CreateDataTimer(g_ScoutTimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		case ID_GRENADE: CreateDataTimer(g_GrenadeTimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		case ID_SG552: CreateDataTimer(g_SG552TimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		case ID_SNIPER_MILITARY: CreateDataTimer(g_SniperMilitaryTimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		case ID_MAGNUM:
		{
			if(IsIncapacitated(client))
				CreateDataTimer(g_MangumTimeCvar * PISTOL_RELOAD_INCAP_MULTIPLY, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
			else
				CreateDataTimer(g_MangumTimeCvar, WeaponReloadClip, pack, TIMER_FLAG_NO_MAPCHANGE);
		}
		default: return Plugin_Continue;
	}
	WritePackCell(pack, client);
	WritePackCell(pack, iCurrentWeapon);
	WritePackCell(pack, weaponid);
	WritePackCell(pack, g_hClientReload_Time[client]);
	
	return Plugin_Continue;
}

public Action WeaponReloadClip(Handle timer, Handle pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	int CurrentWeapon = ReadPackCell(pack);
	WeaponID weaponid = ReadPackCell(pack);
	float reloadtime = ReadPackCell(pack);
	int clip;
	
	if ( reloadtime != g_hClientReload_Time[client] || //裝彈時間被刷新
	CurrentWeapon == -1 || //CurrentWeapon drop
	!IsValidEntity(CurrentWeapon) || 
	client == 0 || //client disconnected
	!IsClientInGame(client) ||
	!IsPlayerAlive(client) ||
	GetClientTeam(client)!=2 ||
	!HasEntProp(CurrentWeapon, Prop_Send, "m_bInReload") ||
	GetEntProp(CurrentWeapon, Prop_Send, "m_bInReload") == 0 || //reload interrupted
	(clip = GetWeaponClip(CurrentWeapon)) == WeaponMaxClip[weaponid] //CurrentWeapon complete reload finished
	)
	{
		return Plugin_Handled;
	}
	
	if (clip < WeaponMaxClip[weaponid])
	{
		switch(weaponid)
		{
			case ID_SMG,ID_RIFLE,ID_HUNTING_RIFLE,ID_SMG_SILENCED,ID_SMG_MP5,
			ID_AK47,ID_RIFLE_DESERT,ID_AWP,ID_GRENADE,ID_SCOUT,ID_SG552,
			ID_SNIPER_MILITARY:
			{
				#if DEBUG
					PrintToChatAll("CurrentWeapon reload clip completed");
				#endif
			
				int ammo = GetWeaponAmmo(client, WeaponAmmoOffest[weaponid]);
				if( (ammo - (WeaponMaxClip[weaponid] - clip)) <= 0)
				{
					clip = clip + ammo;
					ammo = 0;
				}
				else
				{
					ammo = ammo - (WeaponMaxClip[weaponid] - clip);
					clip = WeaponMaxClip[weaponid];
				}
				SetWeaponAmmo(client,WeaponAmmoOffest[weaponid],ammo);
				SetWeaponClip(CurrentWeapon,clip);
			}
			case ID_PISTOL,ID_DUAL_PISTOL,ID_MAGNUM:
			{
				#if DEBUG
					PrintToChatAll("Pistol reload clip completed");
				#endif
				SetWeaponClip(CurrentWeapon,WeaponMaxClip[weaponid]);
			}
			default:
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}
stock int GetWeaponAmmo(int client, int offest)
{
    return GetEntData(client, ammoOffset+(offest*4));
} 

stock int GetWeaponClip(int weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_iClip1");
} 

stock void SetWeaponAmmo(int client, int offest, int ammo)
{
    SetEntData(client, ammoOffset+(offest*4), ammo);
} 
stock void SetWeaponClip(int weapon, int clip)
{
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
} 

stock bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

stock WeaponID GetWeaponID(int weapon,const char[] weapon_name)
{
	if(StrEqual(weapon_name,"weapon_pistol",false))
	{
		if( GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0) //dual pistol
		{
			return ID_DUAL_PISTOL;
		}
		return ID_PISTOL;
	}
	
	for(WeaponID i = ID_NONE; i < ID_WEAPON_MAX ; ++i)
	{
		if(StrEqual(weapon_name,Weapon_Name[i],false))
			return i;
	}
	return ID_NONE;
}

public void ConVarChange_CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void ConVarChange_MaxClipChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetWeaponMaxClip();
}

void GetCvars()
{
	g_EnableReloadClipCvar  = hEnableReloadClipCvar.BoolValue;
	g_EnableClipRecoverCvar = hEnableClipRecoverCvar.BoolValue;
	g_SmgTimeCvar 			= hSmgTimeCvar.FloatValue;
	g_RifleTimeCvar 		= hRifleTimeCvar.FloatValue;
	g_HuntingRifleTimeCvar	= hHuntingRifleTimeCvar.FloatValue;
	g_PistolTimeCvar 		= hPistolTimeCvar.FloatValue;
	g_DualPistolTimeCvar 	= hDualPistolTimeCvar.FloatValue;
	g_SmgSilencedTimeCvar	= hSmgSilencedTimeCvar.FloatValue;
	g_SmgMP5TimeCvar		= hSmgMP5TimeCvar.FloatValue;
	g_AK47TimeCvar			= hAK47TimeCvar.FloatValue;
	g_RifleDesertTimeCvar	= hRifleDesertTimeCvar.FloatValue;
	g_SniperMilitaryTimeCvar= hSniperMilitaryTimeCvar.FloatValue;
	g_GrenadeTimeCvar		= hGrenadeTimeCvar.FloatValue;
	g_SG552TimeCvar			= hSG552TimeCvar.FloatValue;
	g_AWPTimeCvar			= hAWPTimeCvar.FloatValue;
	g_ScoutTimeCvar			= hScoutTimeCvar.FloatValue;
	g_MangumTimeCvar		= hMangumTimeCvar.FloatValue;
}

public void SetWeapon()
{
	Weapon_Name[ID_NONE] = "";
	Weapon_Name[ID_PISTOL] = "weapon_pistol";
	Weapon_Name[ID_DUAL_PISTOL] = "weapon_pistol";
	Weapon_Name[ID_SMG] = "weapon_smg";
	//Weapon_Name[ID_PUMPSHOTGUN] = "weapon_pumpshotgun";
	Weapon_Name[ID_RIFLE] = "weapon_rifle";
	//Weapon_Name[ID_AUTOSHOTGUN] = "weapon_autoshotgun";
	Weapon_Name[ID_HUNTING_RIFLE] = "weapon_hunting_rifle";
	Weapon_Name[ID_SMG_SILENCED] = "weapon_smg_silenced";
	Weapon_Name[ID_SMG_MP5] = "weapon_smg_mp5";
	//Weapon_Name[ID_CHROMESHOTGUN] = "weapon_shotgun_chrome";
	Weapon_Name[ID_MAGNUM] = "weapon_pistol_magnum";
	Weapon_Name[ID_AK47] = "weapon_rifle_ak47";
	Weapon_Name[ID_RIFLE_DESERT] = "weapon_rifle_desert";
	Weapon_Name[ID_SNIPER_MILITARY] = "weapon_sniper_military";
	Weapon_Name[ID_GRENADE] = "weapon_grenade_launcher";
	Weapon_Name[ID_SG552] = "weapon_rifle_sg552";
	//Weapon_Name[ID_M60] = "weapon_rifle_m60";
	Weapon_Name[ID_AWP] = "weapon_sniper_awp";
	Weapon_Name[ID_SCOUT] = "weapon_sniper_scout";
	//Weapon_Name[ID_SPASSHOTGUN] = "weapon_shotgun_spas";
	
	WeaponAmmoOffest[ID_NONE] = 0;
	WeaponAmmoOffest[ID_PISTOL] = 0;
	WeaponAmmoOffest[ID_DUAL_PISTOL] = 0;
	WeaponAmmoOffest[ID_SMG] = 5;
	//WeaponAmmoOffest[ID_PUMPSHOTGUN] = 7;
	WeaponAmmoOffest[ID_RIFLE] = 3;
	//WeaponAmmoOffest[ID_AUTOSHOTGUN] = 8;
	WeaponAmmoOffest[ID_HUNTING_RIFLE] = 9;
	WeaponAmmoOffest[ID_SMG_SILENCED] = 5;
	WeaponAmmoOffest[ID_SMG_MP5] = 5;
	//WeaponAmmoOffest[ID_CHROMESHOTGUN] = 7;
	WeaponAmmoOffest[ID_MAGNUM] = 0;
	WeaponAmmoOffest[ID_AK47] = 3;
	WeaponAmmoOffest[ID_RIFLE_DESERT] = 3;
	WeaponAmmoOffest[ID_SNIPER_MILITARY] = 10;
	WeaponAmmoOffest[ID_GRENADE] = 17;
	WeaponAmmoOffest[ID_SG552] = 3;
	//WeaponAmmoOffest[ID_M60] = 6;
	WeaponAmmoOffest[ID_AWP] = 10;
	WeaponAmmoOffest[ID_SCOUT] = 10;
	//WeaponAmmoOffest[ID_SPASSHOTGUN] = 8;
}

public void SetWeaponMaxClip()
{
	WeaponMaxClip[ID_NONE] = 0;
	WeaponMaxClip[ID_PISTOL] = hPistolClipCvar.IntValue;
	WeaponMaxClip[ID_DUAL_PISTOL] = hDualPistolClipCvar.IntValue;
	WeaponMaxClip[ID_SMG] = hSmgClipCvar.IntValue;
	//WeaponMaxClip[ID_PUMPSHOTGUN] = 8;
	WeaponMaxClip[ID_RIFLE] = hRifleClipCvar.IntValue;
	//WeaponMaxClip[ID_AUTOSHOTGUN] = 10;
	WeaponMaxClip[ID_HUNTING_RIFLE] = hHuntingRifleClipCvar.IntValue;
	WeaponMaxClip[ID_SMG_SILENCED] = hSmgSilencedClipCvar.IntValue;
	WeaponMaxClip[ID_SMG_MP5] = hSmgMP5ClipCvar.IntValue;
	//WeaponMaxClip[ID_CHROMESHOTGUN] = 8;
	WeaponMaxClip[ID_MAGNUM] = hMangumClipCvar.IntValue;
	WeaponMaxClip[ID_AK47] = hAK47ClipCvar.IntValue;
	WeaponMaxClip[ID_RIFLE_DESERT] = hRifleDesertClipCvar.IntValue;
	WeaponMaxClip[ID_SNIPER_MILITARY] = hSniperMilitaryClipCvar.IntValue;
	WeaponMaxClip[ID_GRENADE] = hGrenadeClipCvar.IntValue;
	WeaponMaxClip[ID_SG552] = hSG552ClipCvar.IntValue;
	//WeaponMaxClip[ID_M60] = 150;
	WeaponMaxClip[ID_AWP] = hAWPClipCvar.IntValue;
	WeaponMaxClip[ID_SCOUT] = hScoutClipCvar.IntValue;
	//WeaponMaxClip[ID_SPASSHOTGUN] = 10;
}
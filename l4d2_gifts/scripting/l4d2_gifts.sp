#define PLUGIN_VERSION		"2.8"

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	Plugin Info:

*	Name	:	[L4D2] Gifts Drop & Spawn
*	Author	:	Aceleracion & HarryPotter
*	Descrp	:	Drop gifts when a special infected died and win points & special weapon
*	Link	:	https://forums.alliedmods.net/showthread.php?t=302731

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define MAXENTITIES                   2048
#define DATABASE_CONFIG 	"l4d2gifts"
#define TAG_GIFT			"[GIFTS]"
#define	MAX_GIFTS			20
#define MAX_STRING_WIDTH	64
#define MAX_TYPEGIFTS		3
#define TYPE_STANDARD		1
#define TYPE_SPECIAL		2
#define STRING_STANDARD		"standard"
#define STRING_SPECIAL		"special"

#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define AURA_CYAN  			"0 255 255"
#define AURA_BLUE  			"0 0 255"
#define AURA_GREEN 			"0 255 0"
#define AURA_PINK 			"255 0 150"
#define AURA_RED 			"255 0 0"
#define AURA_ORANGE 		"255 155 0"
#define AURA_YELLOW 		"255 255 0"
#define AURA_PURPLE 		"155 0 255"
#define AURA_WHITE			"255 255 255"
#define AURA_LIME			"128 255 0"
#define AURA_MAROON			"128 0 0"
#define AURA_TEAL			"0 128 128"
#define AURA_GREY			"50 50 50"

#define	MAX_WEAPONS2		29

#define ENTITY_SAFE_LIMIT 2000 //don't spawn boxes when it's index is above this

ConVar cvar_gift_enable, cvar_gift_life, cvar_gift_chance, cvar_gift_chance2, cvar_gift_maxcollectMap,
	cvar_gift_maxcollectRound, cvar_gift_Announce, cvar_gift_DecayDecay, cvar_gift_MaxIncapCount;

static char g_sWeaponModels2[MAX_WEAPONS2][] =
{
	"models/w_models/weapons/w_pistol_B.mdl",
	"models/w_models/weapons/w_desert_eagle.mdl",
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_rifle_ak47.mdl",
	"models/w_models/weapons/w_rifle_sg552.mdl",
	"models/w_models/weapons/w_desert_rifle.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_shotgun_spas.mdl",
	"models/w_models/weapons/w_shotgun.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_smg_a.mdl",
	"models/w_models/weapons/w_smg_mp5.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_sniper_awp.mdl",
	"models/w_models/weapons/w_sniper_military.mdl",
	"models/w_models/weapons/w_sniper_scout.mdl",
	"models/w_models/weapons/w_m60.mdl",
	"models/w_models/weapons/w_grenade_launcher.mdl",
	"models/weapons/melee/w_chainsaw.mdl",
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/w_models/weapons/w_eq_pipebomb.mdl",
	"models/w_models/weapons/w_eq_bile_flask.mdl",
	"models/w_models/weapons/w_eq_painpills.mdl",
	"models/w_models/weapons/w_eq_adrenaline.mdl",
	"models/w_models/weapons/w_eq_Medkit.mdl",
	"models/w_models/weapons/w_eq_defibrillator.mdl",
	"models/w_models/weapons/w_eq_explosive_ammopack.mdl",
	"models/w_models/weapons/w_eq_incendiary_ammopack.mdl",
};

#define MODEL_GNOME			"models/props_junk/gnome.mdl"

static char weapons_name_standard[][][] = 
{
	//{"grenade_launcher","榴彈發射器"},
	//{"rifle_m60", "M60機關槍"},
	{"defibrillator","電擊器"},
	{"first_aid_kit","治療包"},
	{"pain_pills", "止痛藥丸"},
	{"adrenaline", "腎上腺素"},
	{"health_100", "生命值+100"},
	{"weapon_upgradepack_incendiary", "火焰包"},
	{"weapon_upgradepack_explosive","高爆彈"},
	{"molotov", "火瓶"},
	{"pipe_bomb", "土製炸彈"},
	{"vomitjar", "膽汁"},
	{"gascan","汽油"},
	{"propanetank", "瓦斯桶"},
	{"oxygentank", "氧氣罐"},
	{"fireworkcrate","煙火盒"},
	//{"pistol","手槍"},
	{"pistol_magnum", "沙漠之鷹"},
	//{"pumpshotgun", "木製霰彈槍"},
	//{"shotgun_chrome", "鐵製霰彈槍"},
	//{"smg", "機槍"},
	//{"smg_silenced", "消音機槍"},
	//{"smg_mp5","MP5衝鋒槍"},
	//{"rifle", "步槍"},
	//{"rifle_sg552", "SG552步槍"},
	//{"rifle_ak47", "AK47"},
	//{"rifle_desert","三連發步槍"},
	//{"shotgun_spas","戰鬥霰彈槍"},
	//{"autoshotgun", "連發霰彈槍"},
	//{"hunting_rifle", "獵槍"},
	//{"sniper_military", "軍用狙擊槍"},
	//{"sniper_scout", "SCOUT狙擊槍"},
	//{"sniper_awp", "AWP"},
	{"baseball_bat", "球棒"},
	{"chainsaw", "奪魂鋸"},
	{"cricket_bat", "板球拍"},
	{"crowbar", "鐵撬"},
	{"electric_guitar", "電吉他"},
	{"fireaxe", "斧頭"},
	{"frying_pan", "平底鍋"},
	{"katana", "武士刀"},
	{"machete", "開山刀"},
	{"tonfa", "警棍"},
	{"knife", "小刀"},
	{"golfclub", "高爾夫球棒"},
	{"pitchfork", "草叉"},
	{"shovel", "鐵鏟"},
	{"gnome", "小侏儒"},
	{"", "空(謝謝惠顧)"},
	{"laser_sight",	"雷射裝置"},
	{"incendiary_ammo",	"火焰子彈"},
	{"explosive_ammo",	"高爆子彈"},
	{"ammo","彈藥補給"},
	{"ammo","彈藥補給"},
	{"ammo","彈藥補給"},
	{"ammo","彈藥補給"},
	{"ammo","彈藥補給"},
	{"ammo","彈藥補給"},
	{"ammo","彈藥補給"},
	{"ammo","彈藥補給"},
	{"ammo","彈藥補給"},
	{"ammo","彈藥補給"}
};

static char weapons_name_special[][][] = 
{
	{"first_aid_kit","治療包"},
	{"first_aid_kit","治療包"},
	{"defibrillator","電擊器"},
	{"defibrillator","電擊器"},
	{"pain_pills", "止痛藥丸"},
	{"adrenaline", "腎上腺素"},
	{"health_100", "生命值+100"},
	{"health_100", "生命值+100"},
	{"vomitjar", "膽汁"},
	{"grenade_launcher","榴彈發射器"},
	{"rifle_m60", "殲滅者 M60"},
	{"sniper_awp", "AWP"},
	{"ammo","補給彈藥"},
};

//WeaponName/AmmoOffset/AmmoGive
static char weapon_ammo[][][] =
{
	{"weapon_smg",		 				"5", 	"400"},
	{"weapon_pumpshotgun",				"7", 	"64"},
	{"weapon_rifle",					"3", 	"250"},
	{"weapon_autoshotgun",				"8", 	"64"},
	{"weapon_hunting_rifle",			"9", 	"100"},
	{"weapon_smg_silenced",				"5", 	"400"},
	{"weapon_smg_mp5", 	 				"5", 	"400"},
	{"weapon_shotgun_chrome",	 		"7", 	"64"},
	{"weapon_rifle_ak47",  				"3",	"250"},
	{"weapon_rifle_desert",				"3", 	"250"},
	{"weapon_sniper_military",			"10", 	"100"},
	{"weapon_grenade_launcher", 	 	"17", 	"15"},
	{"weapon_rifle_sg552",	 			"3", 	"250"},
	{"weapon_rifle_m60",  				"6",	"200"},
	{"weapon_sniper_awp", 	 			"10", 	"100"},
	{"weapon_sniper_scout",	 			"10", 	"100"},
	{"weapon_shotgun_spas",  			"8",	"64"}
};

int CurrentPointsForMap[MAXPLAYERS+1];
int CurrentPointsForRound[MAXPLAYERS+1];
int CurrentGiftsForMap[MAXPLAYERS+1][MAX_TYPEGIFTS];
int CurrentGiftsForRound[MAXPLAYERS+1][MAX_TYPEGIFTS];
int CurrentGiftsTotalForMap[MAXPLAYERS+1];
int CurrentGiftsTotalForRound[MAXPLAYERS+1];

char g_sModel[MAX_GIFTS][MAX_STRING_WIDTH];
char g_sTypeModel[MAX_GIFTS][10];
char g_sTypeGift[MAX_GIFTS][10];
float g_fScale[MAX_GIFTS];

char g_sGifType[MAXENTITIES + 1][10];

bool bGiftEnable;
float fGiftLife;
int iGiftChance;
int iGiftChance2;
int iGiftMaxMap;
int iGiftMaxRound;
int iGiftMaxIncapCount;
bool g_bAnnounce;

int gifts_collected_map;
int gifts_collected_round;

char sPath_gifts[PLATFORM_MAX_PATH];
int g_iCountGifts;
int g_iOffset_Incapacitated;        // Used to check if tank is dying
int ammoOffset;	
bool g_bFinalHasStart, g_bIsOpenSafeRoom;

#define SND_REWARD1			"level/gnomeftw.wav"
#define SND_REWARD2			"level/loud/climber.wav"

public Plugin myinfo = 
{
	name = "[L4D2] Gifts Drop & Spawn",
	author = "Aceleracion & Harry Potter",
	description = "Drop gifts (touch gift to earn reward) when a special infected or a tank/witch killed by survivor.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=302731"
}

bool g_bLate;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	g_bLate = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
	LoadTranslations("l4d2_gifts.phrases");
	BuildPath(Path_SM, sPath_gifts, PLATFORM_MAX_PATH, "data/l4d2_gifts.cfg");
	
	if(!FileExists(sPath_gifts))
	{
		SetFailState("Cannot find the file 'data/l4d2_gifts.cfg'");
	}
	
	if(g_bLate)
	{
		if(!LoadConfigGifts(true))
		{
			SetFailState("Cannot load the file 'data/l4d2_gifts.cfg'");
		}
	}
	else
	{
		if(!LoadConfigGifts(false))
		{
			SetFailState("Cannot load the file 'data/l4d2_gifts.cfg'");
		}
	}
	
	if(g_iCountGifts == 0 )
	{
		SetFailState("Do not have models in 'data/l4d2_gifts.cfg'");
	}

	ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	g_iOffset_Incapacitated = FindSendPropInfo("Tank", "m_isIncapacitated");


	cvar_gift_enable = CreateConVar("l4d2_gifts_enabled",	"1", "Enable gifts 0: Disable, 1: Enable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_gift_life = CreateConVar("l4d2_gifts_giflife",	"30",	"How long the gift stay on ground (seconds)", FCVAR_NOTIFY, true, 0.0);
	cvar_gift_chance = CreateConVar("l4d2_gifts_chance", "50",	"Chance (%) of infected drop special gift.", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	cvar_gift_chance2 = CreateConVar("l4d2_gifts_chance2", "100",	"Chance (%) of tank and witch drop second special gift.", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	cvar_gift_maxcollectMap = CreateConVar("l4d2_gifts_maxcollectMap", "0", "Maximum of gifts that all survivors can pick up per map [0 = Disabled]", FCVAR_NOTIFY, true, 0.0);
	cvar_gift_maxcollectRound = CreateConVar("l4d2_gifts_maxcollectRound", "0", "Maximum of gifts that all survivors can pick up per round [0 = Disabled]", FCVAR_NOTIFY, true, 0.0);
	cvar_gift_Announce = CreateConVar("l4d2_gifts_announce",	"1",	"Notify Server who pickes up gift, and what the gift reward is.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_gift_MaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	cvar_gift_DecayDecay = FindConVar("pain_pills_decay_rate");

	GetCvars();
	cvar_gift_enable.AddChangeHook(Cvar_Changed);
	cvar_gift_life.AddChangeHook(Cvar_Changed);
	cvar_gift_chance.AddChangeHook(Cvar_Changed);
	cvar_gift_chance2.AddChangeHook(Cvar_Changed);
	cvar_gift_maxcollectMap.AddChangeHook(Cvar_Changed);
	cvar_gift_maxcollectRound.AddChangeHook(Cvar_Changed);
	cvar_gift_Announce.AddChangeHook(Cvar_Changed);
	cvar_gift_MaxIncapCount.AddChangeHook(Cvar_Changed);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("witch_killed", OnWitchKilled);
	HookEvent("finale_vehicle_ready", Finale_Vehicle_Ready);
	
	RegConsoleCmd("sm_giftcollect", Command_GiftCollected, "View number of gifts collected");
	RegConsoleCmd("sm_giftc", Command_GiftCollected, "View number of gifts collected");
	
	RegAdminCmd("sm_gift", Command_Gift, ADMFLAG_CHEATS, "Spawn a gift in your position");
	RegAdminCmd("sm_reloadgifts", Command_ReloadGift, ADMFLAG_CONFIG, " Reload the config file of gifts (data/l4d2_gifts.cfg)");

	AutoExecConfig(true, "l4d2_gifts");
}

public void OnMapStart()
{
	PrecacheSoundGifts();

	if(!LoadConfigGifts(true))
	{
		SetFailState("Cannot load the file 'data/l4d2_gifts.cfg'");
	}
	
	
	for (int i = 1; i <= MaxClients; i++)
	{
		CurrentPointsForMap[i] = 0;
		for (int j=0; j < MAX_TYPEGIFTS; j++)
		{
			CurrentGiftsForMap[i][j] = 0;
		}
		CurrentGiftsTotalForMap[i] = 0;
	}

	gifts_collected_map = 0;
	
	int max = MAX_WEAPONS2;
	for( int i = 0; i < max; i++ )
	{
		PrecacheModel(g_sWeaponModels2[i], true);
	}
	PrecacheModel(MODEL_GNOME, true);
}

public void PrecacheModelGifts()
{
	for( int i = 0; i < g_iCountGifts; i++ )
	{
		CheckPrecacheModel(g_sModel[i]);
	}
}

public void PrecacheSoundGifts()
{
	PrecacheSound(SND_REWARD1, true);
	PrecacheSound(SND_REWARD2, true);
}

public void CheckPrecacheModel(char[] Model)
{
	if (!IsModelPrecached(Model))
	{
		PrecacheModel(Model, true);
	}
}

public void OnConfigsExecuted()
{
	GetCvars();
}

public void Cvar_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	//Values of cvars
	bGiftEnable = cvar_gift_enable.BoolValue;
	fGiftLife = cvar_gift_life.FloatValue;
	iGiftChance = cvar_gift_chance.IntValue;
	iGiftChance2 = cvar_gift_chance2.IntValue;
	iGiftMaxMap = cvar_gift_maxcollectMap.IntValue;
	iGiftMaxRound = cvar_gift_maxcollectRound.IntValue;
	g_bAnnounce = cvar_gift_Announce.BoolValue;
	iGiftMaxIncapCount = cvar_gift_MaxIncapCount.IntValue;
}

public Action Command_Gift(int client, int args)
{
	if (!bGiftEnable)
		return Plugin_Handled;
	
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	if(IsFakeClient(client))
		return Plugin_Handled;
	
	if(args < 1)
	{
		DropGift(client, STRING_STANDARD);
	}
	else
	{
		char arg1[10];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		if(strcmp(arg1, STRING_STANDARD, false) == 0)
		{
			DropGift(client, STRING_STANDARD);
		}
		else if(strcmp(arg1, STRING_SPECIAL, false) == 0)
		{
			DropGift(client, STRING_SPECIAL);
		}
		else
		{
			ReplyToCommand(client, "[SM] Usage: sm_gift <standard or special>");
		}
	}
	return Plugin_Handled;
}

//==========================================
// CONSOLE COMMANDS
//==========================================

public Action Command_GiftCollected(int client, int args)
{
	if (!bGiftEnable)
		return Plugin_Handled;
	
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	if(GetClientTeam(client) != 2 || IsFakeClient(client))
		return Plugin_Handled;
	

	PrintToChat(client, "%s %T", TAG_GIFT, "Number of gifts collected", client);
	PrintToChat(client, "Special: %T", "In current map: %d | In current round: %d", client, CurrentGiftsForMap[client][TYPE_STANDARD], CurrentGiftsForRound[client][TYPE_STANDARD]);
	PrintToChat(client, "Total: %T", "In current map: %d | In current round: %d", client, CurrentGiftsTotalForMap[client], CurrentGiftsTotalForRound[client]);

	return Plugin_Handled;
}

//==========================================
// ADMINS COMMANDS
//==========================================

public Action Command_ReloadGift(int client, int args)
{
	if(!LoadConfigGifts(true))
	{
		LogError("Cannot load the file 'data/l4d2_gifts.cfg'");
		SetConVarInt(cvar_gift_enable, 0 , false, false);
		GetCvars();
	}
	
	if(g_iCountGifts == 0 )
	{
		LogError("Do not have models!!!");
		SetConVarInt(cvar_gift_enable, 0 , false, false);
		GetCvars();
	}
	
	return Plugin_Handled;
}

public bool LoadConfigGifts(bool precache)
{
	KeyValues hFile = CreateKeyValues("Gifts");
	
	if(!FileToKeyValues(hFile, sPath_gifts) )
	{
		delete hFile;
		return false;
	}
	
	KvGotoFirstSubKey(hFile);
	
	g_iCountGifts = 0;
	char sTemp[MAX_STRING_WIDTH];
	int i = 0;
	do
	{
		char sNum[8];
		KvGetSectionName(hFile, sNum, sizeof(sNum));
		int num = StringToInt(sNum);
		
		if(num > MAX_GIFTS || i >= MAX_GIFTS)
			break;
		
		KvGetString(hFile, "model", sTemp, MAX_STRING_WIDTH);
			
		if(strlen(sTemp) == 0)
			continue;
		
		if(FileExists(sTemp, true))
		{
			strcopy(g_sModel[i], MAX_STRING_WIDTH, sTemp);
			KvGetString(hFile, "type", g_sTypeModel[i], sizeof(g_sTypeModel[]), "static");
			KvGetString(hFile, "gift", g_sTypeGift[i], sizeof(g_sTypeGift[]));
			g_fScale[i] = KvGetFloat(hFile, "scale", 1.0);
			g_iCountGifts++;
			i++;
		}
	} 
	while (KvGotoNextKey(hFile));
	
	delete hFile;

	if(precache)
	{
		PrecacheModelGifts();
	}

	return true;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bFinalHasStart = false;
	g_bIsOpenSafeRoom = false;

	if (!bGiftEnable) 
		return;

	gifts_collected_round = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			CurrentPointsForRound[i] = 0;
			for (int j=0; j < MAX_TYPEGIFTS; j++)
			{
				CurrentGiftsForRound[i][j] = 0;
			}
			CurrentGiftsTotalForRound[i] = 0;
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bFinalHasStart = false;
	g_bIsOpenSafeRoom = false;

	if (!bGiftEnable) 
		return;
	
	gifts_collected_round = 0;
}

public void Finale_Vehicle_Ready(Event event, const char[] name, bool dontBroadcast) 
{
	g_bFinalHasStart = true;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!bGiftEnable)
		return;

	if(g_bIsOpenSafeRoom|| g_bFinalHasStart)
		return;

	if (iGiftMaxRound != 0 && gifts_collected_round > iGiftMaxRound)
		return;
	
	if (iGiftMaxMap != 0 && gifts_collected_map > iGiftMaxMap)
		return;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (attacker != victim && IsValidClient(victim) && GetClientTeam(victim) == 3)
	{
		if(GetZombieClass(victim) == 8)
		{
			if (GetRandomInt(1, 100) <= iGiftChance2)
			{
				DropGift(victim, STRING_SPECIAL);
			}
		}
		else
		{
			if (GetRandomInt(1, 100) <= iGiftChance)
			{
				DropGift(victim);
			}
		}
		
		
	}
}

public void OnWitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!bGiftEnable)
		return;

	if(g_bIsOpenSafeRoom|| g_bFinalHasStart)
		return;	

	//int attacker = GetClientOfUserId(event.GetInt("userid"));
	int witch = event.GetInt("witchid");
	if (GetRandomInt(1, 100) <= iGiftChance2)
	{
		DropGift(witch, STRING_SPECIAL);
	}
}

void NotifyGift(int client, int type, int gift = -1)
{
	if(type == TYPE_STANDARD)
	{
		if(gift == -1 || !IsValidEntity(gift))
		{
			return;
		}

		int iSlot0 = GetPlayerWeaponSlot(client, 0);
		int index = GetURandomIntRange(0,sizeof(weapons_name_standard)-1);
		if( strcmp(weapons_name_standard[index][0], "laser_sight") == 0 || 
			strcmp(weapons_name_standard[index][0], "incendiary_ammo") == 0 || 
			strcmp(weapons_name_standard[index][0], "explosive_ammo") == 0)
		{
			if(iSlot0 > MaxClients) GiveUpgrade(client, weapons_name_standard[index][0]);
		}
		else if( strcmp(weapons_name_standard[index][0], "ammo") == 0)
		{
			if(iSlot0 > MaxClients) GiveClientAmmo(client, iSlot0);
		}
		else if ( strcmp(weapons_name_standard[index][0], "health_100") == 0)
			GiveClientHealth(client, 100);
		else
			GiveWeapon(client, weapons_name_standard[index][0]);

		if(g_bAnnounce) PrintCenterToTeam(TEAM_SURVIVOR, client, weapons_name_standard[index][1]);
		else PrintToChat(client, "%s %T", TAG_GIFT, "Spawn Gift Special Not Points", client, client, weapons_name_standard[index][1]);
		PlaySound(client,SND_REWARD2);
		AddCollect(client, type);
	}
	else if(type == TYPE_SPECIAL)
	{
		if(gift == -1 || !IsValidEntity(gift))
		{
			return;
		}

		int iSlot0 = GetPlayerWeaponSlot(client, 0);
		int index = GetURandomIntRange(0, sizeof(weapons_name_special)-1);
		if( strcmp(weapons_name_special[index][0], "laser_sight") == 0 || 
			strcmp(weapons_name_special[index][0], "incendiary_ammo") == 0 || 
			strcmp(weapons_name_special[index][0], "explosive_ammo") == 0)
		{
			if(iSlot0 > MaxClients) GiveUpgrade(client, weapons_name_special[index][0]);
		}
		else if( strcmp(weapons_name_special[index][0], "ammo") == 0 )
		{
			if(iSlot0 > MaxClients) GiveClientAmmo(client, iSlot0);
		}
		else if ( strcmp(weapons_name_special[index][0], "health_100") == 0 )
			GiveClientHealth(client, 100);
		else
			GiveWeapon(client, weapons_name_special[index][0]);

		if(g_bAnnounce) PrintCenterToTeam(TEAM_SURVIVOR, client, weapons_name_special[index][1]);
		else PrintToChat(client, "%s %T", TAG_GIFT, "Spawn Gift Special Not Points", client, client, weapons_name_special[index][1]);
		PlaySound(client,SND_REWARD1);
		AddCollect(client, type);
	}

}

void GiveWeapon(int client, const char[] weapon)
{
	int flagsgive = GetCommandFlags("give");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", weapon);
	SetCommandFlags("give", flagsgive);
}

int GetRandomIndexGift(const char[] sType)
{
	int[] GiftsIndex = new int[g_iCountGifts];
	int count = 0;
	
	for(int i=0; i < g_iCountGifts; i++)
	{
		if(strcmp(g_sTypeGift[i], sType) == 0)
		{
			GiftsIndex[count] = i;
			count++;
		}
	}
	
	int random = GetRandomInt(0, count-1);
	return GiftsIndex[random];
}

int DropGift(int client, char[] type = STRING_STANDARD)
{	
	float gifPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", gifPos);
	gifPos[2] += 10.0;
	
	int gift = -1;
	int random = GetRandomIndexGift(type);
	
	if(strcmp(g_sTypeModel[random], "physics") == 0)
	{
		gift = CreateEntityByName("prop_physics_override");
	}
	else if(strcmp(g_sTypeModel[random], "static") == 0)
	{
		gift = CreateEntityByName("prop_dynamic_override");
	}
	
	if( CheckIfEntityMax(gift) )
	{
		DispatchKeyValue(gift, "model", g_sModel[random]);
		// char sScale[4];
		// Format(sScale, sizeof(sScale), "%.1f", g_fScale[random]);
		// DispatchKeyValue(gift, "modelscale", "0.5");
		
		Format(g_sGifType[gift], sizeof(g_sGifType[]), "%s", g_sTypeGift[random]);
		DispatchKeyValueVector(gift, "origin", gifPos);
		DispatchKeyValue(gift, "spawnflags", "8448"); // "Don`t take physics damage" + "Generate output on +USE" + "Force Server Side"

		DispatchSpawn(gift);
		SetEntPropFloat(gift, Prop_Send, "m_flModelScale", g_fScale[random]);
		if(strcmp(g_sTypeGift[random], STRING_STANDARD) == 0 || strcmp(g_sTypeGift[random], STRING_SPECIAL) == 0)
		{
			int color = GetRandomInt(1, 7);
			switch(color)
			{
				case 1: SetEntityRenderColor(gift, 0, 255, 255, 255); //COLOR_CYAN
				case 2: SetEntityRenderColor(gift, 144, 238, 144), 255; //COLOR_LIGHT_GREEN
				case 3: SetEntityRenderColor(gift, 128, 0, 128, 255); //COLOR_PURPLE
				case 4: SetEntityRenderColor(gift, 255, 88, 130, 255); //COLOR_PINK
				case 5: SetEntityRenderColor(gift, 255, 0, 0, 255); //COLOR_RED
				case 6: SetEntityRenderColor(gift, 254, 100, 46, 255); //COLOR_ORANGE
				case 7: SetEntityRenderColor(gift, 255, 255, 0, 255); //COLOR_YELLOW
			}
		}
		
		int rmdAura = GetRandomInt(1, 7);
		int color[3];
		switch(rmdAura)
		{
			case 1:
			{
				GetColor(AURA_CYAN, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 2:
			{
				GetColor(AURA_BLUE, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 3:
			{
				GetColor(AURA_GREEN, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 4:
			{
				GetColor(AURA_PINK, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 5:
			{
				GetColor(AURA_RED, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 6:
			{
				GetColor(AURA_ORANGE, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 7:
			{
				GetColor(AURA_YELLOW, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 8:
			{
				GetColor(AURA_PURPLE, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 9:
			{
				GetColor(AURA_WHITE, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 10:
			{
				GetColor(AURA_LIME, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 11:
			{
				GetColor(AURA_MAROON, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 12:
			{
				GetColor(AURA_TEAL, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
			case 13:
			{
				GetColor(AURA_GREY, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 1000, 0, color, true);
			}
		}

		CreateTimer(fGiftLife, Timer_GiftLife, EntIndexToEntRef(gift), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, ColdDown, EntIndexToEntRef(gift),TIMER_FLAG_NO_MAPCHANGE);
	}

	return gift;
}
public Action ColdDown( Handle timer, any ref)
{
	int gift;
	if (ref && (gift = EntRefToEntIndex(ref)) != INVALID_ENT_REFERENCE)
	{
		SDKHook(gift, SDKHook_Touch, OnTouch);
	}

	return Plugin_Continue;
}

public void OnTouch(int gift, int other)
{
	if (IsValidClient(other))
	{
		int iTeam = GetClientTeam(other);

		if(iTeam == 1) return;

		if(iTeam == 2 && IsPlayerAlive(other) &&
			!GetEntProp(other, Prop_Send, "m_isHangingFromLedge") &&
			!GetEntProp(other, Prop_Send, "m_isIncapacitated"))
		{

			if (strcmp(g_sGifType[gift], STRING_STANDARD) == 0)
			{
				//Points for Gifts Special
				NotifyGift(other, TYPE_STANDARD, gift);
			}
			else if (strcmp(g_sGifType[gift], STRING_SPECIAL) == 0)
			{
				//PoiNotifyGift(nts for Gifts Special
				NotifyGift(other, TYPE_SPECIAL, gift);
			}
			gifts_collected_map += 1;
			gifts_collected_round += 1;
			SDKUnhook(gift, SDKHook_Touch, OnTouch);
			AcceptEntityInput(gift, "kill");
		}
		else if(iTeam == 3 && IsPlayerAlive(other) && !IsPlayerGhost(other))
		{
			int CurrentHealth = GetClientHealth(other);
			int AddHP = 0;
			if(GetEntProp(other, Prop_Send, "m_zombieClass") == 8) 
			{
				if(IsTankDying(other)) return;
				AddHP = 450;
			}
			else
			{
				AddHP = 200;
			}
			SetEntityHealth(other, CurrentHealth + AddHP);
			if(g_bAnnounce) PrintCenterTextAll("%t", "Infected Got Gift", other, AddHP);
			else PrintToChat(other, "%s %T", TAG_GIFT, "Infected Got Gift", other, other, AddHP);
			PlaySound(other,SND_REWARD2);
			SDKUnhook(gift, SDKHook_Touch, OnTouch);
			AcceptEntityInput(gift, "kill");
		}
	}
} 

bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients) 
		return false;
	
	if (!IsClientConnected(client)) 
		return false;
	
	if (!IsClientInGame(client)) 
		return false;
	
	return true;
}

int GetZombieClass(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

public Action Timer_GiftLife( Handle timer, any ref)
{
	if ( ref && EntRefToEntIndex(ref) != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ref, "kill");
	}

	return Plugin_Continue;
}

public void AddCollect(int client, int type)
{
	CurrentGiftsForRound[client][type] += 1;
	CurrentGiftsForMap[client][type] += 1;
	CurrentGiftsTotalForRound[client] += 1;
	CurrentGiftsTotalForMap[client] += 1;
}

void GetColor(const char[] str_color, int color[3])
{
	char sColors[3][4];
	ExplodeString(str_color, " ", sColors, 3, 4);

	color[0] = StringToInt(sColors[0]);
	color[1] = StringToInt(sColors[1]);
	color[2] = StringToInt(sColors[2]);
}

stock int GetURandomIntRange(int min, int max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}

void PlaySound(int client,char[] sSoundName)
{
	EmitSoundToAll(sSoundName, client, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

bool IsPlayerGhost (int client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		return true;
	return false;
}

bool IsTankDying(int tankclient)
{
	if (!tankclient) return false;
 
	return view_as<bool>(GetEntData(tankclient, g_iOffset_Incapacitated));
}

stock void GiveUpgrade(int client, char[] name)
{
	char sBuf[32];
	int flags = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", flags & ~FCVAR_CHEAT);
	FormatEx(sBuf, sizeof (sBuf), "upgrade_add %s", name);
	FakeClientCommand(client, sBuf);
	SetCommandFlags("upgrade_add", flags);
}

stock void GiveClientAmmo(int client, int iSlot0)
{
	char slot0ClassName[40];
	GetEdictClassname(iSlot0, slot0ClassName, sizeof(slot0ClassName));
	int weaponAmmoOffset, ammoMax;
	for( int i = 0 ; i < sizeof(weapon_ammo) ; ++i) {
		if (strcmp(slot0ClassName, weapon_ammo[i][0]) == 0)
		{
			weaponAmmoOffset = StringToInt(weapon_ammo[i][1]);
			ammoMax = GetEntData(client, ammoOffset+(weaponAmmoOffset*4)) + StringToInt(weapon_ammo[i][2]);
			if(ammoMax > 999) ammoMax = 999;
			SetEntData(client, ammoOffset+(weaponAmmoOffset*4), ammoMax);
		}	
	}			
}

stock void GiveClientHealth(int client, int iHealthAdd)
{
	if(IsIncapacitated(client) || IsHandingFromLedge(client))
	{
		GiveWeapon(client, "health");
		SetTempHealth( client, 0.0 );
	}
	else
	{
		int iHealth = GetClientHealth( client );
		float fHealth = GetTempHealth( client );

		SetEntityHealth( client, iHealth + iHealthAdd );
		SetClientHealth( client, fHealth );
	}
}

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth );
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

stock bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

stock bool IsHandingFromLedge(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

float GetTempHealth(int client)
{
	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * cvar_gift_DecayDecay.FloatValue;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

void SetClientHealth(int client, float fHealth)
{	
	if( GetEntProp( client, Prop_Send, "m_currentReviveCount" ) >= 1 && iGiftMaxIncapCount >= 1 ) 	// The client has been incompetent once.
	{
		int flagsgive = GetCommandFlags("give");
		SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give health");
		SetCommandFlags("give", flagsgive);
		
		SetEntPropFloat( client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth );
		SetEntPropFloat( client, Prop_Send, "m_healthBufferTime", GetGameTime() );
	}
}

bool CheckIfEntityMax(int entity)
{
	if(entity == -1) return false;

	if(	entity > ENTITY_SAFE_LIMIT)
	{
		AcceptEntityInput(entity, "Kill");
		return false;
	}
	return true;
}

void PrintCenterToTeam (int team, int client, char[] displayMessage)
{
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && (GetClientTeam(i) == team || GetClientTeam(i) == 1))
			PrintCenterText(i, "%t", "Spawn Gift Special Not Points", client, displayMessage);
}

public void L4D2_OnLockDownOpenDoorFinish(const char[] sKeyMan)
{
	g_bIsOpenSafeRoom = true;
}
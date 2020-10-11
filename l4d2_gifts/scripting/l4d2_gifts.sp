#define PLUGIN_VERSION		"2.3"

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
#include <smlib>
#include <glow>

#define DATABASE_CONFIG 	"l4d2gifts"
#define TAG_GIFT			"{G}[{L}GIFTS{G}]\x01"
#define	MAX_GIFTS			20
#define MAX_STRING_WIDTH	64
#define MAX_TYPEGIFTS		3
#define TYPE_SPECIAL		2
#define TYPE_SPECIAL2		1
#define MAX_SPECIALITEMS	53
#define MAX_SPECIALITEMS2	10

#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define COLOR_CYAN  		"0 255 255 255"
#define COLOR_LIGHT_GREEN 	"144 238 144 255"
#define COLOR_PURPLE 		"128 0 128 255"
#define COLOR_PINK 			"250 88 130 255"
#define COLOR_RED 			"255 0 0 255"
#define COLOR_ORANGE 		"254 100 46 255"
#define COLOR_YELLOW 		"255 255 0 255"

#define AURA_CYAN  			"0 255 255"
#define AURA_BLUE  			"0 0 255"
#define AURA_GREEN 			"144 238 144"
#define AURA_PINK 			"250 88 130"
#define AURA_RED 			"255 0 0"
#define AURA_ORANGE 		"254 100 46"
#define AURA_YELLOW 		"255 255 0"

#define SND_REWARD1			"level/loud/climber.wav"
#define SND_REWARD2			"level/gnomeftw.wav"

#define	MAX_WEAPONS2		29

ConVar cvar_gift_enable, cvar_gift_life, cvar_gift_chance, cvar_gift_chance2, cvar_gift_maxcollectMap,
	cvar_gift_maxcollectRound, cvar_gift_Announce, cvar_gift_DecayDecay, cvar_gift_MaxIncapCount;

static char g_sWeaponModels2[MAX_WEAPONS2][] =
{
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	"models/w_models/weapons/w_pistol_a.mdl",
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/w_models/weapons/w_eq_pipebomb.mdl",
	"models/w_models/weapons/w_eq_medkit.mdl",
	"models/w_models/weapons/w_eq_painpills.mdl",

	"models/w_models/weapons/w_shotgun.mdl",
	"models/w_models/weapons/w_desert_rifle.mdl",
	"models/w_models/weapons/w_grenade_launcher.mdl",
	"models/w_models/weapons/w_m60.mdl",
	"models/w_models/weapons/w_rifle_ak47.mdl",
	"models/w_models/weapons/w_rifle_sg552.mdl",
	"models/w_models/weapons/w_shotgun_spas.mdl",
	"models/w_models/weapons/w_smg_a.mdl",
	"models/w_models/weapons/w_smg_mp5.mdl",
	"models/w_models/weapons/w_sniper_awp.mdl",
	"models/w_models/weapons/w_sniper_military.mdl",
	"models/w_models/weapons/w_sniper_scout.mdl",
	"models/weapons/melee/w_chainsaw.mdl",
	"models/w_models/weapons/w_desert_eagle.mdl",
	"models/w_models/weapons/w_eq_bile_flask.mdl",
	"models/w_models/weapons/w_eq_defibrillator.mdl",
	"models/w_models/weapons/w_eq_explosive_ammopack.mdl",
	"models/w_models/weapons/w_eq_incendiary_ammopack.mdl",
	"models/w_models/weapons/w_eq_adrenaline.mdl"
};

#define MODEL_GNOME			"models/props_junk/gnome.mdl"

static char weapons_name[MAX_SPECIALITEMS][2][50] = 
{
	{"grenade_launcher","榴彈發射器"},
	{"rifle_m60", "M60機關槍"},
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
	{"pistol","手槍"},
	{"pistol_magnum", "沙漠之鷹"},
	{"pumpshotgun", "木製霰彈槍"},
	{"shotgun_chrome", "鐵製霰彈槍"},
	{"smg", "機槍"},
	{"smg_silenced", "消音機槍"},
	{"smg_mp5","MP5衝鋒槍"},
	{"rifle", "步槍"},
	{"rifle_sg552", "SG552步槍"},
	{"rifle_ak47", "AK47"},
	{"rifle_desert","三連發步槍"},
	{"shotgun_spas","戰鬥霰彈槍"},
	{"autoshotgun", "連發霰彈槍"},
	{"hunting_rifle", "狙擊槍"},
	{"sniper_military", "軍用狙擊槍"},
	{"sniper_scout", "SCOUT狙擊槍"},
	{"sniper_awp", "AWP"},
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
	{"ammo","補給彈藥"}
};

static char weapons_name2[MAX_SPECIALITEMS2][2][50] = 
{
	{"rifle_m60", "M60機關槍"},
	{"first_aid_kit","治療包"},
	{"defibrillator","電擊器"},
	{"pain_pills", "止痛藥丸"},
	{"adrenaline", "腎上腺素"},
	{"health_100", "生命值+100"},
	{"vomitjar", "膽汁"},
	{"grenade_launcher","榴彈發射器"},
	{"fireworkcrate","煙火盒"},
	{"ammo","補給彈藥"},
};

//WeaponName/AmmoOffset/AmmoGive
static char weapon_ammo[][][] =
{
	{"weapon_smg",		 				"5", 	"300"},
	{"weapon_pumpshotgun",				"7", 	"35"},
	{"weapon_rifle",					"3", 	"200"},
	{"weapon_autoshotgun",				"8", 	"50"},
	{"weapon_hunting_rifle",			"9", 	"100"},
	{"weapon_smg_silenced",				"5", 	"300"},
	{"weapon_smg_mp5", 	 				"5", 	"300"},
	{"weapon_shotgun_chrome",	 		"7", 	"35"},
	{"weapon_rifle_ak47",  				"3",	"200"},
	{"weapon_rifle_desert",				"3", 	"200"},
	{"weapon_sniper_military",			"10", 	"100"},
	{"weapon_grenade_launcher", 	 	"17", 	"20"},
	{"weapon_rifle_sg552",	 			"3", 	"200"},
	{"weapon_rifle_m60",  				"6",	"150"},
	{"weapon_sniper_awp", 	 			"10", 	"80"},
	{"weapon_sniper_scout",	 			"10", 	"80"},
	{"weapon_shotgun_spas",  			"8",	"50"}
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

int g_GifLife[2000];
char g_sGifType[2000][10];
int g_GifEntIndex[2000];
float g_GiftMov[2000];

bool bGiftEnable;
int iGiftLife;
int iGiftChance;
int iGiftChance2;
int iGiftMaxMap;
int iGiftMaxRound;
int iGiftMaxIncapCount;
bool g_RoundEnd, g_bAnnounce;

int gifts_collected_map;
int gifts_collected_round;

char sPath_gifts[PLATFORM_MAX_PATH];
int g_iCountGifts;
int g_iOffset_Incapacitated;        // Used to check if tank is dying
int ammoOffset;	

public Plugin myinfo = 
{
	name = "[L4D2] Gifts Drop & Spawn",
	author = "Aceleracion & Harry Potter",
	description = "Drop gifts (touch gift to earn reward) when a special infected or a tank/witch killed by survivor.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=302731"
}

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
	LoadTranslations("l4d2_gifts.phrases");
	BuildPath(Path_SM, sPath_gifts, PLATFORM_MAX_PATH, "data/l4d2_gifts.cfg");
	
	if(!FileExists(sPath_gifts))
	{
		SetFailState("Cannot find the file 'data/l4d2_gifts.cfg'");
	}
	
	if(!LoadConfigGifts(false))
	{
		SetFailState("Cannot load the file 'data/l4d2_gifts.cfg'");
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
		PrecacheModel(Model, false);
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
	iGiftLife = cvar_gift_life.IntValue;
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
		DropGift(client, "special");
	}
	else
	{
		char arg1[10];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		if(StrEqual(arg1, "special", false))
		{
			DropGift(client, "special");
		}
		else if(StrEqual(arg1, "special2", false))
		{
			DropGift(client, "special2");
		}
		else
		{
			ReplyToCommand(client, "[SM] Usage: sm_gift <special or special2>");
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
	

	Client_PrintToChat(client, false, "%s %t", TAG_GIFT, "Number of gifts collected");
	Client_PrintToChat(client, false, "{B}Special: %t", "In current map: %d | In current round: %d", CurrentGiftsForMap[client][TYPE_SPECIAL], CurrentGiftsForRound[client][TYPE_SPECIAL]);
	Client_PrintToChat(client, false, "{B}Total: %t", "In current map: %d | In current round: %d", CurrentGiftsTotalForMap[client], CurrentGiftsTotalForRound[client]);

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
		CloseHandle(hFile);
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
	
	CloseHandle(hFile);

	if(precache)
	{
		PrecacheModelGifts();
	}
	return true;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!bGiftEnable) 
		return;
	
	g_RoundEnd = false;
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

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!bGiftEnable) 
		return;
	
	g_RoundEnd = true;
	gifts_collected_round = 0;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!bGiftEnable)
		return;

	if (iGiftMaxRound != 0 && gifts_collected_round > iGiftMaxRound)
		return;
	
	if (iGiftMaxMap != 0 && gifts_collected_map > iGiftMaxMap)
		return;
	
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (attacker != victim && IsValidClient(victim) && GetClientTeam(victim) == 3)
	{
		if(Infected_Admitted(victim) == 8)
		{
			if (GetRandomInt(1, 100) < iGiftChance2)
			{
				DropGift(victim, "special2");
			}
		}
		else
		{
			if (GetRandomInt(1, 100) < iGiftChance)
			{
				DropGift(victim);
			}
		}
		
		
	}
}

public Action OnWitchKilled(Event event, const char[] name, bool dontBroadcast)
{
   //int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	int witch = GetEventInt(event, "witchid");
	if (GetRandomInt(1, 100) < iGiftChance2)
	{
		DropGift(witch, "special2");
	}
}

void NotifyGift(int client, int type, int gift = -1)
{
	if(type == TYPE_SPECIAL)
	{
		if(gift == -1 || !IsValidEntity(gift))
		{
			return;
		}

		int index;
		int iSlot0 = GetPlayerWeaponSlot(client, 0);
		if(iSlot0 <= 0 )
		{	
			index = GetURandomIntRange(0,MAX_SPECIALITEMS-1-4);
			GiveWeapon(client, weapons_name[index][0]);
		}
		else
		{
			index = GetURandomIntRange(0,MAX_SPECIALITEMS-1);
			if( StrEqual(weapons_name[index][0], "laser_sight") || StrEqual(weapons_name[index][0], "incendiary_ammo") || StrEqual(weapons_name[index][0], "explosive_ammo") )
				GiveUpgrade(client, weapons_name[index][0]);
			else if( StrEqual(weapons_name[index][0], "ammo") )
				GiveClientAmmo(client, iSlot0);
			else if ( StrEqual(weapons_name[index][0], "health_100") )
				GiveClientHealth(client, 100);
			else
				GiveWeapon(client, weapons_name[index][0]);
		}
		if(g_bAnnounce) Client_PrintToChatAll(false, "%s %t", TAG_GIFT, "Spawn Gift Special Not Points", client, weapons_name[index][1]);
		else Client_PrintToChat(client, false, "%s %t", TAG_GIFT, "Spawn Gift Special Not Points", client, weapons_name[index][1]);
		PlaySound(client,SND_REWARD2);
		AddCollect(client, type);
	}
	else if(type == TYPE_SPECIAL2)
	{
		if(gift == -1 || !IsValidEntity(gift))
		{
			return;
		}

		int index;
		int iSlot0 = GetPlayerWeaponSlot(client, 0);
		if(iSlot0 <= 0 )
		{	
			index = GetURandomIntRange(0,MAX_SPECIALITEMS2-1-1);
			GiveWeapon(client, weapons_name2[index][0]);
		}
		else
		{
			index = GetURandomIntRange(0,MAX_SPECIALITEMS2-1);
			if( StrEqual(weapons_name2[index][0], "ammo") )
				GiveClientAmmo(client, iSlot0);
			else if ( StrEqual(weapons_name2[index][0], "health_100") )
				GiveClientHealth(client, 100);
			else
				GiveWeapon(client, weapons_name2[index][0]);
		}

		if(g_bAnnounce) Client_PrintToChatAll(false, "%s %t", TAG_GIFT, "Spawn Gift Special Not Points", client, weapons_name2[index][1]);
		else Client_PrintToChat(client, false, "%s %t", TAG_GIFT, "Spawn Gift Special Not Points", client, weapons_name2[index][1]);
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
		if(StrEqual(g_sTypeGift[i], sType))
		{
			GiftsIndex[count] = i;
			count++;
		}
	}
	
	int random = GetRandomInt(0, count-1);
	return GiftsIndex[random];
}

int DropGift(int client, char[] type = "special")
{	
	float gifPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", gifPos);
	gifPos[2] += 10.0;
	
	int gift = -1; //prop_physics_override
	int random = GetRandomIndexGift(type);
	
	if(StrEqual(g_sTypeModel[random], "physics"))
	{
		gift = CreateEntityByName("prop_physics_override");
	}
	else if(StrEqual(g_sTypeModel[random], "static"))
	{
		gift = CreateEntityByName("prop_dynamic_override");
	}
	
	if(gift != -1)
	{
		DispatchKeyValue(gift, "model", g_sModel[random]);
		
		if(StrEqual(g_sTypeGift[random], "special")/* || StrEqual(g_sTypeGift[random], "special2")*/)
		{
			int color = GetRandomInt(1, 7);
			switch(color)
			{
				case 1:
					DispatchKeyValue(gift, "rendercolor", COLOR_CYAN);
				case 2:
					DispatchKeyValue(gift, "rendercolor", COLOR_LIGHT_GREEN);
				case 3:
					DispatchKeyValue(gift, "rendercolor", COLOR_PURPLE);
				case 4:
					DispatchKeyValue(gift, "rendercolor", COLOR_PINK);
				case 5:
					DispatchKeyValue(gift, "rendercolor", COLOR_RED);
				case 6:
					DispatchKeyValue(gift, "rendercolor", COLOR_ORANGE);
				case 7:
					DispatchKeyValue(gift, "rendercolor", COLOR_YELLOW);
			}
		}
		
		Format(g_sGifType[gift], sizeof(g_sGifType[]), "%s", g_sTypeGift[random]);
		DispatchKeyValueVector(gift, "origin", gifPos);
		SetEntProp(gift, Prop_Send, "m_nSolidType", 6);
		DispatchSpawn(gift);
		
		SetEntPropFloat(gift, Prop_Send, "m_flModelScale", g_fScale[random]);
		
		int rmdAura = GetRandomInt(1, 7);
		int color[3];
		switch(rmdAura)
		{
			case 1:
			{
				GetColor(AURA_CYAN, color);
				L4D2_SetEntGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 2:
			{
				GetColor(AURA_BLUE, color);
				L4D2_SetEntGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 3:
			{
				GetColor(AURA_GREEN, color);
				L4D2_SetEntGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 4:
			{
				GetColor(AURA_PINK, color);
				L4D2_SetEntGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 5:
			{
				GetColor(AURA_RED, color);
				L4D2_SetEntGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 6:
			{
				GetColor(AURA_ORANGE, color);
				L4D2_SetEntGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 7:
			{
				GetColor(AURA_YELLOW, color);
				L4D2_SetEntGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
		}
		g_GifLife[gift] = 0;
		g_GifEntIndex[gift] = EntIndexToEntRef(gift);
		CreateTimer(1.0, Timer_GiftLife, EntIndexToEntRef(gift), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, ColdDown, EntIndexToEntRef(gift),TIMER_FLAG_NO_MAPCHANGE);
	}

	return gift;
}
public Action ColdDown( Handle timer, any ref)
{
	int gift = EntRefToEntIndex(ref);
	if (IsValidEntity(gift))
	{
		SDKHook(gift, SDKHook_Touch, OnTouch);
	}
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

			if (StrEqual(g_sGifType[gift], "special"))
			{
				//Points for Gifts Special
				NotifyGift(other, TYPE_SPECIAL, gift);
			}
			else if (StrEqual(g_sGifType[gift], "special2"))
			{
				//PoiNotifyGift(nts for Gifts Special
				NotifyGift(other, TYPE_SPECIAL2, gift);
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
			if(g_bAnnounce) Client_PrintToChatAll(false, "%s %t", TAG_GIFT, "Infected Got Gift", other, AddHP);
			else Client_PrintToChat(other, false, "%s %t", TAG_GIFT, "Infected Got Gift", other, AddHP);
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

int Infected_Admitted(int client)
{
	int class = GetEntProp(client, Prop_Send, "m_zombieClass");
	
	if(class == 1 || class == 2 || class == 3 || class == 4 || class == 5 || class == 6 || class == 7 || class == 8)
	{
		return class;
	}
	
	return -1;
}

public Action Timer_GiftLife( Handle timer, any ref)
{
	int gift = EntRefToEntIndex(ref);
	if (IsValidEntity(gift))
	{
		g_GifLife[gift] += 1;
		if( g_RoundEnd || g_GifLife[gift] > iGiftLife)
		{
			g_GifLife[gift] = 0;
			AcceptEntityInput(gift, "kill");
			return Plugin_Stop;
		}
		g_GiftMov[gift] = 0.0;
		CreateTimer(0.1, Timer_RotationGift, ref, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		return Plugin_Continue;
	}
	
	return Plugin_Stop;
}

public Action Timer_RotationGift( Handle timer, any ref)
{
	int gift = EntRefToEntIndex(ref);
	if (IsValidEntity(gift))
	{
		g_GiftMov[gift] += 0.1;
		if( g_RoundEnd || g_GiftMov[gift] >= 1.0)
		{
			g_GiftMov[gift] = 0.0;
			return Plugin_Stop;
		}
		RotateAdvance(gift, 15.0, 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

void RotateAdvance(int index, float value, int axis)
{
	if (IsValidEntity(index))
	{
		float rotate_[3];
		GetEntPropVector(index, Prop_Data, "m_angRotation", rotate_);
		rotate_[axis] += value;
		TeleportEntity( index, NULL_VECTOR, rotate_, NULL_VECTOR);
	}
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
		if (StrEqual(slot0ClassName, weapon_ammo[i][0]))
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
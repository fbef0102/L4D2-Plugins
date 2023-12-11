#define PLUGIN_VERSION		"3.3-2023/12/11"

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	Plugin Info:

*	Name	:	[L4D2] Gifts Drop & Spawn
*	Author	:	Aceleracion & HarryPotter
*	Descrp	:	Drop gifts (touch gift to earn reward) when a special infected or a witch/tank killed by survivor.
*	Link	:	https://github.com/fbef0102/L4D2-Plugins/tree/master/l4d2_gifts

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <l4d2_weapons>

#define MAXENTITIES                   2048

#define	MAX_GIFTS			20
#define MAX_STRING_WIDTH	64
#define MAX_TYPEGIFTS		3
#define TYPE_STANDARD		1
#define TYPE_SPECIAL		2
#define STRING_STANDARD		"standard"
#define STRING_SPECIAL		"special"

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define MODEL_GNOME			"models/props_junk/gnome.mdl"

static char weapons_name_standard[][][] = 
{
	//{"grenade_launcher","Grenade Launcher"},
	//{"rifle_m60", "M60 Machine Gun"},
	{"defibrillator","Defibrillator"},
	{"first_aid_kit","First Aid Kit"},
	{"pain_pills", "Pain Pill"},
	{"adrenaline", "Adrenaline"},
	{"weapon_upgradepack_incendiary", "Incendiary Pack"},
	{"weapon_upgradepack_explosive","Explosive Pack"},
	{"molotov", "Molotov"},
	{"pipe_bomb", "Pipe Bomb"},
	{"vomitjar", "Vomitjar"},
	{"gascan","Gascan"},
	{"propanetank", "Propane Tank"},
	{"oxygentank", "Oxygen Tank"},
	{"fireworkcrate","Firework Crate"},
	{"pistol","Pistol"},
	{"pistol_magnum", "Magnum"},
	{"pumpshotgun", "Pumpshotgun"},
	{"shotgun_chrome", "Chrome Shotgun"},
	{"smg", "Smg"},
	{"smg_silenced", "Silenced Smg"},
	{"smg_mp5","MP5"},
	{"rifle", "Rifle"},
	{"rifle_sg552", "SG552"},
	{"rifle_ak47", "AK47"},
	{"rifle_desert","Desert Rifle"},
	{"shotgun_spas","Spas Shotgun"},
	{"autoshotgun", "Autoshotgun"},
	{"hunting_rifle", "Hunting Rifle"},
	//{"sniper_military", "Military Sniper"},
	//{"sniper_scout", "SCOUT"},
	//{"sniper_awp", "AWP"},
	{"baseball_bat", "Baseball Bat"},
	{"chainsaw", "Chainsaw"},
	{"cricket_bat", "Cricket Bat"},
	{"crowbar", "Crowbar"},
	{"electric_guitar", "Electric Guitar"},
	{"fireaxe", "Fire Axe"},
	{"frying_pan", "Frying Pan"},
	{"katana", "Katana"},
	{"machete", "Machete"},
	{"tonfa", "Tonfa"},
	{"knife", "Knife"},
	{"golfclub", "Golf Club"},
	{"pitchfork", "Pitchfork"},
	{"shovel", "Shovel"},
	{"gnome", "Gnome"},
	{"laser_sight",	"Laser Sight"},
	{"incendiary_ammo",	"Incendiary Ammo"},
	{"explosive_ammo",	"Explosive Ammo"},
	{"ammo","Ammo"},
	{"ammo","Ammo"},
	{"ammo","Ammo"},
	{"ammo","Ammo"},
	{"ammo","Ammo"},
	{"ammo","Ammo"},
	{"ammo","Ammo"},
	{"ammo","Ammo"},
	{"ammo","Ammo"},
	{"ammo","Ammo"},
	{"hp_+100", "Health+100"},
	{"hp_+10","Health+10"},
	{"hp_+30","Health+30"},
	{"hp_+50","Health+50"},
	{"hp_-1","Health-1"},
	{"hp_-5","Health-5"},
	{"hp_-10","Health-10"},
	{"hp_-20","Health-20"},
	{"", "Empty"},
};

static char weapons_name_special[][][] = 
{
	{"first_aid_kit","First Aid Kit"},
	{"first_aid_kit","First Aid Kit"},
	{"defibrillator","Defibrillator"},
	{"pain_pills", "Pain Pill"},
	{"adrenaline", "Adrenaline"},
	{"vomitjar", "Vomitjar"},
	{"grenade_launcher","Grenade Launcher"},
	{"rifle_m60", "M60 Machine Gun"},
	{"sniper_awp", "AWP"},
	{"ammo","Ammo"},
	{"hp_+100", "Health+100"},
	{"hp_+100", "Health+100"},
};

//WeaponName/AmmoOffset/AmmoGive
static char weapon_ammo[][][] =
{
	{"weapon_smg",		 				"5", 	"250"},
	{"weapon_pumpshotgun",				"7", 	"40"},
	{"weapon_rifle",					"3", 	"200"},
	{"weapon_autoshotgun",				"8", 	"50"},
	{"weapon_hunting_rifle",			"9", 	"75"},
	{"weapon_smg_silenced",				"5", 	"250"},
	{"weapon_smg_mp5", 	 				"5", 	"250"},
	{"weapon_shotgun_chrome",	 		"7", 	"40"},
	{"weapon_rifle_ak47",  				"3",	"200"},
	{"weapon_rifle_desert",				"3", 	"200"},
	{"weapon_sniper_military",			"10", 	"90"},
	{"weapon_grenade_launcher", 	 	"17", 	"15"},
	{"weapon_rifle_sg552",	 			"3", 	"200"},
	{"weapon_rifle_m60",  				"6",	"200"},
	{"weapon_sniper_awp", 	 			"10", 	"80"},
	{"weapon_sniper_scout",	 			"10", 	"80"},
	{"weapon_shotgun_spas",  			"8",	"50"}
};

#define	MAX_WEAPONS		29
static char g_sWeaponModels[MAX_WEAPONS][] =
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

int ColorCyan[3], ColorBlue[3], ColorGreen[3], ColorPink[3], ColorRed[3],
	ColorOrange[3], ColorYellow[3], ColorPurple[3], ColorWhite[3],ColorLime[3],
	ColorMaroon[3], ColorTeal[3], ColorLightGreen[3];

#define ENTITY_SAFE_LIMIT 2000 //don't spawn boxes when it's index is above this

ConVar pain_pills_decay_rate, survivor_max_incapacitated_count;

ConVar cvar_gift_enable, cvar_gift_life, cvar_gift_chance,
	cvar_special_gift_chance,
	cvar_gift_infected_hp, cvar_special_gift_infected_hp,
	cvar_gift_Announce,
	cvar_blockSwitch;

bool g_bGiftEnable, g_bCvarBlockSwitch;
float g_fGiftLife;
int g_iGiftChance, g_iSpecialGiftChance, g_iGiftMaxMap, g_iGiftMaxRound,
	g_iGiftHP, g_iSpecialGiftHP;
float pain_pills_decay_rate_float;
int g_iCvarAnnounce;

char g_sModel[MAX_GIFTS][MAX_STRING_WIDTH];
char g_sTypeModel[MAX_GIFTS][10];
char g_sTypeGift[MAX_GIFTS][10];
float g_fScale[MAX_GIFTS];
char g_sGiftGlowCols[MAX_GIFTS][12],
	g_sGiftEntityCols[MAX_GIFTS][12];

int g_iGiftGlowRange[MAX_GIFTS], 
	g_iSpecialGiftGlowRange[MAX_GIFTS];

char g_sGifType[MAXENTITIES + 1][10];

int gifts_collected_map;
int gifts_collected_round;

char sPath_gifts[PLATFORM_MAX_PATH];
int g_iCountGifts;
int g_iOffset_Incapacitated;        // Used to check if tank is dying
int ammoOffset;	

bool 
	g_bGiftGlowEnable[MAX_GIFTS],
	g_bGiftEntityEnable[MAX_GIFTS],
	g_bFinalHasStart, 
	g_bIsOpenSafeRoom,
	g_bHooked[MAXPLAYERS+1];

#define SOUND_SPECIAL			"level/gnomeftw.wav"
#define SOUND_STANDARD			"level/loud/climber.wav"

public Plugin myinfo = 
{
	name = "[L4D2] Gifts Drop & Spawn",
	author = "Aceleracion & Harry Potter",
	description = "Drop gifts (touch gift to earn reward) when a special infected or a tank/witch killed by survivor.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=302731"
}

int ZC_TANK;
bool bLate;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	ZC_TANK = 8;
	bLate = late;
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

	survivor_max_incapacitated_count = FindConVar("survivor_max_incapacitated_count");
	pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");

	cvar_gift_enable = CreateConVar("l4d2_gifts_enabled",									"1", 		"Enable gifts 0: Disable, 1: Enable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_gift_life = CreateConVar("l4d2_gifts_gift_life",									"30",		"How long the gift stay on ground (seconds)", FCVAR_NOTIFY, true, 0.0);
	cvar_gift_chance = CreateConVar("l4d2_gifts_chance", 									"50",		"Chance (%) of infected drop special standard gift.", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	cvar_special_gift_chance = CreateConVar("l4d2_specail_gifts_chance", 					"100",		"Chance (%) of tank and witch drop second special gift.", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	cvar_gift_Announce = CreateConVar("l4d2_gifts_announce_type",							"3",		"Notify Server who pickes up gift, and what the gift reward is. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	cvar_gift_infected_hp = CreateConVar("l4d2_gifts_infected_reward_hp",					"200",		"Increase Infected health if they pick up gift. (0=Off)", FCVAR_NOTIFY, true, 0.0);
	cvar_special_gift_infected_hp = CreateConVar("l4d2_gifts_special_infected_reward_hp",	"400",		"Increase Infected health if they pick up special gift. (0=Off)", FCVAR_NOTIFY, true, 0.0);
	cvar_blockSwitch = 				CreateConVar("l4d2_gifts_block_switch",					"1",		"If 1, prevent survivors from switching into new weapons and items when they open gifts", FCVAR_NOTIFY, true, 0.0);
	AutoExecConfig(true, "l4d2_gifts");

	GetCvars();
	survivor_max_incapacitated_count.AddChangeHook(Cvar_Changed);
	pain_pills_decay_rate.AddChangeHook(Cvar_Changed);

	cvar_gift_enable.AddChangeHook(Cvar_Changed);
	cvar_gift_life.AddChangeHook(Cvar_Changed);
	cvar_gift_chance.AddChangeHook(Cvar_Changed);
	cvar_special_gift_chance.AddChangeHook(Cvar_Changed);
	cvar_gift_Announce.AddChangeHook(Cvar_Changed);
	cvar_gift_infected_hp.AddChangeHook(Cvar_Changed);
	cvar_special_gift_infected_hp.AddChangeHook(Cvar_Changed);
	cvar_blockSwitch.AddChangeHook(Cvar_Changed);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("witch_killed", OnWitchKilled);
	HookEvent("finale_vehicle_ready", Finale_Vehicle_Ready);

	RegAdminCmd("sm_gifts", Command_Gift, ADMFLAG_CHEATS, "Spawn a gift in your position");
	RegAdminCmd("sm_reloadgifts", Command_ReloadGift, ADMFLAG_CONFIG, " Reload the config file of gifts (data/l4d2_gifts.cfg)");

	SetRandomColor();

	if(bLate)
	{
		LateLoad();
	}
}

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);
    }
}

void Cvar_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	//Values of cvars
	g_bGiftEnable = cvar_gift_enable.BoolValue;
	g_fGiftLife = cvar_gift_life.FloatValue;
	g_iGiftChance = cvar_gift_chance.IntValue;
	g_iSpecialGiftChance = cvar_special_gift_chance.IntValue;
	g_iCvarAnnounce = cvar_gift_Announce.IntValue;
	g_iGiftHP = cvar_gift_infected_hp.IntValue;
	g_iSpecialGiftHP = cvar_special_gift_infected_hp.IntValue;
	g_bCvarBlockSwitch = cvar_blockSwitch.BoolValue;

	pain_pills_decay_rate_float = pain_pills_decay_rate.FloatValue;
}

public void OnMapStart()
{
	PrecacheSoundGifts();

	if(!LoadConfigGifts(true))
	{
		SetFailState("Cannot load the file 'data/l4d2_gifts.cfg'");
	}
	
	int max = MAX_WEAPONS;
	for( int i = 0; i < max; i++ )
	{
		PrecacheModel(g_sWeaponModels[i], true);
	}
	PrecacheModel(MODEL_GNOME, true);
}

void PrecacheModelGifts()
{
	for( int i = 0; i < g_iCountGifts; i++ )
	{
		CheckPrecacheModel(g_sModel[i]);
	}
}

void PrecacheSoundGifts()
{
	PrecacheSound(SOUND_SPECIAL, true);
	PrecacheSound(SOUND_STANDARD, true);
}

void CheckPrecacheModel(char[] Model)
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

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

Action Command_Gift(int client, int args)
{
	if (!g_bGiftEnable)
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
			ReplyToCommand(client, "[SM] Usage: sm_gifts <standard or special>");
		}
	}
	return Plugin_Handled;
}

Action Command_ReloadGift(int client, int args)
{
	if(!LoadConfigGifts(true))
	{
		LogError("Cannot load the file 'data/l4d2_gifts.cfg'");
		if(client) ReplyToCommand(client, "Cannot load the file 'data/l4d2_gifts.cfg'");
	}
	
	if(g_iCountGifts == 0 )
	{
		LogError("Do not have models!!!");
		if(client) ReplyToCommand(client, "Do not have models!!!");
	}
	
	return Plugin_Handled;
}

bool LoadConfigGifts(bool precache)
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
		
		hFile.GetString("model", sTemp, MAX_STRING_WIDTH);
			
		if(strlen(sTemp) == 0)
			continue;
		
		if(FileExists(sTemp, true))
		{
			strcopy(g_sModel[i], MAX_STRING_WIDTH, sTemp);
			hFile.GetString("type", g_sTypeModel[i], sizeof(g_sTypeModel[]), "static");
			hFile.GetString("gift", g_sTypeGift[i], sizeof(g_sTypeGift[]));
			g_fScale[i] = hFile.GetFloat("scale", 1.0);
			g_bGiftEntityEnable[i] = view_as<bool>(hFile.GetNum("entity_enable", 1));
			hFile.GetString("entity_color", g_sGiftEntityCols[i], sizeof(g_sGiftEntityCols[]));
			g_bGiftGlowEnable[i] = view_as<bool>(hFile.GetNum("glow_enable", 1));
			hFile.GetString("glow_color", g_sGiftGlowCols[i], sizeof(g_sGiftGlowCols[]));
			g_iGiftGlowRange[i] = hFile.GetNum("glow_range", 0);
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

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bFinalHasStart = false;
	g_bIsOpenSafeRoom = false;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bFinalHasStart = false;
	g_bIsOpenSafeRoom = false;
	gifts_collected_round = 0;
}

void Finale_Vehicle_Ready(Event event, const char[] name, bool dontBroadcast) 
{
	g_bFinalHasStart = true;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bGiftEnable)
		return;

	if(g_bIsOpenSafeRoom|| g_bFinalHasStart)
		return;

	if (g_iGiftMaxRound != 0 && gifts_collected_round > g_iGiftMaxRound)
		return;
	
	if (g_iGiftMaxMap != 0 && gifts_collected_map > g_iGiftMaxMap)
		return;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (attacker != victim && IsValidClient(victim) && GetClientTeam(victim) == 3)
	{
		if(GetZombieClass(victim) == 8)
		{
			if (GetRandomInt(1, 100) <= g_iSpecialGiftChance)
			{
				DropGift(victim, STRING_SPECIAL);
			}
		}
		else
		{
			if (GetRandomInt(1, 100) <= g_iGiftChance)
			{
				DropGift(victim);
			}
		}
		
		
	}
}

void OnWitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bGiftEnable)
		return;

	if(g_bIsOpenSafeRoom|| g_bFinalHasStart)
		return;	

	//int attacker = GetClientOfUserId(event.GetInt("userid"));
	int witch = event.GetInt("witchid");
	if (GetRandomInt(1, 100) <= g_iSpecialGiftChance)
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
		int hp = 0;
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
		else if ( strncmp(weapons_name_standard[index][0], "hp_", 3, false) == 0)
		{
			char sNumber[2][6];
			ExplodeString(weapons_name_standard[index][0], "_", sNumber, sizeof(sNumber), sizeof(sNumber[]));

			hp = StringToInt(sNumber[1]);
			if(hp >= 0)
			{
				GiveClientHealth(client, hp);
			}
			else
			{
				HurtEntity(client, client, float(-hp));
			}
		}
		else
			GiveWeapon(client, weapons_name_standard[index][0]);

		AnnounceToChat(client, weapons_name_standard[index][1], hp);

		PlaySound(client,SOUND_STANDARD);
	}
	else if(type == TYPE_SPECIAL)
	{
		if(gift == -1 || !IsValidEntity(gift))
		{
			return;
		}

		int iSlot0 = GetPlayerWeaponSlot(client, 0);
		int index = GetURandomIntRange(0, sizeof(weapons_name_special)-1);
		int hp = 0;
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
		else if ( strncmp(weapons_name_special[index][0], "hp_", 3, false) == 0)
		{
			char sNumber[2][6];
			ExplodeString(weapons_name_special[index][0], "_", sNumber, sizeof(sNumber), sizeof(sNumber[]));

			hp = StringToInt(sNumber[1]);
			if(hp > 0)
			{
				GiveClientHealth(client, hp);
			}
			else
			{
				HurtEntity(client, client, float(-hp));
			}
		}
		else
			GiveWeapon(client, weapons_name_special[index][0]);

		AnnounceToChat(client, weapons_name_special[index][1], hp);

		PlaySound(client, SOUND_SPECIAL);
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
	
	if( CheckIfEntitySafe(gift) )
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

		if(g_bGiftEntityEnable[random])
		{
			int entitycolor[3];
			if(strcmp(g_sGiftEntityCols[random], "-1 -1 -1", false) == 0)
			{
				switch(GetRandomInt(1, 8))
				{
					case 1: {entitycolor[0] = ColorCyan[0]; entitycolor[1] = ColorCyan[1]; entitycolor[2] = ColorCyan[2];}
					case 2: {entitycolor[0] = ColorLightGreen[0]; entitycolor[1] = ColorLightGreen[1]; entitycolor[2] = ColorLightGreen[2];}
					case 3: {entitycolor[0] = ColorPurple[0]; entitycolor[1] = ColorPurple[1]; entitycolor[2] = ColorPurple[2];}
					case 4: {entitycolor[0] = ColorPink[0]; entitycolor[1] = ColorPink[1]; entitycolor[2] = ColorPink[2];}
					case 5: {entitycolor[0] = ColorRed[0]; entitycolor[1] = ColorRed[1]; entitycolor[2] = ColorRed[2];}
					case 6: {entitycolor[0] = ColorOrange[0]; entitycolor[1] = ColorOrange[1]; entitycolor[2] = ColorOrange[2];}
					case 7: {entitycolor[0] = ColorYellow[0]; entitycolor[1] = ColorYellow[1]; entitycolor[2] = ColorYellow[2];}
					case 8: {entitycolor[0] = 255; entitycolor[1] = 255; entitycolor[2] = 255;}
				}
			}
			else
			{
				GetColor(g_sGiftEntityCols[random], entitycolor);
			}

			SetEntityRenderColor(gift, entitycolor[0], entitycolor[1], entitycolor[2]);
		}
		if(g_bGiftGlowEnable[random])
		{
			int glowcolor[3];
			if(strcmp(g_sGiftGlowCols[random], "-1 -1 -1", false) == 0)
			{
				switch(GetRandomInt(1, 13))
				{
					case 1: {glowcolor[0] = ColorRed[0]; glowcolor[1] = ColorRed[1]; glowcolor[2] = ColorRed[2];}
					case 2: {glowcolor[0] = ColorGreen[0]; glowcolor[1] = ColorGreen[1]; glowcolor[2] = ColorGreen[2];}
					case 3: {glowcolor[0] = ColorBlue[0]; glowcolor[1] = ColorBlue[1]; glowcolor[2] = ColorBlue[2];}
					case 4: {glowcolor[0] = ColorPurple[0]; glowcolor[1] = ColorPurple[1]; glowcolor[2] = ColorPurple[2];}
					case 5: {glowcolor[0] = ColorCyan[0]; glowcolor[1] = ColorCyan[1]; glowcolor[2] = ColorCyan[2];}
					case 6: {glowcolor[0] = ColorOrange[0]; glowcolor[1] = ColorOrange[1]; glowcolor[2] = ColorOrange[2];}
					case 7: {glowcolor[0] = ColorWhite[0]; glowcolor[1] = ColorWhite[1]; glowcolor[2] = ColorWhite[2];}
					case 8: {glowcolor[0] = ColorPink[0]; glowcolor[1] = ColorPink[1]; glowcolor[2] = ColorPink[2];}
					case 9: {glowcolor[0] = ColorLime[0]; glowcolor[1] = ColorLime[1]; glowcolor[2] = ColorLime[2];}
					case 10: {glowcolor[0] = ColorMaroon[0]; glowcolor[1] = ColorMaroon[1]; glowcolor[2] = ColorMaroon[2];}
					case 11: {glowcolor[0] = ColorTeal[0]; glowcolor[1] = ColorTeal[1]; glowcolor[2] = ColorTeal[2];}
					case 12: {glowcolor[0] = ColorYellow[0]; glowcolor[1] = ColorYellow[1]; glowcolor[2] = ColorYellow[2];}
					case 13: {glowcolor[0] = 255; glowcolor[1] = 255; glowcolor[2] = 255;}
				}
			}
			else
			{
				GetColor(g_sGiftGlowCols[random], glowcolor);
			}

			int glowrange = 0;
			if(strcmp(type, STRING_STANDARD, false) == 0) glowrange = g_iGiftGlowRange[random];
			else glowrange = g_iSpecialGiftGlowRange[random];

			L4D2_SetEntityGlow(gift, L4D2Glow_Constant, glowrange, 0, glowcolor, true);
		}

		CreateTimer(g_fGiftLife, Timer_GiftLife, EntIndexToEntRef(gift), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, ColdDown, EntIndexToEntRef(gift),TIMER_FLAG_NO_MAPCHANGE);
	}

	return gift;
}

Action ColdDown( Handle timer, any ref)
{
	int gift;
	if (ref && (gift = EntRefToEntIndex(ref)) != INVALID_ENT_REFERENCE)
	{
		SDKHook(gift, SDKHook_TouchPost, OnTouchPost);
	}

	return Plugin_Continue;
}

void OnTouchPost(int gift, int other)
{
	if (IsValidClient(other))
	{
		int iTeam = GetClientTeam(other);

		if(iTeam == 1) return;

		if(iTeam == 2 && IsPlayerAlive(other) &&
			!IsIncapacitated(other) &&
			!IsHandingFromLedge(other) &&
			L4D_GetPinnedInfected(other) == 0 )
		{

			g_bHooked[other] = true;
			if (strcmp(g_sGifType[gift], STRING_STANDARD) == 0)
			{
				NotifyGift(other, TYPE_STANDARD, gift);
			}
			else if (strcmp(g_sGifType[gift], STRING_SPECIAL) == 0)
			{
				NotifyGift(other, TYPE_SPECIAL, gift);
			}
			g_bHooked[other] = false;
			gifts_collected_map += 1;
			gifts_collected_round += 1;

			SDKUnhook(gift, SDKHook_TouchPost, OnTouchPost);
			AcceptEntityInput(gift, "kill");
		}
		else if(iTeam == 3 && IsPlayerAlive(other) && !IsPlayerGhost(other))
		{
			if(GetEntProp(other, Prop_Send, "m_zombieClass") == ZC_TANK && IsTankDying(other)) return;

			int AddHP = 0;
			if (strcmp(g_sGifType[gift], STRING_STANDARD) == 0) AddHP = g_iGiftHP;
			else AddHP = g_iSpecialGiftHP;

			if(AddHP == 0) return;

			SetEntityHealth(other, GetClientHealth(other) + AddHP);

			switch(g_iCvarAnnounce)
			{
				case 0: { }
				case 1:
				{
					PrintToChatAll("%t", "Infected Got Gift", other, AddHP);
				}
				case 2:
				{
					PrintHintTextToAll("%t", "Infected Got Gift", other, AddHP);
				}
				case 3:
				{
					PrintCenterTextAll("%t", "Infected Got Gift", other, AddHP);
				}
			}

			PlaySound(other, SOUND_STANDARD);
			SDKUnhook(gift, SDKHook_TouchPost, OnTouchPost);
			AcceptEntityInput(gift, "kill");
		}
	}
} 

Action WeaponCanUse(int client, int weapon)
{
	if(!g_bGiftEnable || !g_bCvarBlockSwitch) return Plugin_Continue;

	if(IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		if(g_bHooked[client])
		{
			int wepid = IdentifyWeapon(weapon);
			if(wepid == WEPID_NONE) return Plugin_Continue;
			
			if(wepid == WEPID_GASCAN ||
				wepid == WEPID_PROPANE_TANK ||
				wepid == WEPID_OXYGEN_TANK ||
				wepid == WEPID_FIREWORKS_BOX ||
				wepid == WEPID_COLA_BOTTLES ||
				wepid == WEPID_GNOME_CHOMPSKI) 
			{
				Event hEvent = CreateEvent("weapon_drop");
				if( hEvent != null )
				{
					hEvent.SetInt("userid", GetClientUserId(client));
					hEvent.SetInt("propid", weapon);
					hEvent.Fire();
				}
				return Plugin_Handled;
			}

			int slot = GetSlotFromWeaponId(wepid);
			if(slot == L4D2WeaponSlot_None) return Plugin_Continue;

			if(GetPlayerWeaponSlot(client, slot) == -1) return Plugin_Continue;

			Event hEvent = CreateEvent("weapon_drop");
			if( hEvent != null )
			{
				hEvent.SetInt("userid", GetClientUserId(client));
				hEvent.SetInt("propid", weapon);
				hEvent.Fire();
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
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

Action Timer_GiftLife( Handle timer, any ref)
{
	if ( ref && EntRefToEntIndex(ref) != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ref, "kill");
	}

	return Plugin_Continue;
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

void GiveClientHealth(int client, int iHealthAdd)
{
	int iHealth = GetClientHealth( client );
	float fHealth = GetTempHealth( client );

	if(iHealthAdd>=99) 
	{
		int flagsgive = GetCommandFlags("give");
		SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give health");
		SetCommandFlags("give", flagsgive);
	}

	if( GetEntProp( client, Prop_Send, "m_currentReviveCount" ) >= 1 )
	{
		SetTempHealth( client, fHealth + iHealthAdd);
	}
	else
	{
		SetEntityHealth( client, iHealth + iHealthAdd );
		SetTempHealth( client, fHealth );
	}
}

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth );
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

bool IsHandingFromLedge(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

float GetTempHealth(int client)
{
	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * pain_pills_decay_rate_float;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

bool CheckIfEntitySafe(int entity)
{
	if(entity == -1) return false;

	if(	entity > ENTITY_SAFE_LIMIT)
	{
		AcceptEntityInput(entity, "Kill");
		return false;
	}
	return true;
}

void SetRandomColor()
{
	GetColor("255 0 0", ColorRed);
	GetColor("0 255 0", ColorGreen);
	GetColor("0 0 255", ColorBlue);
	GetColor("128 0 128", ColorPurple);
	GetColor("0 255 255", ColorCyan);
	GetColor("254 100 46", ColorOrange);
	GetColor("255 255 255", ColorWhite);
	GetColor("255 88 130", ColorPink);
	GetColor("128 255 0", ColorLime);
	GetColor("128 0 0", ColorMaroon);
	GetColor("0 128 128", ColorTeal);
	GetColor("255 255 0", ColorYellow);
	GetColor("144 238 144", ColorLightGreen);
}

void HurtEntity(int victim, int attacker, float damage)
{
	SDKHooks_TakeDamage(victim, attacker, attacker, damage, DMG_SLASH);
}

void AnnounceToChat(int client, char[] buffer, int hp)
{
	if(strncmp(buffer, "Health", 6, false) == 0)
	{
		if(hp >= 0)
		{
			switch(g_iCvarAnnounce)
			{
				case 0: { }
				case 1:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if(!IsClientInGame(i)) continue;
						if(IsFakeClient(i)) continue;
						if(GetClientTeam(i) == TEAM_SURVIVOR || GetClientTeam(i) == TEAM_SPECTATOR)
						{
							PrintToChat(i, "%T", "Got Gift (+hp)", i, client, hp);
						}
					}
				}
				case 2:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if(!IsClientInGame(i)) continue;
						if(IsFakeClient(i)) continue;
						if(GetClientTeam(i) == TEAM_SURVIVOR || GetClientTeam(i) == TEAM_SPECTATOR)
						{
							PrintHintText(i, "%T", "Got Gift (+hp)", i, client, hp);
						}
					}
				}
				case 3:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if(!IsClientInGame(i)) continue;
						if(IsFakeClient(i)) continue;
						if(GetClientTeam(i) == TEAM_SURVIVOR || GetClientTeam(i) == TEAM_SPECTATOR)
						{
							PrintCenterText(i, "%T", "Got Gift (+hp)", i, client, hp);
						}
					}
				}
			}
		}
		else
		{
			switch(g_iCvarAnnounce)
			{
				case 0: { }
				case 1:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if(!IsClientInGame(i)) continue;
						if(IsFakeClient(i)) continue;
						if(GetClientTeam(i) == TEAM_SURVIVOR || GetClientTeam(i) == TEAM_SPECTATOR)
						{
							PrintToChat(i, "%T", "Got Gift (-hp)", i, client, hp);
						}
					}
				}
				case 2:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if(!IsClientInGame(i)) continue;
						if(IsFakeClient(i)) continue;
						if(GetClientTeam(i) == TEAM_SURVIVOR || GetClientTeam(i) == TEAM_SPECTATOR)
						{
							PrintHintText(i, "%T", "Got Gift (-hp)", i, client, hp);
						}
					}
				}
				case 3:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if(!IsClientInGame(i)) continue;
						if(IsFakeClient(i)) continue;
						if(GetClientTeam(i) == TEAM_SURVIVOR || GetClientTeam(i) == TEAM_SPECTATOR)
						{
							PrintCenterText(i, "%T", "Got Gift (-hp)", i, client, hp);
						}
					}
				}
			}
		}
	}
	else
	{
		switch(g_iCvarAnnounce)
		{
			case 0: { }
			case 1:
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if(!IsClientInGame(i)) continue;
					if(IsFakeClient(i)) continue;
					if(GetClientTeam(i) == TEAM_SURVIVOR || GetClientTeam(i) == TEAM_SPECTATOR)
					{
						PrintToChat(i, "%T", "Got Gift", i, client, buffer);
					}
				}
			}
			case 2:
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if(!IsClientInGame(i)) continue;
					if(IsFakeClient(i)) continue;
					if(GetClientTeam(i) == TEAM_SURVIVOR || GetClientTeam(i) == TEAM_SPECTATOR)
					{
						PrintHintText(i, "%T", "Got Gift", i, client, buffer);
					}
				}
			}
			case 3:
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if(!IsClientInGame(i)) continue;
					if(IsFakeClient(i)) continue;
					if(GetClientTeam(i) == TEAM_SURVIVOR || GetClientTeam(i) == TEAM_SPECTATOR)
					{
						PrintCenterText(i, "%T", "Got Gift", i, client, buffer);
					}
				}
			}
		}
	}
}

// Other API Forward-------------------------------

// from lockdown_system-l4d2_b.smx
// when door is fully opened
public void L4D2_OnLockDownOpenDoorFinish(const char[] sKeyMan)
{
	g_bIsOpenSafeRoom = true;
}
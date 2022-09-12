#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>  
#include <sdktools>

public Plugin myinfo = 
{
	name = "Annouce Laser & Ammo",
	author = "Hoangzp, Harry",
	description = "Display instruction hint when someone uses ammo or laser sight",
	version = "1.1",
	url = "https://steamcommunity.com/profiles/76561198026784913/"
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
	HookEvent("player_use", Event_PlayerUse);
}
public void Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int item = event.GetInt("targetid");

    if (client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        if(item > MaxClients && IsValidEntity(item))
        {
            static char classname[32];
            GetEntityClassname(item, classname, 32);
            if (classname[0] == 'u' && strcmp(classname, "upgrade_laser_sight", false) == 0)
            {
                IntrucHint(item, "icon_laser_sight", "Upgrade laser sight", "1500", "10", "255 0 0");
            }
            else if (classname[0] == 'w' && strcmp(classname, "weapon_ammo_spawn", false) == 0)
            {
                IntrucHint(item, "icon_ammo", "Ammo", "1500", "10", "255 255 0");
            }
        }
    }
}

public void IntrucHint(int item, char Icon[64], char Word[128], char Range[12], char Time[12], char Color[12])
{
    int entity = CreateEntityByName("env_instructor_hint", -1);
    if(entity == -1) return;

    char sValues[32];
    FormatEx(sValues, sizeof(sValues), "%i", item);
    DispatchKeyValue(item, "targetname", sValues);
    DispatchKeyValue(entity, "hint_target", sValues);
    FormatEx(sValues, sizeof(sValues), Time);
    DispatchKeyValue(entity, "hint_timeout", sValues);
    DispatchKeyValue(entity, "hint_range", Range);
    DispatchKeyValue(entity, "hint_forcecaption", "1");
    DispatchKeyValue(entity, "hint_icon_onscreen", Icon);
    DispatchKeyValue(entity, "hint_caption", Word);
    DispatchKeyValue(entity, "hint_color", Color);
    DispatchSpawn(entity);
    AcceptEntityInput(entity, "ShowHint", -1, -1, 0);
    FormatEx(sValues, sizeof(sValues), "OnUser1 !self:Kill::%d:1", Time);
    SetVariantString(sValues);
    AcceptEntityInput(entity, "AddOutput", -1, -1, 0);
    AcceptEntityInput(entity, "FireUser1", -1, -1, 0);
    DispatchKeyValue(item, "targetname", "");
}

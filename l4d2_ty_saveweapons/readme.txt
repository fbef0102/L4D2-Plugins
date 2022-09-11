L4D2 coop save weapon when map transition if more than 4 players

-AlliedModder-
Save Weapon (Co-op) Improved Version: https://forums.alliedmods.net/showpost.php?p=2757629&postcount=113


-Changelog-
v5.9
-Remake code
-Add the last stand two melee
-Add ConVar and generate cfg
-Save health
-Save Character Model
-Support Bots
-Support custom melee save
-Doesn't save if change map in game (ex. vote change new campaign)
-Compatible with the [ANY] Cheats: https://forums.alliedmods.net/showthread.php?t=195037

v4.1
-Original Post: https://forums.alliedmods.net/showthread.php?t=263860

-Require-
left4dhooks: https://forums.alliedmods.net/showthread.php?p=2684862

-Relate Valve ConVar-
* If true, survivor bots will be used as placeholders for survivors who are still changing levels
* prevent bots from moving, changing weapons, using kits for survivors who are still changing levels
* need to write down in cfg/server.cfg
sm_cvar sb_transition 0 

-ConVar-
cfg/sourcemod/l4d2_ty_saveweapons.cfg
// Do not restore weapons and health to a player after survivors have left start safe area for at least x seconds. (0=Always restore)
l4d2_ty_saveweapons_game_seconds_block "60"

// If 1, restore 100 full health when end of chapter.
l4d2_ty_saveweapons_health "0"

// If 1, save weapons and health for bots as well.
l4d2_ty_saveweapons_save_bot "1"

// If 1, save character model and restore.
l4d2_ty_saveweapons_save_character "0"

// If 1, save health and restore. (can save >100 hp)
l4d2_ty_saveweapons_save_health "1"

-Command-
None

-Natives & Forwards API-
/**
 * @brief Called when restore and give weapons, health to a player
 *
 * @param client    the client who is given to.
 *
 * @noreturn
 */
forward void L4D2_OnSaveWeaponHxGiveC(int client);

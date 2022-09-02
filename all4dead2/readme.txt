Enables admins to have control over the AI Director and spawn all weapons, melee, items, special infected, and Uncommon Infected without using sv_cheats 1

-ChangeLog-
v3.4
-Add gamedata to support infected spawn (without being limit by director)
-Display menu forever
-fixed Invalid edict

v3.1
-Add Gnome and Cola.

v3.0
-Remake code
-Add All weapons、melee、items
-Add firework crate
-Add L4D2 "The Last Stand" two melee: pitchfork、shovel
-Spawn Witch Bride Model in c6m1 to prevent crash

v2.0.0
-Original Post: https://forums.alliedmods.net/showthread.php?p=751952

-Require-
1. To unlock all melee weapons in all campaigns, you MUST use the [Mission and Weapons - Info Editor]("https://forums.alliedmods.net/showthread.php?t=310586") plugin which supersedes the extension.
2. left4dhooks: https://forums.alliedmods.net/showthread.php?p=2684862

-How to use-
type !admin to call adm menu and you will see "ALL4DEAD" option

-Convars-
cfg\sourcemod\all4dead2.cfg
// Whether or not bosses will be forced to spawn all the time.
a4d_always_force_bosses "0"

// Whether or not we announce changes in game.
a4d_notify_players "1"

// The amount of time in seconds between location refreshes. Used only for placing uncommon infected automatically.
a4d_refresh_zombie_location "20.0"

// The amount of zombies to add when an admin requests more zombies.
a4d_zombies_to_add "10"



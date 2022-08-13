CSO Random Supply Boxes in l4d2
-Supply boxes are dropped randomly in the map every certain seconds to provide support for the fight against the zombies.
They contain several types of weapons or items inside, depending on the cvar you set.
video showcase: https://youtu.be/hpGlmwdWH6o

-ChangeLog-
v1.2
AlliedModders Post: https://forums.alliedmods.net/showthread.php?t=335862
-Add convars to turn off this plugin
-Random box model available
-Item chance to drop Weapons/Melee/Medic/Throwable/Others
-Custom sound
-Detect custom melee and spawn
-Translation Support
-Supply box life time
-Remove item if no one picks up after it drops from box after a while

v0.0
-Original author by Lux (https://forums.alliedmods.net/member.php?u=257841)

-Require-
left4dhooks: https://forums.alliedmods.net/showthread.php?p=2684862

-ConVar-
cfg\sourcemod\l4d2_supply_woodbox.cfg
// 0=Plugin off, 1=Plugin on.
l4d2_supply_woodbox_allow "1"

// Changes how Supply box hint displays. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)
l4d2_supply_woodbox_announce_type "3"

// Set the life time for Supply box.
l4d2_supply_woodbox_box_life "180"

// The default Supply box color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue. (empty=disable)
l4d2_supply_woodbox_color "0 145 200"

// If 1, still dorp supply box in final stage rescue
l4d2_supply_woodbox_drop_final "0"

// Max Supply boxes that could drop once.
l4d2_supply_woodbox_drop_max "2"

// Min Supply boxes that could drop once.
l4d2_supply_woodbox_drop_min "1"

// The default Supply box glow range.
l4d2_supply_woodbox_glow_range "1800"

// Item chance to drop Weapons/Melee/Medic/Throwable/Others, separate by commas (no spaces), the sum of 5 value must be 100
l4d2_supply_woodbox_item_chance "30,5,45,15,5"

// Time in seconds to remove item if no one picks up after it drops from box (0=off)
l4d2_supply_woodbox_item_life "60"

// Max Items that could drop in woodbox.
l4d2_supply_woodbox_item_max "4"

// Min Items that could drop in woodbox.
l4d2_supply_woodbox_item_min "2"

// Set the limit for Supply box spawned by the plugin.
l4d2_supply_woodbox_limit "6"

// Turn off the plugin in these maps, separate by commas (no spaces). (0=All maps, Empty = none).
l4d2_supply_woodbox_map_off ""

// Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).
l4d2_supply_woodbox_modes ""

// Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).
l4d2_supply_woodbox_modes_off ""

// Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.
l4d2_supply_woodbox_modes_tog "5"

// Supply Box - Drop sound file (relative to to sound/, empty=random helicopter sound, -1: disable)
l4d2_supply_woodbox_soundfile ""

// Set the max spawn time for Supply box drop.
l4d2_supply_woodbox_time_max "80"

// Set the min spawn time for Supply box drop.
l4d2_supply_woodbox_time_min "60"

// Supply box model type, 1: wood_crate001a, 2: wood_crate001a_damagedMAX, 3: wood_crate002a (0=random)
l4d2_supply_woodbox_type "1"

-Command-
** Spawn a supply box at your crosshair (Admin Flag: ADMFLAG_ROOT)
	sm_supplybox
	sm_box


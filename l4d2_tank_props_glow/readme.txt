When a Tank punches a Hittable it adds a Glow to the hittable which all infected players can see.
+
Stop tank props from fading whilst the tank is alive

-Video-
https://www.youtube.com/watch?v=UZDF6dbagxU&feature=youtu.be

-ChangLog-
v2.4
-AlliedModder Post: https://forums.alliedmods.net/showthread.php?t=312447
-Credit: Sir, A1m`, Derpduck => https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d2_tank_props_glow.sp

-ConVar-
left4dead2\cfg\sourcemod\l4d2_tank_props_glow.cfg
// Time it takes for hittables that were punched by Tank to dissapear after the Tank dies.
l4d2_tank_prop_dissapear_time "10.0"

// Prop Glow Color, three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.
l4d2_tank_prop_glow_color "255 255 255"

// Only Tank can see the glow
l4d2_tank_prop_glow_only "0"

// How near to props do players need to be to enable their glow.
l4d2_tank_prop_glow_range "4500"

// How near to props do players need to be to disable their glow.
l4d2_tank_prop_glow_range_min "256"

// Spectators can see the glow too
l4d2_tank_prop_glow_spectators "1"

// Show Hittable Glow for infected team while the tank is alive
l4d_tank_props_glow "1"







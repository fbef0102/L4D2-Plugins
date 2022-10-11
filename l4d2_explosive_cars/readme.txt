Cars explode after they take some damage

-Require-
1. Left 4 DHooks Direct: https://forums.alliedmods.net/showthread.php?t=321696

-Changelog-
v2.0
-Remake code
-Replace left4downtown with left4dhooks
-Remove car entity after it explodes
-Fixed damage dealt to car
-Safely create entity and safely remove entity
-Safely explode cars between few secomds to prevent client from crash

v1.0.4
Original Post by honorcode23: https://forums.alliedmods.net/showthread.php?p=1304463

-ConVar-
cfg/sourcemod/l4d2_explosive_cars.cfg
// Time to wait before removing the exploded car in case it blockes the way. (0: Don't remove)
l4d2_explosive_cars_removetime "60"

// Damage made by the explosion
l4d2_explosive_cars_damage "10"

// Should cars get damaged by another car's explosion?
l4d2_explosive_cars_explosion_damage "1"

// Maximum health of the cars
l4d2_explosive_cars_health "5000"

// Should infected trigger the car explosion? (1: Yes 0: No)
l4d2_explosive_cars_infected "1"

// Should the car explosion cause a panic event? (1: Yes 0: No)
l4d2_explosive_cars_panic "1"

// Chance that the cars explosion might call a horde (1 / CVAR) [1: Always]
l4d2_explosive_cars_panic_chance "5"

// Power of the explosion when the car explodes
l4d2_explosive_cars_power "300"

// Maximum radius of the explosion
l4d2_explosive_cars_radius "420"

// How much damage do the tank deal to the cars? (0: Default, which is 999 from the engine)
l4d2_explosive_cars_tank "0"

// Time before the fire trace left by the explosion expires
l4d2_explosive_cars_trace "25"

// How often should the fire trace left by the explosion hurt?
l4d2_explosive_cars_trace_interval "0.4"

// On which maps should the plugin disable itself? separate by commas (no spaces). (Example: c5m3_cemetery,c5m5_bridge,cmdd_custom)
l4d2_explosive_cars_unload "c5m5_bridge"

-Command-
None

When using 'Look' in vocalize menu, print corresponding item to chat area and make item glow or create spot marker/infeced maker like back 4 blood.

-ChangeLog-
//fdxx, BHaType	@ 2021
//Harry @ 2022
v2.3
AlliedModders Post: https://forums.alliedmods.net/showpost.php?p=2765332&postcount=30
-Add all gun weapons, melee weapons, minigun, ammo and items.
-Add cooldown.
-Add Item Glow, everyone can see the item through wall.
-Add sound.
-Fixes custom vocalizers that uses SmartLook with capitals.
-Add Spot Marker, using 'Look' in vocalize menu to mark the area.
-Add Infected Marker, using 'Look' in vocalize menu to mark the infected.
-Add Instructor hint, display instructor hint on Spot Marker/Item Hint
(player must Enabled GAME INSTRUCTOR, in ESC -> Options -> Multiplayer, or they can't see)
(DO NOT modify convar "sv_gameinstructor_disable this force all clients to disable their game instructors.
-marker priority: Infected maker > Item hint > Spot marker

v0.2
-Original Post: https://forums.alliedmods.net/showthread.php?t=333669

-Known Issue-
1. Hats and others attaching stuff to players could block the players "use" function, which makes you unable to use 'look' item hint. 
(Install Use Priority Patch plugin to fix: https://forums.alliedmods.net/showthread.php?t=327511)

-Convars-
cfg\sourcemod\l4d2_item_hint.cfg
// ---Item Hint---
// Cold Down Time in seconds a player can use 'Look' Item Hint again.
l4d2_item_hint_cooldown_time "1.0"

// How close can a player use 'Look' item hint.
l4d2_item_hint_use_range "150"

// Item Hint Sound. (relative to to sound/, Empty = OFF)
l4d2_item_hint_use_sound "buttons/blip1.wav"

// Changes how Item Hint displays. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)
l4d2_item_hint_announce_type "1"

// Item Glow Time.
l4d2_item_hint_glow_timer "10.0"

// Item Glow Range.
l4d2_item_hint_glow_range "800"

// Item Glow Color, Three values between 0-255 separated by spaces. (Empty = Disable Item Glow)
l4d2_item_hint_glow_color "0 255 255"

// If 1, Create instructor hint on marked item.
l4d2_item_instructorhint_enable "1"

// Instructor hint color on marked item.
l4d2_item_instructorhint_color "0 255 255"

//Instructor icon name on marked item. (For more icons: https://developer.valvesoftware.com/wiki/Env_instructor_hint)
l4d2_item_instructorhint_icon "icon_interact"
	
// ---Spot Marker---
// Cold Down Time in seconds a player can use 'Look' Spot Marker again.
l4d2_spot_marker_cooldown_time "2.5"

// How far away can a player use 'Look' Spot Marker.
l4d2_spot_marker_use_range "1800"

// Spot Marker Sound. (relative to to sound/, Empty = OFF)
l4d2_spot_marker_use_sound "buttons/blip1.wav"

// Spot Marker Duration.
l4d2_spot_marker_duration "10.0"

// Spot Marker Glow Color, Three values between 0-255 separated by spaces. (Empty = Disable Spot Marker)
l4d2_spot_marker_color "200 200 200"

// Spot Marker Sprite model. (Empty=Disable)
l4d2_spot_marker_sprite_model "materials/vgui/icon_arrow_down.vmt"

// If 1, Create instructor hint on Spot Marker.
l4d2_spot_marker_instructorhint_enable "1"

// Instructor hint color on Spot Marker.
l4d2_spot_marker_instructorhint_color "200 200 200"

// Instructor icon name on Spot Marker.
l4d2_spot_marker_instructorhint_icon "icon_info"
	
// ---Infected Marker---
// Cold Down Time in seconds a player can use 'Look' Infected Marker again.
l4d2_infected_marker_cooldown_time "0.25"

// How far away can a player use 'Look' Infected Marker.
l4d2_infected_marker_use_range "1800"

// Infected Marker Sound. (relative to to sound/, Empty = OFF)
l4d2_infected_marker_use_sound "items/suitchargeok1.wav"

// Changes how infected marker hint displays. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)
l4d2_infected_marker_announce_type "1"

// Infected Marker Glow Time.
l4d2_infected_marker_glow_timer "10.0"

// Infected Marker Glow Rang
l4d2_infected_marker_glow_range "2500"

// Infected Marker Glow Color, Three values between 0-255 separated by spaces. (Empty = Disable Infected Marker)
l4d2_infected_marker_glow_color "255 120 203"

// If 1, Enable 'Look' Infected Marker on witch.
l4d2_infected_marker_witch_enable "1"
	

-Commands-
None

A spectator who watching the survivor at first person view can now see the infected model glows though the wall
(真-抓鬼神器: 誰是透視外掛)

看這影片展示 Video: https://www.bilibili.com/video/BV1Xq4y1a7ie

-ChangeLog-
v2.3
- Remake code
- Alive SI glow color
- Ghost SI glow color
- Admin Flag to toggle Speatator watching cheat
- Enable Speatator watching cheat for spectators default valve

v1.0
- Original Request paid work by Target_7

-Convar-
cfg\sourcemod\l4d2_specting_cheat.cfg
// Alive SI glow color, Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.
l4d2_specting_cheat_alive_color "255 0 0"

// Enable Speatator watching cheat for spectators default? [1-Enable/0-Disable]
l4d2_specting_cheat_default_value "0"

// Ghost SI glow color, Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.
l4d2_specting_cheat_ghost_color "255 255 255"

// Players with these flags have access to use command to toggle Speatator watching cheat. (Empty = Everyone, -1: Nobody)
l4d2_specting_cheat_use_command_flag "z"

-Command-
//Toggle Speatator watching cheat (spectator only)
!speccheat
!watchcheat
!lookcheat
!seecheat
!meetcheat
!starecheat
!hellocheat
!areyoucheat
!fuckyoucheat
!zzz
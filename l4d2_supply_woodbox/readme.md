# Description | 內容
Supply boxes are dropped randomly in the map every certain seconds to provide support for the fight against the zombies.

* [Video | 影片展示](https://youtu.be/9rXlJ8PsOTA)

* Image | 圖示
	* Idea comes from [Counter Strike Online Human Supply boxes](https://cso.fandom.com/wiki/Zombie_2:_Mutation#Supply_boxes)
        > 靈感來自CSO 殭屍模式
	    <br/>![l4d2_supply_woodbox_1](image/l4d2_supply_woodbox_1.jpg)
	* They contain several types of weapons or items inside, depending on the cvar you set.
        > 補給箱內有各式各樣的物資與武器
	    <br/>![l4d2_supply_woodbox_2](image/l4d2_supply_woodbox_2.jpg)

* Apply to | 適用於
```
L4D2
```

* <details><summary>Changelog | 版本日誌</summary>

	* v1.3 (2022-9-12)
        * Remove gascan,  propanecanister, oxygentank if no one picks up

	* v1.2 (2022-8-13)
        * Optimize code.

	* v1.1 (2022-3-29)
        * Support Survival Mode.

	* v1.0 (2022-1-11)
        * [Initial release](https://forums.alliedmods.net/showthread.php?t=335862)
        * Add convars to turn off this plugin
        * Random box model available
        * Item chance to drop Weapons/Melee/Medic/Throwable/Others
        * Custom sound
        * Detect custom melee and spawn
        * Translation Support
        * Supply box life time
        * Remove item if no one picks up after it drops from box after a while
        * Compatibility support for SourceMod 1.11. Fixed various warnings.

	* v0.0
        * Credit: [Lux](https://forums.alliedmods.net/member.php?u=257841) - original code
</details>

* Require | 必要安裝
	1. [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)

* Related Plugin | 相關插件
	1. [l4d_cso_zombie_Regeneration](https://github.com/fbef0102/L4D1_2-Plugins/tree/master/l4d_cso_zombie_Regeneration): The zombies have grown stronger, now they are able to heal their injuries by standing still without receiving any damage.
	    > 殭屍變得更強大，他們只要站著不動便可以自癒傷勢　(仿CSO惡靈降世 殭屍技能)

	2. [weapon_csgo_reload](https://github.com/fbef0102/L4D2-Plugins/tree/master/l4d2_weapon_csgo_reload): Weapon Quickswitch Reloading in L4D1+2
	    > 將武器改成現代遊戲的裝子彈機制 (仿CS:GO切槍裝彈設定)

* <details><summary>ConVar | 指令</summary>

	* cfg\sourcemod\l4d2_supply_woodbox.cfg
		```php
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
		l4d2_supply_woodbox_modes_tog "0"

		// Supply Box - Drop sound file (relative to to sound/, empty=random helicopter sound, -1: disable)
		l4d2_supply_woodbox_soundfile ""

		// Set the max spawn time for Supply box drop.
		l4d2_supply_woodbox_time_max "80"

		// Set the min spawn time for Supply box drop.
		l4d2_supply_woodbox_time_min "60"

		// Supply box model type, 1: wood_crate001a, 2: wood_crate001a_damagedMAX, 3: wood_crate002a (0=random)
		l4d2_supply_woodbox_type "1"
		```
</details>

* <details><summary>Command | 命令</summary>

	* **Spawn a supply box at your crosshair (Admin Flag: ADMFLAG_ROOT)**
		```php
		sm_supplybox
		sm_box
		```
</details>

- - - -
# 中文說明
地圖上隨機出現補給箱，提供人類強力支援 (仿CSO惡靈降世 補給箱)

* 原理
    * 靈感來自CSO 殭屍模式，在這款遊戲中每隔一段時間地圖上出現補給箱，提供人類火力強大的武器
    * 地圖上隨機出現補給箱，只有人類才能看到補給箱位置
    * 有時候空投的補給箱出現在人類無法到達的區域，譬如屋頂。問就是直升機飛行員迷路了
    * 用子彈或近戰武器打破這些補給箱箱子
    * 補給箱不會擋住特感與普通感染者，他們可以穿透

* 功能
    * 可調整補給箱發光顏色、發光範圍、
    * 可調整救援章節也能有空投補給箱
	* 可調整補給箱種類
	* 可設置空投補給箱的音效
	* 可設置每隔一段時間空投補給箱
	* 可設置補給箱內各種物資掉落的機率
	* 可設置每個補給箱裡面能掉落幾個物品
	* 可設置補給箱存在時間，沒人打破會自動消失
	* 可設置補給箱掉落物品的存在時間，沒人拿取會自動消失

# Description | 內容
Drop gifts when a special infected or a witch/tank killed by survivor.

* [Video | 影片展示](https://youtu.be/komzEmVvtH0)

* Image | 圖示
	<br/>![l4d2_gifts_1](image/l4d2_gifts_1.jpg)

* Require | 必要安裝
	1. [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)
	2. [[INC] l4d2_weapons](https://github.com/fbef0102/Game-Private_Plugin/blob/main/left4dead2/scripting/include/l4d2_weapons.inc)
	3. [[INC] Multi Colors](https://github.com/fbef0102/L4D1_2-Plugins/releases/tag/Multi-Colors)

* <details><summary>How does it work?</summary>

	* Drop "Standard Gift" when special infected dies
	* Drop "Special Gift" when a tank/witch dies
	* How to open gift
		* Touch the gifts
		* Press E
	* Gift
		* Weapons
		* Items
		* Health
</details>

* <details><summary>ConVar | 指令</summary>

    * cfg/sourcemod/l4d2_gifts.cfg
		```php
		// Enable gifts 0: Disable, 1: Enable
		l4d2_gifts_enabled "1"

		// How long the gift stay on ground (seconds)
		l4d2_gifts_gift_life "30"

		// Chance (%) of infected drop special standard gift.
		l4d2_gifts_chance_standard "50"

		// Chance (%) of tank and witch drop second special gift.
		l4d2_gifts_chance_special "100"

		// Increase Infected health if they pick up gift. (0=Off)
		l4d2_gifts_infected_reward_hp_standard "200"

		// Increase Infected health if they pick up special gift. (0=Off)
		l4d2_gifts_infected_reward_hp_special "400"

		// Notify Server who pickes up gift, and what the gift reward is. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)
		l4d2_gifts_announce_type "3"

		// If 1, prevent survivors from switching into new weapons and items when they open gifts
		l4d2_gifts_block_switch "0"

		// Standard gift - pick up sound file (relative to to sound/, empty=disable)
		l4d2_gifts_soundfile_standard "level/loud/climber.wav"

		// Special gift - pick up sound file (relative to to sound/, empty=disable)
		l4d2_gifts_soundfile_special "level/gnomeftw.wav"
		```
</details>

* <details><summary>Command | 命令</summary>

	* **Spawn a gift in your position (Adm required: ADMFLAG_CHEATS)**
		```php
		sm_gifts <standard>
		sm_gifts <special>
		```

	* **Reload the config file of gifts (data/l4d2_gifts.cfg)**
		```php
		sm_reloadgifts
		```
</details>

* <details><summary>Data Config</summary>

	* [data\l4d2_gifts.cfg](data\l4d2_gifts.cfg)
		```php
		"models" // modify the gift Model
		{
			"1"
			{
				"model"		"models/items/l4d_gift.mdl"  //model of gift: a small model such as animals, boxes, etc. is preferable.
				"type"		"physics" 					// type of model: physics or static (Not all models can be physical)
				"gift"		"special" 					// type of gift: standard or special
				"scale"		"1.0"	  					// scale of model (default 1.0) [optional] (Not all models accept scale)
				
				"entity_enable"		"1"					// Enable Gift Color [0: Disable Color]		
				"entity_color"		"-1 -1 -1"			// Set Gift Color [-1 -1 -1: Random]
				
				"glow_enable"		"1"					// Enable Glow [0: Disable Glow]
				"glow_color"		"-1 -1 -1"			// Set Glow Color [-1 -1 -1: Random]
				"glow_range"		"600"				// Set Glow Range [0: No distance]
			}
		}

		"standard_items"
		{
			// There are 65 random items drop from standard gifts
			"num"   "65"
			"1"
			{
				"name" "defibrillator"
			}
			"2"
			{
				// spawn random melee weapon from the melee string table (support custom melee )
				"name"  "weapon_melee"
			}
			"3"
			{
				// add player health +100hp
				"name"  "hp"
				"hp"	"100"
			}
			"4"
			{
				// player lose health -1hp
				"name"  "hp"
				"hp"	"-1"
			}
			"5"
			{
				// empty gift, survivor get nothing (Have a good day :D)
				"name" "empty"
			}

			...
		}

		"special_items"
		{
			// There are 13 random items drop from special gifts
			"num"   "13"
			"1"
			{
				"name" "first_aid_kit"
			}

			...
		}

		// resupply player with how much ammo when player picks up "ammo" from gifts
		"weapon_ammo"
		{
			"weapon_smg"				"400"
			...
		}
		```

	* Available gift name
		```php
		"grenade_launcher" => Grenade Launcher
		"rifle_m60" => M60 Machine Gun
		"defibrillator" => Defibrillator
		"first_aid_kit" => First Aid Kit
		"pain_pills" => Pain Pill
		"adrenaline" => Adrenaline
		"weapon_upgradepack_incendiary" => Incendiary Pack
		"weapon_upgradepack_explosive" => Explosive Pack
		"molotov" => Molotov
		"pipe_bomb" => Pipe Bomb
		"vomitjar" => Vomitjar
		"gascan" => Gascan
		"propanetank" => Propane Tank
		"oxygentank" => Oxygen Tank
		"fireworkcrate" => Firework Crate
		"pistol" => Pistol
		"pistol_magnum" => Magnum
		"pumpshotgun" => Pumpshotgun
		"shotgun_chrome" => Chrome Shotgun
		"smg" => Smg
		"smg_silenced" => Silenced Smg
		"smg_mp5" => MP5
		"rifle" => Rifle
		"rifle_sg552" => SG552
		"rifle_ak47" => AK47
		"rifle_desert" => Desert Rifle
		"shotgun_spas" => Spas Shotgun
		"autoshotgun" => Autoshotgun
		"hunting_rifle" => Hunting Rifle
		"sniper_military" => Military Sniper
		"sniper_scout" => SCOUT
		"sniper_awp" => AWP
		"chainsaw" => Chainsaw
		"weapon_melee" => random melee weapons (support custom melee)
		"gnome" => Gnome
		"cola_bottles" => Cola Bottles
		"laser_sight" => Laser Sight
		"incendiary_ammo" => Incendiary Ammo
		"explosive_ammo" => Explosive Ammo
		"ammo" => Ammo
		"hp" => Health
		"empty" => Empty
		```
</details>

* Apply to | 適用於
	```
	L4D2
	```

* <details><summary>Translation Support | 支援翻譯</summary>

	```
	English
	繁體中文
	简体中文
	```
</details>

* <details><summary>Changelog | 版本日誌</summary>

    * v3.5 (2024-5-5)
		* Now survivors can press E to open gifts

    * v3.4 (2024-2-20)
		* Use data file to modify the gift items
		* Update Cvars
		* Update Translation

    * v3.3 (2023-12-11)
		* Remove collect limit
		* Remove some cvars
		* Update translation and data file

    * v3.2 (2023-6-9)
		* Add a convar, prevent survivors from switching into new weapons and items when they open gifts
		* Create Fake weapon_drop event

    * v3.0 (2022-12-26)
		* Add health gift, survivor could increase or lose health

    * v2.9 (2022-12-2)
		* Add cvars to control glow color and range
		* Translation Support

    * v2.8
		* Remake Code
		* Remove rotation, and some static models
		* Add L4D2 "The Last Stand" two melee: pitchfork、shovel
		* Add All weapons、melee、items
		* Add laser、firework crate、ammo、incendiary ammo、explosive_ammo
		* Use left4dhooks instead
		* Remove points
		* Add glow flashing

	* v1.3.6.1
		* [Original Plugin by Aceleracion](https://forums.alliedmods.net/showthread.php?t=302731)
</details>

- - - -
# 中文說明
殺死特感會掉落禮物盒，會獲得驚喜物品，聖誕嘉年華

* 原理
    * 殺死特感掉落"普通禮盒"
    * 殺死Tank或Witch掉落"特殊禮盒"
	* 如何打開禮物盒
		* 人類碰觸到盒
		* 按E
	* 禮物盒會有各式各樣的武器與物品，也有可能為空或失去血量，驚喜一瞬間
	* 特感也能碰禮盒，會自動增加血量

* <details><summary>指令中文介紹 (點我展開)</summary>

    * cfg/sourcemod/l4d2_gifts.cfg
		```php
		// 0=關閉插件, 1=啟動插件
		l4d2_gifts_enabled "1"

		// 禮盒的存活時間，如果沒有人撿起會自動消失 (單位: 秒數)
		l4d2_gifts_gift_life "30"

		// 特感掉落普通禮盒的機率
		l4d2_gifts_chance_standard "50"

		// Tank/Witch掉落特殊禮盒的機率
		l4d2_gifts_chance_special "100"

		// 特感撿到普通禮盒所增加的血量. (0=關閉這項功能)
		l4d2_gifts_infected_reward_hp_standard "200"

		// 特感撿到特殊禮盒所增加的血量. (0=關閉這項功能)
		l4d2_gifts_infected_reward_hp_special "400"

		// 獲得禮物盒的提示該如何顯示. (0: 不提示, 1: 聊天框, 2: 黑底白字框, 3: 螢幕正中間)
		l4d2_gifts_announce_type "3"

		// 1=人類撿起禮盒時，物資直接掉在地上
		// 0=人類撿起禮盒時，物資直接拿在手上
		l4d2_gifts_block_switch "0"

		// 撿起普通禮盒的音效檔案，路徑相對於sound資料夾 (留白=無音效)
		l4d2_gifts_soundfile_standard "level/loud/climber.wav"

		// 撿起特殊禮盒的音效檔案，路徑相對於sound資料夾 (留白=無音效)
		l4d2_gifts_soundfile_special "level/gnomeftw.wav"
		```
</details>

* <details><summary>命令中文介紹 (點我展開)</summary>
    
	* **在準心指向的地方生成禮盒 (權限: ADMFLAG_CHEATS)**
		```php
		sm_gifts <standard> //生成普通禮盒
		sm_gifts <special> //生成特殊禮盒
		```

	* **重載禮盒的模組設定文件 (data/l4d2_gifts.cfg)**
		```php
		sm_reloadgifts
		```
</details>

* <details><summary>文件設定範例</summary>

	* [data\l4d2_gifts.cfg](data\l4d2_gifts.cfg)
		```php
		"models" // 修改禮物盒模型
		{
			"1"
			{
				"model"		"models/items/l4d_gift.mdl" // 禮盒模型
				"type"		"physics" 					// 禮盒的物理效果: physics[能移動] 或是 static[固態] (非所有模組能接受physics)
				"gift"		"special" 					// 禮盒種類: standard[普通禮盒] or special[特殊禮盒]
				"scale"		"1.0"	  					// 禮盒模型尺寸 (預設是 1.0，非所有模組能改變尺寸)

				"entity_enable"		"1"					// 1=設置禮盒顏色, 0=不設置禮盒顏色
				"entity_color"		"-1 -1 -1"			// 設置禮盒顏色，填入RGB三色 (三個數值介於0~255，需要空格) [-1 -1 -1: 隨機顏色]
				
				"glow_enable"		"1"					// 1=開啟禮盒光圈, 0=關閉禮盒光圈
				"glow_color"		"-1 -1 -1"			// 禮盒的光圈顏色，填入RGB三色 (三個數值介於0~255，需要空格) [-1 -1 -1: 隨機顏色]
				"glow_range"		"600"				// 禮盒的顏色發光範圍
			}
		}

		"standard_items"
		{
			// 有65種物資隨機從普通禮盒掉落
			"num"   "65"
			"1"
			{
				"name" "defibrillator"
			}

			"2"
			{
				// 隨機生成可用的近戰武器 (支援三方圖近戰，自動識別)
				"name"  "weapon_melee"
			}
			"3"
			{
				// 增加血量+100hp
				"name"  "hp"
				"hp"	"100"
			}
			"4"
			{
				// 失去血量-1hp
				"name"  "hp"
				"hp"	"-1"
			}
			"5"
			{
				// empty = 倖存者得不到任何東西 (謝謝惠顧!)
				"name" "empty"
			}

			...
		}
		"special_items"
		{
			// 有13種物資隨機從特殊禮盒掉落
			"num"   "13"
			"1"
			{
				"name" "first_aid_kit"
			}

			...
		}

		// 玩家撿到"ammo"時，補給的子彈數量，不准寫負數
		"weapon_ammo"
		{
			"weapon_smg"				"400"
			...
		}
		```

	* 可以寫的禮物
		```php
		"grenade_launcher" => 榴彈發射器
		"rifle_m60" => M60 機關槍
		"defibrillator" => 電擊器
		"first_aid_kit" => 治療包
		"pain_pills" => 藥丸
		"adrenaline" => 腎上腺素
		"weapon_upgradepack_incendiary" => 火焰彈藥包
		"weapon_upgradepack_explosive" => 高爆彈藥包
		"molotov" => 火瓶
		"pipe_bomb" => 土製炸彈
		"vomitjar" => 膽汁瓶
		"gascan" => 汽油桶
		"propanetank" => 瓦斯桶
		"oxygentank" => 氧氣灌
		"fireworkcrate" => 煙火盒
		"pistol" => Pistol
		"pistol_magnum" => Magnum
		"pumpshotgun" => Pumpshotgun
		"shotgun_chrome" => Chrome Shotgun
		"smg" => Smg
		"smg_silenced" => Silenced Smg
		"smg_mp5" => MP5
		"rifle" => Rifle
		"rifle_sg552" => SG552
		"rifle_ak47" => AK47
		"rifle_desert" => Desert Rifle
		"shotgun_spas" => Spas Shotgun
		"autoshotgun" => Autoshotgun
		"hunting_rifle" => Hunting Rifle
		"sniper_military" => Military Sniper
		"sniper_scout" => SCOUT
		"sniper_awp" => AWP
		"chainsaw" => 電鋸
		"weapon_melee" => 隨機近戰武器 (支援三方圖近戰)
		"gnome" => 精靈小矮人
		"cola_bottles" => 可樂瓶
		"laser_sight" => 升級紅外線
		"incendiary_ammo" => 升級火焰子彈
		"explosive_ammo" => 升級高爆子彈
		"ammo" => 補給子彈
		"hp" => 血量增減
		"empty" => 空
		```
</details>
# Description | 內容
Drop gifts (touch gift to earn reward) when a special infected or a witch/tank killed by survivor.

* [Video | 影片展示](https://youtu.be/komzEmVvtH0)

* Image | 圖示
	<br/>![l4d2_gifts_1](image/l4d2_gifts_1.jpg)

* Require | 必要安裝
	1. [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)
	2. [[INC] l4d2_weapons](https://github.com/fbef0102/Game-Private_Plugin/blob/main/left4dead2/scripting/include/l4d2_weapons.inc)
	3. [Mission and Weapons - Info Editor](https://forums.alliedmods.net/showthread.php?t=310586): To unlock all melee weapons in all campaigns

* <details><summary>How does it work?</summary>

	* Drop "Standard Gift" when special infected dies
	* Drop "Special Gift" when a tank/witch dies
	* Survivor needs to touch the gifts to get weapons/items/health
</details>

* <details><summary>ConVar | 指令</summary>

    * cfg/sourcemod/l4d2_gifts.cfg
		```php
		// Enable gifts 0: Disable, 1: Enable
		l4d2_gifts_enabled "1"

		// How long the gift stay on ground (seconds)
		l4d2_gifts_gift_life "30"

		// Chance (%) of infected drop special standard gift.
		l4d2_gifts_chance "50"

		// Chance (%) of tank and witch drop second special gift.
		l4d2_specail_gifts_chance "100"

		// Notify Server who pickes up gift, and what the gift reward is. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)
		l4d2_gifts_announce_type "3"

		// Increase Infected health if they pick up gift. (0=Off)
		l4d2_gifts_infected_reward_hp "200"

		// Increase Infected health if they pick up special gift. (0=Off)
		l4d2_gifts_special_infected_reward_hp "400"

		// If 1, prevent survivors from switching into new weapons and items when they open gifts
		l4d2_gifts_block_switch "1"
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

* <details><summary>How to modify the gift Model</summary>

	* data\l4d2_gifts.cfg
		```php
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
		```
</details>

* <details><summary>How to modify the gift item</summary>

	* Standard Gift: l4d2_gifts.sp line 41~109
	* Special Gift: l4d2_gifts.sp line 114~125
	> __Note__ Recompile after modify
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

	```php
	//[X]Aceleracion @ 2017
	//HarryPotter @ 2022-2023
	```
    * v3.2 (2023-12-11)
		* Remove collect limit
		* Remove some cvars
		* Update translation and data file

    * v3.2 (2023-6-9)
		* Add a convar, prevent survivors from switching into new weapons and items when they open gifts
		* Create Fake weapon_drop event

    * v3.0 (2022-12-26)
		* Request by Anzu
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
    * 殺死特感掉落普通禮盒，殺死Tank或Witch掉落特殊禮盒
	* 人類只要碰觸到盒便會自動拆開，禮物盒會有各式各樣的武器與物品，也有可能為空或失去血量，驚喜一瞬間
	* 特感也能碰禮盒，會自動增加血量

* <details><summary>指令中文介紹 (點我展開)</summary>

    * cfg/sourcemod/l4d2_gifts.cfg
		```php
		// 0=關閉插件, 1=啟動插件
		l4d2_gifts_enabled "1"

		// 禮盒的存活時間，如果沒有人撿起會自動消失 (單位: 秒數)
		l4d2_gifts_gift_life "30"

		// 特感掉落普通禮盒的機率
		l4d2_gifts_chance "50"

		// Tank/Witch掉落特殊禮盒的機率
		l4d2_specail_gifts_chance "100"

		// 獲得禮物盒的提示該如何顯示. (0: 不提示, 1: 聊天框, 2: 黑底白字框, 3: 螢幕正中間)
		l4d2_gifts_announce_type "3"

		// 特感撿到普通禮盒所增加的血量. (0=關閉這項功能)
		l4d2_gifts_infected_reward_hp "200"

		// 特感撿到特殊禮盒所增加的血量. (0=關閉這項功能)
		l4d2_gifts_special_infected_reward_hp "400"

		// 1=人類撿起禮盒時，物資直接掉在地上
		// 0=人類撿起禮盒時，物資直接拿在手上
		l4d2_gifts_block_switch "1"
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

* <details><summary>如何修改禮盒模組</summary>

	* data\l4d2_gifts.cfg
		```php
		"1"
		{
			"model"		"models/items/l4d_gift.mdl"  //禮盒模型
			"type"		"physics" 					// 禮盒的物理效果: physics[能移動] 或是 static[固態] (非所有模組能接受physics)
			"gift"		"special" 					// 禮盒種類: standard[普通禮盒] or special[特殊禮盒]
			"scale"		"1.0"	  					// 禮盒模型尺寸 (預設是 1.0，非所有模組能改變尺寸)

			"entity_enable"		"1"					// 1=設置禮盒顏色, 0=不設置禮盒顏色
			"entity_color"		"-1 -1 -1"			// 設置禮盒顏色，填入RGB三色 (三個數值介於0~255，需要空格) [-1 -1 -1: 隨機顏色]
			
			"glow_enable"		"1"					// 1=開啟禮盒光圈, 0=關閉禮盒光圈
			"glow_color"		"-1 -1 -1"			// 禮盒的光圈顏色，填入RGB三色 (三個數值介於0~255，需要空格) [-1 -1 -1: 隨機顏色]
			"glow_range"		"600"				// 禮盒的顏色發光範圍
		}
		```
</details>

* <details><summary>如何設定禮盒驚喜物品</summary>

	* 普通禮盒: l4d2_gifts.sp 第41~109行
	* 特殊禮盒: l4d2_gifts.sp 第114~125行
	> __Note__ 修改完後必須重新編譯
</details>


# Description | 內容
Enables admins to have control over the AI Director and spawn all weapons, melee, items, special infected, and Uncommon Infected without using sv_cheats 1

* Video | 影片展示
<br/>None

* Image | 圖示
	* All 4 Dead
		> 訊息
		<br/>![all4dead2_1](image/all4dead2_1.jpg)

* Apply to | 適用於
	```
	L4D2
	```

* Translation Support | 支援翻譯
	```
	English
	繁體中文
	简体中文
	```

* <details><summary>Changelog | 版本日誌</summary>

	```php
	//grandwazir @ 2009-2010
	//Harry @ 2020-2023
	```
	* v3.5 (2023-1-27)
		* Translation Support. Thanks to wyxls.

	* v3.4
		* [AlliedModder Post](https://forums.alliedmods.net/showpost.php?p=2719391&postcount=503)
		* Convert All codes to new syntax.
		* Add gamedata to support infected spawn (without being limit by director)
		* Add All weapons、melee、items
		* Add firework crate
		* Add L4D2 "The Last Stand" two melee: pitchfork、shovel
		* Spawn Witch Bride Model in c6m1 to prevent crash
		* Add Gnome and Cola.
		* Display menu forever

	* v2.0
		* [Original Plugin by grandwazir](https://forums.alliedmods.net/showthread.php?t=84609)
</details>

* Require | 必要安裝
	1. [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)
	2. To unlock all melee weapons in all campaigns, you MUST use the [Mission and Weapons - Info Editor](https://forums.alliedmods.net/showthread.php?t=310586) plugin which supersedes the extension.

* <details><summary>ConVar | 指令</summary>

	* cfg\sourcemod\all4dead2.cfg
		```php
        // Whether or not bosses will be forced to spawn all the time.
        a4d_always_force_bosses "0"

        // Whether or not we announce changes in game.
        a4d_notify_players "1"

        // The amount of time in seconds between location refreshes. Used only for placing uncommon infected automatically.
        a4d_refresh_zombie_location "20.0"

        // The amount of zombies to add when an admin requests more zombies.
        a4d_zombies_to_add "10"
		```
</details>

* <details><summary>Command | 命令</summary>

	* **Usage: a4d_spawn_infected <infected_type> (does not work for uncommon infected, use a4d_spawn_uinfected instead)**
        ```php
        a4d_spawn_infected
        ```

	* **Usage: a4d_spawn_uinfected <riot|ceda|clown|mud|roadcrew|jimmy>**
        ```php
        a4d_spawn_uinfected
        ``` 

	* **Usage: a4d_spawn_item <item_type>**
        ```php
        a4d_spawn_item
        a4d_spawn_weapon
        ``` 

	* **This command forces the AI director to start a panic event**
        ```php
        a4d_force_panic
        ``` 

	* **This command forces the AI director to start a panic event endlessly**
        ```php
        a4d_panic_forever
        ``` 

	* **Usage: a4d_force_tank <0|1>**
        ```php
        a4d_force_tank
        ``` 

	* **Usage: a4d_force_witch <0|1>**
        ```php
        a4d_force_witch
        ``` 

	* **Usage: a4d_always_force_bosses <0|1>**
        ```php
        a4d_continuous_bosses
        ``` 

	* **Usage: a4d_add_zombies <0..99>**
        ```php
        a4d_add_zombies
        ``` 

	* **Usage: a4d_enable_notifications <0|1>**
        ```php
        a4d_enable_notifications
        ``` 

	* **Usage: Resets all ConVars to their default settings.**
        ```php
        a4d_reset_to_defaults
        ``` 

</details>

* How to use
    * Type !admin to call adm menu and you will see "ALL4DEAD" option

- - - -
# 中文說明
管理員可以直接操控遊戲導演系統並生成武器、近戰武器、物品、醫療物品、特殊感染者以及特殊一般感染者等等，無須開啟作弊模式

* 原理
    * 管理員輸入!admin就能看到 "ALL4DEAD" 選項

* 用意在哪?
    * 不需要開啟作弊模式就能輕鬆生成各種武器、物品與特感，適合用於服主做測試或惡搞

* 功能
    * 可設置是否通知玩家訊息
    * 可設置每次增加普通感染者的數量




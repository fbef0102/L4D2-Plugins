# Description | 內容
Allow to release victim

* [Video | 影片展示](https://youtu.be/IzL-UIF6K-Y)

* Image | 圖示
	* Press Right Mouse to release the victim
        > 右鍵釋放抓住的倖存者
	    <br/>![l4d2_release_victim_1](image/l4d2_release_victim_1.gif)
	* Can't use attack1 and attack2 for short time after release victim
        > 釋放後短時間不能攻擊
	    <br/>![l4d2_release_victim_2](image/l4d2_release_victim_2.jpg)

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
	//BHaType @ 2019~2022
    //Shadowysn @ 2022
	//HarryPotter @ 2022-2023
	```
	* v1.0h (2023-4-11)
        * Translation Support
        * Add cvars, infected can't use attack1 and attack2 for short time after release victim.

	* v2.5 (2023-1-27)
        * [Shadowysn's fork](https://forums.alliedmods.net/showpost.php?p=2785929&postcount=25)
        * Remove Gamedata

	* v0.4
        * [Original Plugin by BHaType](https://forums.alliedmods.net/showthread.php?p=2676902)
</details>

* Require | 必要安裝
    1. [[INC] Multi Colors](https://github.com/fbef0102/L4D1_2-Plugins/releases/tag/Multi-Colors)

* <details><summary>ConVar | 指令</summary>

	* cfg\sourcemod\l4d2_release_victim.cfg
		```php
        // Reset ability
        l4d2_release_victim_ability_reset "1"

        // Changes how message displays. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)
        l4d2_release_victim_announce_type "1"

        // Release distance
        l4d2_release_victim_distance "900.0"

        // Show effect after release
        l4d2_release_victim_effect "1"

        // Release height
        l4d2_release_victim_height "600.0"

        // After dismounting with the hunter, how long can the player not use attack1 and attack2
        l4d2_release_victim_hunter_attackdelay "6.0"

        // After dismounting with the jockey, how long can the player not use attack1 and attack2
        l4d2_release_victim_jockey_attackdelay "6.0"

        // After dismounting with the charger, how long can the player not use attack1 and attack2
        l4d2_release_victim_charger_attackdelay "6.0"

        // After dismounting with the smoker, how long can the player not use attack1 and attack2
        l4d2_release_victim_smoker_attackdelay "10.0"
		```
</details>

* <details><summary>Command | 命令</summary>

	None
</details>

- - - -
# 中文說明
特感可以釋放被抓住的倖存者

* 原理
    * Charger、Smoker、Jockey、Hunter抓住倖存者之後，可以按下右鍵釋放倖存者
    * AI 特感不適用

* 功能
    * 可設置Charger釋放後不能攻擊的時間
    * 可設置Smoker釋放後不能攻擊的時間
    * 可設置Jockey釋放後不能攻擊的時間
    * 可設置Hunter釋放後不能攻擊的時間
    * 可設置釋放後彈走的高度與距離
    * 可設置釋放後特感的能力重置，必須等一段時間
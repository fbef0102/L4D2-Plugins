# Description | 內容
Vomit Jars hit Survivors, Boomer Explosions slime Infected.

* [Video | 影片展示](https://youtu.be/jdkrz0vJoXo)

* Image | 圖示
	* Boomer Explosions slime Infected.
        > Boomer爆炸的膽汁噴到特感身上
        <br/>![l4d2_biletheworld_1](image/l4d2_biletheworld_1.jpg)
	* Vomit Jars hit Survivors
        > 膽汁瓶會噴到倖存者身上
        <br/>![l4d2_biletheworld_2](image/l4d2_biletheworld_2.jpg)

* Apply to | 適用於
    ```
    L4D2
    ```

* <details><summary>Changelog | 版本日誌</summary>

	```php
	//AtomicStryker @ 2010-2017
	//HarryPotter @ 2022
	```
	* v1.3.1 (2022-12-27)
        * [AlliedModder Post](https://forums.alliedmods.net/showpost.php?p=2771151&postcount=124)
	    * Remake code
	    * Remove gamedata
	    * If player throws Vomit Jar to teammate, reduce his hp :D

	* v1.0.7
	    * [Original Request by AtomicStryker](https://forums.alliedmods.net/showthread.php?t=132264)
</details>

* Require | 必要安裝
	1. [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)

* <details><summary>ConVar | 指令</summary>

	* cfg/sourcemod/l4d2_biletheworld.cfg
		```php
        // If 1, Turn on Bile the World on Boomer Death to common infected, S.I., witch and tank.
        l4d2_bile_the_world_boomer_death "1"

        // Bile Range on Boomer Death.
        l4d2_bile_the_world_boomer_death_radius "250"

        // If 1, Turn on Bile the World on Vomit Jar to survivors themself.
        l4d2_bile_the_world_vomit_jar "1"

        // Bile Range on Vomit Jar.
        l4d2_bile_the_world_vomit_jar_radius "150"

        // How much hp reduce, if player throws Vomit Jar to survivors. (0=off)
        l4d2_bile_the_world_vomit_teammate_hp "30"
		```
</details>

* <details><summary>Command | 命令</summary>

	None
</details>

- - - -
# 中文說明
膽汁瓶會噴到倖存者身上，Boomer爆炸的膽汁噴到特感、Tank、Witch、普通感染者

* 原理
	* 玩家朝隊友丟膽汁瓶，隊友也會被噴到
    * Boomer死亡爆炸時，旁邊如果有特感、Tank、Witch、普通感染者，他們也會被炸到淋上膽汁

* 功能
    * 可設置功能開關
    * 可設置Boomer死亡的膽汁範圍
    * 可設置膽汁瓶的膽汁的範圍
    * 如果玩家朝隊友丟膽汁瓶，丟膽汁瓶的玩家會受到懲罰減少HP，可設置扣除的HP數值


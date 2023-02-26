# Description | 內容
Detects and reports skeets, crowns, levels, highpounces, etc.

* Video | 影片展示
<br/>None

* Image
	* Skill moment
    <br/>![l4d2_skill_detect_1](image/l4d2_skill_detect_1.jpg)  

* Apply to | 適用於
	```
	L4D2 Coop/Versus/Survival/Realism
	```

* Translation Support | 支援翻譯
	```
	English
	繁體中文
	简体中文
	```

* <details><summary>Changelog | 版本日誌</summary>

    * v1.2h (2023-2-25)
        * Request by ligal 
        * Separate translation for the jockey and hunter

    * v1.1h (2022-12-16)
        * Request by Yabi
        * Translation Support

    * v0.9.20 fork
        * [By zonde306](https://github.com/zonde306/l4d2sc/blob/master/l4d2_skill_detect.sp)

    * v0.9.20
        * [SirPlease/l4d2_skill_detect](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d2_skill_detect.sp)
</details>

* Require | 必要安裝
    1. [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)
	2. [[INC] Multi Colors](https://github.com/fbef0102/L4D1_2-Plugins/releases/tag/Multi-Colors)

* <details><summary>ConVar | 指令</summary>

	* cfg/sourcemod/l4d2_skill_detect.cfg
		```php
        // The minimal speed of the first jump of a bunnyhopstreak (0 to allow 'hops' from standstill).
        sm_skill_bhopinitspeed "150"

        // The minimal speed at which hops are considered succesful even if not speed increase is made.
        sm_skill_bhopkeepspeed "300"

        // The lowest bunnyhop streak that will be reported.
        sm_skill_bhopstreak "3"

        // How much height distance a charger must take its victim for a deathcharge to be reported.
        sm_skill_deathcharge_height "400"

        // How much damage a survivor must at least do in the final shot for it to count as a drawcrown.
        sm_skill_drawcrown_damage "500"

        // If set, any damage done that exceeds the health of a victim is hidden in reports.
        sm_skill_hidefakedamage "0"

        // Minimum height of hunter pounce for it to count as a DP.
        sm_skill_hunterdp_height "400"

        // A clear within this time (in seconds) counts as an insta-clear.
        sm_skill_instaclear_time "0.75"

        // How much height distance a jockey must make for his 'DP' to count as a reportable highpounce.
        sm_skill_jockeydp_height "300"

        // Whether to report in chat (see sm_skill_report_flags).
        sm_skill_report_enable "1"

        // Report Flag
        // bitflags: 1,2:skeets/hurt; 4,8:level/chip; 16,32:crown/draw; 64,128:cut/selfclear, ...
        // See Source code for more bitflags
        sm_skill_report_flags "1028095"

        // How much damage a survivor must at least do to a smoker for him to count as self-clearing.
        sm_skill_selfclear_damage "200"

        // Whether to count/forward direct GL hits as skeets.
        sm_skill_skeet_allowgl "1"

        // Whether to count/forward melee skeets.
        sm_skill_skeet_allowmelee "1"

        // Whether to count/forward sniper/magnum headshots as skeets.
        sm_skill_skeet_allowsniper "1"
		```
</details>

* <details><summary>Command | 命令</summary>

	None
</details>

- - - -
# 中文說明
顯示人類與特感各種花式技巧 (譬如推開特感、速救隊友、一槍爆頭、近戰砍死、高撲傷害等等)

* 圖示
	* 大佬裝B的瞬間
    <br/>![l4d2_skill_detect_2](image/l4d2_skill_detect_2.jpg)  

* 原理
	* 每當有高手展現實力，打印在聊天視窗
    * 戰役/對抗/寫實/生存都適用

* 功能
	* 可控制指令選擇打印哪些特殊技巧，請打開源始碼查看

* <details><summary>如何設置<b>sm_skill_report_flags</b>指令值</summary>

    * 指令預設
        ```php
        // 此指令用來決定顯示哪些花式技巧
        // 1028095 = 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512 + 1024 + 2048 + 8192 + 32768 + 65536 + 131072 + 262144 + 524288
        sm_skill_report_flags "1028095"
        ```
    * 源始碼內
        ```php
        REP_SKEET				(2 ^ 0 = 1) //空爆hunter/jokcey
        REP_HURTSKEET			(2 ^ 1 = 2) //低傷害空爆hunter/jokcey
        REP_LEVEL				(2 ^ 2 = 4) //近戰砍死衝鋒的Charger
        REP_HURTLEVEL			(2 ^ 3 = 8) //近戰低傷害砍死衝鋒的Charger
        REP_CROWN				(2 ^ 4 = 16) //一槍殺死Witch並無人受傷
        REP_DRAWCROWN			(2 ^ 5 = 32) //兩槍以上殺死Witch並無人受傷
        REP_TONGUECUT			(2 ^ 6 = 64)  //砍斷Smoker的舌頭
        REP_SELFCLEAR			(2 ^ 7 = 128) //自解Smoker的舌頭
        REP_SELFCLEARSHOVE		(2 ^ 8 = 256) //推開自解Smoker的舌頭
        REP_ROCKSKEET			(2 ^ 9 = 512) //打碎Tank石頭
        REP_DEADSTOP			(2 ^ 10 = 1024) //推停飛撲的hunter/jokcey
        REP_POP					(2 ^ 11 = 2048) //殺死Boomer不被嘔吐
        REP_SHOVE				(2 ^ 12 = 4096) //推開特感
        REP_HUNTERDP			(2 ^ 13 = 8192) //Hunter高撲傷害
        REP_JOCKEYDP			(2 ^ 14 = 16384) //Jockey高空騎到人類
        REP_DEATHCHARGE			(2 ^ 15 = 32768) //Charger衝鋒帶走人類墬樓
        REP_INSTACLEAR			(2 ^ 16 = 65536) //快速拯救隊友
        REP_BHOPSTREAK			(2 ^ 17 = 131072) //連跳
        REP_CARALARM			(2 ^ 18 = 262144) //警報車
        REP_POPSTOP				(2 ^ 19 = 524288) //推開Boomer不被嘔吐
        ```
    * 舉例
        * 如果只要顯示 "打碎Tank石頭"(數值是512)、"Hunter高撲傷害"(數值是8192) => 請寫```sm_skill_report_flagss 8704```  (512 + 8192)
        * 如果只要顯示 "空爆hunter/jokcey"(數值是1)、"打碎Tank石頭"(數值是512)、"警報車"(數值是262144) => 請寫```sm_skill_report_flagss 262657```  (1 + 512 + 262144)
        * 如果要顯示全部，請寫```sm_skill_report_flags 1048575``` (總數值)
</details>
# Description | 內容
HUD with cs kill info list.

* [Video | 影片展示](https://youtu.be/Cehi0IxaCpI)

* Image | 圖示
    * 【L4D2】 (●｀・ω・)=Ｏ)｀-д゜)【你】
	<br/>![l4d2_cs_kill_hud_1](image/l4d2_cs_kill_hud_1.gif)
	<br/>![l4d2_cs_kill_hud_2](image/l4d2_cs_kill_hud_2.jpg)

* Require | 必要安裝
 <br/>None

* <details><summary>ConVar | 指令</summary>

	* cfg/sourcemod/l4d2_cs_kill_hud.cfg
        ```php
        // 0=Plugin off, 1=Plugin on.
        l4d2_cs_kill_hud_enable "1"

        // Numbers of kill list on hud (Default: 5, MAX: 7)
        l4d2_cs_kill_hud_number "5"

        // Time in seconds to erase kill list on hud.
        l4d2_cs_kill_hud_notice_time "7"

        // If 1, disable offical player death message (the red font of kill info)
        l4d2_cs_kill_hud_disable_standard_message "1"

        // If 1, Makes the text blink from white to red.
        l4d2_cs_kill_hud_blink "1"

        // If 1, Shows the text inside a black transparent background.
        // Note: the background may not draw properly when initialized as "0", start the map with "1" to render properly.
        l4d2_cs_kill_hud_background "0"
        ```
</details>

* <details><summary>Command | 命令</summary>

	None
</details>

* <details><summary>How to customize weapon icon</summary>

	* [l4d2_cs_kill_hud.sp](/l4d2_cs_kill_hud/scripting/l4d2_cs_kill_hud.sp#L137-L171) line 137 ~ 171
    * Recompile, done.
</details>

* <details><summary>Known Conflicts</summary>
	
	If you don't use any of these at all, no need to worry about conflicts.
	1. [Mod - Admin System](https://steamcommunity.com/sharedfiles/filedetails/?id=214630948)
		* Please Remove
</details>

* Apply to | 適用於
    ```
    L4D2
    ```

* <details><summary>Related Plugin | 相關插件</summary>

	1. [l4d2_scripted_hud](https://github.com/fbef0102/Game-Private_Plugin/tree/main/Plugin_%E6%8F%92%E4%BB%B6/Server_%E4%BC%BA%E6%9C%8D%E5%99%A8/l4d2_scripted_hud): Display text for up to 5 scripted HUD slots on the screen.
		> 在玩家畫面上方五個Hud位置顯示不同的特殊文字
</details>

* <details><summary>Changelog | 版本日誌</summary>

    * v1.5h (2023-9-12)
        * Add chainsaw

    * v1.4h (2023-6-11)
        * Shows the text inside a black transparent background.
        * Remove headshot or behind wall text if weapon is "pipe bomb", "fire", "melee punch"

    * v1.2h (2023-6-2)
        * Fixed common infected null string

    * v1.1h (2023-6-2)
        * Support Versus mode and witch killed

    * v1.0h (2023-5-28)
        * Merge inc with main sp file
        * Delete all functions, only cs kill info
        * Optimize code and improve performance
        * Add more convars
        * Makes the text blink from white to red.
        * Numbers of kill list on hud
        * Hud will vanish after period time

	* v1.0.3
	    * [Original Plugin by LinLinLin](https://forums.alliedmods.net/showthread.php?t=340601)
</details>

- - - -
# 中文說明
L4D2擊殺提示改成CS遊戲的擊殺列表

* 原理
	* 人類或特感死亡時，依據兇手與武器，顯示出不同的提示在右上角
    * 自殺、Witch抓死人、被小殭屍圍毆致死，也會有提示
    * 穿牆、爆頭，新增額外提示
    * 經過一段時間提示會消失

* <details><summary>指令中文介紹 (點我展開)</summary>

	* cfg/sourcemod/l4d2_cs_kill_hud.cfg
        ```php
        // 0=關閉插件, 1=啟動插件
        l4d2_cs_kill_hud_enable "1"

        // 一次最多顯示的擊殺行數 (預設: 5, 最大: 7)
        l4d2_cs_kill_hud_number "5"

        // 擊殺列表顯示停留的時間.
        l4d2_cs_kill_hud_notice_time "7"

        // 為1時，關閉L4D2官方的擊殺提示 (左方紅字黑框的HUD)
        l4d2_cs_kill_hud_disable_standard_message "1"

        // 為1時，擊殺列表文字紅白閃爍
        l4d2_cs_kill_hud_blink "1"

        // 為1時，擊殺列表顯示黑底背景
        // 注意: 必須重啟伺服器才會生效
        l4d2_cs_kill_hud_background "0"
        ```
</details>

* <details><summary>自製武器圖案</summary>

	* [l4d2_cs_kill_hud.sp](/l4d2_cs_kill_hud/scripting/l4d2_cs_kill_hud.sp#L137-L171) 137 ~ 171 行
    * 重新編譯，完成
</details>

* <details><summary>會衝突的插件or模組</summary>
	
	如果沒安裝以下內容就不需要擔心衝突
	1. [Mod - Admin System](https://steamcommunity.com/sharedfiles/filedetails/?id=214630948)
		* 請移除
</details>
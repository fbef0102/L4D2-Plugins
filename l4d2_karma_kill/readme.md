# Description | 內容
Very Very loudly announces the predicted event of a player leaving the map and or life through height or drown.

* [Video | 影片展示](https://youtu.be/ID5Zxj0QHwg)

* Image | 圖示
    * Arresto Momentum
    <br/>![l4d2_karma_kill_1](image/l4d2_karma_kill_1.gif)

* Require | 必要安裝
    1. [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)
    2. [[INC] Multi Colors](https://github.com/fbef0102/L4D1_2-Plugins/releases/tag/Multi-Colors)

* <details><summary>ConVar | 指令</summary>

    * cfg/sourcemod/l4d2_karma_kill.cfg
        ```php
        // Enable karma jumping. Karma jumping only registers on confirmed kills.
        l4d2_karma_jump "1"

        // Award a confirmed karma maker with a player_death event.
        l4d2_karma_award_confirmed "1"

        // Damage to award on confirmed kills, or -1 to disable. Requires l4d2_karma_award_confirmed set to 1
        l4d2_karma_damage_award_confirmed "300"

        // Whenever or not to make karma announce only happen upon death.
        l4d2_karma_only_confirmed "0"

        // How long does Time get slowed for the server
        l4d2_karma_kill_slowtime_on_server "5.0"

        // How long does Time get slowed for the karma couple
        l4d2_karma_kill_slowtime_on_couple "3.0"

        // How slow Time gets. Hardwired to minimum 0.03 or the server crashes
        l4d2_karma_kill_slowspeed "0.2"

        // Turn Karma Kills on and off 
        l4d2_karma_kill_enabled "1"

        // If you take more than 224 points of damage while incapacitated, you die.
        l4d2_karma_kill_no_fall_damage_protect_from_incap "1"

        // 0 - Entire Server gets slowed, 1 - Only Charger and Survivor do
        l4d2_karma_kill_slowmode "0"

        // If slowmode is 0, how long does it take for the next karma to freeze the entire map. Begins counting from the end of the previous freeze
        l4d2_karma_kill_cooldown "0.0"

        // Allow karma victims to be revived with defibrillator? 0 - No, 1 - Yes.
        l4d2_karma_kill_allow_defib "0"
        ```
</details>

* <details><summary>Command | 命令</summary>

    None
</details>

* Apply to | 適用於
    ```
    L4D2
    ```

* <details><summary>Changelog | 版本日誌</summary>

    * v4.2
        * Remove <autoexecconfig>
        * Remove <updater>
        * Fix error: timer invalid handle
        * Add <multicolors>
        * Remove Tag
        * Fix error: client is not in game
        * Optimize code

    * v4.1
        * [By AtomicStryker, Eyal282](https://forums.alliedmods.net/showthread.php?t=336225)
</details>

- - - -
# 中文說明
被Charger撞飛、Tank打飛、Jockey騎走墬樓、自殺跳樓等等會有慢動作特效

* 原理
    * 如果判定從高空墬樓會倒地或死亡，伺服器時間便會慢下來

* <details><summary>指令中文介紹 (點我展開)</summary>

    * cfg/sourcemod/l4d2_karma_kill.cfg
        ```php
        // 為1時，玩家自己跳樓自殺也會有慢動作效果
        l4d2_karma_jump "1"

        // 為1時，玩家死亡會有慢動作效果
        l4d2_karma_award_confirmed "1"

        // 多少傷害以上才會有慢動作效果 [-1=關閉，_award_confirmed 的指令值必須為1]
        l4d2_karma_damage_award_confirmed "300"

        // 為1時，只有倖存者死亡才會有提示
        l4d2_karma_only_confirmed "0"

        // 慢動作維持多久時間?
        l4d2_karma_kill_slowtime_on_server "5.0"

        // 如果 _kill_slowmode 為 1，抓人的特感與被抓的倖存者，兩個人的慢動作維持多久時間?
        l4d2_karma_kill_slowtime_on_couple "3.0"

        // 如果 _kill_slowmode 為 1，抓人的特感與被抓的倖存者，兩個人的慢動作速度? (最小值0.03)
        l4d2_karma_kill_slowspeed "0.2"

        // 為1時，慢動作時有音效
        l4d2_karma_kill_enabled "1"

        // 為1時，當倒地的倖存者墬樓或淹水時超過224滴的傷害時，立刻死亡.
        l4d2_karma_kill_no_fall_damage_protect_from_incap "1"

        // 0 - 整個伺服器的時間都會慢下來, 1 - 只有抓人的特感與被抓的倖存者，兩個人的時間會慢下來
        l4d2_karma_kill_slowmode "0"

        // 如果 _kill_slowmode 為 0，下一次再觸發慢動作效果的冷卻時間
        l4d2_karma_kill_cooldown "0.0"

        // 為1時，慢動作效果而死亡的倖存者屍體可以使用電擊器復活
        l4d2_karma_kill_allow_defib "0"
        ```
</details>

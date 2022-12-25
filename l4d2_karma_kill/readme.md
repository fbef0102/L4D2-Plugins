# Description | 內容
Very Very loudly announces the predicted event of a player leaving the map and or life through height or drown.

* [Video | 影片展示](https://youtu.be/ID5Zxj0QHwg)

* Image | 圖示
	* Arresto Momentum
	> 動作慢下來
	<br/>![l4d2_karma_kill_1](image/l4d2_karma_kill_1.gif)

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

* Require | 必要安裝
	1. [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)
	2. [[INC] Multi Colors](https://github.com/fbef0102/L4D1_2-Plugins/releases/tag/Multi-Colors)

* <details><summary>ConVar | 指令</summary>

	* cfg/sourcemod/l4d2_karma_kill.cfg
	```php
    // Award a confirmed karma maker with a player_death event.
    l4d2_karma_award_confirmed "1"

    // Prefix for announcements. For colors, replace the side the slash points towards, example is /x04[/x05KarmaCharge/x03]
    l4d2_karma_charge_prefix "TS"

    // Damage to award on confirmed kills, or -1 to disable. Requires l4d2_karma_award_confirmed set to 1
    l4d2_karma_damage_award_confirmed "300"

    // Enable karma jumping. Karma jumping only registers on confirmed kills.
    l4d2_karma_jump "1"

    //  Allow karma victims to be revived with defibrillator? 0 - No, 1 - Yes.
    l4d2_karma_kill_allow_defib "0"

    // Whether or not to enable bird charges, which are unlethal height charges.
    l4d2_karma_kill_bird "1"

    // If slowmode is 0, how long does it take for the next karma to freeze the entire map. Begins counting from the end of the previous freeze
    l4d2_karma_kill_cooldown "0.0"

    //  Turn Karma Kills on and off 
    l4d2_karma_kill_enabled "1"

    // Fixes this by disabling fall damage when carried: https://streamable.com/xuipb6
    l4d2_karma_kill_no_fall_damage_on_carry "1"

    // If you take more than 224 points of damage while incapacitated, you die.
    l4d2_karma_kill_no_fall_damage_protect_from_incap "1"

    //  0 - Entire Server gets slowed, 1 - Only Charger and Survivor do
    l4d2_karma_kill_slowmode "0"

    //  How slow Time gets. Hardwired to minimum 0.03 or the server crashes
    l4d2_karma_kill_slowspeed "0.2"

    //  How long does Time get slowed for the karma couple
    l4d2_karma_kill_slowtime_on_couple "3.0"

    //  How long does Time get slowed for the server
    l4d2_karma_kill_slowtime_on_server "5.0"

    // Whenever or not to make karma announce only happen upon death.
    l4d2_karma_only_confirmed "0"
	```
</details>

* <details><summary>Command | 命令</summary>
	None
</details>

- - - -
# 中文說明
被Charger撞飛、Tank打飛、Jockey騎走墬樓、自殺跳樓等等會有慢動作特效

* 原理
	* 如果判定從高空墬樓會倒地或死亡，伺服器時間便會慢下來

* 功能
	1. 可設置慢動作的時間長度
    2. 可設置慢動作的速度

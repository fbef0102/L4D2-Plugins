# Description | 內容
Quickswitch Reloading like CS:GO in L4D2

* [Video | 影片展示](https://youtu.be/t7n1vYBb5sk)

* Image | 圖示
<br/>None

* Apply to | 適用於
```
L4D2
```

* [L4D1 Version | 適用於L4D1的版本](https://github.com/fbef0102/L4D1-Competitive-Plugins/tree/master/l4d_weapon_csgo_reload)

* <details><summary>Changelog | 版本日誌</summary>

	* v2.2 (2022-11-6)
        * [AlliedModders Post](https://forums.alliedmods.net/showthread.php?t=318820)
        * Add m60
        * Fixed DataPack memory leak issue
        * Replace OnPlayerRunCmd with SDKHook_Reload, better safe and improve code.
        * Adjust "l4d2_sg552_reload_clip_time" from 1.3 to 1.6 since L4D2 "The Last Stand" update.
        * New convars, control each weapon max clip.
        * Fixed dual pistol not working.

	* v1.0
	    * Initial Release
</details>

* Require | 必要安裝
<br/>None

* <details><summary>ConVar | 指令</summary>

	* cfg/sourcemod/l4d2_weapon_csgo_reload.cfg
	```php
    // ak47 max clip
    l4d2_ak47_clip "40"

    // reload time for ak47 clip
    l4d2_ak47_reload_clip_time "1.2"

    // awp max clip
    l4d2_awp_clip "20"

    // reload time for awp clip
    l4d2_awp_reload_clip_time "2.0"

    // desert rifle max clip
    l4d2_desertrifle_clip "60"

    // reload time for desert rifle clip
    l4d2_desertrifle_reload_clip_time "1.8"

    // dual pistol max clip
    l4d2_dualpistol_clip "30"

    // reload time for dual pistol clip
    l4d2_dualpistol_reload_clip_time "1.75"

    // grenade max clip
    l4d2_grenade_clip "1"

    // reload time for grenade clip
    l4d2_grenade_reload_clip_time "2.5"

    // huntingrifle max clip
    l4d2_huntingrifle_reload_clip "15"

    // reload time for hunting rifle clip
    l4d2_huntingrifle_reload_clip_time "2.6"

    // m60 max clip
    l4d2_m60_clip "150"

    // reload time for m60 clip
    l4d2_m60_reload_clip_time "1.2"

    // mangum max clip
    l4d2_mangum_clip "8"

    // reload time for mangum clip
    l4d2_mangum_reload_clip_time "1.18"

    // pistol max clip
    l4d2_pistol_clip "15"

    // reload time for pistol clip
    l4d2_pistol_reload_clip_time "1.2"

    // rifle max clip
    l4d2_rifle_reload_clip "50"

    // reload time for rifle clip
    l4d2_rifle_reload_clip_time "1.2"

    // scout max clip
    l4d2_scout_clip "15"

    // reload time for scout clip
    l4d2_scout_reload_clip_time "1.45"

    // sg552 max clip
    l4d2_sg552_clip "50"

    // reload time for sg552 clip
    l4d2_sg552_reload_clip_time "1.3"

    // smg max clip
    l4d2_smg_reload_clip "50"

    // reload time for smg clip
    l4d2_smg_reload_clip_time "1.04"

    // smg mp5 max clip
    l4d2_smgmp5_clip "50"

    // reload time for smg mp5 clip
    l4d2_smgmp5_reload_clip_time "1.7"

    // smg silenced max clip
    l4d2_smgsilenced_clip "50"

    // reload time for smg silenced clip
    l4d2_smgsilenced_reload_clip_time "1.05"

    // sniper military max clip
    l4d2_snipermilitary_clip "30"

    // reload time for sniper military clip
    l4d2_snipermilitary_reload_clip_time "1.8"

    // 0=off plugin, 1=on plugin
    l4d2_weapon_csgo_reload_allow "1"

    // enable previous clip recover?
    l4d2_weapon_csgo_reload_clip_recover "1"
	```
</details>

* <details><summary>Command | 命令</summary>

	None
</details>

- - - -
# 中文說明
將武器改成現代遊戲的裝子彈機制 (仿CS:GO切槍裝彈設定)

* 原理
	* 裝子彈的時候，彈夾不會歸零
    * 當武器動畫是裝上彈夾的時候，彈夾會填滿

* 功能
	1. 可設置每個武器的快速裝彈時間與彈夾數量
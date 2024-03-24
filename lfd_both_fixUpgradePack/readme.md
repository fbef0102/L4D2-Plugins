# Description | 內容
Fixes upgrade packs pickup bug when there are 5+ survivors

* Video | 影片展示
<br/>None

* Image | 圖示
<br/>None

* <details><summary>How does it work?</summary>

    * (Before) In 5+ survivors, sometimes survivor can't pick up upgrade ammo from upgrade box
    * (After) In 5+ survivors, every survivor can pick up upgrade ammo from upgrade box
</details>

* Require | 必要安裝
<br/>None

* <details><summary>ConVar | 指令</summary>

	* cfg\sourcemod\lfd_both_fixUpgradePack.cfg
        ```php
        // Play sound when ammo already used
        upgrade_denied_sound "1"

        // Explosive ammo multiplier on pickup (Max clip in L4D: 254)
        upgrade_explosive_multi "1.0"

        // Incendiary ammo multiplier on pickup (Max clip in L4D: 254)
        upgrade_incendiary_multi "1.0"

        // Time in seconds to remove upgradepack after first use. (0=off)
        upgrade_clear_time "100"
        ```
</details>

* <details><summary>Command | 命令</summary>

    None
</details>

* Apply to | 適用於
    ```
    L4D1
    L4D2
    ```

* <details><summary>Changelog | 版本日誌</summary>

    * v1.4 
        * Remake code
        * remove unuseful convar
        * add timer to remove upgrade pack entity

    * v1.0
        * [Original Plugin by bullet28](https://forums.alliedmods.net/showthread.php?t=322824)
</details>

- - - -
# 中文說明
修正高爆彈與燃燒彈無法被重複角色模組的倖存者撿起來

* 原理
    * (裝此插件之前) 在5+多人倖存者伺服器中，有時候玩家無法拾取燃燒子彈或高爆子彈
    * (裝此插件之後) 在5+多人倖存者伺服器中，每位玩家可以拾取燃燒子彈或高爆子彈

* <details><summary>指令中文介紹 (點我展開)</summary>

	* cfg\sourcemod\lfd_both_fixUpgradePack.cfg
        ```php
        // 第二次重複拾取時，提示音效
        upgrade_denied_sound "1"

        // 高爆彈藥拾取時，數量加倍 (子彈最多只能到254，認真你就輸了)
        upgrade_explosive_multi "1.0"

        // 燃燒彈藥拾取時，數量加倍 (子彈最多只能到254，認真你就輸了)
        upgrade_incendiary_multi "1.0"

        // 當彈藥包被第一個人拾取時，100秒之後自動移除 (0=不移除直到所有人都拾取一次)
        upgrade_clear_time "100"
        ```
</details>
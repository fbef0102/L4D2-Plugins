# Description | 內容
Mission manager for L4D2, provide information about map orders for other plugins

> __Note__ <br/>
🟥Dedicated Server Only<br/>
🟥只能安裝在Dedicated Server

* Video | 影片展示
<br/>None

* Image | 圖示
<br/>None

* Require | 必要安裝
	1. [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)

* <details><summary>ConVar | 指令</summary>

	None
</details>

* <details><summary>Command | 命令</summary>

	* **List all installed maps on the server**
        ```c
        sm_lmm_list [<coop|versus|scavenge|survival>]
        ```

	* **Give you a list of maps that cannot be recognized in "mission.cache" folder**
        ```c
        sm_lmm_list invalid
        ```
</details>

* Function & API Usage & Notes & FAQ
    * For better description, read [this](https://github.com/rikka0w0/l4d2_mission_manager#function-description)

* <details><summary>API | 串接</summary>

	```c++
    /**
    * @return	Return LMM_GAMEMODE_UNKNOWN (-1) if gamemode is unknown
    */
    native LMM_GAMEMODE LMM_GetCurrentGameMode();

    /**
    * @return	Return LMM_GAMEMODE_UNKNOWN (-1) if gamemode string is invalid or gamemode is unknown
    */
    native LMM_GAMEMODE LMM_StringToGamemode(const char[] name);

    native int LMM_GamemodeToString(LMM_GAMEMODE gamemode, char[] name, int length);

    native int LMM_GetNumberOfMissions(LMM_GAMEMODE gamemode);
    native int LMM_FindMissionIndexByName(LMM_GAMEMODE gamemode, const char[] missionName);
    native int LMM_GetMissionName(LMM_GAMEMODE gamemode, int missionIndex, char[] missionName, int length);
    
    /**
	* Attempt to localize the mission name
    * @return	return 1 for success, 0 for no localization and -1 for error.
    */
    native int LMM_GetMissionLocalizedName(LMM_GAMEMODE gamemode, int missionIndex, char[] missionName, int length, int client);

    native int LMM_GetNumberOfMaps(LMM_GAMEMODE gamemode, int missionIndex);
    native int LMM_FindMapIndexByName(LMM_GAMEMODE gamemode, int& missionIndex, const char[] mapName);
    native int LMM_GetMapName(LMM_GAMEMODE gamemode, int missionIndex, int mapIndex, char[] mapName, int length);
    
    /** 
	* Attempt to localize the map name, return 1 for success, 0 for no localization and -1 for error. 
	* mapName will be converted to lower case internally. Entries in maps.phrases.txt can only have lower case English letters and numbers
    */
    native int LMM_GetMapLocalizedName(LMM_GAMEMODE gamemode, int missionIndex, int mapIndex, char[] mapName, int length, int client);
    
    /**
	* Get the unique ID of the map, which contains the information of both missionIndex and mapIndex
    */
    native int LMM_GetMapUniqueID(LMM_GAMEMODE gamemode, int missionIndex, int mapIndex);
    
    /**
	* Decode the unique ID of the map, and return both missionIndex and mapIndex
    */
    native int LMM_DecodeMapUniqueID(LMM_GAMEMODE gamemode, int& missionIndex, int mapUID);
    
    /**
	* Get the number of map unique id, also the number of maps for the given gamemode
    */
    native int LMM_GetMapUniqueIDCount(LMM_GAMEMODE gamemode);

    native int LMM_GetNumberOfInvalidMissions();
    native int LMM_GetInvalidMissionName(int missionIndex, char[] mapName, int length);

    /**
    * This forward is called during the OnPluginStart() phase.
    * Do NOT use any LMM APIs in OnPluginStart, due to the chance that your plugin is loaded prior to LMM.
    * LMM APIs become available in OnAllPluginsLoaded().
    */
    forward void OnLMMUpdateList();

    /**
    * This can only work while a client is ingame.
    * To call while no clients are not in game requires a signiture @CDirector
    *   
    * Call this before you force change level to close HSCRIPT.
    * Any other way of level changing is fine e.g. level transition L4D "callvote missionchange" ect.
    */
    stock void ShutDownScriptedMode()
	```
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

* <details><summary>Related Plugin | 相關插件</summary>

	1. [sm_l4d_mapchanger](https://github.com/fbef0102/Game-Private_Plugin/tree/main/Plugin_%E6%8F%92%E4%BB%B6/Map_%E9%97%9C%E5%8D%A1/sm_l4d_mapchanger): Force change to next mission when current mission(final stage) end + Force change to next level when survivors wipe out + Vote to next map (Apply to Versus/Survival/Scavenge).
        > 最後一關結束時自動換圖 + 滅團N次後自動切換到下一個關卡 + 玩家投票下一張地圖 (生存/對抗/清道夫模式也適用)
</details>

* <details><summary>Changelog | 版本日誌</summary>

    * v1.0h (2023-11-15)
        * Fix memory leak

    * v1.0.4 (2023-6-20)
        * Require lef4dhooks v1.33 or above

    * v1.0.3 (2023-4-18)
        * Optimize code

    * v1.0.2 (2023-4-17)
        * Get correct gamemode

	* v1.0.1 (2023-4-16)
        * Check if mission/map name translation phrase exists to prevent error
        * Do not check some missions.cache files if there are no corresponding map.
        * Separate error log, save error into logs\l4d2_mission_manager.log.
        * Reduce some annoying error
        * Replace Gamedata with left4dhooks

	* v1.0.0
        * [Original Plugin by rikka0w0](https://github.com/rikka0w0/l4d2_mission_manager)
</details>

- - - -
# 中文說明
地圖管理器，提供給其他插件做依賴與API串接

* 原理
    * 能自動抓取官方圖與三方圖所有的地圖名與關卡名，掃描資料夾missions與maps並複製其內容到mission.cache資料夾裡
        * mission.cache 是插件創立的資料夾，伺服器本身並沒有這個資料夾
    * 這插件只是一個輔助插件，等其他插件真需要的時候再安裝
        * 🟥白話點說，你不是源碼開發者也沒有插件需要依賴這個插件就不要亂裝

* 功能
    * 給開發者使用，提供許多API串接 
    * 所有關於地圖mission文件的錯誤報告都寫在logs\l4d2_mission_manager.log


* 注意事項
    1. <details><summary>安裝新的三方圖</summary>

        * 每當安裝新的三方圖時，left4dead2\missions.cache\會有新的.txt檔案產生，是三方圖對應的mission文件備份
    </details>

* FAQ
    1. <details><summary>為甚麼logs\l4d2_mission_manager.log會有一堆錯誤訊息</summary>

        * 分析：這個插件會檢查三方地圖mission文件，當格式錯誤或者關卡不存在等等，會將錯誤報告寫在logs\l4d2_mission_manager.log
        ![image](https://user-images.githubusercontent.com/12229810/232275149-62919e95-d83b-4aa8-b2c5-8fa7b4202f1f.png) 
        * 原因：Mission文件是決定地圖的關卡順序、名稱、遊戲模式等等，通常是由地圖作者撰寫，但是有的三方圖作者會亂寫，放飛自我，導致地圖格式不正確等等問題
        * 解決方式法一：所以鍋都是地圖問題，請去跟地圖作者抱怨
        * 解決方式法一：嘗試閱讀錯誤並修改left4dead2\missions.cache\ 的地圖mission文件然後儲存，直到沒有錯誤報告為止
        * 解決方式法三：🟥這份錯誤報告不會對伺服器產生任何影響，可以選擇忽略
    </details>
        
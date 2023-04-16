# Description | 內容
Mission manager for L4D2, provide information about map orders for other plugins

* Video | 影片展示
<br/>None

* Image | 圖示
<br/>None

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

	* v1.0.1 (2023-4-16)
        * Check if mission/map name translation phrase exists to prevent error
        * Do not check some missions.cache files if there are no corresponding map.
        * Separate error log, save error into logs\l4d2_mission_manager.log.
        * Reduce some annoying error
        * Replace Gamedata with left4dhooks

	* v1.0.0
        * [Original Plugin by rikka0w0](https://github.com/rikka0w0/l4d2_mission_manager)
</details>

* Require | 必要安裝
	1. [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)

* <details><summary>ConVar | 指令</summary>

	None
</details>

* <details><summary>Command | 命令</summary>

	* **Give you a list of maps that cannot be recognized in "mission.cache" folder**
        ```c
        sm_lmm_list [<coop|versus|scavenge|survival|invalid>]
        ```
</details>

* Function & API Usage & Notes & FAQ
    * For better description, read [this](https://github.com/rikka0w0/l4d2_mission_manager#function-description)

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
    1. <details><summary>安裝此插件之後</summary>

        安裝上這個插件並啟動服務器之後，服務器會自動產生以下檔案
        * left4dead2\addons\sourcemod\configs\
            ![image](https://user-images.githubusercontent.com/12229810/232274359-290168ba-6c5d-48c9-8a8c-a6ccd64cec48.png)
        * left4dead2\missions.cache\
            ![image](https://user-images.githubusercontent.com/12229810/232274406-0726c17c-aa78-4152-a594-7e0e1ae22574.png)
    </details>

    2. <details><summary>安裝新的三方圖</summary>

        * 每當安裝新的三方圖時，left4dead2\addons\sourcemod\configs\內的文件內容會有變化，新增三方圖的關卡與地圖名
        * 每當安裝新的三方圖時，left4dead2\missions.cache\會有新的.txt檔案產生，是三方圖對應的mission文件備份
    </details>

    3. <details><summary>刪除三方圖</summary>

        * 每次刪除三方圖檔案的時候，我建議關閉伺服器然後刪除以下檔案
            * configs\missioncycle.coop.txt
            * configs\missioncycle.scavenge.txt
            * configs\missioncycle.survival.txt
            * configs\missioncycle.versus.txt
        * 再重新啟動服務器，如果不這麼做那也沒關係
    </details>

* FAQ
    1. <details><summary>為甚麼logs\l4d2_mission_manager.log會有一堆錯誤訊息</summary>

        * 分析：這個插件會檢查地圖mission文件，當格式錯誤或者關卡不存在等等，會將錯誤報告寫在logs\l4d2_mission_manager.log
        ![image](https://user-images.githubusercontent.com/12229810/232275149-62919e95-d83b-4aa8-b2c5-8fa7b4202f1f.png) 
        * 原因：Mission文件是決定地圖的關卡順序、名稱、遊戲模式等等，通常是由地圖作者撰寫，但是有的三方作者會亂寫，放飛自我，導致地圖格式不正確等等問題
        * 解決方式法一：所以鍋都是地圖問題，請去跟地圖作者抱怨
        * 解決方式法一：嘗試閱讀錯誤並修改left4dead2\missions.cache\ 的地圖mission文件然後儲存，直到沒有錯誤報告為止
        * 解決方式法三：🟥這份錯誤報告不會對伺服器產生任何影響，可以選擇忽略
    </details>

    2. <details><summary>能否修改地圖順序?</summary>

        * 可以更動以下檔案，地圖順序
            * configs\missioncycle.coop.txt
            * configs\missioncycle.scavenge.txt
            * configs\missioncycle.survival.txt
            * configs\missioncycle.versus.txt
    </details>
        
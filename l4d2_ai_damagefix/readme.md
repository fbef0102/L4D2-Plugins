# Description | 內容
Makes AI SI take (and do) damage like human SI.

> __Note__ <br/>
This Plugin has been discontinued, Use 
<br/>1. [charging_takedamage_patch](/charging_takedamage_patch)
<br/>2. [l4d_ai_hunter_skeet_dmg_fix](https://github.com/fbef0102/L4D1_2-Plugins/tree/master/l4d_ai_hunter_skeet_dmg_fix)


* <details><summary>How does it work?</summary>

	* Human Hunter can be easily killed when pouncing, but AI Hunter can't be easily killed without this plugin
	* Human Charger can be easily killed when charging, but AI Charger can't be easily killed without this plugin
	* After install this plugin, makes AI hunter and charger take same damage like human SI. (Make them easily to be killed)
</details>

* Require | 必要安裝
<br/>None

* <details><summary>ConVar | 指令</summary>

	* cfg\sourcemod\l4d2_ai_damagefix.cfg
		```php
		// Bit flag: Enables plugin features (add together): 1=Skeet pouncing AI hunter, 2=Debuff charging AI charger, 3=Both, 0=off
		l4d2_ai_damagefix_enable "3"
		```
</details>

* <details><summary>Command | 命令</summary>

	None
</details>

* <details><summary>API | 串接</summary>

	```php
	Registers a library name: l4d2_ai_damagefix
	```
</details>

* Apply to | 適用於
	```
	L4D2
	```

* <details><summary>Changelog | 版本日誌</summary>

	* Archived (2024-8-11)
		* This Plugin has been discontinued

	* v1.1h (2024-8-6)
		* Add Library "l4d2_ai_damagefix"

	* v1.0h (2024-2-11)
		* Disable damage fix if hunter get damaged by melee
		* Add cfg

	* v1.1.0
		* Original plugin from [SirPlease/L4D2-Competitive-Rework](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d2_ai_damagefix.sp)
</details>

- - - -
# 中文說明
對AI Hunter與 AI Charger造成的傷害數據跟真人玩家一樣

> __Note__ <br/>
此插件已停止更新，請使用
<br/>1. [charging_takedamage_patch](/charging_takedamage_patch)
<br/>2. [l4d_ai_hunter_skeet_dmg_fix](https://github.com/fbef0102/L4D1_2-Plugins/tree/master/l4d_ai_hunter_skeet_dmg_fix)

* 原理
	* (裝插件之前) 真人扮演的Hunter在飛撲過程中容易被殺死, 但是AI Hunter不容易被殺死，因為官方故意設置傷害機制不同
	* (裝插件之前) 真人扮演的Charger在衝鋒過程中容易被殺死, 但是AI Charger不容易被殺死，因為官方故意設置傷害機制不同
	* (裝插件之後) 對AI Hunter與 AI Charger造成的傷害數據跟真人玩家一樣 (所以他們更容易被殺死)
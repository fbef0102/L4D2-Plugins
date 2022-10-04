In coop/realism, if you died with primary weapon, you will respawn with T1 weapon. Delete datas if hold M60 or mission lost

-Require-
1. [INC] l4d2_weapons: https://github.com/fbef0102/Game-Private_Plugin/blob/main/left4dead2/scripting/include/l4d2_weapons.inc

-ChangeLog-
v1.0
- Original request by Yabi

-Thanks-
jensewe - Offest find

-Detail-
/**
 * Newly-rescued Survivors start with 50 permanent health, a random tier 1 weapon, and a single P220 Pistol. 
 * Their primary tier 1 weapon is determined by what weapons you had when you died:
 * If you died with an assault rifle (Combat Rifle, AK-47, or M16 Assault Rifle) or a submachine gun (normal or silenced), you will respawn with a submachine gun (with a chance for a Silenced Submachine Gun instead in Left 4 Dead 2);
 * If you died with a shotgun (Chrome, Pump, Auto or Combat) or Grenade Launcher, you are given a Pump Shotgun (with a chance for a Chrome Shotgun instead in Left 4 Dead 2);
 * If you died with a Hunting or Sniper Rifle, you will have a 60% chance of getting a submachine gun and a 40% chance of a shotgun.
 * 
 * This plugin tries to fix the following situations
 * 1. If you died with M60, you will respawn with M60 full clip (This is bug)
 * 2. If you died with any weapons and mission lost in coop/realism, you will have T1 weapons after new round starts (Usually happen after changelevel map 2...)
 */

/**
 * L4D2 Windows/Linux
 * CTerrorPlayer,m_knockdownTimer + 100 = Primary weapon ID
 * CTerrorPlayer,m_knockdownTimer + 104 = Primary  ammo
 * CTerrorPlayer,m_knockdownTimer + 108 = Secondary weapon ID
 * CTerrorPlayer,m_knockdownTimer + 112 = Secondary weapon is dual pistol?
 * CTerrorPlayer,m_knockdownTimer + 116 = Secondary weapon non-pistol EHandle
 */

/**
 * Related Official l4d2 cvars
 * survivor_respawn_with_guns               : 1        : , "sv", "launcher" : 0: Just a pistol, 1: Downgrade of last primary weapon, 2: Last primary weapon.
 */

-Convars-
cfg\sourcemod\l4d_death_weapon_respawn_fix.cfg
// 0=Plugin off, 1=Plugin on.
l4d_death_weapon_respawn_fix_enable "1"

-Command-
None

*中文說明*
在戰役與寫實模式當中，如果死亡時有主武器，那麼下次復活的時候會給予T1武器(機槍或散彈槍)
而安裝上這個插件之後會發生以下情況
1. 死亡時有M60主武器，那麼下次復活的時候不再給予M60武器而是給予機槍或散彈槍
2. 死亡時有主武器，滅團重新回合之後不會再給予T1武器 (不影響過關攜帶的武器)



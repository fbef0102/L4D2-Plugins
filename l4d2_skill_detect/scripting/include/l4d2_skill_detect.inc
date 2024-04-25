#if defined  _l4d2_skill_detect_included_
 #endinput
#endif
#define _l4d2_skill_detect_included_

 forward void OnSkeet( int survivor, int vicitm, bool isHunter, bool headshot )

 forward void OnSkeetMelee( int survivor, int vicitm, bool isHunter, bool headshot )
 
 forward void OnSkeetSniper( int survivor, int vicitm, bool isHunter, bool headshot )

 forward void OnSkeetMagnum( int survivor, int vicitm, bool isHunter, bool headshot )

 forward void OnSkeetShotgun( int survivor, int vicitm, bool isHunter, bool headshot )

 forward void OnSkeetGL( int survivor, int vicitm, bool isHunter, bool headshot )

 forward void OnSkeetHurt( int survivor, int vicitm, int damage, bool isOverkill, bool isHunter, bool headshot )
 
 forward void OnSkeetMeleeHurt( int survivor, int vicitm, int damage, bool isOverkill, bool isHunter, bool headshot )

 forward void OnSkeetSniperHurt( int survivor, int vicitm, int damage, bool isOverkill, bool isHunter, bool headshot )

 forward void OnSkeetMagnumHurt( int survivor, int vicitm, int damage, bool isOverkill, bool isHunter, bool headshot )

 forward void OnSkeetShotgunHurt( int survivor, int vicitm, int damage, bool isOverkill, bool isHunter, bool headshot )

 forward void OnHunterDeadstop( int survivor, int hunter )

 forward void OnJocekyDeadstop( int survivor, int joceky )

 forward void OnBoomerPop( int survivor, int boomer, int shoveCount, float timeAlive )

 forward void OnChargerLevel( int survivor, int charger, bool headshot )

 forward void OnChargerLevelHurt( int survivor, int charger, int damage, bool headshot )

 forward void OnWitchCrown( int survivor, int damage )

 forward void OnWitchDrawCrown( int survivor, int damage, int chipdamage )

 forward void OnTongueCut( int survivor, int smoker )

 forward void OnSmokerSelfClear( int survivor, int smoker, bool withShove, bool headshot )

 forward void OnTankRockSkeeted( int survivor, int tank )

 forward void OnTankRockEaten( int tank, int survivor )

 forward void OnHunterHighPounce( int hunter, int victim, int actualDamage, float calculatedDamage, float height, bool bReportedHigh, bool bPlayerIncapped )

 forward void OnJockeyHighPounce( int jockey, int victim, float height, bool bReportedHigh )

 forward void OnDeathCharge( int charger, int victim, float height, float distance, bool wasCarried )

 forward void OnSpecialShoved( int survivor, int infected, int zombieClass )

 forward void OnSpecialClear( int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove, bool headshot )

 forward void OnBoomerVomitLanded( int boomer, int amount )

 forward void OnBunnyHopStreak( int survivor, int streak, float maxVelocity )

 /**
 * @brief Called whenever the survivor trigger the alarm car
 * 
 * @param survivor   the survivor
 * @param infected   the infected if was because the infected, value could be 0
 * @param reason     the reason why alaram was triggered, 0 = CALARM_UNKNOWN, 1 = CALARM_HIT, 2 = CALARM_TOUCHED, 3 = CALARM_EXPLOSION, 4 = CALARM_BOOMER
 *
 * @noreturn
 */
 forward void OnCarAlarmTriggered( int survivor, int infected, int reason )

public SharedPlugin __pl_l4d2_skill_detect =
{
	name = "skill_detect",
	file = "l4d2_skill_detect.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_skill_detect_SetNTVOptional()
{
	
}
#endif
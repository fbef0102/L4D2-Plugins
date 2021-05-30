#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
ConVar hCvarBoomerExposedTimeTolerance;
ConVar hCvarBoomerVomitDelay;

public void Boomer_OnModuleStart() {
	hCvarBoomerExposedTimeTolerance = FindConVar("boomer_exposed_time_tolerance");	
	hCvarBoomerVomitDelay = FindConVar("boomer_vomit_delay");	
	SetConVarFloat(hCvarBoomerExposedTimeTolerance, 10000.0);
	SetConVarFloat(hCvarBoomerVomitDelay, 0.1);
}

public void Boomer_OnModuleEnd() {
	ResetConVar(hCvarBoomerExposedTimeTolerance);
	ResetConVar(hCvarBoomerVomitDelay);
}

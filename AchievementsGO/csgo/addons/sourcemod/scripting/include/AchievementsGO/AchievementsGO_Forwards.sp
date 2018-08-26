public void InitGlobalForwards()
{
	Forward_AllAchievementsLoaded = CreateGlobalForward("AGO_OnAllAchievementsLoaded", ET_Ignore);
	Forward_OnRegisterAchievements = CreateGlobalForward("AGO_OnRegisterAchievements", ET_Ignore);
	Forward_OnAchievementAccomplished = CreateGlobalForward("AGO_OnAchievementAccomplished", ET_Ignore, Param_Cell, Param_Cell);
}

/*public void SendForwardAchievementAccomplished(int client, int IdOfAchievement)
{
	int pluginID = GetArrayCell(AchievementPluginID, GetAchievementPosById(IdOfAchievement));
	Handle plugin = view_as<Handle>(pluginID);
	
	Function func = GetFunctionByName(plugin, "AGO_OnAchievementAccomplished");

	if (func == INVALID_FUNCTION)	return;

	Call_StartFunction(plugin, func);
	Call_PushCell(client);
	Call_PushCell(IdOfAchievement);
	Call_Finish();	
}*/

public void SendForwardAchievementAccomplished(int client, int IdOfAchievement)
{
	Call_StartForward(Forward_OnAchievementAccomplished);
	Call_PushCell(client);
	Call_PushCell(IdOfAchievement);
	Call_Finish();
}

public void SendForwardOnRegisterAchievements()
{
	Call_StartForward(Forward_OnRegisterAchievements);
	Call_Finish();
}

public void SendForwardAllAchievementsLoaded()
{
	Call_StartForward(Forward_AllAchievementsLoaded);
	Call_Finish();
}
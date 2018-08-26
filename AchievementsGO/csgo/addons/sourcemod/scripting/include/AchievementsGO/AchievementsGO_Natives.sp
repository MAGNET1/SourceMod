public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("AchievementsGO");
	
	CreateNative("AGO_AddAchievement", AddAchievement);
	
	CreateNative("AGO_AddPoint", AddPoint);
	CreateNative("AGO_AddPoints", AddPoints);
	CreateNative("AGO_RemovePoint", RemovePoint);
	CreateNative("AGO_RemovePoints", RemovePoints);
	CreateNative("AGO_ResetPoints", ResetPoints);
	
	CreateNative("AGO_GetNameByIndex", GetNameByIndex);
	CreateNative("AGO_GetIndexByName", GetIndexByName);
	CreateNative("AGO_GetDescriptionByIndex", GetDescriptionByIndex);
	CreateNative("AGO_GetCategoryByIndex", GetCategoryByIndex);
	
	CreateNative("AGO_GetAchievementProgress", GetAchievementProgress);
	CreateNative("AGO_IsAchievementCompleted", IsAchievementCompleted);
	CreateNative("AGO_GetAmountOfAchievements", GetAmountOfAchievements);
	CreateNative("AGO_GetAchievementValue", GetAchievementValue);
	
	CreateNative("AGO_AreTablesCreated", AreTablesCreated);
	
	return APLRes_Success;
}

public int AreTablesCreated(Handle plugin, int numParams)
{
	if (tablesCreated == 3)	return 1;
	return 0;
}

public int AddAchievement(Handle plugin, int numParams)
{	
	int PluginID = view_as<int>(plugin);
	
	char Name[ACHIEVEMENT_MAX_NAME_LENGTH];
	char Description[ACHIEVEMENT_MAX_DESCRIPTION_LENGTH];
	char Category[ACHIEVEMENT_MAX_DESCRIPTION_LENGTH];
	
	GetNativeString(1, Name, ACHIEVEMENT_MAX_NAME_LENGTH);
	if (IsStringContainingRestrictedCharacters(Name))	return -1;
	
	GetNativeString(2, Description, ACHIEVEMENT_MAX_DESCRIPTION_LENGTH);
	if (IsStringContainingRestrictedCharacters(Description))	return -1;
	
	GetNativeString(3, Category, ACHIEVEMENT_MAX_CATEGORY_LENGTH);
	if (IsStringContainingRestrictedCharacters(Category))	return -1;
	
	int Value = GetNativeCell(4);
	
	DataPack NewAchievementData = new DataPack();
	NewAchievementData.WriteString(Name);
	NewAchievementData.WriteString(Description);
	NewAchievementData.WriteString(Category);
	NewAchievementData.WriteCell(Value);
	NewAchievementData.WriteCell(PluginID);
	
	int IdOfNewAchievement = SQL_LoadAchievement(NewAchievementData);
	
	if (IdOfNewAchievement != -1)
	{
		AmountOfActiveAchievements++;
		AddCategoryToList(Category);
	}
	
	return IdOfNewAchievement;
}
public void AddCategoryToList(char[] tab)
{
	if (StrEqual(tab, ""))	return;
	
	char TempBuffer[ACHIEVEMENT_MAX_CATEGORY_LENGTH];
	
	for (int i = 0; i < GetArraySize(CategoryList);i++)
	{
		GetArrayString(CategoryList, i, TempBuffer, sizeof(TempBuffer));
		if (StrEqual(TempBuffer, tab))	return;
	}
	
	PushArrayString(CategoryList, tab);
}
public bool IsStringContainingRestrictedCharacters(char[] tab)
{
	if ( (StrContains(tab, "'") != -1) || (StrContains(tab, "|") != -1) )	return true;
	return false;
}

// @@ Add/Remove points

public int AddPoint(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int IdOfAchievement = GetNativeCell(2);
	return UpdatePoints(client, IdOfAchievement, 1);
}

public int AddPoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int IdOfAchievement = GetNativeCell(2);
	int amount = GetNativeCell(3);
	
	return UpdatePoints(client, IdOfAchievement, amount);
}

public int RemovePoint(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int IdOfAchievement = GetNativeCell(2);
	
	return UpdatePoints(client, IdOfAchievement, -1);
}

public int RemovePoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int IdOfAchievement = GetNativeCell(2);
	int amount = GetNativeCell(3);
	
	return UpdatePoints(client, IdOfAchievement, -amount);
}

public int ResetPoints(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int IdOfAchievement = GetNativeCell(2);
	
	if (IdOfAchievement == NOT_FOUND)	return -1;
	
	int PosOfAchievement = FindAchievementPosInPlayerArray(client, IdOfAchievement);
	
	if (!IsClientConnected(client) || PosOfAchievement == NOT_FOUND)	return -1;
	
	SetArrayCell(Player_AchievementProgress[client], PosOfAchievement, 0);
	
	return 0;
}

public int UpdatePoints(int client, int IdOfAchievement, int amount)
{
	if (IdOfAchievement == NOT_FOUND)	return -1;
	
	int PosOfAchievement = FindAchievementPosInPlayerArray(client, IdOfAchievement);
	int Value = GetArrayCell(AchievementValue, GetAchievementPosById(IdOfAchievement));
	
	if (!IsClientInGame(client) || PosOfAchievement == NOT_FOUND)	return -1;
	
	int CurrentProgress = GetArrayCell(Player_AchievementProgress[client], PosOfAchievement);
	
	if (IsAchievementAlreadyAccomplished(CurrentProgress, Value))	return CurrentProgress;
	
	int NewProgress = CurrentProgress + amount;
	
	// Achievement accomplished
	if(NewProgress >= Value)
	{
		PlaySound_Accomplished(client);
		AccomplishedAchievements[client]++;
		NewProgress = Value;
		SetArrayCell(Player_AchievementProgress[client], PosOfAchievement, NewProgress);
		UpdatePlayerData(client); //AchievementsGO_SQLUpdate.sp
		InformPlayersAchievementAccomplished(client, GetAchievementPosById(IdOfAchievement));
		SendForwardAchievementAccomplished(client, IdOfAchievement); // AchievementsGO_Forwards.sp
	}
	SetArrayCell(Player_AchievementProgress[client], PosOfAchievement, NewProgress);
	
	return NewProgress;
}

// @@ Forward stuff

public int IsAchievementAlreadyAccomplished(int Progress, int Value)
{
	return Progress == Value;
}

public void InformPlayersAchievementAccomplished(int client, int AchievementPos)
{
	char Name[MAX_NAME_LENGTH];
	char AchievementNamee[129];
	GetArrayString(AchievementName, AchievementPos, AchievementNamee, sizeof(AchievementNamee));
	GetClientName(client, Name, sizeof(Name));
	//GoPrint(client, "You have accomplished achievement{green} %s{default}! Congratulations!", AchievementNamee);
	GoPrint(ALL, "Player{green} %s{default} has just accomplished achievement{firered} %s{default}!", Name, AchievementNamee);
	
	PrintHintText(client, "<font color=\"#ff0000\">Ukonczono Achievement</font><font color=\"#00ff00\"> %s!</font>", AchievementNamee);
}

public int FindAchievementPosInPlayerArray(int client, int IdOfAchievement)
{
	for (int i = 0; i < GetArraySize(Player_AchievementID[client]);i++)
	{
		if (GetArrayCell(Player_AchievementID[client], i) == IdOfAchievement)	return i;
	}
	return NOT_FOUND;
}

// @@ Information retrieval

public int GetIndexByName(Handle plugin, int numParams)
{
	char Name[256];
	GetNativeString(1, Name, sizeof(Name));
	char ArrayName[256];
	
	for (int i = 0; i < AmountOfActiveAchievements;i++)
	{
		GetArrayString(AchievementName, i, ArrayName, sizeof(ArrayName));
		if (StrEqual(Name, ArrayName))	return i;
	}
	return -1;
}

public int GetNameByIndex(Handle plugin, int numParams)
{
	int IdOfAchievement = GetNativeCell(1);
	
	if (IdOfAchievement == NOT_FOUND)	return -1;
	
	int len = GetNativeCell(3);
	char Name[256];
	int AchievementPos = GetAchievementPosById(IdOfAchievement);
	
	if(AchievementPos != NOT_FOUND)	GetArrayString(AchievementName, AchievementPos, Name, sizeof(Name));
	else Format(Name, sizeof(Name), "NOT FOUND");
	
	SetNativeString(2, Name, len);
	
	if (AchievementPos == NOT_FOUND)	return -1;
	return 0;
}

public int GetDescriptionByIndex(Handle plugin, int numParams)
{
	int IdOfAchievement = GetNativeCell(1);
	
	if (IdOfAchievement == NOT_FOUND)	return -1;
	
	int len = GetNativeCell(3);
	char Name[256];
	int AchievementPos = GetAchievementPosById(IdOfAchievement);
	
	if(AchievementPos != NOT_FOUND)	GetArrayString(AchievementDescription, AchievementPos, Name, sizeof(Name));
	else Format(Name, sizeof(Name), "NOT FOUND");
	
	SetNativeString(2, Name, len);
	
	if (AchievementPos == NOT_FOUND)	return -1;
	return 0;
}

public int GetCategoryByIndex(Handle plugin, int numParams)
{
	int IdOfAchievement = GetNativeCell(1);
	
	if (IdOfAchievement == NOT_FOUND)	return -1;
	
	int len = GetNativeCell(3);
	char Name[256];
	int AchievementPos = GetAchievementPosById(IdOfAchievement);
	
	if(AchievementPos != NOT_FOUND)	GetArrayString(AchievementCategory, AchievementPos, Name, sizeof(Name));
	else Format(Name, sizeof(Name), "NOT FOUND");
	
	SetNativeString(2, Name, len);
	
	if (AchievementPos == NOT_FOUND)	return -1;
	return 0;
}

public int GetAchievementProgress(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int IdOfAchievement = GetNativeCell(2);
	
	if (IdOfAchievement == NOT_FOUND)	return -1;

	int PlayerAchievementPos = FindAchievementPosInPlayerArray(client, IdOfAchievement);
	
	if (PlayerAchievementPos == NOT_FOUND)	return -1;
	
	int progress = GetArrayCell(Player_AchievementProgress[client], PlayerAchievementPos);
	
	return progress;
	
}

public int IsAchievementCompleted(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int IdOfAchievement = GetNativeCell(2);
	
	if (IdOfAchievement == NOT_FOUND)	return -1;

	int PlayerAchievementPos = FindAchievementPosInPlayerArray(client, IdOfAchievement);
	int AchievementPos = GetAchievementPosById(IdOfAchievement);
	
	if (PlayerAchievementPos == NOT_FOUND || AchievementPos == NOT_FOUND)	return -1;
	
	int progress = GetArrayCell(Player_AchievementProgress[client], PlayerAchievementPos);
	int Value = GetArrayCell(AchievementValue, AchievementPos);
	
	if (progress == Value)	return 1;
	return 0;
	
}

public int GetAmountOfAchievements(Handle plugin, int numParams)
{
	return AmountOfActiveAchievements;
}

public int GetAchievementValue(Handle plugin, int numParams)
{
	int IdOfAchievement = GetNativeCell(2);
	
	if (IdOfAchievement == NOT_FOUND)	return -1;
	
	int AchievementPos = GetAchievementPosById(IdOfAchievement);
	
	if (AchievementPos != NOT_FOUND)	return GetArrayCell(AchievementValue, AchievementPos);
	return -1;
}
// @@ Loading Achievement ID, and eventually inserting if doesn't exist
public int SQL_LoadAchievement(DataPack NewAchievementData) // AchievementsGO_Natives.sp
{
	if (!IsConnectionEstablished())	return -1;

	char Name[ACHIEVEMENT_MAX_NAME_LENGTH];

	NewAchievementData.Reset();
	NewAchievementData.ReadString(Name, ACHIEVEMENT_MAX_NAME_LENGTH);

	char buffer[256];
	FormatAchievementLoadQuery(buffer, sizeof(buffer), Name);
	SQL_LockDatabase(DB);
	DBResultSet query = SQL_Query(DB, buffer);
	if (query == null)
	{
		char error[255];
		SQL_GetError(DB, error, sizeof(error));
		LogMessage("Server couldn't get the achievement data (from plugin)! Error: %s", error);
		SQL_UnlockDatabase(DB);
		return -1;
	}
	SQL_UnlockDatabase(DB);

	int IdOfNewAchievement;

	// Such Achievement is not in the Database - we have to create one
	if(query.RowCount == 0)
	{
		AddAchievementToDatabase(NewAchievementData);
		return SQL_LoadAchievement(NewAchievementData);
	}

	while(SQL_FetchRow(query))
	{
		IdOfNewAchievement = SQL_FetchInt(query, 0);
	}

	bool canAdd = true;

	for (int i = 0; i < AchievementID.Length; i++) {
		if (GetArrayCell(AchievementID, i) != IdOfNewAchievement)   continue;

		canAdd = false;
		char buffered[512];
		NewAchievementData.ReadString(buffered, sizeof(buffered));
		SetArrayString(AchievementDescription, i, buffered);
		NewAchievementData.ReadString(buffered, sizeof(buffered));
		SetArrayString(AchievementCategory, i, buffered);
		SetArrayCell(AchievementValue, i, NewAchievementData.ReadCell());
	}

	if (canAdd == true)	AddAchievementToArrays(IdOfNewAchievement, NewAchievementData);

	UpdateAchievementInfo(IdOfNewAchievement, NewAchievementData); // TODO: Check if works

	return IdOfNewAchievement;
}

public void FormatAchievementLoadQuery(char[] query, size, char[] name)
{
	Format(query, size, "SELECT `ID` FROM `Achievements` WHERE `Name`='%s'", name);
}

public void AddAchievementToDatabase(DataPack NewAchievementData)
{
	char Name[ACHIEVEMENT_MAX_NAME_LENGTH];
	char Description[ACHIEVEMENT_MAX_DESCRIPTION_LENGTH];
	char Category[ACHIEVEMENT_MAX_CATEGORY_LENGTH];
	int Value;

	NewAchievementData.Reset();
	NewAchievementData.ReadString(Name, ACHIEVEMENT_MAX_NAME_LENGTH);
	NewAchievementData.ReadString(Description, ACHIEVEMENT_MAX_DESCRIPTION_LENGTH);
	NewAchievementData.ReadString(Category, ACHIEVEMENT_MAX_CATEGORY_LENGTH);
	Value = NewAchievementData.ReadCell();


	char buffer[256];
	FormatAchievementInsertQuery(buffer, sizeof(buffer), Name, Description, Category, Value);
	SQL_LockDatabase(DB);
	if(!SQL_FastQuery(DB, buffer))
	{
		char error[255];
		SQL_GetError(DB, error, sizeof(error));
		LogMessage("Server couldn't get the achievement data (from plugin)! Error: %s", error);
		SQL_UnlockDatabase(DB);
		return;
	}
	SQL_UnlockDatabase(DB);
}

public void FormatAchievementInsertQuery(char[] query, size, char[] Name, char[] Description, char[] Category, int Value)
{
	Format(query, size, "INSERT INTO `Achievements`(`Name`,`Description`,`Category`,`Value`) VALUES('%s','%s','%s',%d)", Name, Description, Category, Value);
}

public void AddAchievementToArrays(int IdOfNewAchievement, DataPack NewAchievementData)
{
	char Name[ACHIEVEMENT_MAX_NAME_LENGTH];
	char Description[ACHIEVEMENT_MAX_DESCRIPTION_LENGTH];
	char Category[ACHIEVEMENT_MAX_CATEGORY_LENGTH];
	int Value;
	int PluginID;

	NewAchievementData.Reset();
	NewAchievementData.ReadString(Name, ACHIEVEMENT_MAX_NAME_LENGTH);
	NewAchievementData.ReadString(Description, ACHIEVEMENT_MAX_DESCRIPTION_LENGTH);
	NewAchievementData.ReadString(Category, ACHIEVEMENT_MAX_CATEGORY_LENGTH);
	Value = NewAchievementData.ReadCell();
	PluginID = NewAchievementData.ReadCell();

	PushArrayCell(AchievementID, IdOfNewAchievement);
	PushArrayString(AchievementName, Name);
	PushArrayString(AchievementDescription, Description);
	PushArrayString(AchievementCategory, Category);
	PushArrayCell(AchievementValue, Value);
	PushArrayCell(AchievementPluginID, PluginID);
}

public void UpdateAchievementInfo(int IdOfNewAchievement, DataPack NewAchievementData)
{
	char Name[ACHIEVEMENT_MAX_NAME_LENGTH];
	char Description[ACHIEVEMENT_MAX_DESCRIPTION_LENGTH];
	char Category[ACHIEVEMENT_MAX_CATEGORY_LENGTH];
	int Value;

	NewAchievementData.Reset();
	NewAchievementData.ReadString(Name, ACHIEVEMENT_MAX_NAME_LENGTH);
	NewAchievementData.ReadString(Description, ACHIEVEMENT_MAX_DESCRIPTION_LENGTH);
	NewAchievementData.ReadString(Category, ACHIEVEMENT_MAX_CATEGORY_LENGTH);
	Value = NewAchievementData.ReadCell();

	char FormatQuery[512];
	FormatUpdateAchievementQuery(IdOfNewAchievement, FormatQuery, Name, Description, Category, Value);
	DB.Query(UpdateAchievementResults, FormatQuery, NewAchievementData, DBPrio_Low);
}

public void FormatUpdateAchievementQuery(int IdOfNewAchievement, char[] FormatBuffer, char[] Name, char[] Description, char[] Category, int Value)
{
	Format(FormatBuffer, 511, "UPDATE `Achievements` SET `Name`='%s', `Description`='%s', `Category`='%s', `Value`=%d WHERE `ID`=%d", Name, Description, Category, Value, IdOfNewAchievement);
}

public void UpdateAchievementResults(Database db, DBResultSet results, const char[] error, DataPack NewAchievementData)
{
	CloseHandle(NewAchievementData);

	if (db == null || results == null)
	{
		LogMessage("Could not update Achievement informations! Error: %s", error);
		return;
	}
}
public void ClearPlayerInfo(int client)
{
	PlayerID[client] = 0;
	AccomplishedAchievements[client] = 0;
	ClearArray(Player_AchievementID[client]);
	ClearArray(Player_AchievementProgress[client]);
}

public void LoadPlayerID(int client)
{
	if (!IsConnectionEstablished())
		return;
	if (client == SERVER || !IsClientConnected(client))
		return;
	if(!AreAllTablesCreated())
	{
		CreateTimer(0.3, WaitLoadPlayerID, client);
		return;
	}
	LogMessage("LoadPlayerID - %N", client);
	PlayerID[client] = GetSteamAccountID(client);

	LoadPlayerAchievements(client);
}
public Action WaitLoadPlayerID(Handle timer, int client)
{
	if(IsClientConnected(client))	LoadPlayerID(client);
}

public void InsertPlayerIdToDatabase(int client)
{
	if (!IsClientConnected(client))	return;

	char query[512];
	FormatInsertClientIdQuery(query, client);
	DB.Query(ProcessInsertPlayerIdResults, query, GetClientUserId(client), DBPrio_Low);
}

public void FormatInsertClientIdQuery(char[] query, int client)
{
	Format(query, 511, "INSERT INTO `Players` (`PlayerID`) VALUES (%d)", GetSteamAccountID(client));
}

public void ProcessInsertPlayerIdResults(Database db, DBResultSet results, const char[] error, int clientUserId)
{
	if (db == null)
	{
		LogMessage("Could not insert PlayerID! Error: %s", error);
		return;
	}

	int client = GetClientOfUserId(clientUserId);

	if (!client)	return;

	// now a player has PlayerID - it's time to obtain it....
	LoadPlayerID(client);
}


// @@ Load player Achievements

public void LoadPlayerAchievements(int client)
{
	if (!IsConnectionEstablished())	return;

	if (client == SERVER || !IsClientConnected(client))	return;

	int clientUserId = GetClientUserId(client);

	if (!AreAllAchievementsLoaded)
	{
		Wait(clientUserId);
		return;
	}

	if (HasDisconnectedInTheMeantime(clientUserId))	return;

	char query[512];
	FormatAchievementsSelectQueryFixed(query, client);
	DB.Query(ProcessPlayerAchievementResults, query, clientUserId);
}

public bool HasDisconnectedInTheMeantime(int clientUserId)
{
	int client = GetClientOfUserId(clientUserId);
	return client == 0;
}

public void Wait(int clientUserId)
{
	CreateTimer(0.2, MakeDelay, clientUserId);
}

public Action MakeDelay(Handle timer, int clientUserId)
{
	int client = GetClientOfUserId(clientUserId);

	if(client)	LoadPlayerAchievements(client);
}

public void FormatAchievementsSelectQueryFixed(char[] query, int client)
{
	int ID = GetArrayCell(AchievementID, i);
	Format(query, 511, "SELECT * FROM `Players` WHERE `PlayerID`=%d", GetSteamAccountID(client));
}


public void ProcessPlayerAchievementResults(Database db, DBResultSet results, const char[] error, int clientUserId)
{
	if (db == null)
	{
		LogMessage("Could not retrieve player achievement informations! Error: %s", error);
		return;
	}

	if (HasDisconnectedInTheMeantime(clientUserId))
	{
		return;
	}

	int client = GetClientOfUserId(clientUserId);
	int achievementID;
	int progress;
	int ID;

	while(SQL_FetchRow(results)) {
		achievementID = SQL_FetchInt(results, 1);
		progress = SQL_FetchInt(results, 2);
		ID = GetArrayCell(AchievementID, achievementID);

		PushArrayCell(Player_AchievementID[client], ID);
		PushArrayCell(Player_AchievementProgress[client], progress);
	}

	for (int i = 0; i < GetArraySize(AchievementName);i++) {
		ID = GetArrayCell(AchievementID, achievementID);

		if(FindValueInArray(Player_AchievementID[client], ID) > -1) {
			continue;
		}

		DataPack ClientAndIndex = new DataPack();
		ClientAndIndex.WriteCell(clientUserId);
		ClientAndIndex.WriteCell(i);
		InsertPlayerAchievementToDatabase(ClientAndIndex);
	}
}

public void InsertPlayerAchievementToDatabase(DataPack ClientAndIndex)
{
	ClientAndIndex.Reset();
	int clientUserId = ClientAndIndex.ReadCell();
	int i = ClientAndIndex.ReadCell();
	CloseHandle(ClientAndIndex);

	if (HasDisconnectedInTheMeantime(clientUserId))	return;

	int client = GetClientOfUserId(clientUserId);

	int ID = GetArrayCell(AchievementID, i);

	char query[512];
	FormatPlayerInsertionQuery(query, client, i);
	DB.Query(ProcessPlayerInsertionResults, query, _, DBPrio_Low);

	PushArrayCell(Player_AchievementID[client], ID);
	PushArrayCell(Player_AchievementProgress[client], 0);
}

public void FormatPlayerInsertionQuery(char[] query, int client, int i)
{
	int ID = GetArrayCell(AchievementID, i);
	Format(query, 511, "INSERT INTO `Players`(`PlayerID`,`AchievementID`,`Progress`) VALUES(%d,%d,0)", PlayerID[client], ID);
}

public void ProcessPlayerInsertionResults(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not insert new achievement row! Error: %s", error);
		return;
	}
}

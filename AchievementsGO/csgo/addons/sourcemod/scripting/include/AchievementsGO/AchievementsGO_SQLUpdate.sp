public void UpdatePlayerData(int client)
{
	int clientUserId = GetClientUserId(client);
	
	if (!IsClientConnected(client) || !AreAllAchievementsLoaded || PlayerID[client] == NOT_ASSIGNED)	return;
	
	UpdatePlayerInformations(clientUserId);
	UpdateAllAchievements(clientUserId);
}


public void UpdatePlayerInformations(int clientUserId)
{
	if (HasDisconnectedInTheMeantime(clientUserId))	return;
	
	int client = GetClientOfUserId(clientUserId);
	
	char query[512];
	FormatPlayerInfoUpdateQuery(query, client);
	DB.Query(CheckPlayerInfoUpdateResults, query, _, DBPrio_High);	
}

public void FormatPlayerInfoUpdateQuery(char[] query, int client)
{
	char Name[MAX_NAME_LENGTH];
	char SteamIdBuffer[128];
	GetClientName(client, Name, sizeof(Name));
	GetClientAuthId(client, AuthId_Steam2, SteamIdBuffer, sizeof(SteamIdBuffer));
	Format(query, 511, "UPDATE `PlayerID` SET `Name`='%s',`AccomplishedAchievements`=%d WHERE `SteamID`='%s'", Name, AccomplishedAchievements[client], SteamIdBuffer);
}

public void CheckPlayerInfoUpdateResults(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not update player informations! Error: %s", error);
		return;
	}
}

public void UpdateAllAchievements(int clientUserId)
{
	int client = GetClientOfUserId(clientUserId);
	
	if (!client)	return;
	
	char query[512];
	for (int i = 0; i < GetArraySize(Player_AchievementID[client]);i++)
	{
		if (HasDisconnectedInTheMeantime(clientUserId))	return; // AchievementGO_SQLLoadData.sp
		
		FormatAchievementsUpdateQuery(query, client, i);
		DB.Query(CheckPlayerAchievementUpdateResults, query, _, DBPrio_High);
	}	
}

public void FormatAchievementsUpdateQuery(char[] query, int client, int i)
{
	int ID = GetArrayCell(Player_AchievementID[client], i);
	int CurrentProgress = GetArrayCell(Player_AchievementProgress[client], i);
	Format(query, 511, "UPDATE `Players` SET `Progress`=%d WHERE `AchievementID`=%d", CurrentProgress, ID);	
}

public void CheckPlayerAchievementUpdateResults(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not update player achievement informations! Error: %s", error);
		return;
	}
}
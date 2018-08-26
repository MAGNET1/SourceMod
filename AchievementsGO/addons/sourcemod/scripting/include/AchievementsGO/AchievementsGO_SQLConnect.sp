public void SQL_InitConnection()
{
	SQL_ConnectToDB();
	CreateTimer(1.0, DoTheRest);
}

public Action DoTheRest(Handle timer)
{
	SQL_Create_Achievements_Table();
	SQL_Create_Players_Table();
	SQL_Create_PlayerID_Table();
}

public void SQL_ConnectToDB()
{
	char sError[512];
	DB = SQLite_UseDatabase("AchievementsGO",sError,sizeof(sError));
	
	SQL_CheckIfConnected(sError);
}

public void SQL_CheckIfConnected(char[] sError)
{
	if (DB == null)
	{
		LogMessage("Could not connect to the DataBase! Error: %s", sError);
	}
	else	IsConnectionEstablished = true;
}

// @@ Creating Achievements table
public void SQL_Create_Achievements_Table()
{
	if(IsConnectionEstablished)
	{
		char query[512];
		FormatAchievementsQuery(query);
		DB.Query(CheckIf_Achievements_QueryPassed, query, _, DBPrio_High);
	}
}

public void FormatAchievementsQuery(char[] query)
{
	Format(query, 511, "CREATE TABLE IF NOT EXISTS `Achievements` (`ID`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,`Name`	TEXT NOT NULL,`Description`	TEXT NOT NULL,`Category`	TEXT,`Value`	INTEGER NOT NULL); ");	
}
public void CheckIf_Achievements_QueryPassed(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not create achievements table! Error: %s", error);
	}
	
	tablesCreated++;
	if (AreAllTablesCreated())	SendForwardOnRegisterAchievements();
}

// @@ Creating players table

public void SQL_Create_Players_Table()
{
	if(IsConnectionEstablished)
	{
		char query[512];
		FormatPlayersQuery(query);
		DB.Query(CheckIf_Players_QueryPassed, query, _, DBPrio_High);
	}
}

public void FormatPlayersQuery(char[] query)
{
	Format(query, 511, "CREATE TABLE IF NOT EXISTS `Players` (`PlayerID`	INTEGER NOT NULL,`AchievementID`	INTEGER NOT NULL,`Progress`	INTEGER NOT NULL,UNIQUE(`PlayerID`,`AchievementID`)); ");	
}
public void CheckIf_Players_QueryPassed(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not create players table! Error: %s", error);
	}
	
	tablesCreated++;
	if (AreAllTablesCreated())	SendForwardOnRegisterAchievements();
}

// @@ Creating PlayerID table - containing a client's unique ID-SteamID pair

public void SQL_Create_PlayerID_Table()
{
	if(IsConnectionEstablished)
	{
		char query[512];
		FormatPlayerIdTableQuery(query);
		DB.Query(CheckIf_PlayerIdTable_QueryPassed, query, _, DBPrio_High);
	}
}

public void FormatPlayerIdTableQuery(char[] query)
{
	Format(query, 511, "CREATE TABLE IF NOT EXISTS `PlayerID` (`ID`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,`SteamID`	TEXT NOT NULL UNIQUE,`Name`	TEXT NOT NULL,`AccomplishedAchievements` INT NOT NULL); ");	
}
public void CheckIf_PlayerIdTable_QueryPassed(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not create PlayerID table! Error: %s", error);
	}
	
	tablesCreated++;
	if (AreAllTablesCreated())	SendForwardOnRegisterAchievements();
}

public bool AreAllTablesCreated()
{
	return tablesCreated == 3;
}
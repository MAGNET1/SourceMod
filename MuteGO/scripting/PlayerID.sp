#pragma semicolon 1

#include <sourcemod>

int PlayerID[MAXPLAYERS];

bool tablesCreated = false;

Database DB;

Handle Forward_PlayerIdGranted;

public Plugin myinfo =
{
    name = "PlayerID",
    author = "MAGNET | YouTube: Koduj z Magnetem",
    description = "Simple player authentication by SteamID",
    version = "0.1",
    url = "http://go-code.pl/"
};

public OnPluginStart()
{
	Forward_PlayerIdGranted = CreateGlobalForward("OnPlayerIdGranted", ET_Ignore, Param_Cell, Param_Cell);
	
	SQL_InitConnection();
}

public void OnClientAuthorized(int client, const char[] auth)
{
	AssignPlayerID(client);
}

public void OnClientDisconnect_Post(int client)
{
	PlayerID[client] = 0;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("PlayerID");
	
	CreateNative("GetPlayerID", GetPlayerID);
	CreateNative("GetClientByPlayerID", GetClientByPlayerID);
	
}

// @@ assigning stuff

public void AssignPlayerID(int client)
{
	if(!tablesCreated)
	{
		CreateTimer(0.1, RetryAssigning, client);
		PrintToServer("Tables hasn't been created! They might be in a second!");
		return;
	}
	
	char SteamIdBuffer[128];
	GetClientAuthId(client, AuthId_Steam2, SteamIdBuffer, sizeof(SteamIdBuffer));
	
	char query[512];
	Format(query, sizeof(query), "SELECT `ID` FROM `PlayerID` WHERE `SteamID`='%s'", SteamIdBuffer);
	DB.Query(CheckIfPlayerExists, query, GetClientUserId(client), DBPrio_High);
}

public Action RetryAssigning(Handle timer, int client)
{
	AssignPlayerID(client);
}

public void CheckIfPlayerExists(Database db, DBResultSet results, const char[] error, int clientUserId)
{
	if (db == null)
	{
		LogMessage("Could not create PlayerID table! Error: %s", error);
	}
	
	int client = GetClientOfUserId(clientUserId);
	
	if (!client)	return;
	
	if(results.RowCount == 0)
	{
		InsertPlayerIdToDatabase(client);
		return;
	}
	
	while(SQL_FetchRow(results))
	{
		PlayerID[client] = SQL_FetchInt(results, 0);
	}
	
	Call_StartForward(Forward_PlayerIdGranted);
	Call_PushCell(client);
	Call_PushCell(PlayerID[client]);
	Call_Finish();
	
}
public void InsertPlayerIdToDatabase(int client)
{
	if (!IsClientConnected(client))	return;
	
	char query[512];
	FormatInsertClientIdQuery(query, client);
	DB.Query(ProcessInsertPlayerIdResults, query, GetClientUserId(client), DBPrio_High);
}

public void FormatInsertClientIdQuery(char[] query, int client)
{
	char SteamIdBuffer[128];
	GetClientAuthId(client, AuthId_Steam2, SteamIdBuffer, sizeof(SteamIdBuffer));
	Format(query, 511, "INSERT INTO `PlayerID`(`SteamID`) VALUES('%s')", SteamIdBuffer);
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
	AssignPlayerID(client);
}

/////// @@ SQL Init

public void SQL_InitConnection()
{
	char sError[512];
	DB = SQLite_UseDatabase("PlayerID",sError,sizeof(sError));
	
	if (DB == null)
	{
		LogMessage("Could not connect to the DataBase! Error: %s", sError);
	}
	
	char query[512];
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `PlayerID` (`ID`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,`SteamID`	TEXT NOT NULL UNIQUE); ");	
	DB.Query(CheckIfTableCreated, query, _, DBPrio_High);
}

public void CheckIfTableCreated(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not create PlayerID table! Error: %s", error);
	}
	
	tablesCreated = true;
}

//// @@ natives

public int GetPlayerID(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	return PlayerID[client];
}

public int GetClientByPlayerID(Handle plugin, int numParams)
{
	int ID = GetNativeCell(1);
	
	for (int i = 0; i < MAXPLAYERS;i++)
	{
		if (!IsClientConnected(i))	continue;
		
		if (PlayerID[i] == ID)	return i;
	}
	
	return -1;
}
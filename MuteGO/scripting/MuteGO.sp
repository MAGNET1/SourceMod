#include <sourcemod>
#include <sdktools>
#include <PlayerID>
#include <clientprefs>
#include <colors>

#define TAG "\x03[MuteGO]\x01"
#define ALL -1
#define MANAGE 0
#define SHOW 1

Database DB

bool IsInDatabase[MAXPLAYERS];

int Mute_Mutation[MAXPLAYERS];
int Mute_Rude[MAXPLAYERS];

int PlayerChoice_Mutation[MAXPLAYERS];
int PlayerChoice_Rude[MAXPLAYERS];

bool DependenciesError=false;
bool tablesCreated=false;

char ColorsName[][] =  { "{default}", "{darkred}", "{purple}", "{green}", "{lightgreen}", "{mediumgreen}", "{lightred}", "{lightpurple}", "{yellow}", "{greyblue}", "{blue}", "{violet}", "{firered}" };
char ColorsTag[][] =  { "\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x0A", "\x0C", "\x0E", "\x0F" };

Handle Cookie_Mutation;
Handle Cookie_Rude;

public Plugin myinfo =
{
    name = "MuteGO",
    author = "MAGNET | YouTube: Koduj z Magnetem",
    description = "Allows admin to mark players who have no mutation or behave rudely. These can be muted by each player",
    version = "0.2",
    url = "http://go-code.pl/"
};

public void OnPluginStart()
{
	SQL_InitConnection();
	RegConsoleCmd("sm_mg", MainMenu);
	
	Cookie_Mutation = RegClientCookie("MuteGO_Mutation", "Mute players without mutation", CookieAccess_Protected);
	Cookie_Rude = RegClientCookie("MuteGO_Mutation", "Mute players considered as rude", CookieAccess_Protected);
	
	LoadTranslations("mutego.phrasesFinal");
}

public void OnClientCookiesCached(int client)
{
 	char sCookieValue[12];
 	
	GetClientCookie(client, Cookie_Mutation, sCookieValue, sizeof(sCookieValue));
	PlayerChoice_Mutation[client] = StringToInt(sCookieValue);
	
	GetClientCookie(client, Cookie_Rude, sCookieValue, sizeof(sCookieValue));
	PlayerChoice_Rude[client] = StringToInt(sCookieValue);
	
	UpdateMuteStatePlayer(client);
}

public void OnPlayerIdGranted(int client, int ID)
{
	LoadPlayerData(client);
}

public void OnClientDisconnect(int client)
{
	if(IsInDatabase[client])
	{
		if (!Mute_Mutation[client] && !Mute_Rude[client])	RemovePlayerFromDatabase(client);
		else UpdatePlayerData(client);
	}
	else
	{
		if (Mute_Mutation[client] || Mute_Rude[client])	InsertPlayerToDatabase(client);
	}
	
	Mute_Mutation[client] = 0;
	Mute_Rude[client] = 0;
	IsInDatabase[client] = false;
	
	UpdateMuteStateAll();
}

// @@ SQL Stuff
public void SQL_InitConnection()
{
	char sError[512];
	DB = SQLite_UseDatabase("MuteGO",sError,sizeof(sError));
	
	if (DB == null)
	{
		LogMessage("Could not connect to the DataBase! Error: %s", sError);
		DependenciesError = true;
		return;
	}
	
	char query[512];
	Format(query, 511, "CREATE TABLE IF NOT EXISTS `Players` (`PlayerID`	INTEGER NOT NULL UNIQUE, `Mutation`	INTEGER NOT NULL, `Rude`	INTEGER NOT NULL)");
	DB.Query(CheckIf_Players_QueryPassed, query, _, DBPrio_High);
}

public void CheckIf_Players_QueryPassed(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not create players table (MuteGO)! Error: %s", error);
		DependenciesError = true;
		return;
	}
	tablesCreated = true;
}

// @@ Load
public void LoadPlayerData(int client)
{
	if (DependenciesError)	return;
	
	if(!tablesCreated)
	{
		CreateTimer(0.5, WaitLoad, GetClientUserId(client));
		return;
	}
	
	char query[512];
	Format(query, sizeof(query), "SELECT * FROM `Players` WHERE `PlayerID`=%d", GetPlayerID(client));
	DB.Query(LoadPlayerResults, query, GetClientUserId(client), DBPrio_High);
}

public Action WaitLoad(Handle timer, int clientUserId)
{
	int client = GetClientOfUserId(clientUserId);
	
	if (client)	LoadPlayerData(client);
}

public void LoadPlayerResults(Database db, DBResultSet results, const char[] error, int clientUserId)
{
	if (db == null || results == null)
	{
		PrintToServer("Could not retrieve player informations (MuteGO)!");
		LogMessage("Could not retrieve player informations (MuteGO)! Error: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(clientUserId);
	if (!client)	return;
	
	while(SQL_FetchRow(results))
	{
		Mute_Mutation[client] = SQL_FetchInt(results, 1);
		Mute_Rude[client] = SQL_FetchInt(results, 2);
	}
	
	if(results.RowCount)
	{
		IsInDatabase[client] = true;
	}
	UpdateMuteStateAll();
	
}

public void UpdatePlayerData(int client)
{
	char query[512];
	Format(query, 511, "UPDATE `Players` SET Mutation=%d,Rude=%d WHERE PlayerID=%d", Mute_Mutation[client], Mute_Rude[client], GetPlayerID(client));
	DB.Query(CheckIfUpdateQueryPassed, query, _, DBPrio_High);	
}

public void CheckIfUpdateQueryPassed(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not update player (MuteGO)! Error: %s", error);
		return;
	}
}

public void RemovePlayerFromDatabase(int client)
{
	char query[512];
	Format(query, 511, "DELETE FROM `Players` WHERE `PlayerID`=%d", GetPlayerID(client));
	DB.Query(CheckIfDeleteQueryPassed, query, _, DBPrio_High);
}

public void CheckIfDeleteQueryPassed(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not delete player (MuteGO)! Error: %s", error);
		return;
	}
}

// @@ Insert
public void InsertPlayerToDatabase(int client)
{
	char query[512];
	Format(query, sizeof(query), "INSERT INTO `Players`(PlayerID,Mutation,Rude) VALUES(%d,%d,%d)", GetPlayerID(client), Mute_Mutation[client], Mute_Rude[client]);
	DB.Query(InsertPlayerResults, query, _, DBPrio_High);
}

public void InsertPlayerResults(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || results == null)
	{
		PrintToServer("Could not insert player informations (BF2GO)!");
		LogMessage("Could not insert player informations! Error: %s", error);
		return;
	}
}


public void UpdateMuteStateAll()
{
	for (int i = 1; i < MAXPLAYERS;i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || IsClientSourceTV(i))	continue;
		
		for (int j = 1; j < MAXPLAYERS;j++)
		{
			if (!IsClientInGame(j) || IsFakeClient(j) || IsClientSourceTV(j) || i == j)	continue;
			
			if(WillBeMuted_Mutation(i, j) || WillBeMuted_Rude(i, j))
				SetListenOverride(i, j, Listen_No);
			else
				SetListenOverride(i, j, Listen_Default);
		}
	}
}

public void UpdateMuteStatePlayer(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client))	return;
	
	for (int i = 1; i < MAXPLAYERS;i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || IsClientSourceTV(i) || i == client)	continue;
		
		if(WillBeMuted_Mutation(client, i) || WillBeMuted_Rude(client, i))
			SetListenOverride(client, i, Listen_No);
		else
			SetListenOverride(client, i, Listen_Default);
	}
}

public bool WillBeMuted_Mutation(int client, int target)
{
	if (PlayerChoice_Mutation[client] && Mute_Mutation[target])	return true;
	return false;
}

public bool WillBeMuted_Rude(int client, int target)
{
	if (PlayerChoice_Rude[client] && Mute_Rude[target])	return true;
	return false;
}

// @@ Menu stuff
public Action MainMenu(int client, int args)
{
	TriggerMainMenu(client);
}

public void TriggerMainMenu(int client)
{
	if (!tablesCreated || DependenciesError)
	{
		GoPrint(client, "%T", "DB problems", client);
		return;
	}
	char FormatBuffer[1024];
	if(Mute_Mutation[client] || Mute_Rude[client])
		Format(FormatBuffer, sizeof(FormatBuffer), "%T", "MainMenu_Marked", client, Mute_Mutation[client] ? "[MUTATION]" : "", Mute_Rude[client] ? "[RUDE]" : "", PlayerChoice_Mutation[client] ? "YES" : "NO", PlayerChoice_Rude[client] ? "YES" : "NO");
	else
		Format(FormatBuffer, sizeof(FormatBuffer), "%T", "MainMenu_OK", client, PlayerChoice_Mutation[client] ? "YES" : "NO", PlayerChoice_Rude[client] ? "YES" : "NO");
	Menu menu = new Menu(TriggerMainMenu_Handler);
	menu.SetTitle(FormatBuffer);

	if(IsAdmin(client))	menu.AddItem("admin", "Admin menu");
	
	if(PlayerChoice_Mutation[client] == 1)
		Format(FormatBuffer, sizeof(FormatBuffer), "%T", "MainMenu_Mutation_Unmute", client);
	else
		Format(FormatBuffer, sizeof(FormatBuffer), "%T", "MainMenu_Mutation_Mute", client);
	menu.AddItem("mutation", FormatBuffer);
	
	if(PlayerChoice_Rude[client] == 1)
		Format(FormatBuffer, sizeof(FormatBuffer), "%T", "MainMenu_Rude_Unmute", client);
	else
		Format(FormatBuffer, sizeof(FormatBuffer), "%T", "MainMenu_Rude_Mute", client);
	menu.AddItem("rude", FormatBuffer);
	
	menu.ExitButton=true;
	menu.Display(client, 30);	
}

public int TriggerMainMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "admin"))	AdminMenu(client);
		else if (StrEqual(InfoBuffer, "mutation"))
		{
			PlayerChoice_Mutation[client] = PlayerChoice_Mutation[client] == 1 ? 0 : 1;
			if (AreClientCookiesCached(client))
			{
				TriggerMainMenu(client);
				
				char sCookieValue[11];
				IntToString(PlayerChoice_Mutation[client], sCookieValue, sizeof(sCookieValue));
				SetClientCookie(client, Cookie_Mutation, sCookieValue);
				UpdateMuteStatePlayer(client);
			}
		}
		else if (StrEqual(InfoBuffer, "rude"))
		{
			PlayerChoice_Rude[client] = PlayerChoice_Rude[client] == 1 ? 0 : 1;
			if (AreClientCookiesCached(client))
			{
				TriggerMainMenu(client);
				
				char sCookieValue[11];
				IntToString(PlayerChoice_Rude[client], sCookieValue, sizeof(sCookieValue));
				SetClientCookie(client, Cookie_Rude, sCookieValue);
				UpdateMuteStatePlayer(client);
			}
		}
	}
}

public void AdminMenu(int client)
{
	if (!tablesCreated || DependenciesError)
	{
		GoPrint(client, "%T", "DB problems", client);
		return;
	}

	Menu menu = new Menu(AdminMenu_Handler);
	menu.SetTitle("MuteGO - Admin Menu");
	char FormatBuffer[128];
	
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "AdminMenu_Manage", client);
	menu.AddItem("manage", FormatBuffer);
	
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "BackButton", client);
	menu.AddItem("back", FormatBuffer);
	
	menu.ExitButton=true;
	menu.Display(client, 30);	
}

public int AdminMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "back"))	TriggerMainMenu(client);
		else if (StrEqual(InfoBuffer, "manage"))	ShowPlayersList(client, MANAGE);
	}
}

public void ShowPlayersList(int client, int mode)
{
	char FormatBuffer[MAX_NAME_LENGTH + 256];
	char InfoBuffer[32];
	
	char MutationBuffer[16];
	char RudeBuffer[16];
	Format(MutationBuffer, sizeof(MutationBuffer), "%T", "Mutation", client);
	Format(RudeBuffer, sizeof(RudeBuffer), "%T", "Rude", client);
	
	Menu menu = new Menu(ShowPlayersList_Handler);
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "PlayersList_Title", client);
	menu.SetTitle(FormatBuffer);

	
	Format(InfoBuffer, sizeof(InfoBuffer), "%d|back", mode);
	menu.AddItem(InfoBuffer, "Back");
	
	for (int i = 1; i < MAXPLAYERS;i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || IsClientSourceTV(i))	continue;
		
		Format(FormatBuffer, sizeof(FormatBuffer), "%s %s %N", Mute_Mutation[i] ? MutationBuffer : "", Mute_Rude[i] ? RudeBuffer : "", i);
		Format(InfoBuffer, sizeof(InfoBuffer), "%d|%d", mode, i);
		
		menu.AddItem(InfoBuffer, FormatBuffer);
	}
	
	menu.ExitButton=true;
	menu.Display(client, 30);
}

public int ShowPlayersList_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		char str[2][16];
		ExplodeString(InfoBuffer, "|", str, sizeof(str), sizeof(str[]));
		
		int mode = StringToInt(str[0]);
		
		if (StrEqual(str[1], "back"))
		{
			if (mode == MANAGE)	AdminMenu(client);
			else TriggerMainMenu(client);
		}
		else
		{
			int target = StringToInt(str[1]);
			if (mode == SHOW)	ShowPlayersList(client, SHOW);
			else DisplayPlayerOptions(client, GetClientUserId(target));
		}
	}
}

public void DisplayPlayerOptions(int client, int targetUserId)
{
	int target = GetClientOfUserId(targetUserId)
	
	if(!target)
	{
		GoPrint(client, "%T", "PlayerLeft", client);
		return;
	}
	
	char MarkBuffer[16];
	char UnmarkBuffer[16];
	
	Format(MarkBuffer, sizeof(MarkBuffer), "%T", "Mark", client);
	Format(UnmarkBuffer, sizeof(UnmarkBuffer), "%T", "Unmark", client);
	
	Menu menu = new Menu(DisplayPlayerOptions_Handler);
	
	char FormatBuffer[1024];
	char InfoBuffer[32];
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "PlayerOptions_Title", client, target, Mute_Mutation[target] ? "YES" : "NO", Mute_Rude[target] ? "YES" : "NO");
	
	menu.SetTitle(FormatBuffer);
	
	Format(FormatBuffer, sizeof(FormatBuffer), "%s - %T", Mute_Mutation[target] ? UnmarkBuffer : MarkBuffer, "Mutation", client);
	Format(InfoBuffer, sizeof(InfoBuffer), "%d|mutation", GetClientUserId(target));
	menu.AddItem(InfoBuffer, FormatBuffer);
	
	Format(FormatBuffer, sizeof(FormatBuffer), "%s - %T", Mute_Rude[target] ? UnmarkBuffer : MarkBuffer, "Rude", client);
	Format(InfoBuffer, sizeof(InfoBuffer), "%d|rude", GetClientUserId(target));
	menu.AddItem(InfoBuffer, FormatBuffer);
	
	menu.AddItem("back", "Back to list");
	
	menu.ExitButton=true;
	menu.Display(client, 30);	
}

public int DisplayPlayerOptions_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "back"))
		{
			ShowPlayersList(client, MANAGE);
		}
		else
		{
			char str[2][16];
			ExplodeString(InfoBuffer, "|", str, sizeof(str), sizeof(str[]));
		
			int target = GetClientOfUserId(StringToInt(str[0]));
			if(!target)
			{
				GoPrint(client, "%T", "PlayerLeft", client);
				ShowPlayersList(client, MANAGE);
				return 0;
			}
			
			if (StrEqual(str[1], "mutation"))
			{
				if(!Mute_Mutation[target])
				{
					Mute_Mutation[target] = 1;
					GoPrint(ALL, "{blue}[%N]{default} Gracz{firered} %N{default} - {lightgreen}Mutation:{darkred} YES", client, target);	
				}
				else
				{
					Mute_Mutation[target] = 0;
					GoPrint(ALL, "{blue}[%N]{default} Gracz{firered} %N{default} - {lightgreen}Mutation:{green} NO", client, target);	
				}
			}
			else if (StrEqual(str[1], "rude"))
			{
				if(!Mute_Rude[target])
				{
					Mute_Rude[target] = 1;
					GoPrint(ALL, "{blue}[%N]{default} Gracz{firered} %N{default} - {lightgreen}Rude:{darkred} YES", client, target);	
				}
				else
				{
					Mute_Rude[target] = 0;
					GoPrint(ALL, "{blue}[%N]{default} Gracz{firered} %N{default} - {lightgreen}Rude:{green} NO", client, target);	
				}
			}
			DisplayPlayerOptions(client, GetClientUserId(target));
			UpdateMuteStateAll();
		}
	}
	
	return 0;
}


public int IsAdmin(int client)
{
	return (GetUserFlagBits(client) & ADMFLAG_BAN || GetUserFlagBits(client) & ADMFLAG_ROOT);
}


//@@ GoPrint

public GoPrint(int client, char[] msg, any ...)
{
	int len = strlen(msg) + 255;
	char[] formatted = new char[len];
	VFormat(formatted, len, msg, 3);
	
	for (int i = 0; i < 13;i++)
	{
		if (StrContains(formatted, ColorsName[i], false) != -1)
			ReplaceString(formatted, len, ColorsName[i], ColorsTag[i], false);
	}
	
	if(client != ALL)	CPrintToChat(client, "%s %s", TAG, formatted);
	else
	{
		for (int i = 1; i < MAXPLAYERS;i++)
		{
			if (!IsClientInGame(i))	continue;
			CPrintToChat(i, "%s %s", TAG, formatted);
		}
	}
}
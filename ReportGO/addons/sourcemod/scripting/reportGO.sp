#include <sourcemod>
#include <sdktools>
#include <multicolors>

#define TAG "{orchid}[Report Tool]{default}"
#define FLAG ADMFLAG_BAN

ArrayList reportMessage;
ArrayList authorName;
ArrayList authorSID;
ArrayList authorSID64;
ArrayList authorAccountID;
ArrayList timestamp;

ConVar cvCapacity;
ConVar cvReportDelay;

int adminControlWho[MAXPLAYERS];
int adminControlWhen[MAXPLAYERS];

int playerReportDelay[MAXPLAYERS];

bool isUserBlocked[MAXPLAYERS];

Database DB;

public void OnPluginStart() {
  LoadTranslations("reportGO.phrases");

  RegConsoleCmd("say", ProcessChat);
  RegConsoleCmd("sm_report", MainMenu);
  InitDynamicTables();

  cvCapacity = CreateConVar("rg_capacity", "25", "Capacity of available reports");
  cvReportDelay = CreateConVar("rg_report_delay", "180", "The interval in which player can send reports (in seconds)");

  ConnectDB();
}

public void OnClientDisconnect(int client) {
  SQL_Save(client);
}

public void OnClientPutInServer(int client) {
  SQL_Load(client);
}

void SQL_Save(int client) {
  if (GetSteamAccountID(client) == 0) return;

  char query[1024];
  Format(query, sizeof(query), "UPDATE `ReportGO` SET IsUserBanned=%d WHERE `SteamID`=%d", isUserBlocked[client] ? 1 : 0, GetSteamAccountID(client));
  DB.Query(CheckDBUpdate, query);
}

public void CheckDBUpdate(Database db, DBResultSet results,
  const char[] error, any data) {
  if (db == null) {
    LogMessage("Could not update player data! Error: %s", error);
  }
}

void SQL_Load(int client) {
  if (GetSteamAccountID(client) == 0) return;

  char query[1024];
  Format(query, sizeof(query), "SELECT * FROM `ReportGO` WHERE `SteamID`=%d", GetSteamAccountID(client));
  DB.Query(CheckDBLoad, query, client);
}

public void CheckDBLoad(Database db, DBResultSet results,
  const char[] error, int client) {
  if (db == null || results == null) {
    LogMessage("Could not load player data! Error: %s", error);
    return;
  }

  if (results.RowCount == 0) {
    char query[1024];
    Format(query, sizeof(query), "INSERT INTO `ReportGO` VALUES(%d, 0)", GetSteamAccountID(client));
    DB.Query(CheckDBInsert, query);
  } else {
    while (results.FetchRow()) {
      isUserBlocked[client] = results.FetchInt(1) == 1 ? true : false;
    }
  }
}

public void CheckDBInsert(Database db, DBResultSet results,
  const char[] error, any data) {
  if (db == null) {
    LogMessage("Could not insert player data! Error: %s", error);
  }
}

void ConnectDB() {
  char sError[512];
  DB = SQLite_UseDatabase("ReportGO", sError, sizeof(sError));
  if (DB == null) {
    LogMessage("Could not connect to the DataBase! Error: %s", sError);
  } else {
    char query[1024];
    Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `ReportGO` (`SteamID`	INTEGER NOT NULL UNIQUE,`IsUserBanned`	INTEGER NOT NULL);");
    DB.Query(CheckDB, query);
  }
}

public void CheckDB(Database db, DBResultSet results,
  const char[] error, any data) {
  if (db == null) {
    LogMessage("Could not create table! Error: %s", error);

  }
}

void InitDynamicTables() {
  reportMessage = new ArrayList(1024);
  authorName = new ArrayList(MAX_NAME_LENGTH);
  authorSID = new ArrayList(64);
  authorSID64 = new ArrayList(64);
  timestamp = new ArrayList();
  authorAccountID = new ArrayList();
}

public void OnMapStart() {
  AutoExecConfig(true, "ReportGO");
}

public Action ProcessChat(int client, int args) {
  char buffer[1024];
  GetCmdArgString(buffer, sizeof(buffer));
  StripQuotes(buffer);
  if (buffer[0] != '$') return Plugin_Continue;

  if (isUserBlocked[client] == true) {
    CPrintToChat(client, "%T", "user blocked", client, TAG);
    return Plugin_Handled;
  }

  if (playerReportDelay[client] > GetTime()) {
    CPrintToChat(client, "%T", "delay", client, TAG, IntAbs(GetTime() - playerReportDelay[client]));
    return Plugin_Handled;
  }

  if (authorName.Length >= cvCapacity.IntValue) {
    CPrintToChat(client, "%T", "capacity", client, TAG);
    return Plugin_Handled;
  }

  CPrintToChat(client, "{grey}> %s", buffer[1]);

  char nameBuffer[MAX_NAME_LENGTH];
  GetClientName(client, nameBuffer, sizeof(nameBuffer));

  char sidBuffer[64];
  GetClientAuthId(client, AuthId_Steam2, sidBuffer, sizeof(sidBuffer));

  char sidBuffer64[64];
  GetClientAuthId(client, AuthId_SteamID64, sidBuffer64, sizeof(sidBuffer64));

  reportMessage.PushString(buffer[1]); //[1] in order to remove the '$' sign
  authorName.PushString(nameBuffer);
  authorSID.PushString(sidBuffer);
  authorSID64.PushString(sidBuffer64);
  timestamp.Push(GetTime());
  authorAccountID.Push(GetSteamAccountID(client));

  CPrintToChat(client, "%T", "message sent", client, TAG);

  playerReportDelay[client] = GetTime() + cvReportDelay.IntValue;

  for (int i = 1; i < MAXPLAYERS; i++) {
    if (IsValidClient(i) && IsUserAdmin(i))
      CPrintToChat(i, "%T", "new report", client, TAG, client);
  }

  return Plugin_Handled;
}

public Action MainMenu(int client, int args) {

  if (!IsUserAdmin(client)) {
    CPrintToChat(client, "%T", "no access", client, TAG);
    return Plugin_Handled;
  }

  Menu menu = new Menu(MainMenu_Handler);
  char buffer[256];
  menu.SetTitle("ReportGO by MAGNET");

  Format(buffer, sizeof(buffer), "%T", "browse", client);
  menu.AddItem("browse", buffer);

  Format(buffer, sizeof(buffer), "%T", "manage", client);
  menu.AddItem("manage", buffer);

  menu.Display(client, 120);
  return Plugin_Handled;
}

public int MainMenu_Handler(Menu menu, MenuAction action, int client, int item) {
  if (action == MenuAction_Select) {
    char InfoBuffer[32];
    menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));

    if (StrEqual(InfoBuffer, "browse")) CheckReport(client);
    else if (StrEqual(InfoBuffer, "manage")) ManagePlayers(client);
  }
}

void CheckReport(int client) {
  if (!IsUserAdmin(client)) {
    CPrintToChat(client, "%T", "no access", client, TAG);
    return;
  }

  Menu menu = new Menu(CheckReport_Handler);

  char buffer[1024];
  char optionBuffer[8];

  Format(buffer, sizeof(buffer), "%T", "back", client);
  menu.AddItem("back", buffer);

  if (authorName.Length == 0) {
    Format(buffer, sizeof(buffer), "%T", "no messages", client);
    menu.SetTitle(buffer);

    menu.ExitButton = false;
  } else {
    Format(buffer, sizeof(buffer), "%T", "amount messages", client, authorName.Length);
    menu.SetTitle(buffer);
    char messageBuffer[1024];
    char playerNameBuffer[MAX_NAME_LENGTH];
    for (int i = 0; i < authorName.Length; i++) {
      reportMessage.GetString(i, messageBuffer, sizeof(messageBuffer));
      authorName.GetString(i, playerNameBuffer, sizeof(playerNameBuffer));
      if (strlen(messageBuffer) > 13) {
        messageBuffer[10] = '.';
        messageBuffer[11] = '.';
        messageBuffer[12] = '.';
        messageBuffer[13] = '\0';
      }

      Format(buffer, sizeof(buffer), "%T", "report format", client, messageBuffer, playerNameBuffer);
      Format(optionBuffer, sizeof(optionBuffer), "%d", i);
      menu.AddItem(optionBuffer, buffer);
    }
  }
  menu.Display(client, 120);

}

public int CheckReport_Handler(Menu menu, MenuAction action, int client, int item) {
  if (action == MenuAction_Select) {
    char InfoBuffer[32];
    menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));

    if (StrEqual(InfoBuffer, "back")) {
      MainMenu(client, 0);
      return 0;
    }

    int option = StringToInt(InfoBuffer);

    // the admin could have picked last report, that has been deleted by someone else in the meantime
    if (option == authorName.Length) {
      return 0;
    }

    // we need to monitor which report was chosen, since there might occur some conflicts during /report access by several admins
    // even at this point there might have been conflict, but the only consequence is wrong reportMessage being displayed, which will surely be spotted by admin
    adminControlWho[client] = authorAccountID.Get(option);
    adminControlWhen[client] = timestamp.Get(option);
    ShowMessage(client, option);
  }
  return 0;
}

void ShowMessage(int client, int option) {
  if (!IsUserAdmin(client)) {
    CPrintToChat(client, "%T", "no access", client, TAG);
    return;
  }

  char messageBuffer[1024];
  reportMessage.GetString(option, messageBuffer, sizeof(messageBuffer));

  char authorBuffer[MAX_NAME_LENGTH];
  authorName.GetString(option, authorBuffer, sizeof(authorBuffer));

  char sidBuffer[64];
  authorSID.GetString(option, sidBuffer, sizeof(sidBuffer));

  int time = timestamp.Get(option);
  char timeBuffer[32];
  FormatTime(timeBuffer, sizeof(timeBuffer), "%d.%m.%Y %R", time);

  char buffer[1024 + MAX_NAME_LENGTH + 100];
  Format(buffer, sizeof(buffer), "%T", "report menu", client, authorBuffer, timeBuffer, sidBuffer, messageBuffer);
  char profileBuffer[256];
  char sid64Buffer[32];
  authorSID64.GetString(option, sid64Buffer, sizeof(sid64Buffer));
  Format(profileBuffer, sizeof(profileBuffer), "http://steamcommunity.com/profiles/%s", sid64Buffer);
  PrintToConsole(client, "\n*******REPORT******\n%s\nProfile: %s\n**************\n ", buffer, profileBuffer);

  Menu menu = new Menu(ShowMessage_Handler);
  menu.SetTitle(buffer);
  char optionBuffer[16];

  Format(buffer, sizeof(buffer), "%T", "back", client);
  Format(optionBuffer, sizeof(optionBuffer), "%d|back", option);
  menu.AddItem(optionBuffer, buffer);

  Format(buffer, sizeof(buffer), "%T", "delete", client);
  Format(optionBuffer, sizeof(optionBuffer), "%d|delete", option);
  menu.AddItem(optionBuffer, buffer);

  menu.Display(client, 120);
}

public int ShowMessage_Handler(Menu menu, MenuAction action, int client, int item) {
  if (action == MenuAction_Select) {
    char InfoBuffer[32];
    menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));

    char str[2][8];
    ExplodeString(InfoBuffer, "|", str, sizeof(str), sizeof(str[]));

    int option = StringToInt(str[0]);

    if (StrEqual(str[1], "back")) {
      CheckReport(client);
    } else if (StrEqual(str[1], "delete")) {
      DeleteMessage(client, option);
      CheckReport(client);
    }
  }
}

void DeleteMessage(int client, int option) {
  int checkWho = authorAccountID.Get(option);
  int checkWhen = timestamp.Get(option);

  if (adminControlWho[client] != checkWho || adminControlWhen[client] != checkWhen) {
    CPrintToChat(client, "%T", "wrong reportMessage", client, TAG);
    return;
  }

  reportMessage.Erase(option);
  authorName.Erase(option)
  authorSID.Erase(option)
  authorSID64.Erase(option)
  authorAccountID.Erase(option)
  timestamp.Erase(option)
}

///
void ManagePlayers(int client) {
  char buffer[MAX_NAME_LENGTH + 16];
  char optionBuffer[8];

  Menu menu = new Menu(ManagePlayers_Handler);
  Format(buffer, sizeof(buffer), "%T", "choose", client);
  menu.SetTitle(buffer);

  Format(buffer, sizeof(buffer), "%T", "back", client);
  menu.AddItem("back", buffer);

  for (int i = 1; i < MAXPLAYERS; i++) {
    if (client == i || !IsValidClient(i) || IsUserAdmin(i) || IsFakeClient(i)) continue;

    Format(buffer, sizeof(buffer), "%N%s", i, isUserBlocked[i] ? " [X]" : "");
    Format(optionBuffer, sizeof(optionBuffer), "%d", GetClientUserId(i));
    menu.AddItem(optionBuffer, buffer);
  }
  menu.Display(client, 120);
}

public int ManagePlayers_Handler(Menu menu, MenuAction action, int client, int item) {
  if (action == MenuAction_Select) {
    char InfoBuffer[32];
    menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
    if (StrEqual(InfoBuffer, "back")) {
      MainMenu(client, 0);
      return 0;
    }

    int target = GetClientOfUserId(StringToInt(InfoBuffer));
    if (!target) {
      CPrintToChat(client, "%T", "user left", client, TAG);
      ManagePlayers(client);
      return 0;
    }

    isUserBlocked[target] = isUserBlocked[target] == true ? false : true;

    if (isUserBlocked[target]) {
      CPrintToChat(target, "%T", "block on", client, TAG);
    } else {
      CPrintToChat(target, "%T", "block off", client, TAG);
    }

    ManagePlayers(client);
  }
  return 0;
}

public bool IsValidClient(int client) {
  if (client >= 1 && client <= MaxClients && IsClientInGame(client))
    return true;

  return false;
}

int IntAbs(int n) {
  if (n < 0) return -n;
  return n;
}

bool IsUserAdmin(int client) {
    if (GetUserFlagBits(client) & (FLAG|ADMFLAG_ROOT))    return true;

    return false;
}
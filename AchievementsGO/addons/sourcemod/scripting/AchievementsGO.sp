#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

#define TAG "\x03[AchievementsGO]\x01"

#define ACHIEVEMENT_MAX_NAME_LENGTH 64
#define ACHIEVEMENT_MAX_DESCRIPTION_LENGTH 128
#define ACHIEVEMENT_MAX_CATEGORY_LENGTH 128

#define NOT_ASSIGNED 0
#define NOT_FOUND -1
#define SERVER 0
#define ALL -1

Database DB;

int AmountOfActiveAchievements = 0;

bool IsConnectionEstablished = false;
bool AreAllAchievementsLoaded = false;

ArrayList AchievementID;
ArrayList AchievementName;
ArrayList AchievementDescription;
ArrayList AchievementCategory;
ArrayList AchievementValue;
ArrayList AchievementPluginID;

ArrayList CategoryList;

ArrayList Player_AchievementID[MAXPLAYERS];
ArrayList Player_AchievementProgress[MAXPLAYERS];

Handle Forward_AllAchievementsLoaded;
Handle Forward_OnRegisterAchievements;
Handle Forward_OnAchievementAccomplished;

int PlayerID[MAXPLAYERS];
int AccomplishedAchievements[MAXPLAYERS];

char Top10Name[10][MAX_NAME_LENGTH];
int Top10Score[10];
int AmountOfLeaders;

char ColorsName[][] =  { "{default}", "{darkred}", "{purple}", "{green}", "{lightgreen}", "{mediumgreen}", "{lightred}", "{lightpurple}", "{yellow}", "{greyblue}", "{blue}", "{violet}", "{firered}" };
char ColorsTag[][] =  { "\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x0A", "\x0C", "\x0E", "\x0F" };

int tablesCreated = 0;

public Plugin myinfo =
{
    name = "AchievementsGO",
    author = "MAGNET | YouTube: Koduj z Magnetem",
    description = "Tool for creating your own achievements",
    version = "0.1",
    url = "http://go-code.pl/"
};

public OnPluginStart()
{
	SQL_InitConnection(); // AchievementsGO_SQLConnect.sp
	InitDynamicTables();
	StartUpdatingPlayerInfo(); // updates player info every 3 minutes
	InitGlobalForwards(); // AchievementsGO_Forwards.sp
	CreateTimer(0.5, DelayLoadTop10);
	
	RegConsoleCmd("sm_ac", ShowAchievementsMenu);
}

public Action DelayLoadTop10(Handle timer)
{
	LoadTop10();
}

public void StartUpdatingPlayerInfo()
{
	CreateTimer(180.0, Timer_UpdatePlayerInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

public Action Timer_UpdatePlayerInfo(Handle timer)
{
	for (int i = 1; i < MAXPLAYERS; i++)	UpdatePlayerData(i);
	
	return Plugin_Continue;
}

public void InitDynamicTables()
{
	AchievementID = CreateArray(4);	
	AchievementName = CreateArray(ACHIEVEMENT_MAX_NAME_LENGTH+1);	
	AchievementDescription = CreateArray(ACHIEVEMENT_MAX_DESCRIPTION_LENGTH+1);	
	AchievementCategory = CreateArray(ACHIEVEMENT_MAX_CATEGORY_LENGTH+1);	
	AchievementValue = CreateArray(10);	
	AchievementPluginID = CreateArray(5);	
	
	CategoryList = CreateArray(ACHIEVEMENT_MAX_CATEGORY_LENGTH + 1);
	
	for (int i = 0; i < MAXPLAYERS;i++)
	{
		Player_AchievementID[i] = CreateArray(4);
		Player_AchievementProgress[i] = CreateArray(10);
	}
}

public void OnClientAuthorized(int client, const char[] auth)
{
	ClearPlayerInfo(client);
	LoadPlayerID(client);
	LoadPlayerAchievements(client);
}

public void OnClientDisconnect(int client)
{
	ClearPlayerInfo(client); //AchievementsGO_SQLLoadData.sp
}

public void OnMapStart()
{
	PrecacheSounds(); // MailboxGO_Sounds.sp
	DownloadSounds();
}

public void OnAllPluginsLoaded()
{
	if (IsConnectionEstablished)	AreAllAchievementsLoaded = true;
	SendForwardAllAchievementsLoaded();
}

#include <AchievementsGO/AchievementsGO_Natives.sp>
#include <AchievementsGO/AchievementsGO_Forwards.sp>
#include <AchievementsGO/AchievementsGO_SQLConnect.sp>
#include <AchievementsGO/AchievementsGO_SQLLoadData.sp>
#include <AchievementsGO/AchievementsGO_SQLUpdate.sp>
#include <AchievementsGO/AchievementsGO_Menu.sp>
#include <AchievementsGO/AchievementsGO_GoPrint.sp>
#include <AchievementsGO/AchievementsGO_Sound.sp>
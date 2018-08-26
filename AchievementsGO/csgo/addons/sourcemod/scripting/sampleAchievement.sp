#pragma semicolon 1

#include <sourcemod>
#include <AchievementsGO>


int AGO_Zabij[3];
int AGO_Zgin[3];
int AGO_HS[3];
int AGO_Saper[3];
int AGO_Podloz[3];
int AGO_Ace[3];

int AceCounter[MAXPLAYERS];

public Plugin myinfo =
{
    name = "AchievementsGO example",
    author = "MAGNET | YouTube: Koduj z Magnetem",
    description = "Example showing how to create your own Achievements",
    version = "0.1",
    url = "http://go-code.pl/"
};

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post); 
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy); 
	
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("bomb_defused", Event_BombDefused);
	
}

public void AGO_OnAchievementAccomplished(int client, int IdOfAchievement)
{
	PrintToChat(client, "Ukonczono. ID: %d", IdOfAchievement);
}

public void AGO_OnRegisterAchievements()
{
	AGO_Zabij[0] = AGO_AddAchievement("Beginner", "Kill 10 players", "Killer path", 10);
	AGO_Zabij[1] = AGO_AddAchievement("Killer", "Kill 100 players", "Killer path", 100);
	AGO_Zabij[2] = AGO_AddAchievement("Murderer - literally :O", "Kill 500 players", "Killer path", 500);
	
	AGO_Zgin[0] = AGO_AddAchievement("No one always wins...", "Die 10 times", "Killer path", 10);
	AGO_Zgin[1] = AGO_AddAchievement("Dawca krwi", "Die 100 times", "Killer path", 100);
	AGO_Zgin[2] = AGO_AddAchievement("Goofball", "Die 500 times", "Killer path", 500);
	
	AGO_HS[0] = AGO_AddAchievement("Headache", "HS 10 times", "Killer path", 10);
	AGO_HS[1] = AGO_AddAchievement("BooM! Headshot!", "HS 50 times", "Killer path", 50);
	AGO_HS[2] = AGO_AddAchievement("Mindblower", "HS 250 times", "Killer path", 250);

	AGO_Saper[0] = AGO_AddAchievement("You are a good sapper", "Defuse 3 bombs", "Sapper path", 3);
	AGO_Saper[1] = AGO_AddAchievement("Advanced sapper", "Defuse 20 bombs", "Sapper path", 20);
	AGO_Saper[2] = AGO_AddAchievement("Why would anyone need defuse?", "Defuse 50 bombs", "Sapper path", 50);
	
	AGO_Podloz[0] = AGO_AddAchievement("So you are a terrorist?", "Plant 3 bombs", "Pyro path", 3);
	AGO_Podloz[1] = AGO_AddAchievement("Known on the bombsites", "Plant 20 bombs", "Pyro path", 20);
	AGO_Podloz[2] = AGO_AddAchievement("Just one BIG BOOM", "Plant 50 bombs", "Pyro path", 50);
	
	AGO_Ace[0] = AGO_AddAchievement("Ace", "Ace 1 time", "", 1);
	AGO_Ace[1] = AGO_AddAchievement("Respect+", "Ace 5 times", "", 5);
	AGO_Ace[2] = AGO_AddAchievement("ACE BABY!", "Ace 50 time", "", 50);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victimId = GetClientOfUserId(event.GetInt("userid"));
	int attackerId = GetClientOfUserId(event.GetInt("attacker"));
	bool headshot = event.GetBool("headshot");
	
	for (int i = 0; i < 3; i++)	AGO_AddPoint(attackerId, AGO_Zabij[i]);
	
	for (int i = 0; i < 3; i++)	AGO_AddPoint(victimId, AGO_Zgin[i]);
	
	AceCounter[attackerId]++;
	
	if(AceCounter[attackerId] == 5)
	{
		for (int i = 0; i < 3; i++)	AGO_AddPoint(attackerId, AGO_Ace[i]);
	}
	
	if(headshot)
	{
		for (int i = 0; i < 3; i++)	AGO_AddPoint(attackerId, AGO_HS[i]);
	}
}

public OnRoundStart(Event event, const char[] name, bool dontBroadcast) 
{ 
    for (int i = 0; i < MAXPLAYERS; i++)	AceCounter[i] = 0;
}  

public Action Event_BombPlanted(Handle event, const char[] name, bool dontBroadcast)
{
	int attackerId = GetClientOfUserId(GetEventInt(event, "userid"));
	
	for (int i = 0; i < 3; i++)	AGO_AddPoint(attackerId, AGO_Podloz[i]);
}

public Action Event_BombDefused(Handle event, const char[] name, bool dontBroadcast)
{
	int attackerId = GetClientOfUserId(GetEventInt(event, "userid"));
	
	for (int i = 0; i < 3; i++)	AGO_AddPoint(attackerId, AGO_Saper[i]);
}
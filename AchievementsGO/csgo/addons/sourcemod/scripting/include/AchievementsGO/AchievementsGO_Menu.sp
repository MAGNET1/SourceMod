public Action ShowAchievementsMenu(int client, int args)
{
	TriggerAchievementsMenu(client);
	
	return Plugin_Continue;
}

public void TriggerAchievementsMenu(int client)
{
	if (PlayerID[client] == NOT_ASSIGNED)	GoPrint(client, "There are some problems with the database. Try again later...");
	
	Menu menu = new Menu(TriggerAchievementsMenu_Handler);
	menu.SetTitle("AchievementsGO by MAGNET");
	
	menu.AddItem("ach", "My achievements");
	menu.AddItem("top10", "Top 10");
	
	menu.ExitButton=true;
	menu.Display(client, 30);	
}

public int TriggerAchievementsMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "ach"))	ShowPlayerAchievements(client);
		else if(StrEqual(InfoBuffer, "top10"))	ShowTop10(client);
	}
}

public void ShowPlayerAchievements(int client)
{
	Menu menu = new Menu(ShowAchievementsMenu_Handler);
	
	char FormatBufferName[128];
	char FormatBufferInfo[256];
	char FormatBufferWhole[256];
	char FormatBufferTitle[512];
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "Accomplished achievements: %d\nAchievements list:", AccomplishedAchievements[client]);
	menu.SetTitle(FormatBufferTitle);
	
	if(GetArraySize(AchievementName) == 0)
	{
		menu.SetTitle("There are no achievements...");
		menu.AddItem("exit", "Exit");
	}
	
	menu.AddItem("back", "Back");
	
	for (int i = 0; i < GetArraySize(CategoryList);i++)
	{
		GetArrayString(CategoryList, i, FormatBufferInfo, sizeof(FormatBufferInfo));
		Format(FormatBufferWhole, sizeof(FormatBufferWhole), "> %s", FormatBufferInfo);
		menu.AddItem(FormatBufferInfo, FormatBufferWhole);
	}
	
	for (int i = 0; i < GetArraySize(Player_AchievementID[client]);i++)
	{
		int AchievementPos = GetAchievementPosById(GetArrayCell(Player_AchievementID[client], i));
		
		if (AchievementPos == NOT_FOUND)	continue;
		
		char tmpCategory[ACHIEVEMENT_MAX_CATEGORY_LENGTH];
		GetArrayString(AchievementCategory, AchievementPos, tmpCategory, sizeof(tmpCategory));
		if (!StrEqual(tmpCategory, ""))	continue;
		
		int progress = GetArrayCell(Player_AchievementProgress[client], i);
		int value = GetArrayCell(AchievementValue, AchievementPos);
		GetArrayString(AchievementName, AchievementPos, FormatBufferName, sizeof(FormatBufferName));
		
		Format(FormatBufferInfo, sizeof(FormatBufferInfo), "%d|%d", i, AchievementPos);
		Format(FormatBufferWhole, sizeof(FormatBufferWhole), "%s (%d/%d)", FormatBufferName, progress, value);
		
		menu.AddItem(FormatBufferInfo, FormatBufferWhole);
	}

	menu.ExitButton=true;
	menu.Display(client, 30);	
}

public int ShowAchievementsMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[256];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		if (StrEqual(InfoBuffer, "back"))	TriggerAchievementsMenu(client);
		else if (!StrEqual(InfoBuffer, "exit"))
		{
			if(StrContains(InfoBuffer, "|") != -1)
			{
				char str[2][8];
				ExplodeString(InfoBuffer, "|", str, sizeof(str), sizeof(str[]));
				DisplayAchievementDetails(client, StringToInt(str[0]), StringToInt(str[1]));	
			}
			else
			{
				ShowCategoryAchievements(client, InfoBuffer);
			}
		}
	}
}

public void ShowCategoryAchievements(int client, char[] CategoryBuffer)
{
	//PrintToChat(client, "ArraySize: %d", GetArraySize(Player_AchievementID[client]));
	Menu menu = new Menu(ShowCategoryAchievements_Handler);
	
	char FormatBufferName[128];
	char FormatBufferInfo[10];
	char FormatBufferWhole[256];
	char FormatBufferTitle[512];
	
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "Category: %s\nAchievements list:", CategoryBuffer);
	menu.SetTitle(FormatBufferTitle);
	
	menu.AddItem("back", "Back");
	
	for (int i = 0; i < GetArraySize(Player_AchievementID[client]);i++)
	{
		int AchievementPos = GetAchievementPosById(GetArrayCell(Player_AchievementID[client], i));
		
		if (AchievementPos == NOT_FOUND)	continue;
		
		char tmpCategory[ACHIEVEMENT_MAX_CATEGORY_LENGTH];
		GetArrayString(AchievementCategory, AchievementPos, tmpCategory, sizeof(tmpCategory));
		if (!StrEqual(tmpCategory, CategoryBuffer))	continue;
		
		int progress = GetArrayCell(Player_AchievementProgress[client], i);
		int value = GetArrayCell(AchievementValue, AchievementPos);
		GetArrayString(AchievementName, AchievementPos, FormatBufferName, sizeof(FormatBufferName));
		
		Format(FormatBufferInfo, sizeof(FormatBufferInfo), "%d|%d", i, AchievementPos);
		Format(FormatBufferWhole, sizeof(FormatBufferWhole), "%s (%d/%d)", FormatBufferName, progress, value);
		
		menu.AddItem(FormatBufferInfo, FormatBufferWhole);
	}

	menu.ExitButton=true;
	menu.Display(client, 30);	
}

public int ShowCategoryAchievements_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		if (StrEqual(InfoBuffer, "back"))	ShowPlayerAchievements(client);
		else if (!StrEqual(InfoBuffer, "exit"))
		{
			char str[2][8];
			ExplodeString(InfoBuffer, "|", str, sizeof(str), sizeof(str[]));
			DisplayAchievementDetails(client, StringToInt(str[0]), StringToInt(str[1]));
		}
	}
}

public int GetAchievementPosById(int id)
{
	for (int i = 0; i < GetArraySize(AchievementName);i++)
	{
		if (GetArrayCell(AchievementID, i) == id)	return i;
	}
	return NOT_FOUND;
}

public void DisplayAchievementDetails(int client, int i, int AchievementPos)
{
	char FormatBufferTitle[512];
	char FormatBufferName[64];
	char FormatBufferDescription[256];
	char FormatBufferCategory[256];
	
	GetArrayString(AchievementName, AchievementPos, FormatBufferName, sizeof(FormatBufferName));
	GetArrayString(AchievementDescription, AchievementPos, FormatBufferDescription, sizeof(FormatBufferDescription));
	GetArrayString(AchievementCategory, AchievementPos, FormatBufferCategory, sizeof(FormatBufferCategory));
	int progress = GetArrayCell(Player_AchievementProgress[client], i);
	int value = GetArrayCell(AchievementValue, AchievementPos);
	if(StrEqual(FormatBufferCategory, ""))
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "Name: %s\nDescription: %s\n \nProgress: %d/%d", FormatBufferName, FormatBufferDescription, progress, value);
	else
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "Name: %s\nDescription: %s\nCategory: %s\n \nProgress: %d/%d", FormatBufferName, FormatBufferDescription, FormatBufferCategory, progress, value);
	
	Menu menu = new Menu(DisplayAchievementDetails_Handler);
	
	menu.SetTitle(FormatBufferTitle);
	menu.AddItem("back", "Back");
	
	menu.ExitButton=false;
	menu.Display(client, 20);
}

public int DisplayAchievementDetails_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "back"))	ShowPlayerAchievements(client);
	}
}

public void ShowTop10(int client)
{
	Menu menu = new Menu(ShowTop10_Handler);
	menu.SetTitle("Current Top 10:");
	char FormatBuffer[MAX_NAME_LENGTH + 20];
	menu.AddItem("back", "Back");
	for (int i = 0; i < AmountOfLeaders;i++)
	{
		Format(FormatBuffer, sizeof(FormatBuffer), "%s (%d)", Top10Name[i], Top10Score[i]);
		menu.AddItem("hold", FormatBuffer);
	}
	
	menu.ExitButton=true;
	menu.Display(client, 30);	
}

public int ShowTop10_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		if (StrEqual(InfoBuffer, "back"))	TriggerAchievementsMenu(client);
		else if (!StrEqual(InfoBuffer, "hold"))	ShowTop10(client);
	}
}
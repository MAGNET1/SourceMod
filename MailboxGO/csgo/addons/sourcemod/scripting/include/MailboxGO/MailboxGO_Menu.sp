public Action ShowMailboxMenu(int client, int args)
{
	TriggerMailboxMenu(client);
	
	return Plugin_Continue;
}

public void TriggerMailboxMenu(int client)
{
	if(IsChanging[client] || IsCreatingNewMessage[client])
	{
		GoPrint(client, "%T", "End action", client);
		return;
	}
	IsManagingOrCreating[client] = NOTHING;
	IsBrowsingAnnouncements[client] = NO;
	
	if(isConnectedWithDB == false)
	{
		GoPrint(client, "%T", "Couldn't receive", client);
		GoPrint(client, "%T", "Ask server", client);
		return;
	}
	
	Menu menu = new Menu(ShowMailboxMenu_Handler);
	
	char FormatBuffer[128];
	Format(FormatBuffer, sizeof(FormatBuffer), "MailboxGO Menu");
	ConcatenateWithAlias(client, FormatBuffer, sizeof(FormatBuffer));
	menu.SetTitle(FormatBuffer);
	
	if(hasRootFlag(client))
	{
		Format(FormatBuffer, sizeof(FormatBuffer), "%T", "MainMenu_Create", client);
		menu.AddItem("create", FormatBuffer);
	}
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "MainMenu_Announcements", client);
	menu.AddItem("announcement", FormatBuffer);
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "MainMenu_New Message", client);
	menu.AddItem("new", FormatBuffer);
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "MainMenu_Open mailbox", client);
	menu.AddItem("open", FormatBuffer);

	menu.ExitButton=true;
	menu.Display(client, 20);	
}

// appends "[ROOT]" or "[VIP]" or "" alias at the end of the string 
public void ConcatenateWithAlias(client, char[] buffer, size)
{
	StrCat(buffer, size, hasRootFlag(client) ? " [ROOT]" : hasVipFlag(client) ? " [VIP]" : "");
}

public int ShowMailboxMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "announcement"))	BrowseAnnouncementsMenu(client);
		else if(StrEqual(InfoBuffer, "create"))	CreateNewMailboxMenu(client);
		else if (StrEqual(InfoBuffer, "open"))
		{
			IsManagingOrCreating[client] = MANAGING;
			BrowseMailboxesMenu(client);
		}
		else if(StrEqual(InfoBuffer, "new"))
		{
			IsManagingOrCreating[client] = CREATING;
			BrowseMailboxesMenu(client);
		}
	}
}

public void BrowseAnnouncementsMenu(int client)
{
	int AnnouncementMailboxesCount = CountAnnouncementMailboxes();
	
	IsBrowsingAnnouncements[client] = YES;

	Menu menu = new Menu(BrowseAnnouncements_Handler);
	
	char FormatBuffer[128];
	char FormatBufferInfo[128];
	
	if(AnnouncementMailboxesCount)
	{
		Format(FormatBuffer, sizeof(FormatBuffer), "%T", "BrowseAnouncements_Announcements", client);
		ConcatenateWithAlias(client, FormatBuffer, sizeof(FormatBuffer));
	}
	else	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "BrowseAnouncements_No announcements", client);
	
	menu.SetTitle(FormatBuffer);
	
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "BackButton", client);
	if(!AnnouncementMailboxesCount)	menu.AddItem("back", FormatBuffer); //"back"
	
	for (int i = 0; i < NumberOfMailboxes;i++)
	{
		if(isAnnouncementBox(i))
		{
			GetArrayString(BoxListName, i, FormatBuffer, sizeof(FormatBuffer));
			Format(FormatBufferInfo, sizeof(FormatBufferInfo), "%d", GetBoxIdByPos(i));
			menu.AddItem(FormatBufferInfo, FormatBuffer);
		}
	}

	menu.ExitButton=true;
	menu.Display(client, 20);
}

public int BrowseAnnouncements_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "back"))	TriggerMailboxMenu(client);
		else
		{
			int BoxListIndex = StringToInt(InfoBuffer);
			IsBrowsingAnnouncementsMailboxID[client] = BoxListIndex;
			BrowseMailboxMessages(client);
		}
	}
}

public int CountAnnouncementMailboxes()
{
	int NumberOfAnnouncementMailboxes;
	
	for (int i = 0; i < NumberOfMailboxes;i++)
	{
		if (isAnnouncementBox(i))	NumberOfAnnouncementMailboxes++;
	}
	
	return NumberOfAnnouncementMailboxes;
}

// checks whether given mailbox is an announcement box
public bool isAnnouncementBox(pos)
{
	return GetArrayCell(BoxListType, pos) == BOX_TYPE_ANNOUNCEMENT;
}

public void InformPlayerMailboxDeleted(int client)
{
	GoPrint(client, "%T", "Mailbox not exists", client);
}

public void DisplayBoxOptionsMenu(int client, int MailboxID)
{
	IsLoggingMailboxID[client] = MailboxID;
	int MailboxPosition = GetBoxPosById(MailboxID);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		return;
	}
	
	LoadMessagesOfCertainMailbox(MailboxID); // MailboxGO_SQLLoadData.sp

	Menu menu = new Menu(DisplayBoxOptionsMenu_Handler);
	
	int MailboxType = GetMailboxTypeByPosition(MailboxPosition);
	int MailboxCapacity = GetMailboxCapacityByPosition(MailboxPosition);
	int MailboxAmountOfMessages = GetMailboxAmountOfMessages(MailboxPosition);
	char MailboxName[32];
	GetMailboxNameByPosition(MailboxPosition, MailboxName, sizeof(MailboxName));
	char MailboxDescription[32];
	GetMailboxDescriptionByPosition(MailboxPosition, MailboxDescription, sizeof(MailboxDescription));
	
	char FormatBuffer[128];
	if(HasAccessToMailbox[client][MailboxPosition])
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "DisplayBoxOptions_Title", client, MailboxName, MailboxType == BOX_TYPE_PUBLIC ? "Public" : MailboxType == BOX_TYPE_LIMITED ? "Limited" : "Announcement", MailboxDescription, MailboxAmountOfMessages, MailboxCapacity);
	else
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "DisplayBoxOptions_Title HIDDEN", client, MailboxName, MailboxType == BOX_TYPE_PUBLIC ? "Public" : MailboxType == BOX_TYPE_LIMITED ? "Limited" : "Announcement", MailboxDescription);
	menu.SetTitle(FormatBuffer);
	
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "DisplayBoxOptions_Login", client);
	if(!IsLogged(client, MailboxPosition))	menu.AddItem("login", FormatBuffer);
	else
	{
		Format(FormatBuffer, sizeof(FormatBuffer), "%T", "DisplayBoxOptions_Show messages", client);
		menu.AddItem("manage", FormatBuffer);
		Format(FormatBuffer, sizeof(FormatBuffer), "%T", "DisplayBoxOptions_Change description", client);
		menu.AddItem("change_desc", FormatBuffer);	
		Format(FormatBuffer, sizeof(FormatBuffer), "%T", "DisplayBoxOptions_Change password", client);
		menu.AddItem("change_pass", FormatBuffer);
	}
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "DisplayBoxOptions_Delete mailbox", client);
	if(hasRootFlag(client))	menu.AddItem("delete", FormatBuffer);

	menu.ExitButton=true;
	menu.Display(client, 120);
}

public int IsLogged(int client, int MailboxPosition)
{
	return HasAccessToMailbox[client][MailboxPosition];
}

public int DisplayBoxOptionsMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "login"))	TurnOnLoggingAndInformPlayer(client);
		else if (StrEqual(InfoBuffer, "manage"))	BrowseMailboxMessages(client);
		else if (StrEqual(InfoBuffer, "change_desc"))	TurnOnChangingAndInformPlayer(client, CHANGING_DESCRIPTION);
		else if (StrEqual(InfoBuffer, "change_pass"))	TurnOnChangingAndInformPlayer(client, CHANGING_PASSWORD);
		else if (StrEqual(InfoBuffer, "delete"))	DeleteMailboxConfirmationMenu(client);
	}
}

public void DeleteMailboxConfirmationMenu(int client)
{
	int MailboxPosition = GetBoxPosById(IsLoggingMailboxID[client]);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		return;
	}
	
	char NameBuffer[32];
	char TitleBuffer[256];
	GetMailboxNameByPosition(MailboxPosition, NameBuffer, sizeof(NameBuffer));
	Format(TitleBuffer, sizeof(TitleBuffer), "%T", "DeleteMailbox_Confirmation", client, NameBuffer);
	Menu menu = new Menu(DeleteMailboxConfirmationMenu_Handler);
	menu.SetTitle(TitleBuffer);
	Format(TitleBuffer, sizeof(TitleBuffer), "%T", "DeleteMailbox_Yes", client, NameBuffer);
	menu.AddItem("yes", TitleBuffer);
	Format(TitleBuffer, sizeof(TitleBuffer), "%T", "DeleteMailbox_No", client, NameBuffer);
	menu.AddItem("no", TitleBuffer);
	menu.ExitButton=false;
	menu.Display(client, 120);	
}

public int DeleteMailboxConfirmationMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "yes"))	DeleteMailbox(client);
		else if (StrEqual(InfoBuffer, "no"))	DisplayBoxOptionsMenu(client, IsLoggingMailboxID[client]);
	}
}

public void TurnOnChangingAndInformPlayer(int client, int mode)
{
	IsChanging[client] = mode;
	IsChangingMailboxID[client] = IsLoggingMailboxID[client];
	GoPrint(client, "%T", "Change_Information", client, mode == CHANGING_PASSWORD ? "password" : "description");
}

public void GetMailboxNameByPosition(int position, char[] tab, int size)
{
	GetArrayString(BoxListName, position, tab, size);
}

public void GetMailboxPasswordByPosition(int position, char[] tab, int size)
{
	GetArrayString(BoxListPassword, position, tab, size);
}

public void GetMailboxDescriptionByPosition(int position, char[] tab, int size)
{
	GetArrayString(BoxListDescription, position, tab, size);
}

public int GetMailboxTypeByPosition(int position)
{
	return GetArrayCell(BoxListType, position);
}

public int GetMailboxCapacityByPosition(int position)
{
	return GetArrayCell(BoxListCapacity, position);
}

public int GetMailboxAmountOfMessages(int position)
{
	return GetArrayCell(BoxListAmountOfMessages, position);
}

public void TurnOnLoggingAndInformPlayer(int client)
{
	int MailboxPosition = GetBoxPosById(IsLoggingMailboxID[client]);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		return;
	}
	
	IsLogging[client] = YES;
	char MailboxName[32];
	GetMailboxNameByPosition(MailboxPosition, MailboxName, sizeof(MailboxName));
	GoPrint(client, "%T", "Password_Type", client, MailboxName);
}


public void BrowseMailboxMessages(int client)
{
	int MailboxID = IsBrowsingAnnouncements[client] ? IsBrowsingAnnouncementsMailboxID[client] : IsLoggingMailboxID[client];
	int MailboxPosition = GetBoxPosById(MailboxID );
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		return;
	}
	
	LoadMessagesOfCertainMailbox(MailboxID); // MailboxGO_SQLLoadData.sp
	
	PlayerMessageID[client] = 0;
	
	int MessagesIndex = FindMessagesIndexOfMailbox(MailboxPosition);
	
	char FormatBuffer[256];
	char FormatBufferInfo[32];
	char FormatBufferAuthor[MAX_NAME_LENGTH];
	char FormatBufferTopic[64];
	
	char FormatBufferTitle[128];
	char FormatBufferMailboxName[32];
	GetMailboxNameByPosition(MailboxPosition,  FormatBufferMailboxName, 31);
	
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "[%s] %T", FormatBufferMailboxName, "BrowseMessages_Title_List", client);
	
	Menu menu = new Menu(BrowseMailboxMessages_Handler);
	
	menu.SetTitle(FormatBufferTitle);
	
	if (AmountOfMessages(MessagesIndex) == 0)
	{
		Format(FormatBufferTitle, sizeof(FormatBufferTitle), "[%s] %T", FormatBufferMailboxName, "BrowseMessages_Title_List_No Messages", client);
		menu.SetTitle(FormatBufferTitle);
	}
	
	for (int i = 0; i < AmountOfMessages(MessagesIndex);i++)
	{
		GetArrayString(MessagesAuthorName[MessagesIndex], i, FormatBufferAuthor, sizeof(FormatBufferAuthor));
		GetArrayString(MessagesTopic[MessagesIndex], i, FormatBufferTopic, sizeof(FormatBufferTopic));
		int xMessageID = GetArrayCell(MessagesID[MessagesIndex], i);
		
		Format(FormatBufferInfo, sizeof(FormatBufferInfo), "%d", xMessageID);
		Format(FormatBuffer, sizeof(FormatBuffer), "%s (%s)", FormatBufferTopic, FormatBufferAuthor);
		menu.AddItem(FormatBufferInfo, FormatBuffer);
	}
	
	menu.AddItem("back", "Back");
	
	menu.ExitButton=true;
	menu.Display(client, 120);
	
}

public int BrowseMailboxMessages_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "back"))
		{
			if (IsBrowsingAnnouncements[client])	BrowseAnnouncementsMenu(client);
			else BrowseMailboxesMenu(client);
		}
		else
		{	
			PlayerMessageID[client] = StringToInt(InfoBuffer);
	
			if (IsBrowsingAnnouncements[client])	ShowMessage(client);
			else	DisplayMessageOptions(client);
		}
	}
}

public void InformPlayerMessageDeleted(int client)
{
	GoPrint(client, "%T", "Message deleted", client);
}

public int GetMessagePosById(int MessageBoxID, int MessageID)
{
	for (int i = 0; i < GetArraySize(MessagesID[MessageBoxID]);i++)
	{
		if (GetArrayCell(MessagesID[MessageBoxID], i) == MessageID)	return i;
	}
	return NOT_EXISTS;
}

public void DisplayMessageOptions(int client)
{
	int MailboxPosition = GetBoxPosById(IsLoggingMailboxID[client]);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		return;
	}
	
	int MessagesIndex = FindMessagesIndexOfMailbox(MailboxPosition);
	
	int MessagePosition = GetMessagePosById(MessagesIndex, PlayerMessageID[client]);
	
	if(MessagePosition == NOT_EXISTS)
	{
		InformPlayerMessageDeleted(client);
		return;
	}
	
	
	Menu menu = new Menu(DisplayMessageOptions_Handler);
	
	char FormatBufferTitle[512];
	char FormatBufferMailboxName[32];
	char FormatBufferMessageTitle[32];
	char FormatBufferTime[64];
	char FormatBufferAuthor[MAX_NAME_LENGTH];
	
	GetMailboxNameByPosition(MailboxPosition,  FormatBufferMailboxName, 31);
	GetArrayString(MessagesTopic[MessagesIndex], MessagePosition, FormatBufferMessageTitle, sizeof(FormatBufferMessageTitle));
	GetArrayString(MessagesAuthorName[MessagesIndex], MessagePosition, FormatBufferAuthor, sizeof(FormatBufferAuthor));
	GetArrayString(MessagesDate[MessagesIndex], MessagePosition, FormatBufferTime, sizeof(FormatBufferTime));
	
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "%T", "MessageOptions_Title", client, FormatBufferMailboxName, FormatBufferMessageTitle, FormatBufferAuthor, FormatBufferTime);
	
	menu.SetTitle(FormatBufferTitle);
	
	Format(FormatBufferTime, sizeof(FormatBufferTime), "%T", "MessageOptions_Show_message", client);
	menu.AddItem("show", FormatBufferTime);
	Format(FormatBufferTime, sizeof(FormatBufferTime), "%T", "MessageOptions_Delete", client);
	menu.AddItem("delete", FormatBufferTime);
	Format(FormatBufferTime, sizeof(FormatBufferTime), "%T", "MessageOptions_Show player info", client);
	if(hasRootFlag(client))	menu.AddItem("info", FormatBufferTime);
	Format(FormatBufferTime, sizeof(FormatBufferTime), "%T", "MessageOptions_Back", client);
	menu.AddItem("back", FormatBufferTime);
	menu.ExitButton=false;
	menu.Display(client, 120);
}

public int DisplayMessageOptions_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "show"))	ShowMessage(client);
		else if (StrEqual(InfoBuffer, "delete"))	DeleteMessage(client);
		else if (StrEqual(InfoBuffer, "info"))	ShowPlayerInfo(client);
		else if (StrEqual(InfoBuffer, "back"))	BrowseMailboxMessages(client);
		
	}
}

public void ShowPlayerInfo(int client)
{
	int MailboxPosition = GetBoxPosById(IsLoggingMailboxID[client]);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		return;
	}
	
	int MessagesIndex = FindMessagesIndexOfMailbox(MailboxPosition);
	
	int MessagePosition = GetMessagePosById(MessagesIndex, PlayerMessageID[client]);
	
	if(MessagePosition == NOT_EXISTS)
	{
		InformPlayerMessageDeleted(client);
		return;
	}
	
	Menu menu = new Menu(ShowPlayerInfo_Handler);
	
	char FormatBufferTitle[512];
	char FormatBufferAuthorName[MAX_NAME_LENGTH];
	char FormatBufferAuthorSid[64];
	
	GetArrayString(MessagesAuthorName[MessagesIndex], MessagePosition, FormatBufferAuthorName, sizeof(FormatBufferAuthorName));
	GetArrayString(MessagesAuthorSID[MessagesIndex], MessagePosition, FormatBufferAuthorSid, sizeof(FormatBufferAuthorSid));
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "%T", "ShowPlayerInfo_Title", client, FormatBufferAuthorName, FormatBufferAuthorSid);
	PrintToConsole(client, FormatBufferTitle);
	
	menu.SetTitle(FormatBufferTitle);
	
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "%T", "BackButton", client);
	menu.AddItem("back", FormatBufferTitle);
	menu.ExitButton=false;
	menu.Display(client, 120);
}

public int ShowPlayerInfo_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "back"))	DisplayMessageOptions(client);
		
	}
}

public void ShowMessage(int client)
{
	int MailboxPosition;
	
	if(IsBrowsingAnnouncements[client])	MailboxPosition = GetBoxPosById(IsBrowsingAnnouncementsMailboxID[client]);
	else MailboxPosition = GetBoxPosById(IsLoggingMailboxID[client]);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		return;
	}
	
	int MessagesIndex = FindMessagesIndexOfMailbox(MailboxPosition);
	
	int MessagePosition = GetMessagePosById(MessagesIndex, PlayerMessageID[client]);
	
	if(MessagePosition == NOT_EXISTS)
	{
		InformPlayerMessageDeleted(client);
		return;
	}
	
	Menu menu = new Menu(ShowMessage_Handler);
	
	char FormatBufferTitle[512];
	char FormatBufferMailboxName[32];
	char FormatBufferMessageTitle[32];
	char FormatBufferMessage[512];
	char FormatBufferAuthor[MAX_NAME_LENGTH];
	
	GetMailboxNameByPosition(MailboxPosition,  FormatBufferMailboxName, 31);
	GetArrayString(MessagesTopic[MessagesIndex], MessagePosition, FormatBufferMessageTitle, sizeof(FormatBufferMessageTitle));
	GetArrayString(MessagesAuthorName[MessagesIndex], MessagePosition, FormatBufferAuthor, sizeof(FormatBufferAuthor));
	GetArrayString(MessagesMessage[MessagesIndex], MessagePosition, FormatBufferMessage, sizeof(FormatBufferMessage));
	
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "%T", "ShowMessage_Title", client, FormatBufferMailboxName, FormatBufferMessageTitle, FormatBufferAuthor, FormatBufferMessage);
	
	menu.SetTitle(FormatBufferTitle);
	
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "%T", "BackButton", client);
	menu.AddItem("back", FormatBufferTitle);
	menu.ExitButton=false;
	menu.Display(client, 120);
}


public int ShowMessage_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "back"))
		{
			if (IsBrowsingAnnouncements[client])	BrowseMailboxMessages(client);
			else	DisplayMessageOptions(client);
		}
		
	}
}

public void DeleteMessage(int client)
{
	Menu menu = new Menu(DeleteMessage_Handler);
	
	char TitleBuffer[128];
	
	Format(TitleBuffer, sizeof(TitleBuffer), "%T", "DeleteMessage_Confirmation_Title", client);
	menu.SetTitle(TitleBuffer);
	
	Format(TitleBuffer, sizeof(TitleBuffer), "%T", "DeleteMessage_Confirmation_Yes", client);
	menu.AddItem("yes", TitleBuffer);
	Format(TitleBuffer, sizeof(TitleBuffer), "%T", "DeleteMessage_Confirmation_No", client);
	menu.AddItem("no", TitleBuffer);
	menu.ExitButton=false;
	menu.Display(client, 20);
}

public int DeleteMessage_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "yes"))	EraseMessage(client); //MailboxGO_Deleting.sp
		else if (StrEqual(InfoBuffer, "no"))	DisplayMessageOptions(client);
		
	}
}

public int GetBoxPosById(int MailboxID)
{
	for (int i = 0; i < NumberOfMailboxes;i++)
	{
		if (GetArrayCell(BoxListID, i) == MailboxID)	return i;
	}
	return NOT_EXISTS;
}

public int GetBoxIdByPos(int MailboxIndex)
{
	return GetArrayCell(BoxListID, MailboxIndex);
}

public int AmountOfMessages(int MessagesIndex)
{
	return GetArraySize(MessagesMessage[MessagesIndex]);
}

// based on the Mailbox array position, searches for an index(position) of corresponding Message Array
public int FindMessagesIndexOfMailbox(int MailboxPos)
{
	return GetArrayCell(BoxListMessagesArrayIndex, MailboxPos);
}

// returns ID of Mailbox on a certain position in handle array


public void CreateNewMailboxMenu(int client)
{
	if(IdOfAdminCreatingMailbox > 0)
	{
		GoPrint(client, "%T", "CreatingNewMailbox_Someone else", client);
		return;
	}
	
	if(NumberOfMailboxes >= MAX_AMOUNT_OF_MAILBOXES)
	{
		GoPrint(client, "%T", "CreatingNewMailbox_Max", client, MAX_AMOUNT_OF_MAILBOXES);
		return;
	}
	
	Menu menu = new Menu(CreateNewMailboxMenu_Handler);
	
	char FormatBuffer[256];
	Format(FormatBuffer, 256, "%T", "CreatingNewMailbox_Title", client, NumberOfMailboxes, MAX_AMOUNT_OF_MAILBOXES);
	menu.SetTitle(FormatBuffer);
	Format(FormatBuffer, 256, "%T", "CreatingNewMailbox_Yes", client);
	menu.AddItem("", FormatBuffer);
	Format(FormatBuffer, 256, "%T", "CreatingNewMailbox_No", client);
	menu.AddItem("", FormatBuffer);

	menu.ExitButton=false;
	menu.Display(client, 20);
	
}

public int CreateNewMailboxMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		switch(item)	
		{
			case 0:	SendInfoAndChangeFlag(client); // MailboxGO_CreatingNewMailbox.sp
			case 1:	GoPrint(client, "%T", "CreatingNewMailbox_No_Inform", client);
		}
	}
}

public void BrowseMailboxesMenu(int client)
{
	Menu menu = new Menu(BrowseMailboxesMenu_Handler);
	
	char FormatBuffer[128];
	
	if(AreThereAnyMailboxes())
	{
		Format(FormatBuffer, 127, "%T", "BrowseMailboxes_Title", client);
		ConcatenateWithAlias(client, FormatBuffer, 128);
	}
	else
	{
		Format(FormatBuffer, 127, "%T", "BrowseMailboxes_Title_No mailboxes", client);
		ConcatenateWithAlias(client, FormatBuffer, 128);
	}
	
	menu.SetTitle(FormatBuffer);
	
	Format(FormatBuffer, 127, "%T", "BackButton", client);
	if(!AreThereAnyMailboxes())	menu.AddItem("wroc", FormatBuffer);	
	
	for (int i = 0; i < NumberOfMailboxes;i++)
	{
		int MailboxType = GetMailboxTypeByPosition(i);
		
		if(!hasVipFlag(client) && !hasRootFlag(client))
		{
			if (MailboxType == BOX_TYPE_LIMITED || MailboxType == BOX_TYPE_ANNOUNCEMENT)	continue;
		}
		
		if(!hasRootFlag(client))
		{
			if (MailboxType == BOX_TYPE_ANNOUNCEMENT)	continue;
		}
		char FormatBufferInfo[6];
		char FormatBufferMailboxName[32];
		
		GetMailboxNameByPosition(i, FormatBufferMailboxName, 31);
		Format(FormatBufferInfo, 5, "%d", GetBoxIdByPos(i));
		Format(FormatBuffer, sizeof(FormatBuffer), "%s (%s)", FormatBufferMailboxName, MailboxType == BOX_TYPE_PUBLIC ? "Public" : MailboxType == BOX_TYPE_LIMITED ? "Limited" : "Announcement");
		
		menu.AddItem(FormatBufferInfo, FormatBuffer);	
	}

	menu.ExitButton=true;
	menu.Display(client, 20);
}

public int AreThereAnyMailboxes()
{
	return NumberOfMailboxes;
}

public int BrowseMailboxesMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		if (StrEqual(InfoBuffer, "wroc"))	TriggerMailboxMenu(client);
		int MailboxID = StringToInt(InfoBuffer);
		
		if(IsManagingOrCreating[client] == CREATING)	CreateNewMessage(client, MailboxID);
		else if (IsManagingOrCreating[client] == MANAGING)	DisplayBoxOptionsMenu(client, MailboxID);
	}
}

public void CreateNewMessage(client, MailboxID)
{
	int MailboxPosition = GetBoxPosById(MailboxID);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		return;
	}	
	
	char MailboxName[32];
	GetMailboxNameByPosition(MailboxPosition, MailboxName, sizeof(MailboxName));
	
	if(MailboxIsFull(MailboxPosition))
	{
		GoPrint(client, "%T", "CreateMessage_Box full", client, MailboxName);
		BrowseMailboxesMenu(client);
		return;
	}
	Menu menu = new Menu(CreateNewMessage_Handler);
	char FormatBuffer[512];
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "CreateMessage_Title", client, MailboxName);
	menu.SetTitle(FormatBuffer);
	
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "CreateMessage_Yes", client, MailboxName);
	menu.AddItem("yes", FormatBuffer);
	Format(FormatBuffer, sizeof(FormatBuffer), "%T", "CreateMessage_No", client, MailboxName);
	menu.AddItem("no", FormatBuffer);

	menu.ExitButton=false;
	menu.Display(client, 120);
	
	IsCreatingNewMessageMailboxID[client] = MailboxID;
}

public int CreateNewMessage_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		if (StrEqual(InfoBuffer, "no"))
		{
			IsCreatingNewMessageMailboxID[client] = 0;
			TriggerMailboxMenu(client);
		}
		else if (StrEqual(InfoBuffer, "yes"))
		{
			IsCreatingNewMessage[client] = CREATING_TITLE;
			GoPrint(client, "%T", "CreateMessage_Inform", client);
			InformPlayerKeepWriting(client);
			DisplayCurrentMessage(client);
		}
	}
}
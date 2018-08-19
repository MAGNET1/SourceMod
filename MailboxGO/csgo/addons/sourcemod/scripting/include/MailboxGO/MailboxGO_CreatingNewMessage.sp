public Action ProcessChatIfCreatingNewMessage(int client, int args)
{
	if (!isPlayerCreatingNewMessage(client))	return Plugin_Continue;
	if (isPlayerCreatingNewMailbox(client))	return Plugin_Stop;
	if (isPlayerLogging(client))	return Plugin_Stop;
	if (isPlayerChanging(client))	return Plugin_Stop;
	
	
	char ArgsBuffer[1024];
	char BufferForOneArg[128];
	
	// retrieving all the arguments and concatenating them as one
	for (int i = 1; i < args+1;i++)
	{
			GetCmdArg(i, BufferForOneArg, 127);
			
			StrCat(ArgsBuffer, 1023, BufferForOneArg);
			if(!isTheLastArgument(i, args))	StrCat(ArgsBuffer, 1023, " ");
	}
	
	GoPrint(client, "%T", "Entered value", client, ArgsBuffer);
	
	if(strcmp(ArgsBuffer, "abort", false) == 0)
	{
		CancelCreatingAndInformPlayer(client);
		return Plugin_Stop;
	}
	
	if(IsCreatingNewMessage[client] == CREATING_TITLE)
	{
		if(strlen(ArgsBuffer) > 20)
		{
			InformPlayerTooManyCharacters(client, 20);
			return Plugin_Stop;
		}
		
		if (GetArraySize(PlayerTitle[client]))	ClearArray(PlayerTitle[client]);
		
		PushArrayString(PlayerTitle[client], ArgsBuffer);
		
		IsCreatingNewMessage[client] = CREATING_MESSAGE;
	}
	else if(IsCreatingNewMessage[client] == CREATING_MESSAGE)
	{
		if(NumberOfLines(client) >= 5)
		{
			InformPlayerMaxLines(client);
			return Plugin_Stop;
		}
		
		if(strlen(ArgsBuffer) > 50)
		{
			InformPlayerTooManyCharacters(client, 50);
			return Plugin_Stop;
		}
		
		/*if(StrContains(ArgsBuffer, "\n"))
		{
			InformPlayerRestrictedCharacters(client);
			return Plugin_Handled;	
		}*/
		
		PushArrayString(PlayerMessage[client], ArgsBuffer);
	}
	
	DisplayCurrentMessage(client);
	
	return Plugin_Stop;
}

public int isPlayerCreatingNewMessage(int client)
{
	return IsCreatingNewMessage[client];
}

public void InformPlayerTooManyCharacters(int client, int limit)
{
	GoPrint(client, "%T", "CreateMessage_TooLong", client, limit);
}
public void InformPlayerRestrictedCharacters(int client)
{
	GoPrint(client, "%T", "CreateMessage_Restricted characters", client);
}
public void InformPlayerMaxLines(int client)
{
	GoPrint(client, "%T", "CreateMessage_Max lines 1", client);
	GoPrint(client, "%T", "CreateMessage_Max lines 2", client);
}

public void DisplayCurrentMessage(int client)
{
	int MailboxPosition = GetBoxPosById(IsCreatingNewMessageMailboxID[client]);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		DoTheClearing(client);
		return;
	}
	char FormatBufferEntireTitle[1024];
	char BufferTitle[64];
	BuildTitle(client, FormatBufferEntireTitle, sizeof(FormatBufferEntireTitle));
	
	Menu menu = new Menu(DisplayCurrentMessage_Handler);
	menu.SetTitle(FormatBufferEntireTitle);
	
	Format(BufferTitle, sizeof(BufferTitle), "%T", "CreateMessage_MessageMenu_Send", client);
	menu.AddItem("send", BufferTitle);
	Format(BufferTitle, sizeof(BufferTitle), "%T", "CreateMessage_MessageMenu_Delete line", client);
	menu.AddItem("delete_line", BufferTitle);
	Format(BufferTitle, sizeof(BufferTitle), "%T", "CreateMessage_MessageMenu_Cancel", client);
	menu.AddItem("cancel", BufferTitle);
	Format(BufferTitle, sizeof(BufferTitle), "%T", "CreateMessage_MessageMenu_Correct", client);
	menu.AddItem("correct", BufferTitle);

	menu.ExitButton=false;
	menu.Display(client, 120);
}

public void BuildTitle(int client, char[] tab, int size)
{
	char FormatBufferMessage[512];
	BuildEntireMessage(client, FormatBufferMessage, sizeof(FormatBufferMessage));
	char BufferMailboxName[64];
	char BufferTitle[32];
	int MailboxPosition = GetBoxPosById(IsCreatingNewMessageMailboxID[client]);
	Format(BufferTitle, sizeof(BufferTitle), "No title");
	if(GetArraySize(PlayerTitle[client]))	GetArrayString(PlayerTitle[client], 0, BufferTitle, sizeof(BufferTitle));
	GetMailboxNameByPosition(MailboxPosition, BufferMailboxName, sizeof(BufferMailboxName));
	Format(tab, size, "%T", "CreateMessage_MessageMenu_Title", client, BufferMailboxName, NumberOfLines(client), BufferTitle, FormatBufferMessage);
}

public void BuildEntireMessage(int client, char[] tab, int size)
{
	char FormatBufferLine[128];
	
	for (int i = 0; i < NumberOfLines(client);i++)
	{
		GetArrayString(PlayerMessage[client], i, FormatBufferLine, 127);
		StrCat(tab, size, FormatBufferLine);
		if(!IsLastLine(client, i))	StrCat(tab, size, "\n");
	}
}
public void InformPlayerKeepWriting(int client)
{
	GoPrint(client, "%T", "CreateMessage_Inform 1", client, NumberOfLines(client));
	GoPrint(client, "%T", "CreateMessage_Inform 2", client, NumberOfLines(client));
	GoPrint(client, "%T", "CreateMessage_Inform 3", client, NumberOfLines(client));
}

public int NumberOfLines(int client)
{
	return GetArraySize(PlayerMessage[client]);
}
public bool IsLastLine(int client, int i)
{
	return (i == GetArraySize(PlayerMessage[client]) - 1);
}
public int DisplayCurrentMessage_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		if (StrEqual(InfoBuffer, "send"))	SendMessage(client);
		else if (StrEqual(InfoBuffer, "delete_line"))	DeleteLineInMessage(client);
		else if (StrEqual(InfoBuffer, "cancel"))	CancelCreatingAndInformPlayer(client);
		else if (StrEqual(InfoBuffer, "correct"))	CorrectTitle(client);
	}
}

public void SendMessage(int client)
{
	int MailboxPosition = GetBoxPosById(IsCreatingNewMessageMailboxID[client]);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		return;
	}
	
	if(MailboxIsFull(MailboxPosition))
	{
		InformPlayerMailboxFilled(client);
		DoTheClearing(client);
		return;
	}
	
	if(!IsCreatingNewMessage[client])
	{
		InformPlayerCreatingCanceled(client);
		return;
	}
	
	if(NumberOfLines(client) == 0)
	{
		DisplayCurrentMessage(client);
		InformPlayerEmptyMessage(client);
		return;
	}
	
	FormatMessageInputDataAndSend(client);
}

public bool MailboxIsFull(int MailboxPos)
{
	return GetArrayCell(BoxListAmountOfMessages, MailboxPos) >= GetArrayCell(BoxListCapacity, MailboxPos);
}

public void InformPlayerMailboxFilled(int client)
{
	GoPrint(client, "%T", "CreateMessage_Someone filled", client);	
}

public void FormatMessageInputDataAndSend(int client)
{	
	char MessageBuffer[512];
	char TitleBuffer[32];
	char TimeBuffer[64];
	char AuthorNameBuffer[MAX_NAME_LENGTH];
	char AuthorSidBuffer[64];
	
	int MailboxPosition = GetBoxPosById(IsCreatingNewMessageMailboxID[client]);
	
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		return;
	}
	
	BuildEntireMessage(client, MessageBuffer, sizeof(MessageBuffer));
	GetArrayString(PlayerTitle[client], 0, TitleBuffer, sizeof(TitleBuffer));
	
	FormatTime(TimeBuffer, sizeof(TimeBuffer), "%d.%m.%Yr. %H:%M", GetTime());
	GetClientName(client, AuthorNameBuffer, sizeof(AuthorNameBuffer));
	GetClientAuthId(client, AuthId_Steam2, AuthorSidBuffer, sizeof(AuthorSidBuffer));
	
	int currAmountOfMessages = GetArrayCell(BoxListAmountOfMessages, MailboxPosition);
	
	SendNotificationToOtherPlayers(client, TitleBuffer);
	
	//@@ SQL
	char QueryBuffer[2048];
	Format(QueryBuffer, sizeof(QueryBuffer), "INSERT INTO `Messages`(`BoxID`,`Message`,`Topic`,`AuthorName`,`AuthorSID`,`AuthorUserID`,`Date`) VALUES(%d,'%s','%s','%s','%s',%d,'%s')", IsCreatingNewMessageMailboxID[client], MessageBuffer, TitleBuffer, AuthorNameBuffer, AuthorSidBuffer, GetClientOfUserId(client), TimeBuffer);
	DB.Query(ExecuteMessageInsertQuery, QueryBuffer, client, DBPrio_High);	
	
	SQL_ChangeAmountOfMessages(client, MailboxPosition, currAmountOfMessages + 1);
	
	GoPrint(client, "%T", "CreateMessage_Success", client);
	PlaySound_MessageSent(client);
	
}
public void SQL_ChangeAmountOfMessages(int client, int MailboxPos, int NewValue)
{
	char QueryBuffer[512];
	Format(QueryBuffer, sizeof(QueryBuffer), "UPDATE `BoxDetails` SET `AmountOfMessages`=%d WHERE `ID`=%d", NewValue, GetArrayCell(BoxListID, MailboxPos));
	DB.Query(ExecuteNewAmountQuery, QueryBuffer, _, DBPrio_High);	
	
	SetArrayCell(BoxListAmountOfMessages, MailboxPos, NewValue);
}

public void ExecuteNewAmountQuery(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could change amount of messages! Error: %s", error);
		return;
	}
}

public void DoTheClearing(int client)
{
	IsCreatingNewMessage[client] = 0;
	IsCreatingNewMessageMailboxID[client] = 0;
	ClearArray(PlayerMessage[client]);
	ClearArray(PlayerTitle[client]);
}

public void ExecuteMessageInsertQuery(Database db, DBResultSet results, const char[] error, any client)
{
	if (db == null)
	{
		LogMessage("Could not insert new message! Error: %s", error);
		GoPrint(client, "%T", "CreateMessage_Error", client);
		return;
	}
	
	// if no one has loaded this mailbox before, there's no point in downloading this data to RAM
	if (isMailboxAlreadyLoaded(IsCreatingNewMessageMailboxID[client]))
	{
		char query[128];
		Format(query, sizeof(query), "SELECT MAX(`ID`) FROM `Messages`");
		DB.Query(ReturnMessageIdQuery, query, client, DBPrio_High);
	}
	else DoTheClearing(client);
}

public void ReturnMessageIdQuery(Database db, DBResultSet results, const char[] error, any client)
{
	if (db == null)
	{
		LogMessage("Could not insert new message! Error: %s", error);
		GoPrint(client, "%T", "CreateMessage_Error", client);
		DoTheClearing(client);
		return;
	}
	int MailboxPosition = GetBoxPosById(IsCreatingNewMessageMailboxID[client]);
	int MessagesPosition = FindMessagesIndexOfMailbox(MailboxPosition);
	
	char MessageBuffer[512];
	char TitleBuffer[32];
	char AuthorNameBuffer[MAX_NAME_LENGTH];
	char AuthorSidBuffer[64];
	char TimeBuffer[32];
	
	BuildEntireMessage(client, MessageBuffer, sizeof(MessageBuffer));
	GetArrayString(PlayerTitle[client], 0, TitleBuffer, sizeof(TitleBuffer));
	GetClientName(client, AuthorNameBuffer, sizeof(AuthorNameBuffer));
	GetClientAuthId(client, AuthId_SteamID64, AuthorSidBuffer, sizeof(AuthorSidBuffer));
	FormatTime(TimeBuffer, sizeof(TimeBuffer), "%d.%m.%Yr. %H:%M", GetTime());
	
	PushArrayString(MessagesMessage[MessagesPosition], MessageBuffer);
	PushArrayString(MessagesTopic[MessagesPosition], TitleBuffer);
	PushArrayString(MessagesAuthorName[MessagesPosition], AuthorNameBuffer);
	PushArrayString(MessagesAuthorSID[MessagesPosition], AuthorSidBuffer);
	PushArrayString(MessagesDate[MessagesPosition], TimeBuffer);
	
	SQL_FetchRow(results);
	PushArrayCell(MessagesID[MessagesPosition], SQL_FetchInt(results, 0));
	
	DoTheClearing(client);
}

public void InformPlayerCreatingCanceled(int client)
{
	GoPrint(client, "%T", "CreateMessage_Canceled", client);
}

public void InformPlayerEmptyMessage(int client)
{
	GoPrint(client, "%T", "CreateMessage_Empty", client);
}

public void DeleteLineInMessage(int client)
{
	if(IsCreatingNewMessage[client])
	{
		if(GetArraySize(PlayerMessage[client]))	RemoveFromArray(PlayerMessage[client], GetArraySize(PlayerMessage[client]) - 1);
		DisplayCurrentMessage(client);
	}
}

public void CancelCreatingAndInformPlayer(int client)
{
	IsCreatingNewMessage[client] = 0;
	IsCreatingNewMessageMailboxID[client] = 0;
	ClearArray(PlayerMessage[client]);
	ClearArray(PlayerTitle[client]);
	GoPrint(client, "%T", "CreateMessage_Aborted", client);	
}

public void CorrectTitle(int client)
{
	if(IsCreatingNewMessage[client])
	{
		IsCreatingNewMessage[client] = CREATING_TITLE;
		ClearArray(PlayerTitle[client]);
		DisplayCurrentMessage(client);
		GoPrint(client, "%T", "CreateMessage_Correct 1", client);
		GoPrint(client, "%T", "CreateMessage_Correct 2", client);
	}
}

public void SendNotificationToOtherPlayers(int client, char[] title)
{
	char NameBuffer[MAX_NAME_LENGTH];
	char MailboxName[32];
	GetClientName(client, NameBuffer, sizeof(NameBuffer));
	int MailboxPosition = GetBoxPosById(IsCreatingNewMessageMailboxID[client]);
	GetMailboxNameByPosition(MailboxPosition, MailboxName, sizeof(MailboxName));
	
	for (int i = 0; i < MAXPLAYERS;i++)
	{
		if(HasAccessToMailbox[i][MailboxPosition])
		{
			GoPrint(client, "%T", "NewMessage 1", i, MailboxName);
			GoPrint(client, "%T", "NewMessage 2", i, NameBuffer, title);
			PlaySound_NewMessage(i);
		}
	}
}
// @@ Deleting certain message

public void EraseMessage(int client)
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
		PlayerMessageID[client] = 0;
		BrowseMailboxMessages(client);
	}
	
	ExecuteMessageDeleteQuery(client);
	
	RemoveFromArray(MessagesID[MessagesIndex], MessagePosition);
	RemoveFromArray(MessagesMessage[MessagesIndex], MessagePosition);
	RemoveFromArray(MessagesTopic[MessagesIndex], MessagePosition);
	RemoveFromArray(MessagesAuthorName[MessagesIndex], MessagePosition);
	RemoveFromArray(MessagesAuthorSID[MessagesIndex], MessagePosition);
	RemoveFromArray(MessagesDate[MessagesIndex], MessagePosition);
	
	int currAmountOfMessages = GetArrayCell(BoxListAmountOfMessages, MailboxPosition);
	SQL_ChangeAmountOfMessages(client, MailboxPosition, currAmountOfMessages - 1);
	
		
}

public void BackToMenu(int client)
{
	GoPrint(client, "%T", "DeleteMessage_Success", client);
	PlaySound_Deleted(client);
	BrowseMailboxMessages(client);
}

public void ExecuteMessageDeleteQuery(int client)
{
	char DeleteQuery[256];
	Format(DeleteQuery, sizeof(DeleteQuery), "DELETE FROM `Messages` WHERE `ID`=%d", PlayerMessageID[client]);
	DB.Query(DeleteMessageQuery, DeleteQuery, client, DBPrio_High);
}

public void DeleteMessageQuery(Database db, DBResultSet results, const char[] error, any client)
{
	if (db == null)
	{
		LogMessage("Couldn't delete message! Error: %s", error);
		GoPrint(client, "%T", "DeleteMessage_Error", client);
		PlayerMessageID[client] = 0;
		return;
	}
	PlayerMessageID[client] = 0;
	BackToMenu(client);
}

// @@ Deleting entire Mailbox

public void DeleteMailbox(int client)
{
	int MailboxPosition = GetBoxPosById(IsLoggingMailboxID[client]);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		return;
	}
	
	NumberOfMailboxes--;
	
	int MessagesIndex = FindMessagesIndexOfMailbox(MailboxPosition);
	
	if(MessagesIndex != NOT_EXISTS)
	{
		ClearArray(MessagesID[MessagesIndex]);
		ClearArray(MessagesMessage[MessagesIndex]);
		ClearArray(MessagesTopic[MessagesIndex]);
		ClearArray(MessagesAuthorName[MessagesIndex]);
		ClearArray(MessagesAuthorSID[MessagesIndex]);
		ClearArray(MessagesDate[MessagesIndex]);
	}
	
	RemoveFromArray(BoxListID, MailboxPosition);
	RemoveFromArray(BoxListName, MailboxPosition);
	RemoveFromArray(BoxListDescription, MailboxPosition);
	RemoveFromArray(BoxListPassword, MailboxPosition);
	RemoveFromArray(BoxListCapacity, MailboxPosition);
	RemoveFromArray(BoxListAmountOfMessages, MailboxPosition);
	RemoveFromArray(BoxListType, MailboxPosition);
	RemoveFromArray(BoxListMessagesArrayIndex, MailboxPosition);
	
	ExecuteDeleteMailbox(client);
	ExecuteDeleteAllTheMessages(client);
	
	RemoveAccessToMailbox(MailboxPosition);
	
	CreateTimer(1.0, GoBackToMenu, client);
	
}

public Action GoBackToMenu(Handle timer, any client)
{
	BrowseMailboxesMenu(client);
	IsLoggingMailboxID[client] = 0;
	GoPrint(client, "%T", "DeleteMailbox_Succcess", client);
	PlaySound_Deleted(client);
}

public void ExecuteDeleteMailbox(int client)
{
	char DeleteQuery[256];
	Format(DeleteQuery, sizeof(DeleteQuery), "DELETE FROM `BoxDetails` WHERE `ID`=%d", IsLoggingMailboxID[client]);
	DB.Query(DeleteMailboxQuery, DeleteQuery, client, DBPrio_High);
}

public void DeleteMailboxQuery(Database db, DBResultSet results, const char[] error, any client)
{
	if (db == null)
	{
		LogMessage("Couldn't delete mailbox! Error: %s", error);
		GoPrint(client, "%T", "DeleteMessage_Error", client);
		return;
	}
	
}

public void ExecuteDeleteAllTheMessages(int client)
{
	char DeleteQuery[256];
	Format(DeleteQuery, sizeof(DeleteQuery), "DELETE FROM `Messages` WHERE `BoxID`=%d", IsLoggingMailboxID[client]);
	DB.Query(DeleteAllTheMessagesQuery, DeleteQuery, client, DBPrio_High);
}
public void DeleteAllTheMessagesQuery(Database db, DBResultSet results, const char[] error, any client)
{
	if (db == null)
	{
		LogMessage("Couldn't delete the messages! Error: %s", error);
		GoPrint(client, "%T", "DeleteMessage_Error", client);
		return;
	}
}

public void RemoveAccessToMailbox(int MailboxPosition)
{
	for (int i = 0; i < MAXPLAYERS; i++)	HasAccessToMailbox[i][MailboxPosition] = 0;
}
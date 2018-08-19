public Action ProcessChatIfChangingMailboxDetails(int client, int args)
{
	if (!isPlayerChanging(client))	return Plugin_Continue;
	if (isPlayerCreatingNewMailbox(client))	return Plugin_Stop;
	if (isPlayerCreatingNewMessage(client))	return Plugin_Stop;
	if (isPlayerLogging(client))	return Plugin_Stop;
	
	if(GetArraySize(ChangesBuffer[client]) > 0)
	{
		AbortChangingSomethingAlreadyIn(client);
		return Plugin_Stop;
	}
	
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
	
	if(IsChanging[client] == CHANGING_DESCRIPTION)
	{
		if(strlen(ArgsBuffer) > 30)
		{
			AbortChangingDescriptionTooLong(client, CHANGING_DESCRIPTION, 30);
			return Plugin_Stop;
		}
		PushArrayString(ChangesBuffer[client], ArgsBuffer);
		ConfirmationMenu(client);
		return Plugin_Stop;
	}
	else if(IsChanging[client] == CHANGING_PASSWORD)
	{
		if(strlen(ArgsBuffer) > 20)
		{
			AbortChangingDescriptionTooLong(client, CHANGING_PASSWORD, 20);
			return Plugin_Stop;
		}
		if(MailboxExists(ArgsBuffer))
		{
			AbortChangingMailboxExists(client);
			return Plugin_Stop;
		}
		PushArrayString(ChangesBuffer[client], ArgsBuffer);
		ConfirmationMenu(client);
		return Plugin_Stop;
	}
	
	// if someone get to this point, something went wrong...
	ResetChangeFlags(client);
	return Plugin_Stop;
	
}

public int isPlayerChanging(int client)
{
	return IsChanging[client];
}

public void ResetChangeFlags(int client)
{
	IsChanging[client] = 0;
	IsChangingMailboxID[client] = 0;
}
public void AbortChangingDescriptionTooLong(int client, int mode, int characters)
{
	GoPrint(client, "%T", "ChangeMailbox_TooLong 1", client, mode == CHANGING_DESCRIPTION ? "description" : "password", characters );
	GoPrint(client, "%T", "ChangeMailbox_TooLong 2", client, mode == CHANGING_DESCRIPTION ? "description" : "password");
	
	DisplayBoxOptionsMenu(client, IsChangingMailboxID[client]);
	
	ResetChangeFlags(client);
}

public void AbortChangingMailboxExists(int client)
{
	GoPrint(client, "%T", "ChangeMailbox_Already exists 1", client);
	GoPrint(client, "%T", "ChangeMailbox_Already exists 2", client);
	
	DisplayBoxOptionsMenu(client, IsChangingMailboxID[client]);
	
	ResetChangeFlags(client);
}

public void AbortChangingSomethingAlreadyIn(int client)
{
	GoPrint(client, "%T", "ChangeMailbox_Already entered 1", client);
	GoPrint(client, "%T", "ChangeMailbox_Already entered 2", client);
	
	ConfirmationMenu(client);
}

public void ConfirmationMenu(int client)
{
	Menu menu = new Menu(ConfirmationMenu_Handler);
	
	char FormatBufferTitle[256];
	char FormatBufferData[40];
	GetArrayString(ChangesBuffer[client], 0, FormatBufferData, sizeof(FormatBufferData));
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "%T", "ChangeMailbox_Confirmation_Title", client, IsChanging[client] == CHANGING_DESCRIPTION ? "description" : "password", FormatBufferData);
	menu.SetTitle(FormatBufferTitle);
	
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "%T", "ChangeMailbox_Confirmation_Yes", client);
	menu.AddItem("yes", FormatBufferTitle);
	Format(FormatBufferTitle, sizeof(FormatBufferTitle), "%T", "ChangeMailbox_Confirmation_No", client);
	menu.AddItem("no", FormatBufferTitle);
	menu.ExitButton=false;
	menu.Display(client, 120);
}

public int ConfirmationMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char InfoBuffer[32];
		
		menu.GetItem(item, InfoBuffer, sizeof(InfoBuffer));
		
		if (StrEqual(InfoBuffer, "yes"))	MakeChanges(client);
		else if (StrEqual(InfoBuffer, "no"))	DenyChanges(client);
	}
}

public void MakeChanges(int client)
{
	char FormatBufferData[40];
	
	GetArrayString(ChangesBuffer[client], 0, FormatBufferData, sizeof(FormatBufferData));
	
	int MailboxPosition = GetBoxPosById(IsChangingMailboxID[client]);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		ResetChangeFlags(client);
		return;
	}
	
	if(IsChanging[client] == CHANGING_DESCRIPTION)
		SetArrayString(BoxListDescription, MailboxPosition, FormatBufferData);
	else
		SetArrayString(BoxListPassword, MailboxPosition, FormatBufferData);
		
	char InsertQuery[512];
	Format(InsertQuery, sizeof(InsertQuery), "UPDATE `BoxDetails` SET `%s`='%s' WHERE `ID`=%d", IsChanging[client] == CHANGING_DESCRIPTION ? "Description" : "Password", FormatBufferData, IsChangingMailboxID[client]);
	DB.Query(ExecuteChangesQuery, InsertQuery, _, DBPrio_High);	
	
	GoPrint(client, "%T", "ChangeMailbox_Success_Inform", client, IsChanging[client] == CHANGING_DESCRIPTION ? "description" : "password");
	PlaySound_Success(client);
	ClearArray(ChangesBuffer[client]);
	DisplayBoxOptionsMenu(client, IsChangingMailboxID[client]);
	ResetChangeFlags(client);
}
public void ExecuteChangesQuery(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not change the details of mailbox! Error: %s", error);
		return;
	}
}

public void DenyChanges(client)
{
	GoPrint(client, "%T", "ChangeMailbox_Deny changes", client, IsChanging[client] == CHANGING_DESCRIPTION ? "description" : "password");
	ClearArray(ChangesBuffer[client]);
	DisplayBoxOptionsMenu(client, IsChangingMailboxID[client]);
	ResetChangeFlags(client);
}
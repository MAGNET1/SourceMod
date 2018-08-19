// sends info and turns flag on, that allows to process chat message
public void SendInfoAndChangeFlag(int client)
{
	GoPrint(client, "%T", "CreateMailbox_EntryInformation 1", client);
	GoPrint(client, "%T", "CreateMailbox_EntryInformation 2", client);

	
	ProgressOfCreatingMailbox = CREATING_NAME;
	IdOfAdminCreatingMailbox = client;
}

public Action ProcessChatIfCreatingNewMailbox(int client, int args)
{
	if (!isPlayerCreatingNewMailbox(client))	return Plugin_Continue;
	if (isPlayerCreatingNewMessage(client))	return Plugin_Stop;
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
	
	switch(ProgressOfCreatingMailbox)
	{
		case CREATING_NAME:
		{
			if(strlen(ArgsBuffer) > 15)
			{
				AbortCreatingNewMailboxMaxCharacters(client);
				return Plugin_Stop;
			}
			if(MailboxExists(ArgsBuffer))
			{
				AbortCreatingNewMailboxAlreadyExists(client);
				return Plugin_Stop;
			}
			strcopy(NewBoxName, 63, ArgsBuffer);
			SetToDescription(client);
		}
		case CREATING_DESCRIPTION:
		{
			if(strlen(ArgsBuffer) > 30)
			{
				AbortCreatingNewMailboxMaxCharacters(client);
				return Plugin_Stop;
			}
			strcopy(NewBoxDescription, 63, ArgsBuffer);
			SetToPassword(client);
		}
		case CREATING_PASSWORD:
		{
			if(strlen(ArgsBuffer) > 20)
			{
				AbortCreatingNewMailboxMaxCharacters(client);
				return Plugin_Stop;
			}
			strcopy(NewBoxPassword, 63, ArgsBuffer);
			SetToCapacity(client);
		}
		case CREATING_CAPACITY:
		{
			NewBoxCapacity = StringToInt(ArgsBuffer);
			if(NewBoxCapacity <= 0)
			{
				AbortCreatingNewMailbox(client);
				return Plugin_Stop;
			}
			if (NewBoxCapacity > 50)	NewBoxCapacity = MAX_MAILBOX_CAPACITY;
			SetToType(client);
		}
		case CREATING_TYPE:
		{
			NewBoxType = StringToInt(ArgsBuffer);
			if(NewBoxType != 1 && NewBoxType != 2 && NewBoxType != 3)
			{
				AbortCreatingNewMailbox(client);
				return Plugin_Stop;
			}
			SetToConfirmation(client);
			ShowConfirmationMenu(client);
		}
		case CREATING_CONFIRMATION:
		{
			if(strcmp(ArgsBuffer, "abort", false) == 0)
			{
				AbortCreatingNewMailboxMenuDisappeared(client);
				return Plugin_Stop;
			}
			GoPrint(client, "%T", "CreateMailbox_Inform_Abort", client);
		}
	}
	
	return Plugin_Stop;
}

public int MailboxExists(char[] MailboxName)
{
	char NameBuffer[32];
	for (int i = 0; i < GetArraySize(BoxListName);i++)
	{
		GetArrayString(BoxListName, i, NameBuffer, sizeof(NameBuffer));
		if (StrEqual(NameBuffer, MailboxName))	return 1;
	}
	return 0;
}
// checks if a certain player (admin) is currently creating new mailbox
public int isPlayerCreatingNewMailbox(int client)
{
	return IdOfAdminCreatingMailbox == client;
}

public int isTheLastArgument(int i, int args)
{
	return i == args;
}

public void ResetFlags()
{
	ProgressOfCreatingMailbox = 0;
	IdOfAdminCreatingMailbox = 0;
}

public void AbortCreatingNewMailbox(int client)
{
	GoPrint(client, "%T", "CreateMailbox_Abort 1", client);
	GoPrint(client, "%T", "CreateMailbox_Abort general", client);
	
	ResetFlags();
}

public void AbortCreatingNewMailboxAlreadyExists(int client)
{
	GoPrint(client, "%T", "CreateMailbox_Abort_Already exists", client);
	GoPrint(client, "%T", "CreateMailbox_Abort general", client);
	
	ResetFlags();
}
public void AbortCreatingNewMailboxMaxCharacters(int client)
{
	GoPrint(client, "%T", "CreateMailbox_Abort_Max characters", client);
	GoPrint(client, "%T", "CreateMailbox_Abort general", client);
	
	ResetFlags();
}

public void AbortCreatingNewMailboxMenuDisappeared(int client)
{
	GoPrint(client, "%T", "CreateMailbox_Abort general", client);
	
	ResetFlags();
}

public void SetToDescription(int client)
{
	ProgressOfCreatingMailbox = CREATING_DESCRIPTION;
	GoPrint(client, "%T", "CreateMailbox_Enter_Description 1", client);
	GoPrint(client, "%T", "CreateMailbox_Enter_Description 2", client);
}

public void SetToPassword(int client)
{
	ProgressOfCreatingMailbox = CREATING_PASSWORD;
	GoPrint(client, "%T", "CreateMailbox_Enter_Password 1", client);
	GoPrint(client, "%T", "CreateMailbox_Enter_Password 2", client);
}

public void SetToCapacity(int client)
{
	ProgressOfCreatingMailbox = CREATING_CAPACITY;
	GoPrint(client, "%T", "CreateMailbox_Enter_Capacity 1", client);
	GoPrint(client, "%T", "CreateMailbox_Enter_Capacity 2", client, MAX_MAILBOX_CAPACITY);
}

public void SetToType(int client)
{
	ProgressOfCreatingMailbox = CREATING_TYPE;
	GoPrint(client, "%T", "CreateMailbox_Enter_Type 1", client);
	GoPrint(client, "%T", "CreateMailbox_Enter_Type 2", client, BOX_TYPE_PUBLIC);
	GoPrint(client, "%T", "CreateMailbox_Enter_Type 3", client, BOX_TYPE_LIMITED);
	GoPrint(client, "%T", "CreateMailbox_Enter_Type 4", client, BOX_TYPE_ANNOUNCEMENT);
}

public void SetToConfirmation(int client)
{
	ProgressOfCreatingMailbox = CREATING_CONFIRMATION;
	GoPrint(client, "%T", "CreateMailbox_Confirmation_Info 1", client);
	GoPrint(client, "%T", "CreateMailbox_Confirmation_Info 2", client);
}

public ShowConfirmationMenu(int client)
{
	Menu menu = new Menu(ShowConfirmationMenu_Handler);
	
	char TitleBuffer[1024];
	Format(TitleBuffer, 1023, "%T", "CreateMailbox_Confirmation_Menu_Title", client, NewBoxName, NewBoxDescription, NewBoxPassword, NewBoxCapacity, NewBoxType == 1 ? "Public" : NewBoxType == 2 ? "Limited" : "Announcement Box");
	
	menu.SetTitle(TitleBuffer);
	
	Format(TitleBuffer, 1023, "%T", "CreateMailbox_Yes", client);
	menu.AddItem("", TitleBuffer);
	Format(TitleBuffer, 1023, "%T", "CreateMailbox_No", client);
	menu.AddItem("", TitleBuffer);

	menu.ExitButton=false;
	menu.Display(client, 60);
}
public int ShowConfirmationMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		switch(item)	
		{
			case 0:	FinaliseCreatingNewMailbox(client);
			case 1:
			{
				GoPrint(client, "%T", "CreateMailbox_Resign", client);
				ResetFlags();
			}
		}
	}
}

public void FinaliseCreatingNewMailbox(int client)
{
	if (!isPlayerCreatingNewMailbox(client))	return;
	
	InsertMailboxToDatabase();
	
	InformAdminInsertionComplete(client);
	
	ResetFlags();
	
	//ClearTabsHoldingNewMailboxInfo();
	
	NumberOfMailboxes++;
	
}

public void InsertMailboxToDatabase()
{
	char InsertQuery[512];
	FormatInsertQuery(InsertQuery);
	DB.Query(ExecuteInsertQuery, InsertQuery, _, DBPrio_High);	
}

public void FormatInsertQuery(char[] query)
{
	Format(query, 511, "INSERT INTO `BoxDetails`(`Name`,`Password`,`Capacity`,`AmountOfMessages`,`Type`,`Description`) VALUES('%s','%s',%d,0,%d,'%s')", NewBoxName, NewBoxPassword, NewBoxCapacity, NewBoxType, NewBoxDescription);
}

public void ExecuteInsertQuery(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not insert new mailbox! Error: %s", error);
		return;
	}
	
	char SelectQuery[512];
	FormatSelectNewMailboxIdQuery(SelectQuery);
	DB.Query(ExecuteSelectNewMailboxIdQuery, SelectQuery, _, DBPrio_High);	
}

public void FormatSelectNewMailboxIdQuery(char[] query)
{
	Format(query, 511, "SELECT MAX(`ID`) FROM `BoxDetails`");
}

public void ExecuteSelectNewMailboxIdQuery(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not select new mailbox ID! Error: %s", error);
		return;
	}
	
	while(SQL_FetchRow(results))
	{	
		PushArrayCell(BoxListID, SQL_FetchInt(results, 0));
	}
	
	PushNewMailboxToArrays();
}

public void PushNewMailboxToArrays()
{
	PushArrayString(BoxListName, NewBoxName);
	PushArrayString(BoxListPassword, NewBoxPassword);
	PushArrayCell(BoxListCapacity, NewBoxCapacity);
	PushArrayCell(BoxListAmountOfMessages, 0);
	PushArrayCell(BoxListType, NewBoxType);
	PushArrayString(BoxListDescription, NewBoxDescription);
	PushArrayCell(BoxListMessagesArrayIndex, -1);
}	

public void InformAdminInsertionComplete(int client)
{
	GoPrint(client, "%T", "CreateMailbox_Successfully", client, NewBoxName);
	PlaySound_Success(client);
}

public void ClearTabsHoldingNewMailboxInfo()
{
	ClearToZero(NewBoxName, sizeof(NewBoxName));
	ClearToZero(NewBoxPassword, sizeof(NewBoxPassword));
	ClearToZero(NewBoxDescription, sizeof(NewBoxDescription));
	NewBoxCapacity = 0;
	NewBoxType = 0;
}

public void ClearToZero(char[] tab, int size)
{
	Format(tab, size, "");
}
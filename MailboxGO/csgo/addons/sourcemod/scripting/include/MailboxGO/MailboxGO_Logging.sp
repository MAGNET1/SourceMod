public Action ProcessChatIfLogging(int client, int args)
{
	if (!isPlayerLogging(client))	return Plugin_Continue;
	if (isPlayerCreatingNewMessage(client))	return Plugin_Stop;
	if (isPlayerCreatingNewMailbox(client))	return Plugin_Stop;
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
	
	int MailboxPosition = GetBoxPosById(IsLoggingMailboxID[client]);
	
	if(MailboxPosition == NOT_EXISTS)
	{
		InformPlayerMailboxDeleted(client);
		IsLogging[client] = NO;
		return Plugin_Stop;
	}
	
	char PasswordBuffer[32];
	GetMailboxPasswordByPosition(MailboxPosition, PasswordBuffer, sizeof(PasswordBuffer));
	
	if(StrEqual(ArgsBuffer, PasswordBuffer))
	{
		HasAccessToMailbox[client][MailboxPosition] = YES;
		GoPrint(client, "%T", "Login_Success", client);
		PlaySound_LoggedIn(client);
	}
	else
	{
		GoPrint(client, "%T", "Login_Failure", client);
		PlaySound_WrongPassword(client);
	}
	
	IsLogging[client] = NO;
	DisplayBoxOptionsMenu(client, IsLoggingMailboxID[client]);
	
	return Plugin_Stop;
	
}

public int isPlayerLogging(int client)
{
	return IsLogging[client];
}
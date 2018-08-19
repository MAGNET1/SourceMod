// file contains reading both the mailbox list and messages of a certain box

// @@ loading mailbox list
public void InitRetrievingMailboxList()
{
	char QueryBuffer[256];
	FormatMailboxListQueryBuffer(QueryBuffer);
	DB.Query(FillArraysWithMailboxList, QueryBuffer, _, DBPrio_High);
}

public void FormatMailboxListQueryBuffer(char[] buffer)
{
	Format(buffer, 255, "SELECT * FROM `BoxDetails`");
}

public void FillArraysWithMailboxList(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null)
	{
		LogMessage("Server couldn't get the mailbox list data! Error: %s", error);
		return;
	}
	
	char FetchBuffer[128];
	
	while(SQL_FetchRow(results))
	{
		// Box ID
		PushArrayCell(BoxListID, SQL_FetchInt(results, 0));
		
		// Box Name
		SQL_FetchString(results, 1, FetchBuffer, sizeof(FetchBuffer));
		PushArrayString(BoxListName, FetchBuffer);
		
		// Box Password
		SQL_FetchString(results, 2, FetchBuffer, sizeof(FetchBuffer));
		PushArrayString(BoxListPassword, FetchBuffer);
		
		// Box Capacity
		PushArrayCell(BoxListCapacity, SQL_FetchInt(results, 3));
		
		// Box Amount of messages
		PushArrayCell(BoxListAmountOfMessages, SQL_FetchInt(results, 4));
		
		// Box Type
		PushArrayCell(BoxListType, SQL_FetchInt(results, 5));
		
		// Box Description
		SQL_FetchString(results, 6, FetchBuffer, sizeof(FetchBuffer));
		PushArrayString(BoxListDescription, FetchBuffer);
		
		// Corresponding 'Messages' array
		PushArrayCell(BoxListMessagesArrayIndex, -1);
		
		//used to move forward + after the loop is done we have a total number of mailboxes
		NumberOfMailboxes++;
	}
}

// @@ loading messages of a certain mailbox

public void LoadMessagesOfCertainMailbox(int MailboxID)
{
	int MailboxPosition = GetBoxPosById(MailboxID);
	
	if (MailboxPosition == NOT_EXISTS)	return;
	
	if (isMailboxAlreadyLoaded(MailboxID))	return;
	
	// connects 'BoxList' and 'Messages' arrays - from now on, 'boxList' holds index of corresponding 'messages' array
	SetArrayCell(BoxListMessagesArrayIndex, MailboxPosition, FirstFreeArrayIndex);
	
	char QueryBuffer[256];
	FormatMailboxMessagesQueryBuffer(QueryBuffer, MailboxID);
	DB.Query(RetrieveMessagesOfCertainMailbox, QueryBuffer, _, DBPrio_High);
}

public void getArrayIndexByMailboxPosition(int MailboxPos)
{
	return GetArrayCell(BoxListID, MailboxPos);
}


public bool isMailboxAlreadyLoaded(int MailboxID)
{
	int MailboxPosition = GetBoxPosById(MailboxID);
	
	if (MailboxPosition == NOT_EXISTS)	return false;
	
	if (GetArrayCell(BoxListMessagesArrayIndex, MailboxPosition) == -1)	return false;
	return true;
}

public void FormatMailboxMessagesQueryBuffer(char[] buffer, MailboxID)
{
	Format(buffer, 255, "SELECT * FROM `Messages` WHERE `BoxID` = %d", MailboxID);
}

public void RetrieveMessagesOfCertainMailbox(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null)
	{
		LogMessage("Server couldn't get the mailbox messages! Error: %s", error);
		return;
	}
	
	char FetchBuffer[128];
	
	while(SQL_FetchRow(results))
	{	
		
		// Message unique ID
		PushArrayCell(MessagesID[FirstFreeArrayIndex], SQL_FetchInt(results, 0));
		
		// Message
		SQL_FetchString(results, 2, FetchBuffer, sizeof(FetchBuffer));
		PushArrayString(MessagesMessage[FirstFreeArrayIndex], FetchBuffer);
		
		// Topic
		SQL_FetchString(results, 3, FetchBuffer, sizeof(FetchBuffer));
		PushArrayString(MessagesTopic[FirstFreeArrayIndex], FetchBuffer);
		
		// Author name
		SQL_FetchString(results, 4, FetchBuffer, sizeof(FetchBuffer));
		PushArrayString(MessagesAuthorName[FirstFreeArrayIndex], FetchBuffer);
		
		// Author SID
		SQL_FetchString(results, 5, FetchBuffer, sizeof(FetchBuffer));
		PushArrayString(MessagesAuthorSID[FirstFreeArrayIndex], FetchBuffer);
		
		// Date
		SQL_FetchString(results, 7, FetchBuffer, sizeof(FetchBuffer));
		PushArrayString(MessagesDate[FirstFreeArrayIndex], FetchBuffer);
	}
	
	FirstFreeArrayIndex++;
}

public int getArrayIndexByMailboxId(int MailboxIndex)
{
	for (int i = 0; i < NumberOfMailboxes;i++)
	{
		if (GetArrayCell(BoxListID, i) == MailboxIndex)	return i;
	}
	return -1;
}
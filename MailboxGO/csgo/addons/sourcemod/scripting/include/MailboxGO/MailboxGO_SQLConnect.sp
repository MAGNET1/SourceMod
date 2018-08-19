public void SQL_InitConnection()
{
	SQL_ConnectToDB();
	SQL_Create_BoxDetails_Table();
	SQL_Create_Messages_Table();
}

public void SQL_ConnectToDB()
{
	char sError[512];
	DB = SQLite_UseDatabase("MailboxDB",sError,sizeof(sError));
	
	SQL_CheckIfConnected(sError);
}

public void SQL_CheckIfConnected(char[] sError)
{
	if (DB == null)
	{
		LogMessage("Could not connect to the DataBase! Error: %s", sError);
	}
	else	isConnectedWithDB = true;
}

// Creating 'BoxDetails' Table
public void SQL_Create_BoxDetails_Table()
{
	if(isConnectedWithDB)
	{
		char query[512];
		Format_BoxDetails_Query(query);
		DB.Query(CheckIf_BoxDetails_QueryPassed, query, _, DBPrio_High);
	}
}

public void Format_BoxDetails_Query(char[] query)
{
	Format(query, 511, "CREATE TABLE `BoxDetails` (`ID`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,`Name`	TEXT NOT NULL,`Password`	TEXT NOT NULL,`Capacity`	INTEGER NOT NULL,`AmountOfMessages`	INTEGER NOT NULL,`Type`	INTEGER NOT NULL,`Description`	TEXT); ");	
}
public void CheckIf_BoxDetails_QueryPassed(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not create BoxDetails table! Error: %s", error);
	}
}
// Creating 'Messages' Table
public void SQL_Create_Messages_Table()
{
	if(isConnectedWithDB)
	{
		char query[512];
		Format_Messages_Query(query);
		DB.Query(CheckIf_Messages_QueryPassed, query, _, DBPrio_High);
	}
}

public void Format_Messages_Query(char[] query)
{
	Format(query, 511, "CREATE TABLE `Messages` (`ID`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,`BoxID`	INTEGER NOT NULL,`Message`	TEXT NOT NULL,`Topic`	TEXT NOT NULL,`AuthorName`	TEXT NOT NULL,`AuthorSID`	TEXT NOT NULL,`AuthorUserID`	ID NOT NULL,`Date`	TEXT NOT NULL);");	
}
public void CheckIf_Messages_QueryPassed(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogMessage("Could not create Messages table! Error: %s", error);
	}
}

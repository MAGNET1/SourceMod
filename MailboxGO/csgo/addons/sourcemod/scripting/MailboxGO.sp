#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

#define TAG "\x03[MailboxGO]\x01"

#define BOX_TYPE_PUBLIC 1
#define BOX_TYPE_LIMITED 2
#define BOX_TYPE_ANNOUNCEMENT 3

#define MAX_MAILBOX_CAPACITY 50
#define MAX_AMOUNT_OF_MAILBOXES 10

// macros defining what parameter does the admin type
#define CREATING_NAME 1
#define CREATING_DESCRIPTION 2
#define CREATING_PASSWORD 3
#define CREATING_CAPACITY 4
#define CREATING_TYPE 5
#define CREATING_CONFIRMATION 6

#define ROOTFLAG ADMFLAG_ROOT // allows to manage mailboxes
#define VIPFLAG ADMFLAG_CUSTOM1 // allows to access hidden mailboxes and send messages

#define NOTHING 0
#define MANAGING 1
#define CREATING 2

#define CREATING_TITLE 1
#define CREATING_MESSAGE 2

#define CHANGING_DESCRIPTION 1
#define CHANGING_PASSWORD 2

#define YES 1
#define NO 0

#define NOT_EXISTS -1

public Plugin myinfo =
{
    name = "MailboxGO",
    author = "MAGNET | YouTube: Koduj z Magnetem",
    description = "Allows Root Admin to create multiple in-game mailboxes, protected by password",
    version = "0.0.2",
    url = "http://go-code.pl/"
};

//ConVars
ConVar cvar_MaxMailboxCapacity;
ConVar cvar_MaxAmountOfMailboxes;

int MaxMailboxCapacity;
int MaxAmountOfMailboxes;

Database DB;
bool isConnectedWithDB = false;

// number of active mailboxes
int NumberOfMailboxes;

// holds index of the first free ArrayList Messages handler
int FirstFreeArrayIndex;

// checks if a certain player has chosen menu option that creates or manages mailbox
int IsManagingOrCreating[MAXPLAYERS]; // MailboxGO_Menu.sp

// integers defining who is creating new mailbox and the progress(example: right now admin X is defining a mailbox password/capacity etc.)
int ProgressOfCreatingMailbox;
int IdOfAdminCreatingMailbox;

// checks if a certain player is currently creating new message, and stores its array position
int IsCreatingNewMessage[MAXPLAYERS];
int IsCreatingNewMessageMailboxID[MAXPLAYERS];

// checks if a certain player is currently logging into a mailbox, and stores its array position
int IsLogging[MAXPLAYERS];
int IsLoggingMailboxID[MAXPLAYERS];

// checks if a certain player is currently changing informations of a mailbox, and stores its array position
int IsChanging[MAXPLAYERS];
int IsChangingMailboxID[MAXPLAYERS];

// stores index of message player is currently checking
int PlayerMessageID[MAXPLAYERS];

// checks if a certain player is currently browsing announcement mailboxes
int IsBrowsingAnnouncements[MAXPLAYERS];
int IsBrowsingAnnouncementsMailboxID[MAXPLAYERS];

//temporary variables for storing new mailbox specification during creation
char NewBoxName[64];
char NewBoxPassword[64];
char NewBoxDescription[64];
int NewBoxCapacity;
int NewBoxType;

// Arrays storing the list of mailboxes
ArrayList BoxListID;
ArrayList BoxListName;
ArrayList BoxListDescription;
ArrayList BoxListPassword;
ArrayList BoxListCapacity;
ArrayList BoxListAmountOfMessages;
ArrayList BoxListType;
ArrayList BoxListMessagesArrayIndex; // stores the index of corresponding 'Messages' Array, that holds all the letters

// Arrays containing all the mailboxes messages
// It doesn't load all the records rightaway - if a certain mailbox is called (example: someone is reading box, or sending message), plugin loads data
ArrayList MessagesID[MAX_MAILBOX_CAPACITY+1];
ArrayList MessagesMessage[MAX_MAILBOX_CAPACITY+1];
ArrayList MessagesTopic[MAX_MAILBOX_CAPACITY+1];
ArrayList MessagesAuthorName[MAX_MAILBOX_CAPACITY+1];
ArrayList MessagesAuthorSID[MAX_MAILBOX_CAPACITY+1];
ArrayList MessagesDate[MAX_MAILBOX_CAPACITY+1];

// Arrays storing temporarily a message that player is creating
ArrayList PlayerMessage[MAXPLAYERS];
ArrayList PlayerTitle[MAXPLAYERS];

// buffer for temporarily storing information of new password/descrition
ArrayList ChangesBuffer[MAXPLAYERS];

// array defining which mailboxes a user has access to after he has logged in
int HasAccessToMailbox[MAXPLAYERS][MAX_AMOUNT_OF_MAILBOXES];

char ColorsName[][] =  { "{default}", "{darkred}", "{purple}", "{green}", "{lightgreen}", "{mediumgreen}", "{lightred}", "{lightpurple}", "{yellow}", "{greyblue}", "{blue}", "{violet}", "{firered}" };
char ColorsTag[][] =  { "\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x0A", "\x0C", "\x0E", "\x0F" };

public OnPluginStart()
{
	LoadTranslations("myboxgo.phrasesFinal");
	
	InitConVars(); // MailboxGO_ConVar.sp
	SQL_InitConnection(); // MailboxGO_SQLConnect.sp
	InitDynamicTables(); // MailboxGO.sp
	InitRetrievingMailboxList(); // MailboxGO_SQLLoadData.sp
	
	RegConsoleCmd("say", ProcessChatIfCreatingNewMailbox);
	RegConsoleCmd("say_team", ProcessChatIfCreatingNewMailbox);
	RegConsoleCmd("say", ProcessChatIfCreatingNewMessage);
	RegConsoleCmd("say_team", ProcessChatIfCreatingNewMessage);
	RegConsoleCmd("say", ProcessChatIfLogging);
	RegConsoleCmd("say_team", ProcessChatIfLogging);
	RegConsoleCmd("say", ProcessChatIfChangingMailboxDetails);
	RegConsoleCmd("say_team", ProcessChatIfChangingMailboxDetails);
	RegConsoleCmd("sm_mb", ShowMailboxMenu);
	
}

public void OnMapStart()
{
	PrecacheSounds(); // MailboxGO_Sounds.sp
	DownloadSounds();
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	
	return true;
}

public void OnClientDisconnect(int client)
{
	for (int i = 0; i < NumberOfMailboxes; i++)	HasAccessToMailbox[client][i] = 0;
	
	if (IdOfAdminCreatingMailbox == client)
	{
		IdOfAdminCreatingMailbox = 0;
		ProgressOfCreatingMailbox = 0;
	}
	IsManagingOrCreating[client] = 0;
	
	IsCreatingNewMessage[client] = 0;
	IsCreatingNewMessageMailboxID[client] = 0;

	IsLogging[client] = 0;
	IsLoggingMailboxID[client] = 0;
	
	PlayerMessageID[client] = 0;
	
	IsChanging[client] = 0;
	IsChangingMailboxID[client] = 0;
	
	IsBrowsingAnnouncements[client] = 0;
	IsBrowsingAnnouncementsMailboxID[client] = 0;
	
	ClearArray(PlayerMessage[client]);
	ClearArray(PlayerTitle[client]);
	ClearArray(ChangesBuffer[client]);
}

public void InitDynamicTables()
{
	BoxListID = CreateArray(4);
	BoxListName = CreateArray(22);
	BoxListDescription = CreateArray(32);
	BoxListPassword = CreateArray(22);
	BoxListCapacity = CreateArray(4);
	BoxListAmountOfMessages = CreateArray(4);
	BoxListType = CreateArray(3);
	BoxListMessagesArrayIndex = CreateArray(3);
	
	
	for (int i = 0; i < MAX_MAILBOX_CAPACITY+1;i++)
	{
		MessagesID[i] = CreateArray(9);
		MessagesMessage[i] = CreateArray(300);
		MessagesTopic[i] = CreateArray(20);
		MessagesAuthorName[i] = CreateArray(MAX_NAME_LENGTH);
		MessagesAuthorSID[i] = CreateArray(64);
		MessagesDate[i] = CreateArray(12);
	}
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		PlayerMessage[i] = CreateArray(64);
		PlayerTitle[i] = CreateArray(32);
		ChangesBuffer[i] = CreateArray(40);
	}
}

int hasRootFlag(int client)
{
	return (GetUserFlagBits(client) & ADMFLAG_ROOT);
}

int hasVipFlag(int client)
{
	return (GetUserFlagBits(client) & ADMFLAG_CUSTOM1);
}

#include <MailboxGO/MailboxGO_SQLConnect.sp>
#include <MailboxGO/MailboxGO_SQLLoadData.sp>
#include <MailboxGO/MailboxGO_Menu.sp>
#include <MailboxGO/MailboxGO_CreatingNewMailbox.sp>
#include <MailboxGO/MailboxGO_CreatingNewMessage.sp>
#include <MailboxGO/MailboxGO_ChangingMailboxData.sp>
#include <MailboxGO/MailboxGO_Logging.sp>
#include <MailboxGO/MailboxGO_Deleting.sp>
#include <MailboxGO/MailboxGO_ConVar.sp>
#include <MailboxGO/MailboxGO_GoPrint.sp>
#include <MailboxGO/MailboxGO_Sound.sp>
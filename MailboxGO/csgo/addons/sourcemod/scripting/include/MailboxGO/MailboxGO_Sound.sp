public void PrecacheSounds()
{
	PrecacheSound("*/MailboxGO/NewMessage.mp3", true);
	PrecacheSound("*/MailboxGO/MessageSent.mp3", true);
	PrecacheSound("*/MailboxGO/WrongPassword.mp3", true);
	PrecacheSound("*/MailboxGO/LoggedIn.mp3", true);
	PrecacheSound("*/MailboxGO/Deleted.mp3", true);
	PrecacheSound("*/MailboxGO/Success.mp3", true);
}

public void DownloadSounds()
{
	AddFileToDownloadsTable("sound/MailboxGO/NewMessage.mp3");
	AddFileToDownloadsTable("sound/MailboxGO/MessageSent.mp3");
	AddFileToDownloadsTable("sound/MailboxGO/WrongPassword.mp3");
	AddFileToDownloadsTable("sound/MailboxGO/LoggedIn.mp3");
	AddFileToDownloadsTable("sound/MailboxGO/Deleted.mp3");
	AddFileToDownloadsTable("sound/MailboxGO/Success.mp3");
}

public void PlaySound_NewMessage(int client)
{
	EmitSoundToClient(client, "*/MailboxGO/NewMessage.mp3");
}

public void PlaySound_MessageSent(int client)
{
	EmitSoundToClient(client, "*/MailboxGO/MessageSent.mp3");
}

public void PlaySound_WrongPassword(int client)
{
	EmitSoundToClient(client, "*/MailboxGO/WrongPassword.mp3");
}

public void PlaySound_LoggedIn(int client)
{
	EmitSoundToClient(client, "*/MailboxGO/LoggedIn.mp3");
}

public void PlaySound_Deleted(int client)
{
	EmitSoundToClient(client, "*/MailboxGO/Deleted.mp3");
}

public void PlaySound_Success(int client)
{
	EmitSoundToClient(client, "*/MailboxGO/Success.mp3");
}